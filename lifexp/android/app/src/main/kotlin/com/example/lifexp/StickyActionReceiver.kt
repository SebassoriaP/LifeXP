package com.example.lifexp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class StickyActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        Log.d("StickyActionReceiver", "onReceive action=$action")

        val prefs = context.getSharedPreferences("lifexp_prefs", Context.MODE_PRIVATE)
        when (action) {
            ACTION_OPEN_HOME -> prefs.edit().putString(KEY_PENDING_ACTION, "home").apply()
            ACTION_FOCUS_30 -> prefs.edit().putString(KEY_PENDING_ACTION, "focus30").apply()
            ACTION_COMPLETE -> prefs.edit().putString(KEY_PENDING_ACTION, "complete").apply()
            else -> return
        }

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        context.startActivity(launchIntent)
    }

    companion object {
        const val ACTION_OPEN_HOME = "lifexp.action.OPEN_HOME"
        const val ACTION_FOCUS_30 = "lifexp.action.FOCUS_30"
        const val ACTION_COMPLETE = "lifexp.action.COMPLETE"
        const val KEY_PENDING_ACTION = "pending_action"
    }
}
