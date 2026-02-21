package com.example.lifexp

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.TextView

class BlockedActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_blocked)

        val prefs = getSharedPreferences("lifexp_prefs", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("blocking_now", true).apply()

        val blockedPkg = intent.getStringExtra("blocked_pkg") ?: "App"
        findViewById<TextView>(R.id.sub).text = "Blocked: $blockedPkg"

        findViewById<Button>(R.id.btnBack).setOnClickListener {
            prefs.edit().putBoolean("blocking_now", false).apply()
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            startActivity(launchIntent)
            finish()
        }

        findViewById<Button>(R.id.btnEnd).setOnClickListener {
            prefs.edit()
                .putString("pending_action", "end_focus")
                .putBoolean("blocking_now", false)
                .apply()

            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            startActivity(launchIntent)
            finish()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        val prefs = getSharedPreferences("lifexp_prefs", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("blocking_now", false).apply()
    }
}
