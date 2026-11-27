import 'dart:async';
import 'dart:convert';

import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/auth/kimlik_servisi.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/senkronizasyon/bolum_ayirici.dart';
import 'package:app/features/senkronizasyon/bulut_kaynagi.dart';
import 'package:flutter/widgets.dart';

/// Bulut eşitleme durumunu gösterir.
enum SenkronDurumu {
  esitlendi,
  gonderiliyor,
  bekleyenDegisiklikVar,
  cevrimdisi,
}

/// Girişte hem cihazda hem hesapta (bulutta) farklı veri bulunduğunda
/// kullanıcıya sorulacak seçimin bilgisi.
class SenkronCakismasi {
  const SenkronCakismasi({
    required this.yerelOzet,
    required this.bulutOzet,
    required this.bulutBolumleri,
  });

  /// "3 ders · 2 deneme · 1 kitap" gibi kısa özet.
  final String yerelOzet;
  final String bulutOzet;
  final Map<String, String> bulutBolumleri;
}

/// Yerel `VeriKaydi` ile `BulutKaynagi` (Firestore) arasında çalışan Offline-First köprü.
/// - Her yazma işlemi önce anında yerel hafızaya (`localStorage`) yapılır. Cihaza
///   yazılamasa (depo dolu) bile değişiklik buluta gönderilmeye devam eder; hata
///   sonra yukarı bildirilir ki ekranda uyarı çıksın.
/// - Fotoğraflar buluta gönderilmez. Oturum açıkken yalnız ana kayıtta durur
///   (tek kopya). Çıkışta hesaba özel `mytus_photos_{uid}` anahtarına taşınır,
///   aynı hesapla girişte geri yerleştirilir ve o anahtar silinir.
/// - Yalnızca değişen veri bölümleri kısa bir gecikmeyle (veya hemen) Firestore'a yazılır.
/// - Gönderilemeyen bölümlerin adı cihazda saklanır: uygulama kapanıp açılsa da
///   kaybolmaz, bağlantı gelince gönderilir.
/// - Girişte bulut OKUNAMAZSA bulut "boş" sayılmaz; hiçbir şey gönderilmeden
///   okunabilene kadar beklenir.
/// - Girişte hem cihazda hem bulutta farklı veri varsa kullanıcıya sorulur;
///   seçilmeyen taraf cihazda yedek olarak saklanır ve geri getirilebilir.
/// - Başka cihazdan gelen değişiklikler bölüm bazında uygulanır (bölüm bazında
///   en son değiştiren kazanır); cihaza özel bilgiler korunur.
class BulutSenkronServisi extends ChangeNotifier implements VeriKaydi {
  BulutSenkronServisi({
    required VeriKaydi yerelKayit,
    required BulutKaynagi bulutKaynagi,
    Duration gonderimGecikmesi = const Duration(milliseconds: 800),
    Duration yenidenDenemeGecikmesi = const Duration(seconds: 20),
    String? cihazId,
  })  : _yerel = yerelKayit,
        _bulut = bulutKaynagi,
        _gonderimGecikmesi = gonderimGecikmesi,
        _yenidenDenemeGecikmesi = yenidenDenemeGecikmesi,
        cihazId =
            cihazId ?? 'cihaz_${DateTime.now().microsecondsSinceEpoch}';

  final VeriKaydi _yerel;
  final BulutKaynagi _bulut;
  final Duration _gonderimGecikmesi;
  final Duration _yenidenDenemeGecikmesi;
  final String cihazId;

  PlanDeposu? _depo;
  KullaniciBilgisi? _aktifKullanici;
  StreamSubscription<({Map<String, String> bolumler, String? sonCihazId})>?
      _dinlemeAboneligi;
  Timer? _gonderimZamanlayici;
  Timer? _yenidenDenemeZamanlayici;

  /// Buluttaki bilinen son hâl (bölüm adı -> JSON metni).
  final Map<String, String> _bilinenBolumler = {};

  /// Şu an buluta yazılmakta olan bölümler (kendi yazdığımızın yankısını tanımak için).
  final Map<String, String> _gonderimdekiBolumler = {};

  /// Cihazda değişip henüz buluta gönderilemeyen bölümler.
  final Map<String, String> _bekleyenBolumler = {};

  /// Cihazdaki verinin bölümlerinin son hâli (yerel değişikliği tanımak için).
  Map<String, String> _sonYerelBolumler = {};

  /// Girişteki ilk eşitleme (bulut ile cihazın karşılaştırılması) yapıldı mı?
  bool _ilkEsitlemeTamam = false;
  SenkronCakismasi? _cakisma;
  bool _yedekVar = false;
  bool _uzaktanYukleniyor = false;

