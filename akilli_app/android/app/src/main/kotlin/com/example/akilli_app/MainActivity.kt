package com.example.akilli_app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.app.AppOpsManager
import android.content.Context
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

                    val serviceIntent = Intent(this, AppBlockerForegroundService::class.java).apply {
                        action = "START"
                        putStringArrayListExtra("packages", ArrayList(packages))
                        putExtra("taskName", taskName)
                    }

                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    result.success(true)
                }
                "clearBlockedApps" -> {
                    val serviceIntent = Intent(this, AppBlockerForegroundService::class.java).apply {
                        action = "STOP"
                    }
                    try {
                        startService(serviceIntent)
                    } catch (_: Exception) {}
                    result.success(true)
                }
                "isAccessibilityEnabled" -> {
                    // Verifica se Usage Stats E Overlay estão ambas ativas
                    val usageOk = isUsageStatsPermissionGranted()
                    val overlayOk = Settings.canDrawOverlays(this)
                    result.success(usageOk && overlayOk)
                }
                "openAccessibilitySettings" -> {
                    // Abre a tela de permissão que falta
                    if (!Settings.canDrawOverlays(this)) {
                        // Prioriza overlay pois é o que bloqueia visualmente
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                    } else if (!isUsageStatsPermissionGranted()) {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "canDrawOverlays" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                "openOverlaySettings" -> {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    )
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "checkMotivationIntent" -> {
                    val hasMotivation = intent?.getBooleanExtra("show_motivation", false) ?: false
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
        
        if (intent.getBooleanExtra("show_motivation", false)) {
            // O Flutter tratará via MethodChannel
        }
    }

    private fun isUsageStatsPermissionGranted(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
