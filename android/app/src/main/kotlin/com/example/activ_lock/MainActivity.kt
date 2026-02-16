package com.example.activ_lock

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.activlock/native"
    private var pendingLockedPackage: String? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Handle initial intent if app was launched by service
        handleIntent(intent, flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "isAccessibilityServiceEnabled" -> {
                    val contentResolver = contentResolver
                    val enabledServices = android.provider.Settings.Secure.getString(contentResolver, android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
                    val packageName = packageName
                    val isEnabled = enabledServices?.contains("$packageName/$packageName.AppAccessibilityService") == true
                    result.success(isEnabled)
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(intent)
                    result.success(null)
                }
                "showLockScreen" -> {
                    val intent = Intent(this, MainActivity::class.java)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    startActivity(intent)
                    result.success(null)
                }
                "getPendingLockedPackage" -> {
                    result.success(pendingLockedPackage)
                    pendingLockedPackage = null
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        flutterEngine?.let { handleIntent(intent, it) }
    }

    private fun handleIntent(intent: Intent, flutterEngine: FlutterEngine) {
        val lockedPackage = intent.getStringExtra("locked_package")
        if (lockedPackage != null) {
            pendingLockedPackage = lockedPackage
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .invokeMethod("navigateToLockScreen", lockedPackage)
        }
    }
}