  /// Bulutta kaldırılmış içerik (örnek kitap) taşıyan bölümlerin ayıklanmış
  /// hâli. İlk eşitleme bitince buluta bir kez gönderilir; böylece içerik
  /// buluttan da silinir (25 Kasım 2026 kararı).
  Map<String, String> _buluttaTemizlenecek = {};
  bool _atildi = false;
  SenkronDurumu _durum = SenkronDurumu.esitlendi;

  SenkronDurumu get durum => _durum;
  bool get bekleyenVarMi => _bekleyenBolumler.isNotEmpty;

  /// Girişte kullanıcının seçmesi gereken bir çakışma varsa dolu.
  SenkronCakismasi? get bekleyenCakisma => _cakisma;

  /// Bu hesap için cihazda bir yedek (seçilmeyen veri) var mı?
  bool get yedekVar => _yedekVar;

  void depoBagla(PlanDeposu depo) {
    _depo = depo;
  }

  static String _fotoAnahtari(String uid) => 'mytus_photos_$uid';
  static String _yedekAnahtari(String uid) => 'mytus_backup_$uid';

  /// Cihaz eşitleme durumu: cihazdaki veri hangi hesaba ait ve hangi bölümler
  /// henüz buluta gönderilemedi. Uygulama kapanıp açılsa da kalır.
  static const String durumAnahtari = 'mytus_senkron_durumu';

  /// Eşitlenen bölümlerden hesap ayarı sayılan ("ayarlar") dışındakiler; girişte
  /// cihaz ile bulutun aynı veri olup olmadığına bunlarla bakılır.
  static const List<String> _icerikBolumleri = [
    'plan',
    'odak',
    'denemeler',
    'defterler',
    'kutuphane',
  ];

  @override
  Future<String?> oku() => _yerel.oku();

  @override
  Future<String?> anahtarliOku(String anahtar) => _yerel.anahtarliOku(anahtar);

  @override
  Future<void> anahtarliYaz(String anahtar, String icerik) =>
      _yerel.anahtarliYaz(anahtar, icerik);

  @override
  Future<void> anahtarliSil(String anahtar) => _yerel.anahtarliSil(anahtar);

  // ------------------------------------------------------------ yerel yazma

  @override
  Future<void> yaz(String icerik) async {
    // 1. Her zaman önce yerel hafızaya yaz (Offline-First). Yazılamazsa
    //    (ör. tarayıcı deposu dolu) buluta göndermeyi yine de sürdürürüz;
    //    hata en sonda yeniden fırlatılır ki kullanıcı uyarılsın.
    Object? yerelHata;
    StackTrace? yerelYigin;
    try {
      await _yerel.yaz(icerik);
    } catch (e, yigin) {
      yerelHata = e;
      yerelYigin = yigin;
    }

    final kullanici = _aktifKullanici;
    if (kullanici != null && !_uzaktanYukleniyor) {
      await _bulutKuyrugunaEkle(icerik);
    }

    if (yerelHata != null) {
      Error.throwWithStackTrace(yerelHata, yerelYigin ?? StackTrace.current);
    }
  }

  /// Cihazda değişen bölümleri bulut kuyruğuna ekler ve (ilk eşitleme
  /// yapıldıysa) gönderir. Fotoğraflar ayıklanır, buluta gitmez.
  Future<void> _bulutKuyrugunaEkle(String icerik) async {
    final yeni = _bolumlereAyir(icerik);
    if (yeni == null) return;

    var degisti = false;
    for (final e in yeni.entries) {
      if (_sonYerelBolumler[e.key] != e.value ||
          _bekleyenBolumler.containsKey(e.key)) {
        if (_bekleyenBolumler[e.key] != e.value) {
          _bekleyenBolumler[e.key] = e.value;
          degisti = true;
        }
      }
    }
    _sonYerelBolumler = yeni;
    if (_bekleyenBolumler.isEmpty) return;
    if (degisti) await _cihazDurumunuYaz();

    _durumGuncelle(SenkronDurumu.bekleyenDegisiklikVar);
    _gonderimZamanlayici?.cancel();
    if (_gonderimGecikmesi == Duration.zero) {
      await bekleyenleriSimdiGonder();
    } else {
      _gonderimZamanlayici = Timer(_gonderimGecikmesi, () {
        bekleyenleriSimdiGonder();
      });
    }
  }

  // ------------------------------------------------------------ giriş

