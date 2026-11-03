import 'package:flutter/material.dart';

/// Rapordaki A–F Hata Sınıfları (Rapor Bölüm 3.3).
enum HataSinifi {
  /// A · Bilgi kusuru (Bilmiyordum).
  a('A', 'Bilgi Kusuru', 'Bilmiyordum (kaynaktan eksik halka okunur)', Colors.blue),

  /// B · Yanlış biliyordum (Emin + Yanlış).
  /// Güven matrisinin en tehlikeli hücresidir; hiperdüzeltme etkisiyle aynı gün kapatılır.
  b('B', 'Yanlış İnanç', 'Emin işaretlenip yanlış çıkan (aynı gün düzeltilmeli)', Colors.red),

  /// C · Okuma / kurgu hatası.
  /// Negatif kök, sıfat, "hangileri" kaçırma. İki gün >%15 ise yük %70 kuralı devreye girer.
  c('C', 'Okuma / Kurgu', 'Kök, sıfat veya soru formatı kaçırıldı', Colors.orange),

  /// D · Mantık / halka hatası.
  /// Doğru bilgi, yanlış zincir halkası / çeldiriciye kapılma (iki şık arasında kalma).
  d('D', 'Mantık / Halka', 'İki şık arasında kalıp yanlış halkayı seçme', Colors.purple),

  /// E · Süre / yorgunluk hatası.
  /// Son 30 soruda tempo ve odak kaybından kaynaklanan hatalar.
  e('E', 'Süre / Yorgunluk', 'Zaman baskısı veya bilişsel yorgunluk', Colors.amber),

  /// F · Form / dikkat hatası.
  /// Optik forma kodlama veya işaretleme kayması.
  f('F', 'Form / Dikkat', 'Optik form kayması veya dikkatsizlik', Colors.brown);

  const HataSinifi(this.kod, this.ad, this.aciklama, this.renk);

  final String kod;
  final String ad;
  final String aciklama;
  final Color renk;
}

/// Soru çözümünde güven seviyesi (Rapor Bölüm 3.3 Güven Matrisi).
enum GuvenSeviyesi {
  emin('Emin', 'Tamamen emin olarak işaretledim', 1.0),
  kararsiz('Kararsız', 'İki şık arasında kalarak işaretledim', 0.5),
  tahmin('Tahmin', 'Bilmeden tahminle işaretledim', 0.2);

  const GuvenSeviyesi(this.ad, this.aciklama, this.katsayi);

  final String ad;
  final String aciklama;
  final double katsayi;
}

/// Tek bir deneme sorusunun hata ve güven analizi kaydı.
class DenemeSorusu {
  const DenemeSorusu({
    required this.id,
    required this.soruNo,
    required this.oturumTemelMi,
    this.dersAdi = '',
    this.guven = GuvenSeviyesi.kararsiz,
    this.dogruMu = false,
    this.hataSinifi,
    this.celdirici = '',
    this.ayiranKriter = '',
    this.kural = '',
  });

  final String id;
  final int soruNo;
  final bool oturumTemelMi; // true: Temel (TTBT), false: Klinik (KTBT)
  final String dersAdi;
  final GuvenSeviyesi guven;
  final bool dogruMu;
  final HataSinifi? hataSinifi;
  final String celdirici;
  final String ayiranKriter;
  final String kural;

  /// Güven matrisindeki en tehlikeli "Emin + Yanlış" hücresi mi?
  bool get hiperDuzeltmeGerektirir => !dogruMu && guven == GuvenSeviyesi.emin;

  Map<String, dynamic> toJson() => {
        'id': id,
        'soruNo': soruNo,
        'oturumTemelMi': oturumTemelMi,
        'dersAdi': dersAdi,
        'guven': guven.name,
        'dogruMu': dogruMu,
        'hataSinifi': hataSinifi?.name,
        'celdirici': celdirici,
        'ayiranKriter': ayiranKriter,
        'kural': kural,
      };

  factory DenemeSorusu.fromJson(Map<String, dynamic> json) {
    return DenemeSorusu(
      id: json['id'] as String? ?? UniqueKey().toString(),
      soruNo: json['soruNo'] as int? ?? 1,
      oturumTemelMi: json['oturumTemelMi'] as bool? ?? true,
      dersAdi: json['dersAdi'] as String? ?? '',
      guven: GuvenSeviyesi.values.asNameMap()[json['guven']] ??
          GuvenSeviyesi.kararsiz,
      dogruMu: json['dogruMu'] as bool? ?? false,
      hataSinifi: HataSinifi.values.asNameMap()[json['hataSinifi']],
      celdirici: json['celdirici'] as String? ?? '',
      ayiranKriter: json['ayiranKriter'] as String? ?? '',
      kural: json['kural'] as String? ?? '',
    );
  }
}

/// 100 soruluk tek bir TUS oturumu (Temel veya Klinik).
class DenemeOturumu {
  const DenemeOturumu({
    this.dogru = 0,
    this.yanlis = 0,
    this.bos = 0,
  });

  final int dogru;
  final int yanlis;
  final int bos;

  /// Toplam soru sayısı (azami 100).
  int get toplamSoru => dogru + yanlis + bos;

  /// ÖSYM net hesabı: Doğru - (Yanlış / 4).
  double get net {
    final deger = dogru - (yanlis / 4.0);
    return deger < 0 ? 0.0 : deger;
  }

  Map<String, dynamic> toJson() => {
        'dogru': dogru,
        'yanlis': yanlis,
        'bos': bos,
      };

