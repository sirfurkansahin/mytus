import 'package:app/features/denemeler/modeller.dart';
import 'package:flutter/material.dart';

/// Hata Defteri & Çeldirici Bankası maddesi (Rapor Bölüm 2.2 ve 3.3).
class HataKaydi {
  const HataKaydi({
    required this.id,
    required this.baslik,
    this.dersAdi = '',
    this.konuAdi = '',
    this.hataSinifi = HataSinifi.b,
    this.guven = GuvenSeviyesi.kararsiz,
    this.celdirici = '',
    this.ayiranKriter = '',
    this.kural = '',
    required this.tarih,
    this.pekiştirildi = false,
    this.denemeId,
    this.soruNo,
  });

  final String id;
  final String baslik; // Soru özeti veya kavram adı
  final String dersAdi;
  final String konuAdi;
  final HataSinifi hataSinifi;
  final GuvenSeviyesi guven;
  final String celdirici; // Karışan çeldirici şık / hastalık / ilaç
  final String ayiranKriter; // İki şıkkı ayıran tek kriter
  final String kural; // Bir daha yapmamak için kural
  final DateTime tarih;
  final bool pekiştirildi; // Tekrar edilip düzeltildi mi?
  final String? denemeId;
  final int? soruNo;

  bool get hiperDuzeltmeGerektirir =>
      !pekiştirildi && guven == GuvenSeviyesi.emin && hataSinifi == HataSinifi.b;

  HataKaydi copyWith({
    String? baslik,
    String? dersAdi,
    String? konuAdi,
    HataSinifi? hataSinifi,
    GuvenSeviyesi? guven,
    String? celdirici,
    String? ayiranKriter,
    String? kural,
    bool? pekiştirildi,
  }) {
    return HataKaydi(
      id: id,
      baslik: baslik ?? this.baslik,
      dersAdi: dersAdi ?? this.dersAdi,
      konuAdi: konuAdi ?? this.konuAdi,
      hataSinifi: hataSinifi ?? this.hataSinifi,
      guven: guven ?? this.guven,
      celdirici: celdirici ?? this.celdirici,
      ayiranKriter: ayiranKriter ?? this.ayiranKriter,
      kural: kural ?? this.kural,
      tarih: tarih,
      pekiştirildi: pekiştirildi ?? this.pekiştirildi,
      denemeId: denemeId,
      soruNo: soruNo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'baslik': baslik,
        'dersAdi': dersAdi,
        'konuAdi': konuAdi,
        'hataSinifi': hataSinifi.name,
        'guven': guven.name,
        'celdirici': celdirici,
        'ayiranKriter': ayiranKriter,
        'kural': kural,
        'tarih': tarih.toIso8601String(),
        'pekiştirildi': pekiştirildi,
        'denemeId': denemeId,
        'soruNo': soruNo,
      };

  factory HataKaydi.fromJson(Map<String, dynamic> json) {
    return HataKaydi(
      id: json['id'] as String? ?? UniqueKey().toString(),
      baslik: json['baslik'] as String? ?? 'Hata',
      dersAdi: json['dersAdi'] as String? ?? '',
      konuAdi: json['konuAdi'] as String? ?? '',
      hataSinifi: HataSinifi.values.asNameMap()[json['hataSinifi']] ?? HataSinifi.b,
      guven: GuvenSeviyesi.values.asNameMap()[json['guven']] ?? GuvenSeviyesi.kararsiz,
      celdirici: json['celdirici'] as String? ?? '',
      ayiranKriter: json['ayiranKriter'] as String? ?? '',
      kural: json['kural'] as String? ?? '',
      tarih: DateTime.tryParse(json['tarih'] as String? ?? '') ?? DateTime.now(),
      pekiştirildi: json['pekiştirildi'] as bool? ?? false,
      denemeId: json['denemeId'] as String?,
      soruNo: json['soruNo'] as int?,
    );
  }
}

/// Sınıflama & Skor Defteri maddesi (Rapor Bölüm 2.2 Tuzak Sınıfı 8).
class SkorKarti {
  const SkorKarti({
    required this.id,
    required this.ad,
    required this.brans,
    required this.parametreler,
    required this.klinikKarar,
    this.osymTuzagi = '',
    this.ozelMi = false,
  });

  final String id;
  final String ad; // Örn: Modifiye Hinchey, Hodgkin IPS
  final String brans; // Örn: Genel Cerrahi, Dahiliye, Pediatri
  final List<String> parametreler; // Puanlama veya evre kriterleri
  final String klinikKarar; // Puanın getirdiği tanı veya tedavi kararı
  final String osymTuzagi; // ÖSYM'nin soru kökünde yaptığı tuzak
  final bool ozelMi; // Kullanıcının kendisi mi ekledi?

  Map<String, dynamic> toJson() => {
        'id': id,
        'ad': ad,
        'brans': brans,
        'parametreler': parametreler,
        'klinikKarar': klinikKarar,
        'osymTuzagi': osymTuzagi,
        'ozelMi': ozelMi,
      };