  /// Kullanıcı giriş yaptığında (veya oturum açıkken uygulama açıldığında) çağrılır.
  Future<void> oturumAcildi(KullaniciBilgisi kullanici) async {
    if (_aktifKullanici?.uid == kullanici.uid && _dinlemeAboneligi != null) {
      return;
    }
    await _dinlemeAboneligi?.cancel();
    _dinlemeAboneligi = null;
    _gonderimZamanlayici?.cancel();
    _yenidenDenemeZamanlayici?.cancel();
    _bilinenBolumler.clear();
    _gonderimdekiBolumler.clear();
    _bekleyenBolumler.clear();
    _buluttaTemizlenecek = {};
    _ilkEsitlemeTamam = false;
    _cakisma = null;

    // Yerel değişiklikleri tanımak için cihazdaki verinin bugünkü hâli ve
    // önceki oturumdan kalan (gönderilemeyen) bölümler.
    _sonYerelBolumler = _bolumlereAyir(await _yerel.oku()) ?? {};
    final cihazDurumu = await _cihazDurumunuOku();
    _kayitliSahip = cihazDurumu.sahipUid;
    _oncekiBekleyen = cihazDurumu.bekleyen;
    _aktifKullanici = kullanici;
    _yedekVar = await _yedekMetni(kullanici.uid) != null;

    try {
      await _bulut.profilKaydet(
        uid: kullanici.uid,
        eposta: kullanici.eposta,
        takmaAd: kullanici.takmaAd,
      );
    } catch (_) {
      // Çevrimdışıysa profil kaydı sonraya kalabilir.
    }

    await _ilkEsitlemeyiDene();

    // Başka cihazlardan gelecek değişiklikleri dinlemeye başla.
    if (_aktifKullanici?.uid != kullanici.uid) return;
    _dinlemeAboneligi = _bulut.bolumleriDinle(kullanici.uid).listen(
      (olay) => _buluttanGeldi(kullanici, olay.bolumler),
      onError: (_) => _durumGuncelle(SenkronDurumu.cevrimdisi),
    );
  }

  Future<void>? _ilkEsitlemeSuruyor;

  /// Bulutu okumayı dener; okunursa cihaz ile bulutu karşılaştırır.
  /// Okunamazsa (çevrimdışı) bulut "boş" SAYILMAZ: hiçbir şey gönderilmez.
  /// Aynı anda yalnız bir deneme yürür.
  Future<void> _ilkEsitlemeyiDene() {
    return _ilkEsitlemeSuruyor ??=
        _ilkEsitlemeyiDeneIc().whenComplete(() => _ilkEsitlemeSuruyor = null);
  }

  Future<void> _ilkEsitlemeyiDeneIc() async {
    final kullanici = _aktifKullanici;
    if (kullanici == null || _ilkEsitlemeTamam || _cakisma != null) return;
    Map<String, String> bulutBolumleri;
    try {
      bulutBolumleri = await _bulut.bolumleriOku(kullanici.uid);
    } catch (_) {
      _durumGuncelle(SenkronDurumu.cevrimdisi);
      _yenidenDenemeyiKur();
      return;
    }
    if (_aktifKullanici?.uid != kullanici.uid) return;
    await _ilkEsitle(kullanici, bulutBolumleri);
  }

