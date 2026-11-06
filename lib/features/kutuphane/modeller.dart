/// Kütüphane modülü veri modelleri (Sürüm 1).
/// Kitap ve içindekiler/bölüm yapısı, ilerleme hesabı ve toplu ayrıştırma.
library;

class KitapBolumu {
  const KitapBolumu({
    required this.id,
    required this.ad,
    this.baslangicSayfa,
    this.bitisSayfa,
    this.tamamlandi = false,
    this.tamamlanmaTarihi,
  });

  final String id;
  final String ad;
  final int? baslangicSayfa;
  final int? bitisSayfa;
  final bool tamamlandi;
  final DateTime? tamamlanmaTarihi;

  int? get sayfaSayisi {
    if (baslangicSayfa == null || bitisSayfa == null) return null;
    final fark = bitisSayfa! - baslangicSayfa! + 1;
    return fark > 0 ? fark : null;
  }

  String get sayfaAraligiMetni {
    if (baslangicSayfa == null && bitisSayfa == null) return '';
    if (baslangicSayfa != null && bitisSayfa != null) {
      return 's. $baslangicSayfa–$bitisSayfa';
    }
    return 's. ${baslangicSayfa ?? bitisSayfa}';
  }

  KitapBolumu kopya({
    String? id,
    String? ad,
    int? baslangicSayfa,
    int? bitisSayfa,
    bool? tamamlandi,
    DateTime? tamamlanmaTarihi,
  }) {
    return KitapBolumu(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      baslangicSayfa: baslangicSayfa ?? this.baslangicSayfa,
      bitisSayfa: bitisSayfa ?? this.bitisSayfa,
      tamamlandi: tamamlandi ?? this.tamamlandi,
      tamamlanmaTarihi: tamamlanmaTarihi ?? this.tamamlanmaTarihi,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ad': ad,
        if (baslangicSayfa != null) 'baslangicSayfa': baslangicSayfa,
        if (bitisSayfa != null) 'bitisSayfa': bitisSayfa,
        'tamamlandi': tamamlandi,
        if (tamamlanmaTarihi != null)
          'tamamlanmaTarihi': tamamlanmaTarihi!.toIso8601String(),
      };

  factory KitapBolumu.fromJson(Map<String, dynamic> json) {
    return KitapBolumu(
      id: json['id'] as String? ?? '',
      ad: json['ad'] as String? ?? '',
      baslangicSayfa: json['baslangicSayfa'] as int?,
      bitisSayfa: json['bitisSayfa'] as int?,
      tamamlandi: json['tamamlandi'] as bool? ?? false,
      tamamlanmaTarihi: json['tamamlanmaTarihi'] != null
          ? DateTime.tryParse(json['tamamlanmaTarihi'] as String)
          : null,
    );
  }
}

class Kitap {
  const Kitap({
    required this.id,
    required this.ad,
    this.dersId,
    this.dersAdi,
    this.toplamSayfa,
    required this.eklenmeTarihi,
    this.bolumler = const [],
  });

  final String id;
  final String ad;
  final int? dersId;
  final String? dersAdi;
  final int? toplamSayfa;
  final DateTime eklenmeTarihi;
  final List<KitapBolumu> bolumler;

  int get toplamBolumSayisi => bolumler.length;

  int get tamamlananBolumSayisi =>
      bolumler.where((b) => b.tamamlandi).length;

  int get kalanBolumSayisi => toplamBolumSayisi - tamamlananBolumSayisi;

  double get ilerlemeOrani {
    if (bolumler.isEmpty) return 0.0;
    return tamamlananBolumSayisi / bolumler.length;
  }

  int get yuzde => (ilerlemeOrani * 100).round();

  bool get tamamlandi =>
      bolumler.isNotEmpty && tamamlananBolumSayisi == bolumler.length;

  KitapBolumu? get siradakiBolum {
    for (final b in bolumler) {
      if (!b.tamamlandi) return b;
    }
    return null;
  }

