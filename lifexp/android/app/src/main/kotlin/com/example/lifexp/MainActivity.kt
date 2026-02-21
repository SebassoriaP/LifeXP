package com.example.lifexp

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "lifexp/sticky_service"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                val prefs = getSharedPreferences("lifexp_prefs", Context.MODE_PRIVATE)
                when (call.method) {
                    "startSticky" -> {
                        val intent = Intent(this, StickyNotificationService::class.java).apply {
                            action = StickyNotificationService.ACTION_START
                        }
                        startForegroundService(intent)
                        result.success(null)
                    }
                    "stopSticky" -> {
                        val intent = Intent(this, StickyNotificationService::class.java).apply {
                            action = StickyNotificationService.ACTION_STOP
                        }
                        startService(intent)
                        result.success(null)
                    }
                    "setStickyEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        prefs.edit().putBoolean("sticky_enabled", enabled).apply()
                        result.success(null)
                    }
                    "getStickyEnabled" -> {
                        result.success(prefs.getBoolean("sticky_enabled", true))
                    }
                    "setStickyLastDate" -> {
                        val date = call.argument<String>("date")
                        prefs.edit().putString("sticky_last_date", date).apply()
                        result.success(null)
                    }
                    "setStickyLastSyncAt" -> {
                        val ms = call.argument<Number>("ms")?.toLong() ?: 0L
                        prefs.edit().putLong("sticky_last_sync_at", ms).apply()
                        result.success(null)
                    }
                    "getStickyLastSyncAt" -> {
                        result.success(prefs.getLong("sticky_last_sync_at", 0L))
                    }
                    "setStickyLastDecision" -> {
                        val decision = call.argument<String>("decision") ?: ""
                        prefs.edit().putString("sticky_last_decision", decision).apply()
                        result.success(null)
                    }
                    "getStickyLastDecision" -> {
                        result.success(prefs.getString("sticky_last_decision", "") ?: "")
                    }
                    "getStickyLastDate" -> {
                        result.success(prefs.getString("sticky_last_date", "") ?: "")
                    }
                    "getPendingAction" -> {
                        result.success(prefs.getString("pending_action", "") ?: "")
                    }
                    "clearPendingAction" -> {
                        prefs.edit().remove("pending_action").apply()
                        result.success(null)
                    }
                    "setFocusModeActive" -> {
                        val active = call.argument<Boolean>("active") ?: false
                        prefs.edit().putBoolean("focus_mode_active", active).apply()
                        if (!active) {
                            prefs.edit().putBoolean("blocking_now", false).apply()
                        }
                        result.success(null)
                    }
                    "setBlockedPackages" -> {
                        val json = call.argument<String>("json") ?: "[]"
                        prefs.edit().putString("blocked_packages", json).apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