  Future<void> _ilkEsitle(
    KullaniciBilgisi kullanici,
    Map<String, String> hamBulutBolumleri,
  ) async {
    if (_ilkEsitlemeTamam || _cakisma != null) return;
    final bulutBolumleri =
        BolumAyirici.kaldirilanlariAyikla(hamBulutBolumleri);
    _buluttaTemizlenecek = {
      for (final e in bulutBolumleri.entries)
        if (hamBulutBolumleri[e.key] != e.value) e.key: e.value,
    };
    final yerelMetin = await _yerel.oku();
    final yerelBolumler = _bolumlereAyir(yerelMetin) ?? {};
    final yerelDolu = _anlamliVeriVarMi(yerelMetin);
    final bulutDolu = _bulutDoluMu(bulutBolumleri);
    _bilinenBolumler.addAll(bulutBolumleri);

    if (_kayitliSahip == kullanici.uid && yerelDolu) {
      // Aynı hesap, uygulama yeniden açıldı. Gönderilemeyen bölümler cihazdan,
      // diğerleri (başka cihazlarda değişmiş olabilir) buluttan alınır.
      final gonderilmemis = {
        ..._oncekiBekleyen,
        ..._bekleyenBolumler.keys,
      };
      final uygulanacak = <String, String>{};
      for (final e in bulutBolumleri.entries) {
        if (gonderilmemis.contains(e.key)) continue;
        if (yerelBolumler[e.key] != e.value) uygulanacak[e.key] = e.value;
      }
      for (final ad in gonderilmemis) {
        final yerel = yerelBolumler[ad];
        if (yerel != null && yerel != bulutBolumleri[ad]) {
          _bekleyenBolumler[ad] = yerel;
        } else {
          _bekleyenBolumler.remove(ad);
        }
      }
      await _esitlemeyiTamamla(kullanici);
      if (uygulanacak.isNotEmpty) await _bolumleriYereleUygula(uygulanacak);
    } else if (!bulutDolu) {
      // Bulut boş: cihazda veri varsa buluta aktarılır (İlk Giriş Göçü).
      if (yerelDolu) _bekleyenBolumler.addAll(yerelBolumler);
      await _esitlemeyiTamamla(kullanici);
    } else if (!yerelDolu) {
      // Cihaz boş: buluttaki veri (çıkışta saklanan fotoğraflarla) indirilir.
      _bekleyenBolumler.clear();
      await _tamamenBuluttanYukle(kullanici, bulutBolumleri, yerelMetin);
      await _esitlemeyiTamamla(kullanici);
    } else if (_ayniVeriMi(yerelBolumler, bulutBolumleri)) {
      // Aynı veri (ör. önceki sürümle giriş yapılmış cihaz): sormaya gerek yok.
      _bekleyenBolumler.clear();
      await _esitlemeyiTamamla(kullanici);
      final ayarlar = bulutBolumleri['ayarlar'];
      if (ayarlar != null && ayarlar != yerelBolumler['ayarlar']) {
        await _bolumleriYereleUygula({'ayarlar': ayarlar});
      }
    } else {
      // İkisinde de farklı veri var: karar kullanıcının (DECISIONS: "kullanıcıya sorulur").
      _cakisma = SenkronCakismasi(
        yerelOzet: _ozet(yerelMetin),
        bulutOzet: _ozet(BolumAyirici.birlestir(bolumler: bulutBolumleri)),
        bulutBolumleri: Map.unmodifiable(bulutBolumleri),
      );
      _bildir();
      return;
    }

    _kaldirilanlariBuluttanTemizle();
    if (_bekleyenBolumler.isNotEmpty) {
      await bekleyenleriSimdiGonder();
    } else {
      _durumGuncelle(SenkronDurumu.esitlendi);
    }
  }

  /// İlk eşitlemede bulutta görülen kaldırılmış içeriğin (örnek kitap)
  /// ayıklanmış bölümünü gönderim sırasına alır. Cihazda o bölümde
  /// gönderilmemiş değişiklik varsa zaten o gidecektir; dokunulmaz.
  void _kaldirilanlariBuluttanTemizle() {
    for (final e in _buluttaTemizlenecek.entries) {
      _bekleyenBolumler.putIfAbsent(e.key, () => e.value);
    }
    _buluttaTemizlenecek = {};
  }

  Future<void> _esitlemeyiTamamla(KullaniciBilgisi kullanici) async {
    _ilkEsitlemeTamam = true;
    _oncekiBekleyen = {};
    _yenidenDenemeZamanlayici?.cancel();
    await _cihazDurumunuYaz(sahipUid: kullanici.uid);
  }

  /// Girişteki çakışmayı kullanıcının seçimine göre çözer. Seçilmeyen taraf
  /// cihazda yedek olarak saklanır (Ayarlar > hesap kartından geri getirilebilir).
  Future<void> cakismayiCoz({required bool cihazdakiKalsin}) async {
    final cakisma = _cakisma;
    final kullanici = _aktifKullanici;
    if (cakisma == null || kullanici == null) return;
    final yerelMetin = await _yerel.oku();

    if (cihazdakiKalsin) {
      await _yedekYaz(
        kullanici.uid,
        BolumAyirici.birlestir(bolumler: cakisma.bulutBolumleri),
      );
      _bekleyenBolumler
        ..clear()
        ..addAll(_bolumlereAyir(yerelMetin) ?? {});
    } else {
      if (yerelMetin != null && yerelMetin.isNotEmpty) {
        await _yedekYaz(kullanici.uid, yerelMetin);
      }
      _bekleyenBolumler.clear();
      await _tamamenBuluttanYukle(
        kullanici,
        cakisma.bulutBolumleri,
        null,
      );
    }
    _cakisma = null;
    await _esitlemeyiTamamla(kullanici);
    _bildir();
    _kaldirilanlariBuluttanTemizle();
    if (_bekleyenBolumler.isNotEmpty) {
      await bekleyenleriSimdiGonder();
    } else {
      _durumGuncelle(SenkronDurumu.esitlendi);
    }
  }