  factory SkorKarti.fromJson(Map<String, dynamic> json) {
    return SkorKarti(
      id: json['id'] as String? ?? UniqueKey().toString(),
      ad: json['ad'] as String? ?? '',
      brans: json['brans'] as String? ?? '',
      parametreler: (json['parametreler'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      klinikKarar: json['klinikKarar'] as String? ?? '',
      osymTuzagi: json['osymTuzagi'] as String? ?? '',
      ozelMi: json['ozelMi'] as bool? ?? true,
    );
  }
}

/// Branşlara göre Mekanizma Zinciri Türleri (Rapor Bölüm 4.1).
enum ZincirTuru {
  dahiliye('Dahiliye / Pediatri / Patoloji', [
    '1. Etiyoloji',
    '2. Mekanizma',
    '3. Klinik / Triad',
    '4. Tanı / Ayırıcı',
    '5. Tedavi / İlk Tercih',
  ]),
  farmakoloji('Farmakoloji', [
    '1. İlaç Hedefi / Reseptör',
    '2. Etki Mekanizması',
    '3. Farmakokinetik',
    '4. Endikasyon / Yan Etki',
    '5. Etkileşim & Yeni Üyeler',
  ]),
  biyokimya('Biyokimya', [
    '1. Enzim / Kofaktör',
    '2. Metabolik Yolak',
    '3. Eksiklik / Bozukluk',
    '4. Klinik Tablo',
    '5. Laboratuvar Bulguları',
  ]),
  mikrobiyoloji('Mikrobiyoloji', [
    '1. Etken & Özellikleri',
    '2. Virülans Faktörleri',
    '3. Klinik Tablo',
    '4. Tanı & Besiyeri',
    '5. Tedavi & Direnç',
  ]),
  fizyoloji('Fizyoloji', [
    '1. Uyaran',
    '2. İkincil Haberci / Sinyal',
    '3. Yanıt / Hormon',
    '4. Yön (Artar / Azalır)',
    '5. Bozulma & Geri Bildirim',
  ]),
  anatomi('Anatomi', [
    '1. Anatomik Yapı',
    '2. Komşuluklar',
    '3. Hasar / Yaralanma',
    '4. Fonksiyon Kaybı',
    '5. Cerrahi Landmark',
  ]);

  const ZincirTuru(this.ad, this.halkaAdlari);

  final String ad;
  final List<String> halkaAdlari;
}

/// 5 Halkalı Mekanizma Zinciri (Illness Script) maddesi (Rapor Bölüm 4.1).
class MekanizmaZinciri {
  const MekanizmaZinciri({
    required this.id,
    required this.baslik,
    required this.tur,
    required this.halkalar,
    this.ayiranOzellik = '',
    this.nedenCevabi = '',
  });

  final String id;
  final String baslik; // Hastalık, ilaç veya kavram
  final ZincirTuru tur;
  final List<String> halkalar; // 5 halkanın içerikleri
  final String ayiranOzellik; // Komşusundan ayıran tek özellik
  final String nedenCevabi; // Mekanizmanın "Neden?" açıklaması

  Map<String, dynamic> toJson() => {
        'id': id,
        'baslik': baslik,
        'tur': tur.name,
        'halkalar': halkalar,
        'ayiranOzellik': ayiranOzellik,
        'nedenCevabi': nedenCevabi,
      };

  factory MekanizmaZinciri.fromJson(Map<String, dynamic> json) {
    return MekanizmaZinciri(
      id: json['id'] as String? ?? UniqueKey().toString(),
      baslik: json['baslik'] as String? ?? '',
      tur: ZincirTuru.values.asNameMap()[json['tur']] ?? ZincirTuru.dahiliye,
      halkalar: (json['halkalar'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['', '', '', '', ''],
      ayiranOzellik: json['ayiranOzellik'] as String? ?? '',
      nedenCevabi: json['nedenCevabi'] as String? ?? '',
    );
  }
}

/// 3 Dakikalık Vaka Kartı (Rapor Bölüm 5.5 İntörn / Klinisyen Modu).
class VakaKarti {
  const VakaKarti({
    required this.id,
    required this.tarih,
    required this.hastaOzeti,
    required this.belirleyiciHalka,
    required this.olasiSoruKoku,
    required this.celdirici,
    required this.ayiranKriter,
    this.dersAdi = '',
  });

  final String id;
  final DateTime tarih;
  final String hastaOzeti; // Bugünkü hasta, tek cümle
  final String belirleyiciHalka; // Hangi halka belirleyiciydi?
  final String olasiSoruKoku; // En olası, ilk, en sık, değildir
  final String celdirici; // Neyle karışırdı?
  final String ayiranKriter; // Ayıran tek kriter
  final String dersAdi; // İlgili ders

  Map<String, dynamic> toJson() => {
        'id': id,
        'tarih': tarih.toIso8601String(),
        'hastaOzeti': hastaOzeti,
        'belirleyiciHalka': belirleyiciHalka,
        'olasiSoruKoku': olasiSoruKoku,
        'celdirici': celdirici,
        'ayiranKriter': ayiranKriter,
        'dersAdi': dersAdi,
      };

  factory VakaKarti.fromJson(Map<String, dynamic> json) {
    return VakaKarti(
      id: json['id'] as String? ?? UniqueKey().toString(),
      tarih: DateTime.tryParse(json['tarih'] as String? ?? '') ?? DateTime.now(),
      hastaOzeti: json['hastaOzeti'] as String? ?? '',
      belirleyiciHalka: json['belirleyiciHalka'] as String? ?? '',
      olasiSoruKoku: json['olasiSoruKoku'] as String? ?? '',
      celdirici: json['celdirici'] as String? ?? '',
      ayiranKriter: json['ayiranKriter'] as String? ?? '',
      dersAdi: json['dersAdi'] as String? ?? '',
    );
  }
}
