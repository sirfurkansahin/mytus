import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:app/core/tarih.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:flutter/widgets.dart';

enum YuklemeDurumu { yukleniyor, hazir, hata }

/// Kullanıcının planı: sınav tarihi, dersler, konular ve notlar.
/// Bellekte tutulur, her değişiklikte telefona (VeriKaydi) yazılır.
/// Not yazarken her tuşta dosya yazmamak için kayıt kısa bir gecikmeyle yapılır.
class PlanDeposu extends ChangeNotifier {
  PlanDeposu({
    required VeriKaydi kayit,
    this.kayitGecikmesi = const Duration(milliseconds: 500),
  }) : _kayit = kayit;

  final VeriKaydi _kayit;

  /// Sıfır verilirse her değişiklik hemen yazılır (testler için).
  final Duration kayitGecikmesi;

  YuklemeDurumu durum = YuklemeDurumu.yukleniyor;
  String? hataMesaji;
  bool kayitHatasi = false;

  DateTime? sinavTarihi;
  bool karsilamaTamam = false;

  int _sonId = 0;
  final List<Ders> _dersler = [];
  final List<Konu> _konular = [];

  Timer? _zamanlayici;
  bool _kirli = false;
  Future<void> _yazmaKuyrugu = Future<void>.value();

  // ---------------------------------------------------------------- yükleme

  Future<void> yukle() async {
    if (durum != YuklemeDurumu.yukleniyor) {
      durum = YuklemeDurumu.yukleniyor;
      hataMesaji = null;
      notifyListeners();
    }
    try {
      final metin = await _kayit.oku();
      if (metin != null && metin.isNotEmpty && !_jsonYukle(metin)) {
        // Bozuk dosyanın üstüne yazıp veriyi kaybetmemek için açılışı durdururuz.
        durum = YuklemeDurumu.hata;
        hataMesaji = 'Veri dosyası okunamadı.';
        notifyListeners();
        return;
      }
      durum = YuklemeDurumu.hazir;
    } catch (_) {
      durum = YuklemeDurumu.hata;
      hataMesaji = 'Veriler okunamadı.';
    }
    notifyListeners();
  }

  bool _jsonYukle(String metin) {
    try {
      final veri = jsonDecode(metin);
      if (veri is! Map<String, dynamic>) return false;

      final dersler = <Ders>[];
      final dersListesi = veri['dersler'];
      if (dersListesi is List) {
        for (final e in dersListesi) {
          final d = Ders.fromJson(e);
          if (d != null) dersler.add(d);
        }
      }
      final dersNumaralari = dersler.map((d) => d.id).toSet();
      final konular = <Konu>[];
      final konuListesi = veri['konular'];
      if (konuListesi is List) {
        for (final e in konuListesi) {
          final k = Konu.fromJson(e);
          if (k != null && dersNumaralari.contains(k.dersId)) konular.add(k);
        }
      }

      var enBuyuk = 0;
      for (final d in dersler) {
        enBuyuk = math.max(enBuyuk, d.id);
      }
      for (final k in konular) {
        enBuyuk = math.max(enBuyuk, k.id);
      }
      final kayitliSon = veri['sonId'];

      final tarih = veri['sinavTarihi'];
      sinavTarihi = tarih is String ? tarihCoz(tarih) : null;
      karsilamaTamam = veri['karsilamaTamam'] == true;
      _sonId = math.max(kayitliSon is int ? kayitliSon : 0, enBuyuk);
      _dersler
        ..clear()
        ..addAll(dersler);
      _konular
        ..clear()
        ..addAll(konular);
      return true;
    } on FormatException {
      return false;
    }
  }

  Map<String, Object?> toJson() => {
        'surum': 1,
        'sonId': _sonId,
        'karsilamaTamam': karsilamaTamam,
        'sinavTarihi': sinavTarihi == null ? null : tarihAnahtari(sinavTarihi!),
        'dersler': [for (final d in _dersler) d.toJson()],
        'konular': [for (final k in _konular) k.toJson()],
      };

  // ---------------------------------------------------------------- okuma

  List<Ders> dersler(DersGrubu grup) =>
      _dersler.where((d) => d.grup == grup).toList(growable: false);

  Ders? dersBul(int id) {
    for (final d in _dersler) {
      if (d.id == id) return d;
    }
    return null;
  }

  List<Konu> konular(int dersId) =>
      _konular.where((k) => k.dersId == dersId).toList(growable: false);

  Konu? konuBul(int id) {
    for (final k in _konular) {
      if (k.id == id) return k;
    }
    return null;
  }

  int konuSayisi(int dersId) => konular(dersId).length;

  int calisilanSayisi(int dersId) =>
      konular(dersId).where((k) => k.ilkCalisma != null).length;

  // ---------------------------------------------------------------- yazma

  /// Adı düzeltir: baştaki/sondaki boşlukları atar, ardışık boşlukları teke indirir.
  /// Boşsa null döner. En fazla 80 karakter.
  static String? adTemizle(String ham) {
    final ad = ham.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (ad.isEmpty) return null;
    return ad.length > 80 ? ad.substring(0, 80) : ad;
  }

  int _yeniId() => ++_sonId;

  /// Karşılama ekranı bitti: sınav tarihini ve seçilen dersleri kaydeder.
  Future<void> karsilamayiTamamla({
    required DateTime sinavTarihi,
    required List<HazirDers> secilenDersler,
  }) async {
    this.sinavTarihi = DateTime(sinavTarihi.year, sinavTarihi.month, sinavTarihi.day);
    for (final h in secilenDersler) {
      _dersEkleIc(h.ad, h.grup);
    }
    karsilamaTamam = true;
    _degisti();
    await hemenKaydet();
  }