  factory DenemeOturumu.fromJson(Map<String, dynamic> json) {
    return DenemeOturumu(
      dogru: json['dogru'] as int? ?? 0,
      yanlis: json['yanlis'] as int? ?? 0,
      bos: json['bos'] as int? ?? 0,
    );
  }
}

/// 200 soruluk TUS deneme sınavı kaydı ve bilişsel metrikleri.
class DenemeSinavi {
  const DenemeSinavi({
    required this.id,
    required this.ad,
    required this.tarih,
    this.temel = const DenemeOturumu(),
    this.klinik = const DenemeOturumu(),
    this.soruHatalari = const [],
    this.kaygiPuani,
    this.notlar = '',
  });

  final String id;
  final String ad;
  final DateTime tarih;
  final DenemeOturumu temel;
  final DenemeOturumu klinik;
  final List<DenemeSorusu> soruHatalari;
  final int? kaygiPuani; // 0-10 sınav öncesi kaygı skalası (Rapor Bölüm 5.2)
  final String notlar;

  /// 200 soru üzerinden toplam net.
  double get toplamNet => temel.net + klinik.net;

  /// K Puanı (Klinik Ağırlıklı): 0.4 * TemelNet + 0.6 * KlinikNet (Rapor Bölüm 2.1).
  double get klinikAgirlikliPuan {
    return (0.4 * temel.net) + (0.6 * klinik.net);
  }

  /// T Puanı (Temel Ağırlıklı): 0.6 * TemelNet + 0.4 * KlinikNet.
  double get temelAgirlikliPuan {
    return (0.6 * temel.net) + (0.4 * klinik.net);
  }

  /// ÖSYM 85 EBAP (En Büyük Ağırlıklı Puan) tavan ölçekleme modeli (Rapor Bölüm 2.1).
  /// Sınav Puanı = 55 + 30 * [7(AP - X) - S] / [7(EBAP - X) - S]
  /// Referans: X (Ortalama) ≈ 38.5, S (Standart Sapma) ≈ 17.0, EBAP = 85.0.
  double get tahminiEbapPuani {
    const double xOrtalama = 38.5;
    const double sSapma = 17.0;
    const double ebap = 85.0;

    final ap = klinikAgirlikliPuan;
    final pay = (7 * (ap - xOrtalama)) - sSapma;
    final payda = (7 * (ebap - xOrtalama)) - sSapma;

    if (payda == 0) return 45.0;
    final ham = 55.0 + 30.0 * (pay / payda);

    if (ham < 45.0) return 45.0;
    if (ham > 85.0) return 85.0;
    return double.parse(ham.toStringAsFixed(2));
  }

  /// A–F sınıflarına göre hata adetleri dağılımı.
  Map<HataSinifi, int> get hataDagilimi {
    final harita = <HataSinifi, int>{for (final s in HataSinifi.values) s: 0};
    for (final s in soruHatalari) {
      if (s.hataSinifi != null) {
        harita[s.hataSinifi!] = (harita[s.hataSinifi!] ?? 0) + 1;
      }
    }
    return harita;
  }

  /// Kalibrasyon Farkı: Ortalama Güven - Doğruluk (Rapor Bölüm 4.2).
  /// Hedef: mutlak değer <= %5. +%8 üzerinde aşırı güven alarmı tetiklenir.
  double get kalibrasyonFarki {
    if (soruHatalari.isEmpty) return 0.0;
    double toplamGuven = 0.0;
    int toplamDogru = 0;
    for (final s in soruHatalari) {
      toplamGuven += s.guven.katsayi;
      if (s.dogruMu) toplamDogru++;
    }
    final ortalamaGuven = toplamGuven / soruHatalari.length;
    final dogrulukOrani = toplamDogru / soruHatalari.length;
    return double.parse(((ortalamaGuven - dogrulukOrani) * 100).toStringAsFixed(1));
  }

  /// "Emin" işaretlenen sorularda doğruluk oranı (Rapor Hedefi >= %90).
  double get eminDogrulukOrani {
    final eminler = soruHatalari.where((s) => s.guven == GuvenSeviyesi.emin).toList();
    if (eminler.isEmpty) return 100.0;
    final dogrular = eminler.where((s) => s.dogruMu).length;
    return (dogrular / eminler.length) * 100.0;
  }

  /// "Emin + Yanlış" (B sınıfı) acil düzeltme bekleyen soru sayısı.
  int get hiperDuzeltmeSayisi {
    return soruHatalari.where((s) => s.hiperDuzeltmeGerektirir).length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ad': ad,
        'tarih': tarih.toIso8601String(),
        'temel': temel.toJson(),
        'klinik': klinik.toJson(),
        'soruHatalari': soruHatalari.map((s) => s.toJson()).toList(),
        'kaygiPuani': kaygiPuani,
        'notlar': notlar,
      };

  factory DenemeSinavi.fromJson(Map<String, dynamic> json) {
    return DenemeSinavi(
      id: json['id'] as String? ?? UniqueKey().toString(),
      ad: json['ad'] as String? ?? 'Deneme',
      tarih: DateTime.tryParse(json['tarih'] as String? ?? '') ?? DateTime.now(),
      temel: json['temel'] != null
          ? DenemeOturumu.fromJson(json['temel'] as Map<String, dynamic>)
          : const DenemeOturumu(),
      klinik: json['klinik'] != null
          ? DenemeOturumu.fromJson(json['klinik'] as Map<String, dynamic>)
          : const DenemeOturumu(),
      soruHatalari: (json['soruHatalari'] as List<dynamic>?)
              ?.map((e) => DenemeSorusu.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      kaygiPuani: json['kaygiPuani'] as int?,
      notlar: json['notlar'] as String? ?? '',
    );
  }
}
