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

/// Yerel `VeriKaydi` ile `BulutKaynagi` (Firestore) arasında çalışan Offline-First köprü.
/// - Her yazma işlemi önce anında yerel hafızaya (`localStorage`) yapılır.
/// - Fotoğraflar buluta gönderilmez; cihazda `mytus_photos_{uid}` anahtarında saklanır.
/// - Yalnızca değişen veri bölümleri kısa bir gecikmeyle (veya hemen) Firestore'a yazılır.
/// - İnternet kesilirse değişiklikler kuyrukta bekler, bağlantı gelince gönderilir.
class BulutSenkronServisi extends ChangeNotifier implements VeriKaydi {
  BulutSenkronServisi({
    required VeriKaydi yerelKayit,
    required BulutKaynagi bulutKaynagi,
    Duration gonderimGecikmesi = const Duration(milliseconds: 800),
    String? cihazId,
  })  : _yerel = yerelKayit,
        _bulut = bulutKaynagi,
        _gonderimGecikmesi = gonderimGecikmesi,
        cihazId =
            cihazId ?? 'cihaz_${DateTime.now().microsecondsSinceEpoch}';

  final VeriKaydi _yerel;
  final BulutKaynagi _bulut;
  final Duration _gonderimGecikmesi;
  final String cihazId;

  PlanDeposu? _depo;
  KullaniciBilgisi? _aktifKullanici;
  StreamSubscription<({Map<String, String> bolumler, String? sonCihazId})>?
      _dinlemeAboneligi;
  Timer? _gonderimZamanlayici;

  final Map<String, String> _sonGonderilenBolumler = {};
  final Map<String, String> _bekleyenBolumler = {};
  bool _uzaktanYukleniyor = false;
  SenkronDurumu _durum = SenkronDurumu.esitlendi;

  SenkronDurumu get durum => _durum;
  bool get bekleyenVarMi => _bekleyenBolumler.isNotEmpty;

  void depoBagla(PlanDeposu depo) {
    _depo = depo;
  }

  static String _fotoAnahtari(String uid) => 'mytus_photos_$uid';
  static String _yedekAnahtari(String uid) => 'mytus_backup_$uid';

  @override
  Future<String?> oku() => _yerel.oku();

  @override
  Future<String?> anahtarliOku(String anahtar) => _yerel.anahtarliOku(anahtar);

  @override
  Future<void> anahtarliYaz(String anahtar, String icerik) =>
      _yerel.anahtarliYaz(anahtar, icerik);

  @override
  Future<void> anahtarliSil(String anahtar) => _yerel.anahtarliSil(anahtar);

