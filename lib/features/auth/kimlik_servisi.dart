import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Uygulama içinde kullanılan yalın kullanıcı modeli.
class KullaniciBilgisi {
  const KullaniciBilgisi({
    required this.uid,
    required this.eposta,
    this.takmaAd,
  });

  final String uid;
  final String eposta;
  final String? takmaAd;
}

/// Türkçe hata mesajı taşıyan kimlik doğrulama hatası.
class KimlikHatasi implements Exception {
  const KimlikHatasi(this.mesaj, {this.kod = 'bilinmeyen'});

  final String mesaj;
  final String kod;

  @override
  String toString() => mesaj;
}

/// Kimlik doğrulama işlemlerini soyutlayan arayüz.
/// Gerçek uygulamada [FirebaseKimlikServisi], testlerde [SahteKimlikServisi] kullanılır.
abstract class KimlikServisi extends ChangeNotifier {
  /// Şu an oturumu açık olan kullanıcı. Yoksa null.
  KullaniciBilgisi? get aktifKullanici;

  /// Başlangıç oturum kontrolü tamamlandı mı?
  bool get hazirMi;

  /// E-posta ve şifre ile giriş yapar.
  Future<KullaniciBilgisi> girisYap({
    required String eposta,
    required String sifre,
  });

  /// E-posta, şifre ve isteğe bağlı takma ad ile yeni hesap açar.
  Future<KullaniciBilgisi> kayitOl({
    required String eposta,
    required String sifre,
    String? takmaAd,
  });

  /// Şifre sıfırlama bağlantısını e-posta adresine gönderir.
  Future<void> sifreSifirlamaGonder({required String eposta});

  /// Oturumu kapatır.
  Future<void> cikisYap();

  /// Aktif kullanıcı hesabını Firebase Auth üzerinden siler (KVKK uyumu).
  Future<void> hesabiSil();
}

/// Firebase Authentication tabanlı gerçek kimlik doğrulama servisi.
class FirebaseKimlikServisi extends KimlikServisi {
  FirebaseKimlikServisi({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance {
    _baslat();
  }

  final FirebaseAuth _auth;
  StreamSubscription<User?>? _abonelik;
  KullaniciBilgisi? _aktifKullanici;
  bool _hazir = false;

  @override
  KullaniciBilgisi? get aktifKullanici => _aktifKullanici;

  @override
  bool get hazirMi => _hazir;

  Future<void> _baslat() async {
    if (kIsWeb) {
      try {
        await _auth.setPersistence(Persistence.LOCAL);
      } catch (_) {}
    }
    _aktifKullanici = _kullaniciDonustur(_auth.currentUser);
    _hazir = true;
    notifyListeners();

    _abonelik = _auth.authStateChanges().listen((user) {
      _aktifKullanici = _kullaniciDonustur(user);
      _hazir = true;
      notifyListeners();
    });
  }

  static KullaniciBilgisi? _kullaniciDonustur(User? user) {
    if (user == null) return null;
    return KullaniciBilgisi(
      uid: user.uid,
      eposta: user.email ?? '',
      takmaAd: user.displayName,
    );
  }

  @override
  Future<KullaniciBilgisi> girisYap({
    required String eposta,
    required String sifre,
  }) async {
    try {
      final sonuc = await _auth.signInWithEmailAndPassword(
        email: eposta.trim(),
        password: sifre,
      );
      final bilgi = _kullaniciDonustur(sonuc.user);
      if (bilgi == null) {
        throw const KimlikHatasi('Giriş yapılamadı. Lütfen tekrar dene.');
      }
      _aktifKullanici = bilgi;
      notifyListeners();
      return bilgi;
    } on FirebaseAuthException catch (e) {
      throw KimlikHatasi(firebaseHataMesaji(e.code), kod: e.code);
    }
  }

  @override
  Future<KullaniciBilgisi> kayitOl({
    required String eposta,
    required String sifre,
    String? takmaAd,
  }) async {
    try {
      final sonuc = await _auth.createUserWithEmailAndPassword(
        email: eposta.trim(),
        password: sifre,
      );
      final user = sonuc.user;
      if (user == null) {
        throw const KimlikHatasi('Hesap oluşturulamadı. Lütfen tekrar dene.');
      }
      final temizAd = takmaAd?.trim();
      if (temizAd != null && temizAd.isNotEmpty) {
        await user.updateDisplayName(temizAd);
      }
      final bilgi = KullaniciBilgisi(
        uid: user.uid,
        eposta: user.email ?? eposta.trim(),
        takmaAd: (temizAd != null && temizAd.isNotEmpty)
            ? temizAd
            : user.displayName,
      );
      _aktifKullanici = bilgi;
      notifyListeners();
      return bilgi;
    } on FirebaseAuthException catch (e) {
      throw KimlikHatasi(firebaseHataMesaji(e.code), kod: e.code);
    }
  }

  @override
  Future<void> sifreSifirlamaGonder({required String eposta}) async {
    try {
      await _auth.sendPasswordResetEmail(email: eposta.trim());
    } on FirebaseAuthException catch (e) {
      throw KimlikHatasi(firebaseHataMesaji(e.code), kod: e.code);
    }
  }

  @override
  Future<void> cikisYap() async {
    await _auth.signOut();
    _aktifKullanici = null;
    notifyListeners();
  }

  @override
  Future<void> hesabiSil() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
      _aktifKullanici = null;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw KimlikHatasi(firebaseHataMesaji(e.code), kod: e.code);
    }
  }

  @override
  void dispose() {
    _abonelik?.cancel();
    super.dispose();
  }

