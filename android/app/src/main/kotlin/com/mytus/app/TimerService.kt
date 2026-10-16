package com.mytus.app

import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

// Sayac calisirken sistemin uygulamayi arka planda oldurmesini zorlastirir (on plan servisi).
// Sure takibini alarm yapar; bu servis yalnizca "calisan sayac" bildirimini tutar ve
// uygulama surecini canli tutar. Sure bitince alici (TimerAlarmReceiver) servisi durdurur.
class TimerService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val endAt = intent?.getLongExtra(TimerNotifier.EXTRA_END_AT, 0L) ?: 0L
        val bildirim = TimerNotifier.buildRunning(this, endAt)
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(
                TimerNotifier.ID_RUNNING,
                bildirim,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(TimerNotifier.ID_RUNNING, bildirim)
        }
        return START_NOT_STICKY
    }
}