  Kitap kopya({
    String? id,
    String? ad,
    int? dersId,
    String? dersAdi,
    int? toplamSayfa,
    DateTime? eklenmeTarihi,
    List<KitapBolumu>? bolumler,
  }) {
    return Kitap(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      dersId: dersId ?? this.dersId,
      dersAdi: dersAdi ?? this.dersAdi,
      toplamSayfa: toplamSayfa ?? this.toplamSayfa,
      eklenmeTarihi: eklenmeTarihi ?? this.eklenmeTarihi,
      bolumler: bolumler ?? this.bolumler,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ad': ad,
        if (dersId != null) 'dersId': dersId,
        if (dersAdi != null) 'dersAdi': dersAdi,
        if (toplamSayfa != null) 'toplamSayfa': toplamSayfa,
        'eklenmeTarihi': eklenmeTarihi.toIso8601String(),
        'bolumler': [for (final b in bolumler) b.toJson()],
      };

  factory Kitap.fromJson(Map<String, dynamic> json) {
    final rawBolumler = json['bolumler'] as List<dynamic>? ?? [];
    return Kitap(
      id: json['id'] as String? ?? '',
      ad: json['ad'] as String? ?? '',
      dersId: json['dersId'] as int?,
      dersAdi: json['dersAdi'] as String?,
      toplamSayfa: json['toplamSayfa'] as int?,
      eklenmeTarihi: json['eklenmeTarihi'] != null
          ? DateTime.tryParse(json['eklenmeTarihi'] as String) ?? DateTime.now()
          : DateTime.now(),
      bolumler: [
        for (final item in rawBolumler)
          if (item is Map<String, dynamic>) KitapBolumu.fromJson(item),
      ],
    );
  }
}

/// Çok satırlı içindekiler metnini veya kameradan/Lens'ten kopyalanan listeyi
/// otomatik olarak [KitapBolumu] listesine ayrıştırır.
List<KitapBolumu> topluBolumleriAyristir(String hamMetin) {
  final satirlar = hamMetin.split('\n');
  final sonuc = <KitapBolumu>[];
  var sayac = 1;

  for (var satir in satirlar) {
    satir = satir.trim();
    if (satir.isEmpty) continue;

    // Sayfa aralığı tespiti: örn "s. 15-42", "sayfa 10-20", "(15-30)", "... 45-80"
    int? basSayfa;
    int? bitSayfa;

    final sayfaRegex = RegExp(
      r'(?:s\.?|sayfa|\.{2,}|[-–—]|\()?\s*(\d{1,4})\s*[-–—]\s*(\d{1,4})\s*\)?$',
      caseSensitive: false,
    );
    final match = sayfaRegex.firstMatch(satir);
    if (match != null) {
      basSayfa = int.tryParse(match.group(1)!);
      bitSayfa = int.tryParse(match.group(2)!);
      // Bölüm adından sayfa kısmını temizle
      satir = satir.substring(0, match.start).trim();
    } else {
      // Tekil sayfa numarası: örn "... 124"
      final tekSayfaRegex = RegExp(r'(?:\.{2,}|\s{2,}|s\.?)\s*(\d{1,4})$', caseSensitive: false);
      final tekMatch = tekSayfaRegex.firstMatch(satir);
      if (tekMatch != null) {
        basSayfa = int.tryParse(tekMatch.group(1)!);
        satir = satir.substring(0, tekMatch.start).trim();
      }
    }

    // Başındaki gereksiz noktaları veya tireleri temizle
    satir = satir.replaceAll(RegExp(r'[\.\-_]+$'), '').trim();

    if (satir.isEmpty) {
      satir = 'Bölüm $sayac';
    }

    sonuc.add(
      KitapBolumu(
        id: 'b_${DateTime.now().microsecondsSinceEpoch}_$sayac',
        ad: satir,
        baslangicSayfa: basSayfa,
        bitisSayfa: bitSayfa,
      ),
    );
    sayac++;
  }

  return sonuc;
}
