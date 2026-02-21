package com.example.lifexp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.content.ContextCompat

class StickyBootReceiver : BroadcastReceiver() {
    companion object {
        private const val KEY_ENABLED = "sticky_enabled"
        private const val KEY_LAST_DATE = "sticky_last_date"
        private const val KEY_LAST_SYNC_AT = "sticky_last_sync_at"
        private const val KEY_LAST_DECISION = "sticky_last_decision"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        Log.d("StickyBootReceiver", "onReceive action=$action")

        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }

        val prefs = context.getSharedPreferences("lifexp_prefs", Context.MODE_PRIVATE)
        val enabled = prefs.getBoolean(KEY_ENABLED, true)
        val lastDate = prefs.getString(KEY_LAST_DATE, null)
        val nowMs = System.currentTimeMillis()
        val lastSyncAt = prefs.getLong(KEY_LAST_SYNC_AT, 0L)
        val today = DateUtil.todayLocalIsoDate()
        val cooldownMs = 10 * 60 * 1000L
        val inCooldown = (nowMs - lastSyncAt) < cooldownMs
        val shouldStart = enabled && !inCooldown && (lastDate == null || lastDate != today)

        Log.d(
            "StickyBootReceiver",
            "enabled=$enabled lastDate=$lastDate today=$today inCooldown=$inCooldown shouldStart=$shouldStart",
        )

        if (!shouldStart) return

        prefs.edit()
            .putString(KEY_LAST_DATE, today)
            .putLong(KEY_LAST_SYNC_AT, nowMs)
            .putString(KEY_LAST_DECISION, "start")
            .apply()

        val serviceIntent = Intent(context, StickyNotificationService::class.java).apply {
            this.action = StickyNotificationService.ACTION_START
        }
        ContextCompat.startForegroundService(context, serviceIntent)
    }
}