  void sinavTarihiBelirle(DateTime tarih) {
    sinavTarihi = DateTime(tarih.year, tarih.month, tarih.day);
    _degisti();
  }

  Ders? _dersEkleIc(String ham, DersGrubu grup) {
    final ad = adTemizle(ham);
    if (ad == null) return null;
    final kucuk = ad.toLowerCase();
    final varMi = _dersler.any(
      (d) => d.grup == grup && d.ad.toLowerCase() == kucuk,
    );
    if (varMi) return null;
    final ders = Ders(id: _yeniId(), ad: ad, grup: grup);
    _dersler.add(ders);
    return ders;
  }

  /// Ders ekler. Ad boşsa veya aynı grupta aynı adlı ders varsa null döner.
  Ders? dersEkle(String ad, DersGrubu grup) {
    final ders = _dersEkleIc(ad, grup);
    if (ders != null) _degisti();
    return ders;
  }

  bool dersAdiDegistir(int id, String ham) {
    final ad = adTemizle(ham);
    final indeks = _dersler.indexWhere((d) => d.id == id);
    if (ad == null || indeks < 0) return false;
    final ders = _dersler[indeks];
    final kucuk = ad.toLowerCase();
    final baskasiVar = _dersler.any(
      (d) => d.id != id && d.grup == ders.grup && d.ad.toLowerCase() == kucuk,
    );
    if (baskasiVar) return false;
    _dersler[indeks] = ders.kopya(ad: ad);
    _degisti();
    return true;
  }

  /// Dersi ve ona bağlı tüm konuları (notlarıyla) siler.
  void dersSil(int id) {
    _dersler.removeWhere((d) => d.id == id);
    _konular.removeWhere((k) => k.dersId == id);
    _degisti();
  }

  /// Konu ekler. Ad boşsa, ders yoksa veya aynı derste aynı adlı konu varsa null döner.
  Konu? konuEkle(int dersId, String ham) {
    final ad = adTemizle(ham);
    if (ad == null || dersBul(dersId) == null) return null;
    final kucuk = ad.toLowerCase();
    final varMi = _konular.any(
      (k) => k.dersId == dersId && k.ad.toLowerCase() == kucuk,
    );
    if (varMi) return null;
    final konu = Konu(id: _yeniId(), dersId: dersId, ad: ad);
    _konular.add(konu);
    _degisti();
    return konu;
  }

  bool konuAdiDegistir(int id, String ham) {
    final ad = adTemizle(ham);
    final indeks = _konular.indexWhere((k) => k.id == id);
    if (ad == null || indeks < 0) return false;
    final konu = _konular[indeks];
    final kucuk = ad.toLowerCase();
    final baskasiVar = _konular.any(
      (k) => k.id != id && k.dersId == konu.dersId && k.ad.toLowerCase() == kucuk,
    );
    if (baskasiVar) return false;
    _konular[indeks] = konu.kopya(ad: ad);
    _degisti();
    return true;
  }

  void konuSil(int id) {
    _konular.removeWhere((k) => k.id == id);
    _degisti();
  }

  /// Notu günceller. Ekranı yeniden çizdirmez (yazarken gereksiz), yalnızca kaydı planlar.
  void notYaz(int konuId, String metin) {
    final indeks = _konular.indexWhere((k) => k.id == konuId);
    if (indeks < 0) return;
    _konular[indeks] = _konular[indeks].kopya(not: metin);
    _degisti(bildir: false);
  }

  // ---------------------------------------------------------------- kayıt

  void _degisti({bool bildir = true}) {
    _kirli = true;
    if (bildir) notifyListeners();
    _zamanlayici?.cancel();
    _zamanlayici = null;
    if (kayitGecikmesi == Duration.zero) {
      hemenKaydet();
    } else {
      _zamanlayici = Timer(kayitGecikmesi, hemenKaydet);
    }
  }

  /// Bekleyen değişiklik varsa hemen yazar. Yazma bitince tamamlanan bir Future döner.
  Future<void> hemenKaydet() {
    _zamanlayici?.cancel();
    _zamanlayici = null;
    if (_kirli) {
      _kirli = false;
      final icerik = jsonEncode(toJson());
      _yazmaKuyrugu = _yazmaKuyrugu.then((_) => _yaz(icerik));
    }
    return _yazmaKuyrugu;
  }

  Future<void> _yaz(String icerik) async {
    try {
      await _kayit.yaz(icerik);
      kayitHatasi = false;
    } catch (_) {
      kayitHatasi = true;
    }
  }

  @override
  void dispose() {
    _zamanlayici?.cancel();
    super.dispose();
  }
}

/// Ekranların depoya ulaşmasını sağlar; depo değişince bağımlı ekranlar yeniden çizilir.
class DepoKapsami extends InheritedNotifier<PlanDeposu> {
  const DepoKapsami({
    super.key,
    required PlanDeposu deposu,
    required super.child,
  }) : super(notifier: deposu);

  /// Çizim sırasında kullan: depo değişince ekran yenilenir.
  static PlanDeposu of(BuildContext context) {
    final kapsam = context.dependOnInheritedWidgetOfExactType<DepoKapsami>();
    assert(kapsam != null, 'DepoKapsami bulunamadı');
    return kapsam!.notifier!;
  }

  /// initState gibi yerlerde kullan: değişince yenilenmez.
  static PlanDeposu oku(BuildContext context) {
    final kapsam = context.getInheritedWidgetOfExactType<DepoKapsami>();
    assert(kapsam != null, 'DepoKapsami bulunamadı');
    return kapsam!.notifier!;
  }
}
