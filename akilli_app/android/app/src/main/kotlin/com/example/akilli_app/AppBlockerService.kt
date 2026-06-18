package com.example.akilli_app

// DEPRECATED: Este arquivo não é mais utilizado.
// O bloqueio agora é feito via AppBlockerForegroundService + UsageStatsManager.
// Mantido apenas para evitar erros de compilação em referências residuais.

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

class AppBlockerService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}
}
