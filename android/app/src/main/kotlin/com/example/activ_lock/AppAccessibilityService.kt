package com.example.activ_lock

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.content.Context
import android.content.SharedPreferences

class AppAccessibilityService : AccessibilityService() {
    private var nativeLockedApps: List<String> = emptyList()

    private val handler = android.os.Handler(android.os.Looper.getMainLooper())
    private val reloadRunnable = object : Runnable {
        override fun run() {
            loadLockedApps()
            handler.postDelayed(this, 2000) // Poll every 2 seconds
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        loadLockedApps()
        // Start polling
        handler.post(reloadRunnable)
    }

    private fun loadLockedApps() {
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val rawList = prefs.getString("flutter.native_locked_apps", "") ?: ""
        nativeLockedApps = if (rawList.isNotEmpty()) rawList.split(",") else emptyList()
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(reloadRunnable)
    }

    private var lastLockTime: Long = 0
    private val LOCK_TIMEOUT = 1000L // 1 second cooldown

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        // We now listen to STATE_CHANGED and CONTENT_CHANGED.
        // Filter out noise.
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED && 
            event.eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            return
        }

        val packageName = event.packageName?.toString() ?: return

        // Deduplicate rapid firing events
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastLockTime < LOCK_TIMEOUT) return

        if (nativeLockedApps.contains(packageName)) {
            // Check if it's really the app coming to foreground (simple check)
            // For now, if we match the package, we lock it.
            
            // App is locked! Launch our lock screen
            lastLockTime = currentTime
            android.util.Log.d("ActivLock", "Locking package: $packageName")
            
            val intent = Intent(this, MainActivity::class.java)
            // Critical Flags for Background Launch
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or 
                    Intent.FLAG_ACTIVITY_NO_USER_ACTION or 
                    Intent.FLAG_ACTIVITY_NO_HISTORY // Don't keep intent in history stack
            
            intent.putExtra("locked_package", packageName)
            intent.putExtra("route", "/lock_screen")
            
            startActivity(intent)
        }
    }

    override fun onInterrupt() {
        // Required method
    }
}