  /// Cihazdaki yedeği (girişte seçilmeyen veri) geri getirir. Şu anki veri
  /// yedeğin yerine geçer; yani hiçbir şey kaybolmaz, iki taraf yer değiştirir.
  Future<bool> yedegiGeriYukle() async {
    final kullanici = _aktifKullanici;
    if (kullanici == null || !_ilkEsitlemeTamam) return false;
    final yedek = await _yedekMetni(kullanici.uid);
    if (yedek == null) return false;
    final simdiki = await _yerel.oku();
    if (simdiki != null && simdiki.isNotEmpty) {
      await _yedekYaz(kullanici.uid, simdiki);
    }
    await _uzaktanVeriyiUygula(yedek);
    final yeni = _depodakiBolumler() ?? _bolumlereAyir(yedek) ?? {};
    _sonYerelBolumler = yeni;
    _bekleyenBolumler
      ..clear()
      ..addAll(yeni);
    await _cihazDurumunuYaz();
    _bildir();
    await bekleyenleriSimdiGonder();
    return true;
  }

  // ------------------------------------------------------------ buluttan gelen

  Future<void> _buluttanGeldi(
    KullaniciBilgisi kullanici,
    Map<String, String> hamBolumler,
  ) async {
    if (_aktifKullanici?.uid != kullanici.uid) return;
    final bolumler = BolumAyirici.kaldirilanlariAyikla(hamBolumler);
    if (!_ilkEsitlemeTamam) {
      // Girişte bulut okunamamıştı: bulutun gerçek hâli şimdi geldi.
      final suren = _ilkEsitlemeSuruyor;
      if (suren != null) await suren;
      if (!_ilkEsitlemeTamam && _cakisma == null) {
        final islem = _ilkEsitle(kullanici, hamBolumler);
        _ilkEsitlemeSuruyor = islem;
        try {
          await islem;
        } finally {
          if (identical(_ilkEsitlemeSuruyor, islem)) _ilkEsitlemeSuruyor = null;
        }
      }
      return;
    }

    final degisen = <String, String>{};
    for (final e in bolumler.entries) {
      if (_bilinenBolumler[e.key] == e.value) continue;
      _bilinenBolumler[e.key] = e.value;
      // Kendi yazdığımızın yankısı.
      if (_gonderimdekiBolumler[e.key] == e.value) continue;
      // Bizde gönderilmemiş daha yeni değişiklik var: bölüm bazında son
      // değiştiren kazanır, bizimki birazdan gönderilecek.
      if (_bekleyenBolumler.containsKey(e.key)) continue;
      if (_sonYerelBolumler[e.key] == e.value) continue;
      degisen[e.key] = e.value;
    }
    if (degisen.isNotEmpty) {
      await _bolumleriYereleUygula(degisen);
    }
    if (_bekleyenBolumler.isNotEmpty) {
      await bekleyenleriSimdiGonder();
    } else {
      _durumGuncelle(SenkronDurumu.esitlendi);
    }
  }

  /// Değişen bölümleri cihazdaki veriye uygular; diğer bölümler ve cihaza özel
  /// bilgiler korunur, fotoğraflar notlarına geri yerleşir.
  Future<void> _bolumleriYereleUygula(Map<String, String> bolumler) async {
    final kullanici = _aktifKullanici;
    if (kullanici == null || bolumler.isEmpty) return;
    final yerelMetin = await _yerel.oku();
    var yerel = <String, dynamic>{};
    if (yerelMetin != null && yerelMetin.isNotEmpty) {
      try {
        final v = jsonDecode(yerelMetin);
        if (v is Map<String, dynamic>) yerel = v;
      } catch (_) {}
    }
    final fotolar = await _yerlestirilecekFotograflar(kullanici.uid, yerelMetin);
    final birlesik = BolumAyirici.yereleUygula(
      yerel: yerel,
      bolumler: bolumler,
      fotograflar: fotolar,
    );
    await _uzaktanVeriyiUygula(birlesik);
    _sonYerelBolumler = _depodakiBolumler() ?? _bolumlereAyir(birlesik) ?? {};
    await _fotoAnahtariniTemizle(kullanici.uid);
  }

  /// Cihazdaki veriyi tamamen buluttakiyle değiştirir (çıkışta saklanan
  /// fotoğraflar geri yerleşir).
  Future<void> _tamamenBuluttanYukle(
    KullaniciBilgisi kullanici,
    Map<String, String> bulutBolumleri,
    String? yerelMetin,
  ) async {
    final fotolar = await _yerlestirilecekFotograflar(kullanici.uid, yerelMetin);
    final birlesik = BolumAyirici.birlestir(
      bolumler: bulutBolumleri,
      fotograflar: fotolar,
    );
    await _uzaktanVeriyiUygula(birlesik);
    _sonYerelBolumler = _depodakiBolumler() ?? _bolumlereAyir(birlesik) ?? {};
    await _fotoAnahtariniTemizle(kullanici.uid);
  }

