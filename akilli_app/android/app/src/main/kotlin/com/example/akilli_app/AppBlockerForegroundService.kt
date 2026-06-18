package com.example.akilli_app

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.app.usage.UsageStatsManager
import android.app.usage.UsageEvents
import androidx.core.app.NotificationCompat
import java.util.Timer
import java.util.TimerTask

class AppBlockerForegroundService : Service() {

    companion object {
        var blockedPackages: MutableSet<String> = mutableSetOf()
        var taskName: String = ""
        var isEnabled: Boolean = false
        var snoozedUntil: MutableMap<String, Long> = mutableMapOf()

        // Referência para snooze timer (usa Handler no BlockOverlay)
        fun startSnooze(packageName: String, durationMs: Long = 2 * 60 * 1000L) {
            snoozedUntil[packageName] = System.currentTimeMillis() + durationMs
        }
    }

    private var pollingTimer: Timer? = null
    private val CHANNEL_ID = "akilli_blocker_channel"
    private val NOTIFICATION_ID = 9001

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "START" -> {
                val packages = intent.getStringArrayListExtra("packages") ?: arrayListOf()
                val task = intent.getStringExtra("taskName") ?: ""
                blockedPackages.clear()
                blockedPackages.addAll(packages)
                taskName = task
                isEnabled = packages.isNotEmpty()

                if (isEnabled) {
                    startForegroundWithNotification()
                    startPolling()
                } else {
                    stopPolling()
                    stopSelf()
                }
            }
            "STOP" -> {
                blockedPackages.clear()
                isEnabled = false
                taskName = ""
                snoozedUntil.clear()
                stopPolling()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_STICKY
    }

    private fun startForegroundWithNotification() {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Android 14+ requires foreground service type
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun buildNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentTitle("Modo Foco Ativo 🔒")
            .setContentText("Tarefa: $taskName")
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Modo Foco Akilli",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notificação do Modo Foco ativo"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun startPolling() {
        stopPolling() // Limpa timer anterior
        android.util.Log.d("AkilliBloquer", "Polling started. Blocked: $blockedPackages")
        pollingTimer = Timer()
        pollingTimer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                if (!isEnabled || blockedPackages.isEmpty()) return
                val currentPkg = getForegroundPackage()
                if (currentPkg != null && blockedPackages.contains(currentPkg)) {
                    // Verificar snooze
                    val snoozeEnd = snoozedUntil[currentPkg]
                    if (snoozeEnd != null && System.currentTimeMillis() < snoozeEnd) {
                        return // Está em snooze
                    }

                    android.util.Log.d("AkilliBloquer", "BLOCKING: $currentPkg")
                    // App bloqueado detectado, lançar overlay
                    val overlayIntent = Intent(this@AppBlockerForegroundService, BlockOverlayActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        putExtra("blocked_package", currentPkg)
                        putExtra("task_name", taskName)
                    }
                    startActivity(overlayIntent)
                }
            }
        }, 0, 1500) // Verifica a cada 1.5 segundos
    }

    private fun stopPolling() {
        pollingTimer?.cancel()
        pollingTimer = null
    }

    private fun getForegroundPackage(): String? {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return null
        val now = System.currentTimeMillis()
        val events = usm.queryEvents(now - 5000, now) // Últimos 5 segundos
        var lastPkg: String? = null
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                lastPkg = event.packageName
            }
        }
        return lastPkg
    }

    override fun onDestroy() {
        stopPolling()
        super.onDestroy()
    }
}
