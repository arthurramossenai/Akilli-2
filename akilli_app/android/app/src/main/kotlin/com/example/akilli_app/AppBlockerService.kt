package com.example.akilli_app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.CountDownTimer
import android.view.accessibility.AccessibilityEvent
import androidx.core.app.NotificationCompat

class AppBlockerService : AccessibilityService() {

    companion object {
        var blockedPackages: MutableSet<String> = mutableSetOf()
        var taskName: String = ""
        var isEnabled: Boolean = false
        var snoozedUntil: MutableMap<String, Long> = mutableMapOf() // pkg -> timestamp
        var activeTimers: MutableMap<String, CountDownTimer> = mutableMapOf()
        
        fun startSnoozeTimer(context: Context, packageName: String) {
            val durationMs = 2 * 60 * 1000L // 2 minutos
            snoozedUntil[packageName] = System.currentTimeMillis() + durationMs

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channelId = "snooze_channel"

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(channelId, "Snooze de Foco", NotificationManager.IMPORTANCE_LOW)
                notificationManager.createNotificationChannel(channel)
            }

            activeTimers[packageName]?.cancel() // Cancela timer anterior se houver
            
            val notificationId = packageName.hashCode()

            val timer = object : CountDownTimer(durationMs, 1000) {
                override fun onTick(millisUntilFinished: Long) {
                    val seconds = (millisUntilFinished / 1000).toInt()
                    val m = seconds / 60
                    val s = seconds % 60
                    val timeStr = String.format("%02d:%02d", m, s)

                    val notification = NotificationCompat.Builder(context, channelId)
                        .setSmallIcon(android.R.drawable.ic_dialog_alert)
                        .setContentTitle("App desbloqueado temporariamente")
                        .setContentText("O app será bloqueado em $timeStr")
                        .setOnlyAlertOnce(true)
                        .setOngoing(true)
                        .build()

                    notificationManager.notify(notificationId, notification)
                }

                override fun onFinish() {
                    notificationManager.cancel(notificationId)
                    snoozedUntil.remove(packageName)
                    activeTimers.remove(packageName)
                }
            }
            activeTimers[packageName] = timer
            timer.start()
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 300
        }
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isEnabled || event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        if (packageName == "com.example.akilli_app") return
        if (packageName == "com.android.settings") return
        if (packageName == "com.android.systemui") return

        if (!blockedPackages.contains(packageName)) return

        val snoozeEnd = snoozedUntil[packageName]
        if (snoozeEnd != null && System.currentTimeMillis() < snoozeEnd) {
            return
        }

        val overlayIntent = Intent(this, BlockOverlayActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("blocked_package", packageName)
            putExtra("task_name", taskName)
        }
        startActivity(overlayIntent)
    }

    override fun onInterrupt() {}
}