  @override
  Future<void> yaz(String icerik) async {
    // 1. Her zaman önce yerel hafızaya yaz (Offline-First).
    await _yerel.yaz(icerik);

    final kullanici = _aktifKullanici;
    if (kullanici == null || _uzaktanYukleniyor) return;

    // 2. Fotoğrafları ayıkla ve hesaba özel yerel anahtarda koru.
    Map<String, dynamic> cozulmus;
    try {
      final ham = jsonDecode(icerik);
      if (ham is! Map<String, dynamic>) return;
      cozulmus = ham;
    } catch (_) {
      return;
    }

    final ayrilmis = BolumAyirici.ayir(cozulmus);
    await _fotograflariBirlestirVeKaydet(kullanici.uid, ayrilmis.fotograflar);

    // 3. Yalnızca değişen bölümleri bulut kuyruğuna ekle.
    for (final entry in ayrilmis.bolumler.entries) {
      if (_sonGonderilenBolumler[entry.key] != entry.value) {
        _bekleyenBolumler[entry.key] = entry.value;
      }
    }

    if (_bekleyenBolumler.isEmpty) return;

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

  Future<Map<String, String>> _fotograflariBirlestirVeKaydet(
    String uid,
    Map<String, String> yeniFotolar,
  ) async {
    final mevcut = await _mevcutFotograflariOku(uid);
    if (yeniFotolar.isNotEmpty) {
      mevcut.addAll(yeniFotolar);
      await _yerel.anahtarliYaz(_fotoAnahtari(uid), jsonEncode(mevcut));
    }
    return mevcut;
  }

  /// Kullanıcı giriş yaptığında çağrılır:
  /// - Bulutta veri varsa indirir ve yerel fotoğraflarla birleştirir (cihazda da farklı veri varsa yedeğini alır).
  /// - Bulut boşsa ve cihazda yerel veri varsa otomatik olarak buluta aktarır (İlk Giriş Göçü).
  Future<void> oturumAcildi(KullaniciBilgisi kullanici) async {
    if (_aktifKullanici?.uid == kullanici.uid && _dinlemeAboneligi != null) {
      return;
    }
    await _dinlemeAboneligi?.cancel();
    _aktifKullanici = kullanici;
    _sonGonderilenBolumler.clear();
    _bekleyenBolumler.clear();

    try {
      await _bulut.profilKaydet(
        uid: kullanici.uid,
        eposta: kullanici.eposta,
        takmaAd: kullanici.takmaAd,
      );
    } catch (_) {
      // Çevrimdışıysa profil kaydı sonraya kalabilir.
    }

    final yerelMetin = await _yerel.oku();
    final yerelDolu = _anlamliVeriVarMi(yerelMetin);

    Map<String, String> bulutBolumleri = {};
    var bulutOkundu = false;
    try {
      bulutBolumleri = await _bulut.bolumleriOku(kullanici.uid);
      bulutOkundu = true;
    } catch (_) {
      _durumGuncelle(SenkronDurumu.cevrimdisi);
    }

    final bulutDolu = bulutBolumleri.isNotEmpty &&
        bulutBolumleri.values.any((v) => v.contains('"karsilamaTamam":true'));

    if (bulutOkundu && bulutDolu) {
      // Cihazda da önceden veri varsa kaybolmaması için hesaba özel yedek anahtarına kaydet.
      if (yerelDolu && yerelMetin != null) {
        final yerelHarita = jsonDecode(yerelMetin) as Map<String, dynamic>;
        final yerelAyrilmis = BolumAyirici.ayir(yerelHarita);
        await _fotograflariBirlestirVeKaydet(
          kullanici.uid,
          yerelAyrilmis.fotograflar,
        );
        await _yerel.anahtarliYaz(_yedekAnahtari(kullanici.uid), yerelMetin);
      }

      _sonGonderilenBolumler.addAll(bulutBolumleri);
      final fotolar = await _mevcutFotograflariOku(kullanici.uid);
      final birlesikMetin = BolumAyirici.birlestir(
        bolumler: bulutBolumleri,
        fotograflar: fotolar,
      );
      await _uzaktanVeriyiUygula(birlesikMetin);
      _durumGuncelle(SenkronDurumu.esitlendi);
    } else if (yerelDolu && yerelMetin != null) {
      // İlk Giriş Göçü: Bulut boş ama cihazda yerel veri var -> Buluta aktar!
      final yerelHarita = jsonDecode(yerelMetin) as Map<String, dynamic>;
      final ayrilmis = BolumAyirici.ayir(yerelHarita);
      await _fotograflariBirlestirVeKaydet(
        kullanici.uid,
        ayrilmis.fotograflar,
      );
      _bekleyenBolumler.addAll(ayrilmis.bolumler);
      await bekleyenleriSimdiGonder();
    }

    // Başka cihazlardan gelecek değişiklikleri dinlemeye başla.
    _dinlemeAboneligi = _bulut.bolumleriDinle(kullanici.uid).listen(
      (olay) async {
        if (olay.bolumler.isEmpty) return;
        // Kendi gönderdiğimiz değişiklikse tekrar yükleme.
        if (olay.sonCihazId == cihazId) return;

        var degisiklikVar = false;
        for (final e in olay.bolumler.entries) {
          if (_sonGonderilenBolumler[e.key] != e.value) {
            degisiklikVar = true;
            _sonGonderilenBolumler[e.key] = e.value;
          }
        }
        if (!degisiklikVar) return;

        final fotolar = await _mevcutFotograflariOku(kullanici.uid);
        final birlesik = BolumAyirici.birlestir(
          bolumler: _sonGonderilenBolumler,
          fotograflar: fotolar,
        );
        await _uzaktanVeriyiUygula(birlesik);
        _durumGuncelle(SenkronDurumu.esitlendi);
      },
      onError: (_) => _durumGuncelle(SenkronDurumu.cevrimdisi),
    );
  }

  /// Bekleyen değişiklikleri hemen buluta gönderir.
  Future<void> bekleyenleriSimdiGonder() async {
    _gonderimZamanlayici?.cancel();
    final kullanici = _aktifKullanici;
    if (kullanici == null || _bekleyenBolumler.isEmpty) return;

    final gonderilecek = Map<String, String>.from(_bekleyenBolumler);
    _durumGuncelle(SenkronDurumu.gonderiliyor);
    try {
      await _bulut.bolumleriYaz(
        uid: kullanici.uid,
        degisenBolumler: gonderilecek,
        cihazId: cihazId,
      );
      for (final e in gonderilecek.entries) {
        _sonGonderilenBolumler[e.key] = e.value;
        if (_bekleyenBolumler[e.key] == e.value) {
          _bekleyenBolumler.remove(e.key);
        }
      }
      _durumGuncelle(
        _bekleyenBolumler.isEmpty
            ? SenkronDurumu.esitlendi
            : SenkronDurumu.bekleyenDegisiklikVar,
      );
    } catch (_) {
      _durumGuncelle(SenkronDurumu.cevrimdisi);
    }
  }

  /// Kullanıcı çıkış yaptığında çağrılır:
  /// - Bekleyen değişiklikleri buluta gönderir.
  /// - Fotoğrafları hesaba özel yerel anahtarda (`mytus_photos_{uid}`) korur.
  /// - Cihazdaki aktif çalışma verisini sıfırlar.
  Future<void> oturumKapatildi({bool hesabiTamamenSil = false}) async {
    _gonderimZamanlayici?.cancel();
    await _dinlemeAboneligi?.cancel();
    _dinlemeAboneligi = null;

    final kullanici = _aktifKullanici;
    if (kullanici != null) {
      if (hesabiTamamenSil) {
        try {
          await _bulut.kullaniciVerileriniSil(kullanici.uid);
        } catch (_) {}
        await _yerel.anahtarliSil(_fotoAnahtari(kullanici.uid));
        await _yerel.anahtarliSil(_yedekAnahtari(kullanici.uid));
      } else {
        await bekleyenleriSimdiGonder();
      }
    }

    _aktifKullanici = null;
    _sonGonderilenBolumler.clear();
    _bekleyenBolumler.clear();

    // Cihazdaki aktif çalışma verisini temizle (fotoğraflar hesaba özel anahtarda durur).
    _uzaktanYukleniyor = true;
    try {
      await _depo?.tumVerileriSifirla();
    } finally {
      _uzaktanYukleniyor = false;
    }
    _durumGuncelle(SenkronDurumu.esitlendi);
  }

  Future<void> _uzaktanVeriyiUygula(String birlesikJson) async {
    _uzaktanYukleniyor = true;
    try {
      await _yerel.yaz(birlesikJson);
      _depo?.yedektenYukle(birlesikJson);
    } finally {
      _uzaktanYukleniyor = false;
    }
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

  void _durumGuncelle(SenkronDurumu yeni) {
    if (_durum == yeni) return;
    _durum = yeni;
    notifyListeners();
  }

  @override
  void dispose() {
    _gonderimZamanlayici?.cancel();
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