  // ------------------------------------------------------------ gönderme

  /// Bekleyen değişiklikleri hemen buluta gönderir.
  Future<void> bekleyenleriSimdiGonder() async {
    _gonderimZamanlayici?.cancel();
    final kullanici = _aktifKullanici;
    if (kullanici == null || _bekleyenBolumler.isEmpty) return;
    if (!_ilkEsitlemeTamam) {
      // Bulut ile karşılaştırma yapılmadan hiçbir şey gönderilmez (bulut
      // okunamadıysa "boş" sanıp başka cihazın verisini silmemek için).
      await _ilkEsitlemeyiDene();
      if (!_ilkEsitlemeTamam) return;
      if (_bekleyenBolumler.isEmpty) return;
    }
    if (_cakisma != null) return;

    final gonderilecek = Map<String, String>.from(_bekleyenBolumler);
    _gonderimdekiBolumler.addAll(gonderilecek);
    _durumGuncelle(SenkronDurumu.gonderiliyor);
    try {
      await _bulut.bolumleriYaz(
        uid: kullanici.uid,
        degisenBolumler: gonderilecek,
        cihazId: cihazId,
      );
      for (final e in gonderilecek.entries) {
        _bilinenBolumler[e.key] = e.value;
        if (_bekleyenBolumler[e.key] == e.value) {
          _bekleyenBolumler.remove(e.key);
        }
      }
      await _cihazDurumunuYaz();
      _durumGuncelle(
        _bekleyenBolumler.isEmpty
            ? SenkronDurumu.esitlendi
            : SenkronDurumu.bekleyenDegisiklikVar,
      );
    } catch (_) {
      _durumGuncelle(SenkronDurumu.cevrimdisi);
      _yenidenDenemeyiKur();
    } finally {
      for (final e in gonderilecek.entries) {
        if (_gonderimdekiBolumler[e.key] == e.value) {
          _gonderimdekiBolumler.remove(e.key);
        }
      }
    }
  }

  void _yenidenDenemeyiKur() {
    if (_atildi || _aktifKullanici == null) return;
    _yenidenDenemeZamanlayici?.cancel();
    _yenidenDenemeZamanlayici = Timer(_yenidenDenemeGecikmesi, () {
      if (!_ilkEsitlemeTamam) {
        _ilkEsitlemeyiDene();
      } else {
        bekleyenleriSimdiGonder();
      }
    });
  }

  // ------------------------------------------------------------ çıkış

  /// Kullanıcı çıkış yaptığında çağrılır:
  /// - Bekleyen değişiklikleri buluta gönderir.
  /// - Fotoğrafları hesaba özel yerel anahtara (`mytus_photos_{uid}`) taşır.
  /// - Cihazdaki çalışma verisi bu hesabınsa sıfırlar. Giriş sonrası eşitleme
  ///   hiç yapılamadıysa cihazdaki veri bu hesabın değildir (ör. misafir
  ///   modundaki çalışma): o veri silinmez, cihazda kalır.
  Future<void> oturumKapatildi({bool hesabiTamamenSil = false}) async {
    _gonderimZamanlayici?.cancel();
    _yenidenDenemeZamanlayici?.cancel();
    await _dinlemeAboneligi?.cancel();
    _dinlemeAboneligi = null;

    final kullanici = _aktifKullanici;
    final veriBuHesabin = _ilkEsitlemeTamam;
    if (kullanici != null) {
      if (hesabiTamamenSil) {
        try {
          await _bulut.kullaniciVerileriniSil(kullanici.uid);
        } catch (_) {}
        await _guvenliSil(_fotoAnahtari(kullanici.uid));
        await _guvenliSil(_yedekAnahtari(kullanici.uid));
      } else if (veriBuHesabin) {
        await bekleyenleriSimdiGonder();
        // Fotoğraflar buluta gitmez: hesaba özel anahtara taşınır, aynı hesapla
        // tekrar girildiğinde geri gelir.
        await _fotograflariHesabaTasi(kullanici.uid, await _yerel.oku());
      }
    }

    _aktifKullanici = null;
    _bilinenBolumler.clear();
    _gonderimdekiBolumler.clear();
    _bekleyenBolumler.clear();
    _ilkEsitlemeTamam = false;
    _cakisma = null;
    _buluttaTemizlenecek = {};
    _yedekVar = false;

    if (veriBuHesabin || hesabiTamamenSil) {
      // Cihazdaki aktif çalışma verisini temizle (fotoğraflar hesaba özel anahtarda durur).
      _uzaktanYukleniyor = true;
      try {
        await _depo?.tumVerileriSifirla();
      } finally {
        _uzaktanYukleniyor = false;
      }
      _oncekiBekleyen = {};
      await _cihazDurumunuYaz(sahipUid: null);
    }
    _sonYerelBolumler = {};
    _durumGuncelle(SenkronDurumu.esitlendi);
    _bildir();
  }

