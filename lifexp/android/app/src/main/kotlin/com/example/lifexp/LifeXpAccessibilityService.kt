package com.example.lifexp

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import org.json.JSONArray

class LifeXpAccessibilityService : AccessibilityService() {
    override fun onServiceConnected() {
        Log.d("LifeXpAccessibility", "Service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val pkg = event.packageName?.toString() ?: return
        if (pkg.isBlank()) return
        if (pkg == packageName) return
        if (pkg == "com.android.systemui") return

        val prefs = getSharedPreferences("lifexp_prefs", Context.MODE_PRIVATE)
        val active = prefs.getBoolean("focus_mode_active", false)
        if (!active) return

        val blockedJson = prefs.getString("blocked_packages", "[]") ?: "[]"
        val blocked = parseBlocked(blockedJson)
        if (!blocked.contains(pkg)) return

        val alreadyBlocking = prefs.getBoolean("blocking_now", false)
        if (alreadyBlocking) return

        prefs.edit().putBoolean("blocking_now", true).apply()
        Log.d("LifeXpAccessibility", "Blocking package=$pkg")

        val i = Intent(this, BlockedActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("blocked_pkg", pkg)
        }
        startActivity(i)
    }

    override fun onInterrupt() {}

    private fun parseBlocked(json: String): Set<String> {
        return try {
            val arr = JSONArray(json)
            val out = HashSet<String>()
            for (i in 0 until arr.length()) {
                out.add(arr.getString(i))
            }
            out
        } catch (e: Exception) {
            emptySet()
        }
    }
}
