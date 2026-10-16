package com.mytus.app

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

// Flutter (Dart) ile Android arasindaki kopru. Kanal adi Dart tarafiyla ayni olmali.
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.mytus.app/timer")
            .setMethodCallHandler { call, result ->
                try {
                    handle(call, result)
                } catch (e: Exception) {
                    result.error("native_error", e.message, null)
                }
            }
        // Ikinci kanal: tum uygulama verisini tek bir dosyada saklar (dersler, konular, notlar).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.mytus.app/storage")
            .setMethodCallHandler { call, result ->
                try {
                    handleStorage(call, result)
                } catch (e: Exception) {
                    result.error("storage_error", e.message, null)
                }
            }
    }

    // Yazma: once gecici dosyaya yazilir, sonra asil dosyanin yerine gecirilir.
    // Boylece yazarken uygulama kapansa bile eski veri bozulmaz.
    private fun handleStorage(call: MethodCall, result: MethodChannel.Result) {
        val dosya = File(filesDir, "mytus_data.json")
        when (call.method) {
            "read" -> {
                result.success(if (dosya.exists()) dosya.readText(Charsets.UTF_8) else null)
            }
            "write" -> {
                val icerik = call.argument<String>("content") ?: ""
                val gecici = File(filesDir, "mytus_data.json.tmp")
                gecici.writeText(icerik, Charsets.UTF_8)
                if (!gecici.renameTo(dosya)) {
                    dosya.writeText(icerik, Charsets.UTF_8)
                    gecici.delete()
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "ping" -> result.success(true)
            "schedule" -> {
                val endAt = (call.argument<Number>("endAtMs") ?: 0L).toLong()
                TimerNotifier.schedule(this, endAt)
                result.success(null)
            }
            "cancel" -> {
                TimerNotifier.cancel(this)
                result.success(null)
            }
            "dismissRunning" -> {
                TimerNotifier.dismissRunning(this)
                result.success(null)
            }
            "dismissDone" -> {
                TimerNotifier.dismissDone(this)
                result.success(null)
            }
            "notificationsEnabled" -> {
                val nm = getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager
                val acik = if (Build.VERSION.SDK_INT >= 24) nm.areNotificationsEnabled() else true
                result.success(acik)
            }
            "requestNotificationPermission" -> {
                if (Build.VERSION.SDK_INT >= 33) {
                    requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
                }
                result.success(null)
            }
            "batteryUnrestricted" -> {
                val pm = getSystemService(POWER_SERVICE) as PowerManager
                val serbest = if (Build.VERSION.SDK_INT >= 23) pm.isIgnoringBatteryOptimizations(packageName) else true
                result.success(serbest)
            }
            "openBatterySettings" -> {
                try {
                    startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                } catch (e: Exception) {
                    openAppSettings()
                }
                result.success(null)
            }
            "openAppSettings" -> {
                openAppSettings()
                result.success(null)
            }
            "kvGet" -> {
                val key = call.argument<String>("key") ?: ""
                result.success(TimerNotifier.prefs(this).getString(key, null))
            }
            "kvSet" -> {
                val key = call.argument<String>("key") ?: ""
                val value = call.argument<String>("value")
                TimerNotifier.prefs(this).edit().putString(key, value).apply()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
        startActivity(intent)
    }
}
