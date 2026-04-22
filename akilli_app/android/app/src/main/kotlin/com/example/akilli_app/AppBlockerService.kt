package com.example.akilli_app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class AppBlockerService : AccessibilityService() {

    companion object {
        var blockedPackages: MutableSet<String> = mutableSetOf()
        var taskName: String = ""
        var isEnabled: Boolean = false
        var snoozedUntil: MutableMap<String, Long> = mutableMapOf() // pkg -> timestamp
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

        // Ignora o próprio app Akilli e a tela de configurações do sistema
        if (packageName == "com.example.akilli_app") return
        if (packageName == "com.android.settings") return
        if (packageName == "com.android.systemui") return

        // Verifica se o app está na lista de bloqueados
        if (!blockedPackages.contains(packageName)) return

        // Verifica se o app está em modo snooze (lembrar em 2 min)
        val snoozeEnd = snoozedUntil[packageName]
        if (snoozeEnd != null && System.currentTimeMillis() < snoozeEnd) {
            return // Ainda em snooze, não bloqueia
        }

        // Bloqueia! Abre a tela de overlay
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
