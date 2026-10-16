import 'package:flutter/services.dart';

/// Android tarafıyla konuşan köprü (alarm, bildirim, pil ayarları, küçük kayıt alanı).
/// Android dışında veya testlerde köprü yoktur; o zaman her çağrı sessizce "bilinmiyor" (null) döner.
class FtNative {
  const FtNative();

  static const MethodChannel _kanal = MethodChannel('com.mytus.app/timer');

  Future<T?> _cagir<T>(String yontem, [Map<String, Object?>? degiskenler]) async {
    try {
      return await _kanal.invokeMethod<T>(yontem, degiskenler);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Android köprüsü çalışıyor mu?
  Future<bool> kullanilabilir() async => (await _cagir<bool>('ping')) ?? false;

  /// Derleme numarası (hangi sürümün kurulu olduğunu anlamak için). Bilinmiyorsa null.
  Future<String?> derlemeNo() => _cagir<String>('buildNumber');

  /// Bitiş saatinde (epoch ms) çalacak alarmı kurar ve geri sayımlı bildirimi gösterir.
  Future<void> alarmKur(int bitisMs) async {
    await _cagir<Object>('schedule', {'endAtMs': bitisMs});
  }

  /// Alarmı ve "çalışıyor" bildirimini kaldırır.
  Future<void> alarmIptal() async {
    await _cagir<Object>('cancel');
  }

  Future<void> calisanBildirimiKaldir() async {
    await _cagir<Object>('dismissRunning');
  }

  Future<void> bitenBildirimiKaldir() async {
    await _cagir<Object>('dismissDone');
  }

  /// Bildirimler açık mı? (bilinmiyorsa null)
  Future<bool?> bildirimAcik() => _cagir<bool>('notificationsEnabled');

  Future<void> bildirimIzniIste() async {
    await _cagir<Object>('requestNotificationPermission');
  }

  /// Pil tasarrufu bu uygulamayı kısıtlamıyor mu? (bilinmiyorsa null)
  Future<bool?> pilKisitsiz() => _cagir<bool>('batteryUnrestricted');

  Future<void> pilAyarlariniAc() async {
    await _cagir<Object>('openBatterySettings');
  }

  Future<void> uygulamaAyarlariniAc() async {
    await _cagir<Object>('openAppSettings');
  }

  /// Küçük kayıt alanı (sayaç durumu, "rehber görüldü" bilgisi, alarm kaydı).
  Future<String?> kayitOku(String anahtar) =>
      _cagir<String>('kvGet', {'key': anahtar});

  Future<void> kayitYaz(String anahtar, String deger) async {
    await _cagir<Object>('kvSet', {'key': anahtar, 'value': deger});
  }
}