  /// Firebase hata kodlarını sade Türkçe mesajlara çevirir.
  static String firebaseHataMesaji(String kod) {
    switch (kod) {
      case 'invalid-email':
        return 'Geçerli bir e-posta adresi girin.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'email-already-in-use':
        return 'Bu e-posta adresiyle zaten bir hesap var.';
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen biraz bekleyip tekrar deneyin.';
      case 'network-request-failed':
        return 'İnternet bağlantısı kurulamadı. Bağlantınızı kontrol edin.';
      case 'requires-recent-login':
        return 'Güvenlik için önce çıkış yapıp tekrar giriş yapmanız gerekiyor.';
      default:
        return 'İşlem sırasında bir sorun oluştu ($kod).';
    }
  }
}

/// Birim ve widget testleri için bellekte çalışan sahte kimlik servisi.
class SahteKimlikServisi extends KimlikServisi {
  SahteKimlikServisi({
    KullaniciBilgisi? baslangicKullanicisi,
    bool hazir = true,
  })  : _aktifKullanici = baslangicKullanicisi,
        _hazir = hazir {
    if (baslangicKullanicisi != null) {
      _kayitliSifreler[baslangicKullanicisi.eposta.toLowerCase()] = '123456';
      _kayitliKullanicilar[baslangicKullanicisi.eposta.toLowerCase()] =
          baslangicKullanicisi;
    }
  }

  KullaniciBilgisi? _aktifKullanici;
  bool _hazir;
  final Map<String, String> _kayitliSifreler = {};
  final Map<String, KullaniciBilgisi> _kayitliKullanicilar = {};
  final List<String> sifirlamaGonderilenler = [];
  int cikisSayisi = 0;
  int silmeSayisi = 0;

  @override
  KullaniciBilgisi? get aktifKullanici => _aktifKullanici;

  @override
  bool get hazirMi => _hazir;

  void hazirAyarla(bool deger) {
    _hazir = deger;
    notifyListeners();
  }

  @override
  Future<KullaniciBilgisi> girisYap({
    required String eposta,
    required String sifre,
  }) async {
    final anahtar = eposta.trim().toLowerCase();
    if (!anahtar.contains('@')) {
      throw const KimlikHatasi(
        'Geçerli bir e-posta adresi girin.',
        kod: 'invalid-email',
      );
    }
    final kayitliSifre = _kayitliSifreler[anahtar];
    if (kayitliSifre == null || kayitliSifre != sifre) {
      throw const KimlikHatasi(
        'E-posta veya şifre hatalı.',
        kod: 'invalid-credential',
      );
    }
    _aktifKullanici = _kayitliKullanicilar[anahtar];
    notifyListeners();
    return _aktifKullanici!;
  }

  @override
  Future<KullaniciBilgisi> kayitOl({
    required String eposta,
    required String sifre,
    String? takmaAd,
  }) async {
    final temizEposta = eposta.trim();
    final anahtar = temizEposta.toLowerCase();
    if (!anahtar.contains('@')) {
      throw const KimlikHatasi(
        'Geçerli bir e-posta adresi girin.',
        kod: 'invalid-email',
      );
    }
    if (sifre.length < 6) {
      throw const KimlikHatasi(
        'Şifre çok zayıf. En az 6 karakter kullanın.',
        kod: 'weak-password',
      );
    }
    if (_kayitliKullanicilar.containsKey(anahtar)) {
      throw const KimlikHatasi(
        'Bu e-posta adresiyle zaten bir hesap var.',
        kod: 'email-already-in-use',
      );
    }
    final bilgi = KullaniciBilgisi(
      uid: 'uid_${_kayitliKullanicilar.length + 1}',
      eposta: temizEposta,
      takmaAd: takmaAd?.trim().isEmpty == true ? null : takmaAd?.trim(),
    );
    _kayitliSifreler[anahtar] = sifre;
    _kayitliKullanicilar[anahtar] = bilgi;
    _aktifKullanici = bilgi;
    notifyListeners();
    return bilgi;
  }

  @override
  Future<void> sifreSifirlamaGonder({required String eposta}) async {
    final temiz = eposta.trim();
    if (!temiz.contains('@')) {
      throw const KimlikHatasi(
        'Geçerli bir e-posta adresi girin.',
        kod: 'invalid-email',
      );
    }
    sifirlamaGonderilenler.add(temiz);
  }

  @override
  Future<void> cikisYap() async {
    cikisSayisi++;
    _aktifKullanici = null;
    notifyListeners();
  }

  @override
  Future<void> hesabiSil() async {
    final aktif = _aktifKullanici;
    if (aktif != null) {
      final anahtar = aktif.eposta.toLowerCase();
      _kayitliKullanicilar.remove(anahtar);
      _kayitliSifreler.remove(anahtar);
    }
    silmeSayisi++;
    _aktifKullanici = null;
    notifyListeners();
  }
}

/// Ekranların [KimlikServisi]'ne ulaşmasını sağlar; oturum değişince ekranlar yenilenir.
class KimlikKapsami extends InheritedNotifier<KimlikServisi> {
  const KimlikKapsami({
    super.key,
    required KimlikServisi servis,
    required super.child,
  }) : super(notifier: servis);

  static KimlikServisi? belki(BuildContext context) {
    final kapsam = context.dependOnInheritedWidgetOfExactType<KimlikKapsami>();
    return kapsam?.notifier;
  }

  static KimlikServisi of(BuildContext context) {
    final kapsam = context.dependOnInheritedWidgetOfExactType<KimlikKapsami>();
    assert(kapsam != null, 'KimlikKapsami bulunamadı');
    return kapsam!.notifier!;
  }
}

