import 'package:flutter/services.dart';

/// Tüm uygulama verisinin tek bir metin (JSON) olarak saklandığı yer.
abstract class VeriKaydi {
  /// Kayıtlı metni okur. Hiç kayıt yoksa null döner. Okuma başarısızsa hata fırlatır.
  Future<String?> oku();

  /// Metni yazar (eskisinin yerine geçer).
  Future<void> yaz(String icerik);
}

/// Telefonun uygulama klasöründeki dosyaya yazar (Android tarafı: MainActivity.kt).
/// Dosya, uygulama silinene kadar kalır; yazma önce geçici dosyaya yapılıp yer değiştirilir,
/// böylece yazarken kapanma durumunda eski veri bozulmaz.
class DosyaKaydi implements VeriKaydi {
  const DosyaKaydi();

  static const MethodChannel _kanal = MethodChannel('com.mytus.app/storage');

  @override
  Future<String?> oku() => _kanal.invokeMethod<String>('read');

  @override
  Future<void> yaz(String icerik) async {
    await _kanal.invokeMethod<Object>('write', {'content': icerik});
  }
}

/// Testler için bellekte tutan kayıt.
class BellekKaydi implements VeriKaydi {
  BellekKaydi({this.icerik, this.okumaHatasi = false});

  String? icerik;
  bool okumaHatasi;
  int yazmaSayisi = 0;

  @override
  Future<String?> oku() async {
    if (okumaHatasi) throw StateError('okuma hatası');
    return icerik;
  }

  @override
  Future<void> yaz(String icerik) async {
    this.icerik = icerik;
    yazmaSayisi++;
  }
}
