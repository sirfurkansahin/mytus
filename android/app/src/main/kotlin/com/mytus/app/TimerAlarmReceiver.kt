package com.mytus.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

// Alarm zamani gelince Android bunu calistirir (uygulama kapali olsa bile).
// Ne zaman tetiklendigini kaydeder: bu kayit, prototipin "alarm gercekten calisti mi" olcumudur.
class TimerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TimerNotifier.ACTION_DONE) return
        val beklenen = intent.getLongExtra(TimerNotifier.EXTRA_END_AT, 0L)
        TimerNotifier.prefs(context).edit()
            .putString("last_fired_at", System.currentTimeMillis().toString())
            .putString("last_expected_end", beklenen.toString())
            .apply()
        TimerNotifier.dismissRunning(context)
        TimerNotifier.showDone(context)
    }
}
