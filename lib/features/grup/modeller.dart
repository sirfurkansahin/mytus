import 'dart:math';

/// Davet kodlarında kafa karıştırabilecek 0, O, 1, I karakterleri çıkarılmış alfabe.
const String _kodKarakterleri = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/// 6 karakterlik benzersiz grup davet kodu üretir (Örn: TUS84X).
String davetKoduUret({int uzunluk = 6, Random? rastgele}) {
  final rng = rastgele ?? Random();
  return List.generate(
    uzunluk,
    (_) => _kodKarakterleri[rng.nextInt(_kodKarakterleri.length)],
  ).join();
}

/// Çalışma grubu modeli (2-10 kişilik arkadaş grubu).
class Grup {
  const Grup({
    required this.id,
    required this.ad,
    required this.davetKodu,
    required this.olusturanUid,
    required this.olusturmaTarihi,
    this.hedefKonu = 40,
    this.hedefSoru = 1000,
  });

  final String id;
  final String ad;
  final String davetKodu;
  final String olusturanUid;
  final DateTime olusturmaTarihi;
  final int hedefKonu;
  final int hedefSoru;

  Grup kopya({
    String? id,
    String? ad,
    String? davetKodu,
    String? olusturanUid,
    DateTime? olusturmaTarihi,
    int? hedefKonu,
    int? hedefSoru,
  }) {
    return Grup(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      davetKodu: davetKodu ?? this.davetKodu,
      olusturanUid: olusturanUid ?? this.olusturanUid,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
      hedefKonu: hedefKonu ?? this.hedefKonu,
      hedefSoru: hedefSoru ?? this.hedefSoru,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ad': ad,
        'davetKodu': davetKodu,
        'olusturanUid': olusturanUid,
        'olusturmaTarihi': olusturmaTarihi.toIso8601String(),
        'hedefKonu': hedefKonu,
        'hedefSoru': hedefSoru,
      };

  factory Grup.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Grup(
      id: docId ?? json['id'] as String? ?? '',
      ad: json['ad'] as String? ?? 'Çalışma Grubu',
      davetKodu: (json['davetKodu'] as String? ?? '').toUpperCase().trim(),
      olusturanUid: json['olusturanUid'] as String? ?? '',
      olusturmaTarihi: json['olusturmaTarihi'] != null
          ? DateTime.tryParse(json['olusturmaTarihi'] as String) ?? DateTime.now()
          : DateTime.now(),
      hedefKonu: json['hedefKonu'] as int? ?? 40,
      hedefSoru: json['hedefSoru'] as int? ?? 1000,
    );
  }
}

/// Gruptaki her üyenin haftalık çalışma ve puan bilgisi.
class GrupUyesi {
  const GrupUyesi({
    required this.uid,
    required this.takmaAd,
    required this.haftaBaslangici,
    this.konuSayisi = 0,
    this.soruSayisi = 0,
    this.sonDers,
    required this.guncellemeTarihi,
  });

  final String uid;
  final String takmaAd;
  final String haftaBaslangici; // YYYY-MM-DD
  final int konuSayisi;
  final int soruSayisi;
  final String? sonDers;
  final DateTime guncellemeTarihi;

  /// Puan Kuralı (Seçenek C: Konu ve Soru Modeli):
  /// 1 Konu = 10 Puan, 1 Soru = 1 Puan
  int get puan => (konuSayisi * 10) + soruSayisi;

  GrupUyesi kopya({
    String? uid,
    String? takmaAd,
    String? haftaBaslangici,
    int? konuSayisi,
    int? soruSayisi,
    String? sonDers,
    DateTime? guncellemeTarihi,
  }) {
    return GrupUyesi(
      uid: uid ?? this.uid,
      takmaAd: takmaAd ?? this.takmaAd,
      haftaBaslangici: haftaBaslangici ?? this.haftaBaslangici,
      konuSayisi: konuSayisi ?? this.konuSayisi,
      soruSayisi: soruSayisi ?? this.soruSayisi,
      sonDers: sonDers ?? this.sonDers,
      guncellemeTarihi: guncellemeTarihi ?? this.guncellemeTarihi,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'takmaAd': takmaAd,
        'haftaBaslangici': haftaBaslangici,
        'konuSayisi': konuSayisi,
        'soruSayisi': soruSayisi,
        'puan': puan,
        if (sonDers != null) 'sonDers': sonDers,
        'guncellemeTarihi': guncellemeTarihi.toIso8601String(),
      };

  factory GrupUyesi.fromJson(Map<String, dynamic> json, {String? docId}) {
    return GrupUyesi(
      uid: docId ?? json['uid'] as String? ?? '',
      takmaAd: json['takmaAd'] as String? ?? 'Meslektaşımız',
      haftaBaslangici: json['haftaBaslangici'] as String? ?? '',
      konuSayisi: json['konuSayisi'] as int? ?? 0,
      soruSayisi: json['soruSayisi'] as int? ?? 0,
      sonDers: json['sonDers'] as String?,
      guncellemeTarihi: json['guncellemeTarihi'] != null
          ? DateTime.tryParse(json['guncellemeTarihi'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Ortak hedef modu hesaplayıcısı (Örn: Haftalık 50 konu & 1.000 soru hedefi).
class GrupHedefDurumu {
  const GrupHedefDurumu({
    required this.toplamKonu,
    required this.toplamSoru,
    required this.hedefKonu,
    required this.hedefSoru,
  });

  final int toplamKonu;
  final int toplamSoru;
  final int hedefKonu;
  final int hedefSoru;

  double get konuOrani =>
      hedefKonu <= 0 ? 1.0 : (toplamKonu / hedefKonu).clamp(0.0, 1.0);

  double get soruOrani =>
      hedefSoru <= 0 ? 1.0 : (toplamSoru / hedefSoru).clamp(0.0, 1.0);

  double get genelOran => ((konuOrani + soruOrani) / 2).clamp(0.0, 1.0);
  int get genelYuzde => (genelOran * 100).round();

  factory GrupHedefDurumu.hesapla({
    required List<GrupUyesi> uyeler,
    required Grup grup,
  }) {
    final toplamKonu = uyeler.fold<int>(0, (toplam, u) => toplam + u.konuSayisi);
    final toplamSoru = uyeler.fold<int>(0, (toplam, u) => toplam + u.soruSayisi);
    return GrupHedefDurumu(
      toplamKonu: toplamKonu,
      toplamSoru: toplamSoru,
      hedefKonu: grup.hedefKonu,
      hedefSoru: grup.hedefSoru,
    );
  }
}