  // ------------------------------------------------------------ yardımcılar

  Future<void> _uzaktanVeriyiUygula(String birlesikJson) async {
    _uzaktanYukleniyor = true;
    try {
      try {
        await _yerel.yaz(birlesikJson);
      } catch (_) {
        // Cihaza yazılamasa da (depo dolu) ekrandaki veri güncellenir;
        // PlanDeposu bir sonraki kayıtta yeniden dener ve uyarı gösterir.
      }
      _depo?.yedektenYukle(birlesikJson);
    } finally {
      _uzaktanYukleniyor = false;
    }
  }

  /// PlanDeposu'nun şu anki verisinin bölümleri (yazılacağı biçimde).
  Map<String, String>? _depodakiBolumler() {
    final depo = _depo;
    if (depo == null) return null;
    return _bolumlereAyir(jsonEncode(depo.toJson()));
  }

  static Map<String, String>? _bolumlereAyir(String? metin) {
    if (metin == null || metin.isEmpty) return null;
    try {
      final v = jsonDecode(metin);
      if (v is Map<String, dynamic>) return BolumAyirici.ayir(v).bolumler;
    } catch (_) {}
    return null;
  }

  Future<({String? sahipUid, Set<String> bekleyen})> _cihazDurumunuOku() async {
    try {
      final metin = await _yerel.anahtarliOku(durumAnahtari);
      if (metin != null && metin.isNotEmpty) {
        final v = jsonDecode(metin);
        if (v is Map) {
          final sahip = v['sahipUid'];
          final bekleyen = v['bekleyen'];
          return (
            sahipUid: sahip is String ? sahip : null,
            bekleyen: {
              if (bekleyen is List)
                for (final b in bekleyen)
                  if (b is String) b,
            },
          );
        }
      }
    } catch (_) {}
    return (sahipUid: null, bekleyen: <String>{});
  }

  /// Cihazdaki verinin sahibi olan hesap (çıkışta silinir).
  String? _kayitliSahip;

  /// Önceki oturumdan kalan, girişteki ilk eşitlemede değerlendirilecek bölümler.
  Set<String> _oncekiBekleyen = {};

  /// Cihaz durumunu yazar. [sahipUid] verilmezse bilinen sahip korunur.
  Future<void> _cihazDurumunuYaz({Object? sahipUid = _degismez}) async {
    if (!identical(sahipUid, _degismez)) _kayitliSahip = sahipUid as String?;
    try {
      await _yerel.anahtarliYaz(
        durumAnahtari,
        jsonEncode({
          'sahipUid': _kayitliSahip,
          'bekleyen': {..._oncekiBekleyen, ..._bekleyenBolumler.keys}.toList(),
        }),
      );
    } catch (_) {
      // Depo dolu: en iyi çaba. Bekleyenler bellekte durur ve gönderilir.
    }
  }

  static const Object _degismez = Object();

  static Map<String, String> _metindekiFotograflar(String? metin) {
    if (metin == null || metin.isEmpty) return {};
    try {
      final v = jsonDecode(metin);
      if (v is Map<String, dynamic>) return BolumAyirici.ayir(v).fotograflar;
    } catch (_) {}
    return {};
  }

  Future<Map<String, String>> _mevcutFotograflariOku(String uid) async {
    final metin = await _yerel.anahtarliOku(_fotoAnahtari(uid));
    if (metin == null || metin.isEmpty) return {};
    try {
      final cozulmus = jsonDecode(metin);
      if (cozulmus is Map) {
        return {
          for (final e in cozulmus.entries)
            if (e.key is String && e.value is String)
              e.key as String: e.value as String,
        };
      }
    } catch (_) {}
    return {};
  }

  /// Buluttan gelen veriye geri yerleştirilecek fotoğraflar: çıkışta hesaba özel
  /// anahtara taşınmış olanlar + şu an cihazdaki ana kayıtta duranlar.
  Future<Map<String, String>> _yerlestirilecekFotograflar(
    String uid,
    String? yerelMetin,
  ) async {
    final fotolar = await _mevcutFotograflariOku(uid);
    fotolar.addAll(_metindekiFotograflar(yerelMetin));
    return fotolar;
  }

