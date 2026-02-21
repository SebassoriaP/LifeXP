package com.example.lifexp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class StickyNotificationService : Service() {
    companion object {
        private const val CHANNEL_ID = "lifexp_daily_v2"
        private const val CHANNEL_NAME = "LifeXP Daily"
        private const val CHANNEL_DESC = "Daily reminder to complete missions or focus"
        private const val NOTIFICATION_ID = 2001

        const val ACTION_START = "lifexp.action.START_STICKY"
        const val ACTION_STOP = "lifexp.action.STOP_STICKY"
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> stopSticky()
            else -> startSticky()
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startSticky() {
        createChannelIfNeeded()
        startForeground(NOTIFICATION_ID, buildNotification())
    }

    private fun stopSticky() {
        NotificationManagerCompat.from(this).cancel(NOTIFICATION_ID)
        @Suppress("DEPRECATION")
        stopForeground(true)
        stopSelf()
    }

    private fun buildNotification(): Notification {
        val openHomeIntent = Intent(this, StickyActionReceiver::class.java).apply {
            action = StickyActionReceiver.ACTION_OPEN_HOME
        }
        val openHomePending = PendingIntent.getBroadcast(
            this,
            10,
            openHomeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val focusIntent = Intent(this, StickyActionReceiver::class.java).apply {
            action = StickyActionReceiver.ACTION_FOCUS_30
        }
        val focusPending = PendingIntent.getBroadcast(
            this,
            11,
            focusIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val completeIntent = Intent(this, StickyActionReceiver::class.java).apply {
            action = StickyActionReceiver.ACTION_COMPLETE
        }
        val completePending = PendingIntent.getBroadcast(
            this,
            12,
            completeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        // NOTE: Even with ongoing foreground notifications, some OEMs still allow swipe-away.
        // Foreground service provides the strongest persistence available in Android app layer.
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("LifeXP")
            .setContentText("Completa 1 misión o haz Focus 30 💪")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .addAction(0, "Open", openHomePending)
            .addAction(0, "Focus 30", focusPending)
            .addAction(0, "Complete", completePending)
            .build()
    }

    private fun createChannelIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = manager.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = CHANNEL_DESC
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }
}
