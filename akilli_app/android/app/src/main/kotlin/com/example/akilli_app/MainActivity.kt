package com.example.akilli_app

import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.akilli/app_blocker"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setBlockedApps" -> {
                    val packages = call.argument<List<String>>("packages") ?: listOf()
                    val taskName = call.argument<String>("taskName") ?: ""
                    AppBlockerService.blockedPackages.clear()
                    AppBlockerService.blockedPackages.addAll(packages)
                    AppBlockerService.taskName = taskName
                    AppBlockerService.isEnabled = packages.isNotEmpty()
                    AppBlockerService.snoozedUntil.clear()
                    result.success(true)
                }
                "clearBlockedApps" -> {
                    AppBlockerService.blockedPackages.clear()
                    AppBlockerService.isEnabled = false
                    AppBlockerService.taskName = ""
                    AppBlockerService.snoozedUntil.clear()
                    result.success(true)
                }
                "isAccessibilityEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "checkMotivationIntent" -> {
                    val hasMotivation = intent?.getBooleanExtra("show_motivation", false) ?: false
                    // Limpa a flag para não disparar duas vezes
                    intent?.removeExtra("show_motivation")
                    result.success(hasMotivation)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Se voltou pelo overlay com motivação, o Flutter tratará via intent extras
        if (intent.getBooleanExtra("show_motivation", false)) {
            // O Flutter pode ler isso via MethodChannel se necessário
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        
        return enabledServices.contains("com.example.akilli_app/com.example.akilli_app.AppBlockerService") || 
               enabledServices.contains("AppBlockerService")
    }
}