  /// Fotoğraflar ana kayda geri yerleştirildikten sonra hesaba özel kopyayı siler
  /// (aynı fotoğraf iki kez saklanmasın).
  Future<void> _fotoAnahtariniTemizle(String uid) =>
      _guvenliSil(_fotoAnahtari(uid));

  Future<void> _guvenliSil(String anahtar) async {
    try {
      await _yerel.anahtarliSil(anahtar);
    } catch (_) {}
  }

  /// Çıkışta cihazdaki fotoğrafları hesaba özel anahtara taşır. Yalnız şu an
  /// cihazdaki notların fotoğrafları taşınır (silinen notların fotoğrafı kalmaz).
  Future<void> _fotograflariHesabaTasi(String uid, String? yerelMetin) async {
    if (!_anlamliVeriVarMi(yerelMetin)) return;
    final fotolar = _metindekiFotograflar(yerelMetin);
    final anahtar = _fotoAnahtari(uid);
    if (fotolar.isEmpty) {
      await _fotoAnahtariniTemizle(uid);
      return;
    }
    final metin = jsonEncode(fotolar);
    try {
      await _yerel.anahtarliYaz(anahtar, metin);
    } catch (_) {
      // Depo dolu: ana kaydı (çıkışta zaten temizlenecek) boşaltıp yeniden dene.
      try {
        await _yerel.yaz('{}');
      } catch (_) {}
      await _yerel.anahtarliYaz(anahtar, metin);
    }
  }

  Future<String?> _yedekMetni(String uid) async {
    try {
      final metin = await _yerel.anahtarliOku(_yedekAnahtari(uid));
      if (metin != null && metin.isNotEmpty) return metin;
    } catch (_) {}
    return null;
  }

  Future<void> _yedekYaz(String uid, String metin) async {
    await _yerel.anahtarliYaz(_yedekAnahtari(uid), metin);
    _yedekVar = true;
  }

  static bool _anlamliVeriVarMi(String? metin) {
    if (metin == null || metin.isEmpty) return false;
    try {
      final v = jsonDecode(metin);
      if (v is! Map<String, dynamic>) return false;
      return v['karsilamaTamam'] == true ||
          (v['dersler'] is List && (v['dersler'] as List).isNotEmpty) ||
          (v['denemeler'] is List && (v['denemeler'] as List).isNotEmpty);
    } catch (_) {
      return false;
    }
  }

  static bool _bulutDoluMu(Map<String, String> bolumler) =>
      bolumler.isNotEmpty &&
      bolumler.values.any((v) => v.contains('"karsilamaTamam":true'));

  static bool _ayniVeriMi(Map<String, String> yerel, Map<String, String> bulut) {
    for (final ad in _icerikBolumleri) {
      if ((yerel[ad] ?? '') != (bulut[ad] ?? '')) return false;
    }
    return true;
  }

  /// Çakışma penceresinde gösterilen kısa özet.
  static String _ozet(String? metin) {
    var ders = 0, konu = 0, deneme = 0, kitap = 0;
    try {
      final v = metin == null || metin.isEmpty ? null : jsonDecode(metin);
      if (v is Map) {
        int say(String alan) => v[alan] is List ? (v[alan] as List).length : 0;
        ders = say('dersler');
        konu = say('calismalar');
        deneme = say('denemeler');
        kitap = say('kitaplar');
      }
    } catch (_) {}
    return '$ders ders · $konu takvim kaydı · $deneme deneme · $kitap kitap';
  }

  void _durumGuncelle(SenkronDurumu yeni) {
    if (_durum == yeni) return;
    _durum = yeni;
    _bildir();
  }

  void _bildir() {
    if (!_atildi) notifyListeners();
  }

  @override
  void dispose() {
    _atildi = true;
    _gonderimZamanlayici?.cancel();
    _yenidenDenemeZamanlayici?.cancel();
    _dinlemeAboneligi?.cancel();
    super.dispose();
  }
}

/// Ekranların [BulutSenkronServisi]'ne ulaşmasını sağlar.
class SenkronKapsami extends InheritedNotifier<BulutSenkronServisi> {
  const SenkronKapsami({
    super.key,
    required BulutSenkronServisi servis,
    required super.child,
  }) : super(notifier: servis);

  static BulutSenkronServisi? belki(BuildContext context) {
    final kapsam =
        context.dependOnInheritedWidgetOfExactType<SenkronKapsami>();
    return kapsam?.notifier;
  }
}
