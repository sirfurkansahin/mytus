import 'dart:convert';

/// PlanDeposu JSON verisini Firestore'un 1 MB belge sınırına takılmaması için
/// mantıksal bölümlere (`plan`, `denemeler`, `defterler`, `kutuphane`, `ayarlar`, `odak`)
/// ayıran ve kütüphane fotoğraflarını cihazda hesaba özel tutmak üzere ayıklayan yardımcı.
class BolumAyirici {
  const BolumAyirici._();

  static const List<String> bolumAdlari = [
    'ayarlar',
    'plan',
    'odak',
    'denemeler',
    'defterler',
    'kutuphane',
  ];

  static const Map<String, List<String>> _bolumAlanlari = {
    'ayarlar': [
      'surum',
      'sonId',
      'karsilamaTamam',
      'sinavTarihi',
      'temaSecimi',
      'mufredatTuru',
      'turSayisi',
      'gunlukTekrarSiniri',
      'gunlukYeniKonuSiniri',
      'zorGun',
      'ftAyar',
      'kurtarmaModuAktif',
      'hedefYatisSaati',
      'hedefKalkisSaati',
    ],
    'plan': [
      'dersler',
      'konular',
      'calismalar',
      'gunlukSorular',
    ],
    'odak': [
      'odaklar',
      'oturum',
      'uykular',
    ],
    'denemeler': [
      'denemeler',
    ],
    'defterler': [
      'hataDefteri',
      'ozelSkorlar',
      'zincirler',
      'vakaKartlari',
    ],
    'kutuphane': [
      'kitaplar',
    ],
  };

  /// Tam JSON nesnesinden fotoğrafları çıkarır ve bölümlere ayrılmış JSON metinlerini döner.
  static ({
    Map<String, String> bolumler,
    Map<String, String> fotograflar,
  }) ayir(Map<String, dynamic> tamVeri) {
    final fotograflar = <String, String>{};
    final kopya = Map<String, dynamic>.from(tamVeri);

    // Kütüphanedeki fotoğrafları ayıkla (buluta gitmez, cihazda hesaba özel kalır).
    final hamKitaplar = kopya['kitaplar'];
    if (hamKitaplar is List) {
      final temizKitaplar = <Map<String, dynamic>>[];
      for (final k in hamKitaplar) {
        if (k is! Map) continue;
        final kitapMap = Map<String, dynamic>.from(k);
        final hamBolumler = kitapMap['bolumler'];
        if (hamBolumler is List) {
          final temizBolumler = <Map<String, dynamic>>[];
          for (final b in hamBolumler) {
            if (b is! Map) continue;
            final bolumMap = Map<String, dynamic>.from(b);
            final hamNotlar = bolumMap['notlar'];
            if (hamNotlar is List) {
              final temizNotlar = <Map<String, dynamic>>[];
              for (final n in hamNotlar) {
                if (n is! Map) continue;
                final notMap = Map<String, dynamic>.from(n);
                final notId = notMap['id'] as String?;
                final resim = notMap['resimBase64'] as String?;
                if (notId != null &&
                    notId.isNotEmpty &&
                    resim != null &&
                    resim.isNotEmpty) {
                  fotograflar[notId] = resim;
                  notMap.remove('resimBase64');
                }
                temizNotlar.add(notMap);
              }
              bolumMap['notlar'] = temizNotlar;
            }
            temizBolumler.add(bolumMap);
          }
          kitapMap['bolumler'] = temizBolumler;
        }
        temizKitaplar.add(kitapMap);
      }
      kopya['kitaplar'] = temizKitaplar;
    }

    final bolumler = <String, String>{};
    for (final entry in _bolumAlanlari.entries) {
      final parca = <String, dynamic>{};
      for (final alan in entry.value) {
        if (kopya.containsKey(alan)) {
          parca[alan] = kopya[alan];
        }
      }
      bolumler[entry.key] = jsonEncode(parca);
    }

    return (bolumler: bolumler, fotograflar: fotograflar);
  }

  /// Buluttan gelen bölümleri ve cihazdaki fotoğrafları tek bir PlanDeposu JSON metninde birleştirir.
  static String birlestir({
    required Map<String, String> bolumler,
    Map<String, String> fotograflar = const {},
  }) {
    final birlesik = <String, dynamic>{};
    for (final bolumJson in bolumler.values) {
      if (bolumJson.isEmpty) continue;
      try {
        final cozulmus = jsonDecode(bolumJson);
        if (cozulmus is Map<String, dynamic>) {
          birlesik.addAll(cozulmus);
        }
      } catch (_) {}
    }

    // Cihazdaki fotoğrafları ilgili notlara geri yerleştir.
    if (fotograflar.isNotEmpty && birlesik['kitaplar'] is List) {
      final hamKitaplar = birlesik['kitaplar'] as List;
      final guncelKitaplar = <Map<String, dynamic>>[];
      for (final k in hamKitaplar) {
        if (k is! Map) continue;
        final kitapMap = Map<String, dynamic>.from(k);
        final hamBolumler = kitapMap['bolumler'];
        if (hamBolumler is List) {
          final guncelBolumler = <Map<String, dynamic>>[];
          for (final b in hamBolumler) {
            if (b is! Map) continue;
            final bolumMap = Map<String, dynamic>.from(b);
            final hamNotlar = bolumMap['notlar'];
            if (hamNotlar is List) {
              final guncelNotlar = <Map<String, dynamic>>[];
              for (final n in hamNotlar) {
                if (n is! Map) continue;
                final notMap = Map<String, dynamic>.from(n);
                final notId = notMap['id'] as String?;
                if (notId != null && fotograflar.containsKey(notId)) {
                  notMap['resimBase64'] = fotograflar[notId];
                }
                guncelNotlar.add(notMap);
              }
              bolumMap['notlar'] = guncelNotlar;
            }
            guncelBolumler.add(bolumMap);
          }
          kitapMap['bolumler'] = guncelBolumler;
        }
        guncelKitaplar.add(kitapMap);
      }
      birlesik['kitaplar'] = guncelKitaplar;
    }

    return jsonEncode(birlesik);
  }
}
