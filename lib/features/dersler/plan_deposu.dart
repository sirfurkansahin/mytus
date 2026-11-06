import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:app/core/tarih.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/bilissel/modeller.dart';
import 'package:app/features/defterler/hazir_skorlar.dart';
import 'package:app/features/defterler/modeller.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/kutuphane/modeller.dart';
import 'package:app/features/ft_time/ft_oturum.dart';
import 'package:app/features/takvim/calisma.dart';
import 'package:app/features/takvim/tekrar_motoru.dart';
import 'package:flutter/widgets.dart';

enum YuklemeDurumu { yukleniyor, hazir, hata }

/// Kullanıcının görünüm teması tercihi.
enum TemaSecimi { sistem, acik, koyu }

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
  MufredatTuru mufredatTuru = MufredatTuru.speetus;
  TemaSecimi temaSecimi = TemaSecimi.sistem;

  int _sonId = 0;
  final List<Ders> _dersler = [];
  final List<Konu> _konular = [];
  final List<Calisma> _calismalar = [];

  /// Her konu kaç tur çalışılacak (varsayılan 3, Rapor Bölüm 6: 3 faz, 3 tur).
  int turSayisi = 3;

  /// Bir güne düşebilecek en çok tekrar sayısı (varsayılan 10).
  int gunlukTekrarSiniri = 10;

  /// Bir güne yerleştirilmesi önerilen en çok yeni konu sayısı (varsayılan 4).
  int gunlukYeniKonuSiniri = 4;

  /// "Zor gün" (nöbet/yoğun gün) olarak işaretlenen gün; o gün yük hafifler. Yoksa null.
  DateTime? _zorGun;

  /// F.T. time süre ayarları.
  FtAyarlari ftAyar = const FtAyarlari();

  final Map<String, int> _gunlukSorular = {};
  final List<OdakKaydi> _odaklar = [];
  FtOturum? _oturum;
  final List<DenemeSinavi> _denemeler = [];
  final List<HataKaydi> _hataDefteri = [];
  final List<SkorKarti> _ozelSkorlar = [];
  final List<MekanizmaZinciri> _zincirler = [];
  final List<VakaKarti> _vakaKartlari = [];
  final List<UykuKaydi> _uykular = [];
  final List<Kitap> _kitaplar = [];
  bool _kurtarmaModuAktif = false;
  String _hedefYatisSaati = '23:30';
  String _hedefKalkisSaati = '07:30';

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

      final konuNumaralari = konular.map((k) => k.id).toSet();
      final calismalar = <Calisma>[];
      final calismaListesi = veri['calismalar'];
      if (calismaListesi is List) {
        for (final e in calismaListesi) {
          final c = Calisma.fromJson(e);
          if (c != null && konuNumaralari.contains(c.konuId)) calismalar.add(c);
        }
      }

      var enBuyuk = 0;
      for (final d in dersler) {
        enBuyuk = math.max(enBuyuk, d.id);
      }
      for (final k in konular) {
        enBuyuk = math.max(enBuyuk, k.id);
      }
      for (final c in calismalar) {
        enBuyuk = math.max(enBuyuk, c.id);
      }
      final kayitliSon = veri['sonId'];

      final tarih = veri['sinavTarihi'];
      sinavTarihi = tarih is String ? tarihCoz(tarih) : null;
      karsilamaTamam = veri['karsilamaTamam'] == true;
      final temaAdi = veri['temaSecimi'];
      temaSecimi = TemaSecimi.values.firstWhere(
        (t) => t.name == temaAdi,
        orElse: () => TemaSecimi.sistem,
      );
      final mufredatAdi = veri['mufredatTuru'];
      mufredatTuru = MufredatTuru.values.firstWhere(
        (m) => m.name == mufredatAdi,
        orElse: () => _dersler.any((d) => d.grup == DersGrubu.klinik)
            ? MufredatTuru.klasik
            : MufredatTuru.speetus,
      );
      _sonId = math.max(kayitliSon is int ? kayitliSon : 0, enBuyuk);
      _dersler
        ..clear()
        ..addAll(dersler);
      _konular
        ..clear()
        ..addAll(konular);
      _calismalar
        ..clear()
        ..addAll(calismalar);
      final tur = veri['turSayisi'];
      turSayisi = tur is int && tur >= 1 && tur <= 10 ? tur : 3;
      final sinir = veri['gunlukTekrarSiniri'];
      gunlukTekrarSiniri = sinir is int && sinir >= 0 ? sinir : 10;
      final yeniSinir = veri['gunlukYeniKonuSiniri'];
      gunlukYeniKonuSiniri =
          yeniSinir is int && yeniSinir >= 1 && yeniSinir <= 20 ? yeniSinir : 4;
      final zorGun = veri['zorGun'];
      _zorGun = zorGun is String ? tarihCoz(zorGun) : null;
      ftAyar = FtAyarlari.fromJson(veri['ftAyar']);
      final sorular = veri['gunlukSorular'];
      if (sorular is Map) {
        _gunlukSorular.clear();
        for (final entry in sorular.entries) {
          if (entry.key is String && entry.value is int) {
            _gunlukSorular[entry.key as String] = entry.value as int;
          }
        }
      }
      final odaklar = <OdakKaydi>[];
      final odakListesi = veri['odaklar'];
      if (odakListesi is List) {
        final gorulen = <String>{};
        for (final e in odakListesi) {
          final o = OdakKaydi.fromJson(e);
          if (o == null || !gorulen.add(o.anahtar)) continue;
          odaklar.add(
            o.konuId != null && !konuNumaralari.contains(o.konuId)
                ? o.konuSiz()
                : o,
          );
        }
      }
      _odaklar
        ..clear()
        ..addAll(odaklar);
      var oturum = FtOturum.fromJson(veri['oturum']);
      if (oturum != null &&
          oturum.konuId != null &&
          !konuNumaralari.contains(oturum.konuId)) {
        oturum = oturum.konuSiz();
      }
      _oturum = oturum;
      if (oturum != null) enBuyuk = math.max(enBuyuk, oturum.id);

      final denemeler = <DenemeSinavi>[];
      final denemeListesi = veri['denemeler'];
      if (denemeListesi is List) {
        for (final e in denemeListesi) {
          if (e is Map<String, dynamic>) {
            denemeler.add(DenemeSinavi.fromJson(e));
          }
        }
      }
      _denemeler
        ..clear()
        ..addAll(denemeler);

      final hatalar = <HataKaydi>[];
      final hataListesi = veri['hataDefteri'];
      if (hataListesi is List) {
        for (final e in hataListesi) {
          if (e is Map<String, dynamic>) {
            hatalar.add(HataKaydi.fromJson(e));
          }
        }
      }
      _hataDefteri
        ..clear()
        ..addAll(hatalar);

      final skorlar = <SkorKarti>[];
      final skorListesi = veri['ozelSkorlar'];
      if (skorListesi is List) {
        for (final e in skorListesi) {
          if (e is Map<String, dynamic>) {
            skorlar.add(SkorKarti.fromJson(e));
          }
        }
      }
      _ozelSkorlar
        ..clear()
        ..addAll(skorlar);

      final zincirler = <MekanizmaZinciri>[];
      final zincirListesi = veri['zincirler'];
      if (zincirListesi is List) {
        for (final e in zincirListesi) {
          if (e is Map<String, dynamic>) {
            zincirler.add(MekanizmaZinciri.fromJson(e));
          }
        }
      }
      _zincirler
        ..clear()
        ..addAll(zincirler);

      final vakalar = <VakaKarti>[];
      final vakaListesi = veri['vakaKartlari'];
      if (vakaListesi is List) {
        for (final e in vakaListesi) {
          if (e is Map<String, dynamic>) {
            vakalar.add(VakaKarti.fromJson(e));
          }
        }
      }
      _vakaKartlari
        ..clear()
        ..addAll(vakalar);

      final uykular = <UykuKaydi>[];
      final uykuListesi = veri['uykular'];
      if (uykuListesi is List) {
        for (final e in uykuListesi) {
          if (e is Map<String, dynamic>) {
            uykular.add(UykuKaydi.fromJson(e));
          }
        }
      }
      _uykular
        ..clear()
        ..addAll(uykular);

      final kitaplar = <Kitap>[];
      final kitapListesi = veri['kitaplar'];
      if (kitapListesi is List) {
        for (final e in kitapListesi) {
          if (e is Map<String, dynamic>) {
            kitaplar.add(Kitap.fromJson(e));
          }
        }
      }
      _kitaplar
        ..clear()
        ..addAll(kitaplar);
      _kurtarmaModuAktif = veri['kurtarmaModuAktif'] as bool? ?? false;
      _hedefYatisSaati = veri['hedefYatisSaati'] as String? ?? '23:30';
      _hedefKalkisSaati = veri['hedefKalkisSaati'] as String? ?? '07:30';

      _sonId = math.max(_sonId, enBuyuk);
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
        'temaSecimi': temaSecimi.name,
        'mufredatTuru': mufredatTuru.name,
        'dersler': [for (final d in _dersler) d.toJson()],
        'konular': [for (final k in _konular) k.toJson()],
        'calismalar': [for (final c in _calismalar) c.toJson()],
        'turSayisi': turSayisi,
        'gunlukTekrarSiniri': gunlukTekrarSiniri,
        'gunlukYeniKonuSiniri': gunlukYeniKonuSiniri,
        'gunlukSorular': _gunlukSorular,
        'zorGun': _zorGun == null ? null : tarihAnahtari(_zorGun!),
        'ftAyar': ftAyar.toJson(),
        'odaklar': [for (final o in _odaklar) o.toJson()],
        'oturum': _oturum?.toJson(),
        'denemeler': [for (final d in _denemeler) d.toJson()],
        'hataDefteri': [for (final h in _hataDefteri) h.toJson()],
        'ozelSkorlar': [for (final s in _ozelSkorlar) s.toJson()],
        'zincirler': [for (final z in _zincirler) z.toJson()],
        'vakaKartlari': [for (final v in _vakaKartlari) v.toJson()],
        'uykular': [for (final u in _uykular) u.toJson()],
        'kitaplar': [for (final k in _kitaplar) k.toJson()],
        'kurtarmaModuAktif': _kurtarmaModuAktif,
        'hedefYatisSaati': _hedefYatisSaati,
        'hedefKalkisSaati': _hedefKalkisSaati,
      };

  // ---------------------------------------------------------------- okuma

  List<Ders> get tumDersler => List.unmodifiable(_dersler);

  List<Ders> dersler([DersGrubu? grup]) => grup == null
      ? List.unmodifiable(_dersler)
      : _dersler.where((d) => d.grup == grup).toList(growable: false);

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
      konular(dersId).where((k) => konuCalisildi(k.id)).length;

  // ---------------------------------------------------------------- yazma

  /// Adı düzeltir: baştaki/sondaki boşlukları atar, ardışık boşlukları teke indirir.
  /// Boşsa null döner. En fazla 80 karakter.
  static String? adTemizle(String ham) {
    final ad = ham.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (ad.isEmpty) return null;
    return ad.length > 80 ? ad.substring(0, 80) : ad;
  }

  int _yeniId() => ++_sonId;

  /// Karşılama ekranı bitti: sınav tarihini, seçilen dersleri ve hazır alt konuları kaydeder.
  Future<void> karsilamayiTamamla({
    required DateTime sinavTarihi,
    required List<HazirDers> secilenDersler,
    MufredatTuru mufredatTuru = MufredatTuru.speetus,
  }) async {
    this.sinavTarihi = DateTime(sinavTarihi.year, sinavTarihi.month, sinavTarihi.day);
    this.mufredatTuru = mufredatTuru;
    for (final h in secilenDersler) {
      final ders = _dersEkleIc(h.ad, h.grup);
      if (ders != null) {
        for (final k in h.konular) {
          _konuEkleIc(ders.id, k);
        }
      }
    }
    karsilamaTamam = true;
    _degisti();
    await hemenKaydet();
  }


  /// Müfredat tarzını değiştirir ve yeni dersleri yükler.
  Future<void> mufredatSifirlaVeDegistir({
    required MufredatTuru yeniTur,
    required List<HazirDers> yeniDersler,
  }) async {
    _dersler.clear();
    _konular.clear();
    _calismalar.clear();
    _odaklar.clear();
    _oturum = null;
    _denemeler.clear();
    mufredatTuru = yeniTur;
    for (final h in yeniDersler) {
      final ders = _dersEkleIc(h.ad, h.grup);
      if (ders != null) {
        for (final k in h.konular) {
          _konuEkleIc(ders.id, k);
        }
      }
    }
    _degisti();
    await hemenKaydet();
    notifyListeners();
  }
  void sinavTarihiBelirle(DateTime tarih) {
    sinavTarihi = DateTime(tarih.year, tarih.month, tarih.day);
    _degisti();
  }

  Ders? _dersEkleIc(String ham, [DersGrubu grup = DersGrubu.temel]) {
    final ad = adTemizle(ham);
    if (ad == null) return null;
    final kucuk = ad.toLowerCase();
    final varMi = _dersler.any((d) => d.ad.toLowerCase() == kucuk);
    if (varMi) return null;
    final ders = Ders(id: _yeniId(), ad: ad, grup: grup);
    _dersler.add(ders);
    return ders;
  }

  /// Ders ekler. Ad boşsa veya aynı adlı ders varsa null döner.
  Ders? dersEkle(String ad, [DersGrubu grup = DersGrubu.temel]) {
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
      (d) => d.id != id && d.ad.toLowerCase() == kucuk,
    );
    if (baskasiVar) return false;
    _dersler[indeks] = ders.kopya(ad: ad);
    _degisti();
    return true;
  }

  /// Dersi ve ona bağlı tüm konuları (notlarıyla) siler.
  void dersSil(int id) {
    final konuNumaralari =
        _konular.where((k) => k.dersId == id).map((k) => k.id).toSet();
    _calismalar.removeWhere((c) => konuNumaralari.contains(c.konuId));
    _konuBaginiTemizle(konuNumaralari);
    _dersler.removeWhere((d) => d.id == id);
    _konular.removeWhere((k) => k.dersId == id);
    _degisti();
  }

  Konu? _konuEkleIc(int dersId, String ham) {
    final ad = adTemizle(ham);
    if (ad == null || dersBul(dersId) == null) return null;
    final kucuk = ad.toLowerCase();
    final varMi = _konular.any(
      (k) => k.dersId == dersId && k.ad.toLowerCase() == kucuk,
    );
    if (varMi) return null;
    final konu = Konu(id: _yeniId(), dersId: dersId, ad: ad);
    _konular.add(konu);
    return konu;
  }

  /// Konu ekler. Ad boşsa, ders yoksa veya aynı derste aynı adlı konu varsa null döner.
  Konu? konuEkle(int dersId, String ham) {
    final konu = _konuEkleIc(dersId, ham);
    if (konu != null) _degisti();
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
    _calismalar.removeWhere((c) => c.konuId == id);
    _konuBaginiTemizle({id});
    _konular.removeWhere((k) => k.id == id);
    _degisti();
  }

  /// Silinen konulara bağlı odak kayıtları ve oturum konusuz kalır (puanlar silinmez).
  void _konuBaginiTemizle(Set<int> konuNumaralari) {
    for (var i = 0; i < _odaklar.length; i++) {
      final k = _odaklar[i].konuId;
      if (k != null && konuNumaralari.contains(k)) {
        _odaklar[i] = _odaklar[i].konuSiz();
      }
    }
    final o = _oturum;
    if (o != null && o.konuId != null && konuNumaralari.contains(o.konuId)) {
      _oturum = o.konuSiz();
    }
  }

  /// Notu günceller. Ekranı yeniden çizdirmez (yazarken gereksiz), yalnızca kaydı planlar.
  void notYaz(int konuId, String metin) {
    final indeks = _konular.indexWhere((k) => k.id == konuId);
    if (indeks < 0) return;
    _konular[indeks] = _konular[indeks].kopya(not: metin);
    _degisti(bildir: false);
  }

  // ---------------------------------------------------------- çalışmalar

  Calisma? calismaBul(int id) {
    for (final c in _calismalar) {
      if (c.id == id) return c;
    }
    return null;
  }

  static int _calismaSirala(Calisma a, Calisma b) {
    final k = a.tarih.compareTo(b.tarih);
    return k != 0 ? k : a.id.compareTo(b.id);
  }

  /// Bir konunun tüm çalışmaları (tarih sırasıyla).
  List<Calisma> calismalarKonu(int konuId) =>
      _calismalar.where((c) => c.konuId == konuId).toList()
        ..sort(_calismaSirala);

  /// Belirli güne planlanmış çalışmalar.
  List<Calisma> calismalarGun(DateTime gun) =>
      _calismalar.where((c) => ayniGun(c.tarih, gun)).toList()
        ..sort(_calismaSirala);

  /// Planlanmış tüm çalışmalar (tarih sırasıyla).
  List<Calisma> tumCalismalar() => [..._calismalar]..sort(_calismaSirala);

  /// Çalışmanın tur numarası: aynı konunun çalışmaları arasında tarih sırası (1'den başlar).
  int turNo(Calisma c) {
    final sirali = calismalarKonu(c.konuId);
    final i = sirali.indexWhere((x) => x.id == c.id);
    return i < 0 ? 1 : i + 1;
  }

  bool konuCalisildi(int konuId) =>
      _calismalar.any((c) => c.konuId == konuId && c.tamam);

  /// Konunun ilk "Çalıştım" günü (yoksa null).
  DateTime? ilkCalisma(int konuId) {
    DateTime? en;
    for (final c in _calismalar) {
      if (c.konuId == konuId && c.tamam && (en == null || c.tarih.isBefore(en))) {
        en = c.tarih;
      }
    }
    return en;
  }

  /// Tüm tekrarlar (sınav tarihi seçilmediyse boş).
  List<TekrarOgesi> tekrarlar(DateTime bugun) {
    final sinav = sinavTarihi;
    if (sinav == null) return const [];
    return tekrarlariHesapla(
      calismalar: _calismalar,
      sinavTarihi: sinav,
      bugun: bugun,
      gunlukSinir: etkinTekrarSiniri(bugun),
    );
  }

  /// Bir güne yerleştirilmiş konu sayısı (tamamlananlar dahil).
  int gundekiKonuSayisi(DateTime gun) => calismalarGun(gun).length;

  /// O gün için önerilen yeni konu sınırına ulaşıldı mı?
  bool gunDolu(DateTime gun) => gundekiKonuSayisi(gun) >= gunlukYeniKonuSiniri;

  /// Verilen gün "Zor gün" olarak işaretli mi?
  bool zorGunMu(DateTime gun) => _zorGun != null && ayniGun(_zorGun!, gun);

  /// O günün tekrar sınırı: zor günde %70'e iner (en az 3).
  int etkinTekrarSiniri(DateTime gun) => zorGunMu(gun)
      ? math.max(3, (gunlukTekrarSiniri * 0.7).floor())
      : gunlukTekrarSiniri;

  /// "Zor gün": bugünün ve geciken yapılmamış konuları yarına taşır, tekrar yükünü %70'e indirir.
  void zorGunBaslat(DateTime bugun) {
    final g = gunBasi(bugun);
    final yarin = gunEkle(g, 1);
    for (var i = 0; i < _calismalar.length; i++) {
      final c = _calismalar[i];
      if (!c.tamam && !c.tarih.isAfter(g)) {
        _calismalar[i] = c.kopya(tarih: yarin);
      }
    }
    _zorGun = g;
    _degisti();
  }

  /// Zor gün işaretini kaldırır (taşınan konular yerinde kalır).
  void zorGunKapat() {
    if (_zorGun == null) return;
    _zorGun = null;
    _degisti();
  }

  /// Geciken tekrarları "bugün yapıldı" sayar; sonraki tekrarlar mevcut kayma kuralıyla yeniden dağılır.
  int gecikenTekrarlariSifirla(DateTime bugun) {
    final g = gunBasi(bugun);
    var sayac = 0;
    for (var tur = 0; tur < 500; tur++) {
      TekrarOgesi? hedef;
      for (final t in tekrarlar(g)) {
        if (t.eylemYapilabilir && t.tarih.isBefore(g)) {
          hedef = t;
          break;
        }
      }
      if (hedef == null || !tekrarYapildi(hedef.calismaId, hedef.no, g)) break;
      sayac++;
    }
    return sayac;
  }

  /// Konuyu bir güne yerleştirir. Aynı konu tekrar yerleştirilebilir (sonraki tur).
  Calisma? calismaEkle(int konuId, DateTime gun) {
    if (konuBul(konuId) == null) return null;
    final c = Calisma(id: _yeniId(), konuId: konuId, tarih: gunBasi(gun));
    _calismalar.add(c);
    _degisti();
    return c;
  }

  void calismaSil(int id) {
    _calismalar.removeWhere((c) => c.id == id);
    _degisti();
  }

  /// Henüz çalışılmamış bir çalışmanın gününü değiştirir (ör. "Bugüne al").
  bool calismaGunuDegistir(int id, DateTime gun) {
    final i = _calismalar.indexWhere((c) => c.id == id);
    if (i < 0 || _calismalar[i].tamam) return false;
    _calismalar[i] = _calismalar[i].kopya(tarih: gunBasi(gun));
    _degisti();
    return true;
  }

  /// Gecikmiş (bugünden önceki, tamamlanmamış) tüm çalışmaları bugüne taşır.
  int gecikenleriBuguneAl(DateTime bugun) {
    final hedef = gunBasi(bugun);
    var tasinan = 0;
    for (var i = 0; i < _calismalar.length; i++) {
      final c = _calismalar[i];
      if (!c.tamam && c.tarih.isBefore(hedef)) {
        _calismalar[i] = c.kopya(tarih: hedef);
        tasinan++;
      }
    }
    if (tasinan > 0) _degisti();
    return tasinan;
  }

  /// "Çalıştım": çalışma bugün yapıldı sayılır ve tekrarlar bugünden başlar.
  bool calistim(int id, DateTime bugun) {
    final i = _calismalar.indexWhere((c) => c.id == id);
    if (i < 0 || _calismalar[i].tamam) return false;
    _calismalar[i] = _calismalar[i].kopya(tarih: gunBasi(bugun), tamam: true);
    _degisti();
    return true;
  }

  /// "Çalıştım" işaretini geri alır; yapılmış tekrar kayıtları da silinir.
  bool calismaGeriAl(int id) {
    final i = _calismalar.indexWhere((c) => c.id == id);
    if (i < 0 || !_calismalar[i].tamam) return false;
    _calismalar[i] = _calismalar[i].kopya(tamam: false, tekrarlar: const []);
    _degisti();
    return true;
  }

  /// "Tekrar yaptım". Önceki tekrarlar yapılmadıysa veya çalışma bitmediyse false döner.
  bool tekrarYapildi(int calismaId, int no, DateTime bugun) {
    final i = _calismalar.indexWhere((c) => c.id == calismaId);
    final sinav = sinavTarihi;
    if (i < 0 || sinav == null || no < 1) return false;
    final c = _calismalar[i];
    if (!c.tamam || c.tekrarKaydi(no) != null) return false;
    if (no > tekrarGunleri(gunFarki(sinav, c.tarih)).length) return false;
    for (var onceki = 1; onceki < no; onceki++) {
      if (c.tekrarKaydi(onceki) == null) return false;
    }
    final yeni = [...c.tekrarlar, TekrarKaydi(no: no, tarih: gunBasi(bugun))]
      ..sort((a, b) => a.no.compareTo(b.no));
    _calismalar[i] = c.kopya(tekrarlar: yeni);
    _degisti();
    return true;
  }

  /// Tekrar işaretini ve ondan sonrakileri geri alır.
  bool tekrarGeriAl(int calismaId, int no) {
    final i = _calismalar.indexWhere((c) => c.id == calismaId);
    if (i < 0 || _calismalar[i].tekrarKaydi(no) == null) return false;
    final kalan = _calismalar[i].tekrarlar.where((k) => k.no < no).toList();
    _calismalar[i] = _calismalar[i].kopya(tekrarlar: kalan);
    _degisti();
    return true;
  }


  // ------------------------------------------------------------- ayarlar

  void turSayisiBelirle(int sayi) {
    turSayisi = sayi < 1 ? 1 : (sayi > 5 ? 5 : sayi);
    _degisti();
  }

  void gunlukSinirBelirle(int sayi) {
    gunlukTekrarSiniri = sayi < 3 ? 3 : (sayi > 30 ? 30 : sayi);
    _degisti();
  }

  void gunlukYeniKonuSinirBelirle(int sayi) {
    gunlukYeniKonuSiniri = sayi < 1 ? 1 : (sayi > 20 ? 20 : sayi);
    _degisti();
  }

  Map<String, int> get gunlukSorular => Map.unmodifiable(_gunlukSorular);

  int soruSayisiGun(DateTime gun) => _gunlukSorular[tarihAnahtari(gun)] ?? 0;

  void soruSayisiAyarla(DateTime gun, int adet) {
    final anahtar = tarihAnahtari(gun);
    final yeni = math.max(0, adet);
    if (yeni == 0) {
      _gunlukSorular.remove(anahtar);
    } else {
      _gunlukSorular[anahtar] = yeni;
    }
    _degisti();
  }

  void soruEkle(DateTime gun, int fark) {
    soruSayisiAyarla(gun, soruSayisiGun(gun) + fark);
  }

  void ftAyarBelirle(FtAyarlari ayar) {
    ftAyar = ayar;
    _degisti();
  }

  void temaBelirle(TemaSecimi yeni) {
    if (temaSecimi == yeni) return;
    temaSecimi = yeni;
    _degisti();
  }

  /// Yedek metnini (JSON) doğrular ve tüm veriyi yedekten geri yükler.
  bool yedektenYukle(String jsonMetni) {
    final tamam = _jsonYukle(jsonMetni);
    if (tamam) _degisti();
    return tamam;
  }

  /// Tüm ders, konu, çalışma ve odak kayıtlarını sıfırlayıp karşılama ekranına döndürür.
  Future<void> tumVerileriSifirla() async {
    _sonId = 0;
    _dersler.clear();
    _konular.clear();
    _calismalar.clear();
    _odaklar.clear();
    _oturum = null;
    _denemeler.clear();
    _hataDefteri.clear();
    _ozelSkorlar.clear();
    _zincirler.clear();
    _vakaKartlari.clear();
    _uykular.clear();
    _kitaplar.clear();
    _kurtarmaModuAktif = false;
    _hedefYatisSaati = '23:30';
    _hedefKalkisSaati = '07:30';
    sinavTarihi = resmiSinavTarihi;
    karsilamaTamam = false;
    turSayisi = 3;
    gunlukTekrarSiniri = 10;
    gunlukYeniKonuSiniri = 4;
    _gunlukSorular.clear();
    _zorGun = null;
    ftAyar = const FtAyarlari();
    _degisti();
    await hemenKaydet();
  }

  // ------------------------------------------------------ F.T. time oturumu

  FtOturum? get oturum => _oturum;

  List<OdakKaydi> get odaklar => List.unmodifiable(_odaklar);

  /// Yeni oturum başlatır (varsa eskisinin yerine). Süreler o anki ayarlardan alınır.
  FtOturum oturumBaslat({required int toplamDongu, int? konuId}) {
    final gecerliKonu = konuId != null && konuBul(konuId) != null ? konuId : null;
    final o = FtOturum.yeni(
      id: _yeniId(),
      toplamDongu: toplamDongu,
      ayar: ftAyar,
      konuId: gecerliKonu,
    );
    _oturum = o;
    _degisti();
    return o;
  }

  /// Oturumun yeni durumunu kaydeder. Çalışma bölümü bittiyse döngü puanlanır.
  /// Aynı döngü ikinci kez puanlanmaz.
  void oturumGuncelle(FtOturum yeni) {
    _oturum = yeni;
    _donguyuPuanla(yeni);
    _degisti();
  }

  void oturumKapat() {
    if (_oturum == null) return;
    _oturum = null;
    _degisti();
  }

  void _donguyuPuanla(FtOturum o) {
    if (o.faz != FtFaz.calisma || !o.bolumBitti) return;
    final anahtar = '${o.id}:${o.dongu}';
    if (_odaklar.any((x) => x.anahtar == anahtar)) return;
    _odaklar.add(
      OdakKaydi(
        anahtar: anahtar,
        tarihMs: o.sayac.endAtMs ?? DateTime.now().millisecondsSinceEpoch,
        dakika: o.donguPuani,
        konuId: o.konuId,
      ),
    );
  }

  /// Süresi dolan bölümü "bitti" yapar ve gerekirse puanlar. Uygulama açılırken
  /// ve arka plandan dönerken çağrılır. Bir şey değiştiyse true döner.
  bool oturumuTazele(int nowMs) {
    final o = _oturum;
    if (o == null) return false;
    final yeni = o.guncelle(nowMs);
    if (identical(yeni, o)) return false;
    oturumGuncelle(yeni);
    return true;
  }

  int get toplamPuan => _odaklar.fold(0, (t, o) => t + o.puan);

  /// [bas] dahil, [son] hariç aralıktaki puan.
  int puanAraligi(DateTime bas, DateTime son) {
    var t = 0;
    for (final o in _odaklar) {
      final g = o.tarih;
      if (!g.isBefore(bas) && g.isBefore(son)) t += o.puan;
    }
    return t;
  }

  int puanGun(DateTime gun) {
    final bas = gunBasi(gun);
    return puanAraligi(bas, gunEkle(bas, 1));
  }

  /// Pazartesi başlangıçlı hafta puanı.
  int puanHafta(DateTime gun) {
    final bas = gunEkle(gunBasi(gun), -(gun.weekday - 1));
    return puanAraligi(bas, gunEkle(bas, 7));
  }

  /// Odak sonrası "Çalıştım" onayı: konunun bekleyen en erken yerleştirmesini
  /// bugüne alıp çalışıldı yapar; hiç bekleyeni yoksa bugüne yeni bir tane açar.
  bool konuCalistimIsaretle(int konuId, DateTime bugun) {
    if (konuBul(konuId) == null) return false;
    Calisma? hedef;
    for (final c in calismalarKonu(konuId)) {
      if (!c.tamam) {
        hedef = c;
        break;
      }
    }
    hedef ??= calismaEkle(konuId, bugun);
    if (hedef == null) return false;
    return calistim(hedef.id, bugun);
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


  // ---------------------------------------------------------------- denemeler

  List<DenemeSinavi> get denemeler => List.unmodifiable(_denemeler);

  DenemeSinavi? denemeBul(String id) {
    for (final d in _denemeler) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<void> denemeEkle(DenemeSinavi deneme) async {
    _denemeler.insert(0, deneme);
    _degisti();
    await hemenKaydet();
  }

  Future<void> denemeGuncelle(DenemeSinavi deneme) async {
    final idx = _denemeler.indexWhere((d) => d.id == deneme.id);
    if (idx != -1) {
      _denemeler[idx] = deneme;
      _degisti();
      await hemenKaydet();
    }
  }

  Future<void> denemeSil(String id) async {
    _denemeler.removeWhere((d) => d.id == id);
    _degisti();
    await hemenKaydet();
  }

  // ---------------------------------------------------------------- özel defterler

  List<HataKaydi> get hataDefteri => List.unmodifiable(_hataDefteri);

  Future<void> hataEkle(HataKaydi hata) async {
    _hataDefteri.insert(0, hata);
    _degisti();
    await hemenKaydet();
  }

  Future<void> hataGuncelle(HataKaydi hata) async {
    final idx = _hataDefteri.indexWhere((h) => h.id == hata.id);
    if (idx != -1) {
      _hataDefteri[idx] = hata;
      _degisti();
      await hemenKaydet();
    }
  }

  Future<void> hataPekistir(String id, bool pekistirildi) async {
    final idx = _hataDefteri.indexWhere((h) => h.id == id);
    if (idx != -1) {
      _hataDefteri[idx] = _hataDefteri[idx].copyWith(pekistirildi: pekistirildi);
      _degisti();
      await hemenKaydet();
    }
  }

  Future<void> hataSil(String id) async {
    _hataDefteri.removeWhere((h) => h.id == id);
    _degisti();
    await hemenKaydet();
  }

  List<SkorKarti> get tumSkorlar => [..._ozelSkorlar, ...hazirSkorlar];
  List<SkorKarti> get ozelSkorlar => List.unmodifiable(_ozelSkorlar);

  Future<void> skorEkle(SkorKarti skor) async {
    _ozelSkorlar.insert(0, skor);
    _degisti();
    await hemenKaydet();
  }

  Future<void> skorSil(String id) async {
    _ozelSkorlar.removeWhere((s) => s.id == id);
    _degisti();
    await hemenKaydet();
  }

  List<MekanizmaZinciri> get zincirler => List.unmodifiable(_zincirler);

  Future<void> zincirEkle(MekanizmaZinciri zincir) async {
    _zincirler.insert(0, zincir);
    _degisti();
    await hemenKaydet();
  }

  Future<void> zincirSil(String id) async {
    _zincirler.removeWhere((z) => z.id == id);
    _degisti();
    await hemenKaydet();
  }

  List<VakaKarti> get vakaKartlari => List.unmodifiable(_vakaKartlari);

  Future<void> vakaEkle(VakaKarti vaka) async {
    _vakaKartlari.insert(0, vaka);
    _degisti();
    await hemenKaydet();
  }

  Future<void> vakaSil(String id) async {
    _vakaKartlari.removeWhere((v) => v.id == id);
    _degisti();
    await hemenKaydet();
  }

  // ------------------------------------------------ Bilişsel & Uyku Yönetimi

  List<UykuKaydi> get uykular => List.unmodifiable(_uykular);
  bool get kurtarmaModuAktif => _kurtarmaModuAktif;
  String get hedefYatisSaati => _hedefYatisSaati;
  String get hedefKalkisSaati => _hedefKalkisSaati;

  Future<void> kurtarmaModuAyarla(bool aktif) async {
    _kurtarmaModuAktif = aktif;
    _degisti();
    await hemenKaydet();
  }

  Future<void> hedefUykuAyarla({
    required String yatis,
    required String kalkis,
  }) async {
    _hedefYatisSaati = yatis;
    _hedefKalkisSaati = kalkis;
    _degisti();
    await hemenKaydet();
  }

  Future<void> uykuKaydet(UykuKaydi kayit) async {
    _uykular.removeWhere((u) => u.tarih == kayit.tarih);
    _uykular.insert(0, kayit);
    _degisti();
    await hemenKaydet();
  }

  Future<void> uykuSil(String tarih) async {
    _uykular.removeWhere((u) => u.tarih == tarih);
    _degisti();
    await hemenKaydet();
  }

  UykuKaydi? bugunkuUyku([DateTime? gun]) {
    final t = tarihAnahtari(gun ?? DateTime.now());
    for (final u in _uykular) {
      if (u.tarih == t) return u;
    }
    return null;
  }

  /// Bugünkü zor bilişsel çalışma süresi (dakika).
  /// Rapor Kuralı: Günde en fazla 3-4 saat (180-240 dk) derin analitik iş yapılmalıdır.
  int zorBilisselDakikaBugun([DateTime? gun]) {
    final g = gunBasi(gun ?? DateTime.now());
    final yarin = gunEkle(g, 1);
    var toplam = 0;
    for (final o in _odaklar) {
      if (!o.tarih.isBefore(g) && o.tarih.isBefore(yarin) && o.zorBilissel) {
        toplam += o.dakika;
      }
    }
    return toplam;
  }

  /// Bugünkü tüm odak süresi (dakika).
  int toplamOdakDakikaBugun([DateTime? gun]) {
    final g = gunBasi(gun ?? DateTime.now());
    final yarin = gunEkle(g, 1);
    var toplam = 0;
    for (final o in _odaklar) {
      if (!o.tarih.isBefore(g) && o.tarih.isBefore(yarin)) {
        toplam += o.dakika;
      }
    }
    return toplam;
  }

  /// Günlük ortalama odak puanı (1.0 - 5.0).
  double ortalamaOdakPuani([DateTime? gun]) {
    final g = gunBasi(gun ?? DateTime.now());
    final yarin = gunEkle(g, 1);
    var toplam = 0;
    var sayi = 0;
    for (final o in _odaklar) {
      if (!o.tarih.isBefore(g) && o.tarih.isBefore(yarin)) {
        toplam += o.odakPuani;
        sayi++;
      }
    }
    return sayi == 0 ? 0.0 : toplam / sayi;
  }

  /// 240 dk (4 saat) tavanı aşıldı mı?
  bool get zorBilisselTavanAsildi => zorBilisselDakikaBugun() >= 240;

  /// 180 dk (3 saat) eşiğine ulaşıldı mı?
  bool get zorBilisselYaklasti =>
      zorBilisselDakikaBugun() >= 180 && !zorBilisselTavanAsildi;

  /// Saatlere göre odak ortalaması (Sirkadiyen biyolojik verim dağılımı).
  Map<int, double> saatlikOdakDagilimi([int sonGun = 14]) {
    final esik = gunEkle(gunBasi(DateTime.now()), -sonGun);
    final toplamlar = <int, int>{};
    final sayilar = <int, int>{};
    for (final o in _odaklar) {
      if (o.tarih.isBefore(esik)) continue;
      final saat = o.tarih.hour;
      toplamlar[saat] = (toplamlar[saat] ?? 0) + o.odakPuani;
      sayilar[saat] = (sayilar[saat] ?? 0) + 1;
    }
    final sonuc = <int, double>{};
    for (final saat in toplamlar.keys) {
      sonuc[saat] = toplamlar[saat]! / sayilar[saat]!;
    }
    return sonuc;
  }

  /// Son denemelerdeki C tipi (Okuma / kurgu / dikkat) hata oranı.
  double get sonOkumaHatasiOrani {
    if (_denemeler.isEmpty) return 0.0;
    final sonDenemeler = _denemeler.take(3);
    var toplamHata = 0;
    var cHatasi = 0;
    for (final d in sonDenemeler) {
      for (final s in d.soruHatalari) {
        if (!s.dogruMu) {
          toplamHata++;
          if (s.hataSinifi == HataSinifi.c) cHatasi++;
        }
      }
    }
    if (toplamHata == 0) return 0.0;
    return cHatasi / toplamHata;
  }

  /// C tipi hata oranı > %15 ise Prefrontal Korteks Yorgunluğu alarmı.
  bool get pfcErkenUyariAktif => sonOkumaHatasiOrani > 0.15;

  /// Sınava 7 gün kala Uyku Taper Protokolü aktif mi?
  bool get uykuTaperAktif {
    final sinav = sinavTarihi;
    if (sinav == null) return false;
    final fark = gunFarki(sinav, gunBasi(DateTime.now()));
    return fark >= 0 && fark <= 7;
  }

  /// Döngü tamamlandığında odak puanı ve zor bilişsel iş türünü günceller.
  Future<void> sonOdakGuncelle({
    required String anahtar,
    required int odakPuani,
    required bool zorBilissel,
  }) async {
    final idx = _odaklar.indexWhere((x) => x.anahtar == anahtar);
    if (idx != -1) {
      _odaklar[idx] = _odaklar[idx].kopyala(
        odakPuani: odakPuani,
        zorBilissel: zorBilissel,
      );
      _degisti();
      await hemenKaydet();
    }
  }


  // ---------------------------------------------------------------- kÃ¼tÃ¼phane

  List<Kitap> get kitaplar => List.unmodifiable(_kitaplar);

  Kitap? kitapBul(String id) {
    for (final k in _kitaplar) {
      if (k.id == id) return k;
    }
    return null;
  }

  Future<void> kitapEkle(Kitap kitap) async {
    _kitaplar.insert(0, kitap);
    _degisti();
    await hemenKaydet();
  }

  Future<void> kitapGuncelle(Kitap kitap) async {
    final idx = _kitaplar.indexWhere((k) => k.id == kitap.id);
    if (idx != -1) {
      _kitaplar[idx] = kitap;
      _degisti();
      await hemenKaydet();
    }
  }

  Future<void> kitapSil(String id) async {
    _kitaplar.removeWhere((k) => k.id == id);
    _degisti();
    await hemenKaydet();
  }

  Future<void> kitapBolumDurumuDegistir(
    String kitapId,
    String bolumId,
    bool tamamlandi,
  ) async {
    final kIdx = _kitaplar.indexWhere((k) => k.id == kitapId);
    if (kIdx == -1) return;
    final kitap = _kitaplar[kIdx];
    final yeniBolumler = <KitapBolumu>[];
    for (final b in kitap.bolumler) {
      if (b.id == bolumId) {
        yeniBolumler.add(
          b.kopya(
            tamamlandi: tamamlandi,
            tamamlanmaTarihi: tamamlandi ? DateTime.now() : null,
          ),
        );
      } else {
        yeniBolumler.add(b);
      }
    }
    _kitaplar[kIdx] = kitap.kopya(bolumler: yeniBolumler);
    _degisti();
    await hemenKaydet();
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
