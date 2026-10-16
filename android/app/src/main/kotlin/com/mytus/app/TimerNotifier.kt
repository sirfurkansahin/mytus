package com.mytus.app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build

// F.T. time sayacinin Android tarafi: alarm kurma, bildirim gosterme, kucuk kayit alani.
// Yalnizca Android'in kendi (cerceve) siniflarini kullanir; ek paket yoktur.
object TimerNotifier {
    const val ACTION_DONE = "com.mytus.app.TIMER_DONE"
    const val EXTRA_END_AT = "endAtMs"

    private const val PREFS = "mytus_native"
    private const val CH_RUNNING = "mytus_timer_running"
    private const val CH_DONE = "mytus_timer_done"
    const val ID_RUNNING = 1
    private const val ID_DONE = 2
    private val VIBRATION = longArrayOf(0, 500, 250, 500, 250, 500)

    fun prefs(ctx: Context): SharedPreferences =
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun pendingFlags(): Int =
        PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= 23) PendingIntent.FLAG_IMMUTABLE else 0)

    // Bildirime dokununca uygulamayi ac.
    private fun openAppIntent(ctx: Context): PendingIntent {
        val intent = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName) ?: Intent()
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
        return PendingIntent.getActivity(ctx, 0, intent, pendingFlags())
    }

    private fun alarmIntent(ctx: Context, endAtMs: Long): PendingIntent {
        val intent = Intent(ctx, TimerAlarmReceiver::class.java)
        intent.action = ACTION_DONE
        intent.putExtra(EXTRA_END_AT, endAtMs)
        return PendingIntent.getBroadcast(ctx, 1, intent, pendingFlags())
    }

    private fun notificationManager(ctx: Context): NotificationManager =
        ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun ensureChannels(ctx: Context) {
        if (Build.VERSION.SDK_INT < 26) return
        val nm = notificationManager(ctx)
        val running = NotificationChannel(CH_RUNNING, "Çalışan sayaç", NotificationManager.IMPORTANCE_LOW)
        running.setShowBadge(false)
        val done = NotificationChannel(CH_DONE, "Süre bitti", NotificationManager.IMPORTANCE_HIGH)
        done.enableVibration(true)
        done.vibrationPattern = VIBRATION
        done.setSound(null, null)
        done.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        nm.createNotificationChannel(running)
        nm.createNotificationChannel(done)
    }

    @Suppress("DEPRECATION")
    private fun newBuilder(ctx: Context, channel: String): Notification.Builder =
        if (Build.VERSION.SDK_INT >= 26) Notification.Builder(ctx, channel) else Notification.Builder(ctx)

    // Alarmi kurar (telefon kilitli/uykuda olsa bile) ve calisan sayac bildirimini gosterir.
    // setAlarmClock: Android'in "saat alarmi" turu. Pil tasarrufundan en az etkilenen turdur
    // ve ayrica "tam zamanli alarm" izni istemez.
    // Bildirim bir on plan servisi uzerinden gosterilir: boylece sistem (ozellikle bazi
    // telefon markalari) uygulamayi arka planda oldurup alarmi silemez.
    fun schedule(ctx: Context, endAtMs: Long) {
        ensureChannels(ctx)
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.setAlarmClock(AlarmManager.AlarmClockInfo(endAtMs, openAppIntent(ctx)), alarmIntent(ctx, endAtMs))
        startRunningService(ctx, endAtMs)
    }

    // Servis baslatilamazsa (ornegin sistem izin vermezse) duz bildirime geri donulur.
    private fun startRunningService(ctx: Context, endAtMs: Long) {
        try {
            val intent = Intent(ctx, TimerService::class.java)
            intent.putExtra(EXTRA_END_AT, endAtMs)
            if (Build.VERSION.SDK_INT >= 26) ctx.startForegroundService(intent) else ctx.startService(intent)
        } catch (e: Exception) {
            prefs(ctx).edit().putString("svc_error", e.toString()).apply()
            notificationManager(ctx).notify(ID_RUNNING, buildRunning(ctx, endAtMs))
        }
    }

    fun buildRunning(ctx: Context, endAtMs: Long): Notification {
        ensureChannels(ctx)
        val b = newBuilder(ctx, CH_RUNNING)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("F.T. time çalışıyor")
            .setContentText("Süre bitince seni uyaracağım")
            .setWhen(endAtMs)
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(openAppIntent(ctx))
        if (Build.VERSION.SDK_INT >= 24) b.setChronometerCountDown(true)
        if (Build.VERSION.SDK_INT >= 31) {
            b.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
        }
        return b.build()
    }

    // Alarmi ve "calisiyor" bildirimini kaldirir (duraklat / sifirla).
    fun cancel(ctx: Context) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.cancel(alarmIntent(ctx, 0L))
        dismissRunning(ctx)
    }

    // Servisi durdurur (bildirimi de kalkar); servis yoksa bildirimi dogrudan siler.
    fun dismissRunning(ctx: Context) {
        try {
            ctx.stopService(Intent(ctx, TimerService::class.java))
        } catch (e: Exception) {
            // Servis zaten yoksa bir sey yapmaya gerek yok.
        }
        notificationManager(ctx).cancel(ID_RUNNING)
    }

    fun dismissDone(ctx: Context) {
        notificationManager(ctx).cancel(ID_DONE)
    }

    // Sure bitti bildirimi: titresim (kanal ayari) + kilit ekraninda gorunur.
    @Suppress("DEPRECATION")
    fun showDone(ctx: Context) {
        ensureChannels(ctx)
        val b = newBuilder(ctx, CH_DONE)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("Süre bitti")
            .setContentText("Uygulamayı açıp devam edebilirsin.")
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setContentIntent(openAppIntent(ctx))
        if (Build.VERSION.SDK_INT < 26) {
            b.setPriority(Notification.PRIORITY_HIGH)
            b.setVibrate(VIBRATION)
        }
        notificationManager(ctx).notify(ID_DONE, b.build())
    }
}
