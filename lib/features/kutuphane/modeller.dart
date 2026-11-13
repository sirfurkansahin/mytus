/// Kütüphane modülü veri modelleri (Sürüm 1).
/// Kitap, içindekiler/bölüm yapısı ve bölümlere ait fotoğraflı/metinli notlar.
library;

/// Fotoğraflı ve metinli notlar için hazır TUS etiketleri.
const List<String> hazirNotEtiketleri = [
  'Tablo',
  'Spot',
  'Hoca notu',
  'Şema / Algoritma',
];

/// Kitabın bir bölümüne eklenen fotoğraflı veya metinli not kartı.
class BolumNotu {
  const BolumNotu({
    required this.id,
    this.metin = '',
    this.resimBase64,
    required this.olusturmaTarihi,
    this.etiketler = const [],
  });

  final String id;
  final String metin;
  final String? resimBase64;
  final DateTime olusturmaTarihi;
  final List<String> etiketler;

  bool get resimVar => resimBase64 != null && resimBase64!.isNotEmpty;
  bool get metinVar => metin.trim().isNotEmpty;
  bool get etiketVar => etiketler.isNotEmpty;

  BolumNotu kopya({
    String? id,
    String? metin,
    String? resimBase64,
    DateTime? olusturmaTarihi,
    List<String>? etiketler,
  }) {
    return BolumNotu(
      id: id ?? this.id,
      metin: metin ?? this.metin,
      resimBase64: resimBase64 ?? this.resimBase64,
      olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
      etiketler: etiketler ?? this.etiketler,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (metin.isNotEmpty) 'metin': metin,
        if (resimBase64 != null) 'resimBase64': resimBase64,
        'olusturmaTarihi': olusturmaTarihi.toIso8601String(),
        if (etiketler.isNotEmpty) 'etiketler': etiketler,
      };

  factory BolumNotu.fromJson(Map<String, dynamic> json) {
    final rawEtiketler = json['etiketler'] as List<dynamic>? ?? [];
    return BolumNotu(
      id: json['id'] as String? ?? '',
      metin: json['metin'] as String? ?? '',
      resimBase64: json['resimBase64'] as String?,
      olusturmaTarihi: json['olusturmaTarihi'] != null
          ? DateTime.tryParse(json['olusturmaTarihi'] as String) ?? DateTime.now()
          : DateTime.now(),
      etiketler: [
        for (final e in rawEtiketler)
          if (e is String && e.isNotEmpty) e,
      ],
    );
  }
}

class KitapBolumu {
  const KitapBolumu({
    required this.id,
    required this.ad,
    this.baslangicSayfa,
    this.bitisSayfa,
    this.tamamlandi = false,
    this.tamamlanmaTarihi,
    this.notlar = const [],
  });

  final String id;
  final String ad;
  final int? baslangicSayfa;
  final int? bitisSayfa;
  final bool tamamlandi;
  final DateTime? tamamlanmaTarihi;
  final List<BolumNotu> notlar;

  int get notSayisi => notlar.length;
  bool get notVar => notlar.isNotEmpty;

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
    List<BolumNotu>? notlar,
  }) {
    return KitapBolumu(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      baslangicSayfa: baslangicSayfa ?? this.baslangicSayfa,
      bitisSayfa: bitisSayfa ?? this.bitisSayfa,
      tamamlandi: tamamlandi ?? this.tamamlandi,
      tamamlanmaTarihi: tamamlanmaTarihi ?? this.tamamlanmaTarihi,
      notlar: notlar ?? this.notlar,
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
        if (notlar.isNotEmpty)
          'notlar': [for (final n in notlar) n.toJson()],
      };

  factory KitapBolumu.fromJson(Map<String, dynamic> json) {
    final rawNotlar = json['notlar'] as List<dynamic>? ?? [];
    return KitapBolumu(
      id: json['id'] as String? ?? '',
      ad: json['ad'] as String? ?? '',
      baslangicSayfa: json['baslangicSayfa'] as int?,
      bitisSayfa: json['bitisSayfa'] as int?,
      tamamlandi: json['tamamlandi'] as bool? ?? false,
      tamamlanmaTarihi: json['tamamlanmaTarihi'] != null
          ? DateTime.tryParse(json['tamamlanmaTarihi'] as String)
          : null,
      notlar: [
        for (final item in rawNotlar)
          if (item is Map<String, dynamic>) BolumNotu.fromJson(item),
      ],
    );
  }
}

class Kitap {
  const Kitap({
    required this.id,
    required this.ad,
    this.dersId,
    this.dersAdi,
    this.klasorAdi,
    this.toplamSayfa,
    this.gunlukSayfaHedefi,
    required this.eklenmeTarihi,
    this.bolumler = const [],
  });

  final String id;
  final String ad;
  final int? dersId;
  final String? dersAdi;
  final String? klasorAdi;
  final int? toplamSayfa;

  /// Kullanıcının bu kitap için belirlediği günlük sayfa hedefi (opsiyonel).
  final int? gunlukSayfaHedefi;
  final DateTime eklenmeTarihi;
  final List<KitapBolumu> bolumler;

  /// Klasör atanmamışsa 'Diğer Kitaplar' etiketi döner.
  String get klasorEtiketi {
    final temiz = klasorAdi?.trim();
    return (temiz != null && temiz.isNotEmpty) ? temiz : 'Diğer Kitaplar';
  }

  bool get klasoruVar => klasorAdi != null && klasorAdi!.trim().isNotEmpty;

  int get toplamBolumSayisi => bolumler.length;

  int get tamamlananBolumSayisi =>
      bolumler.where((b) => b.tamamlandi).length;

  int get kalanBolumSayisi => toplamBolumSayisi - tamamlananBolumSayisi;

  int get notluBolumSayisi => bolumler.where((b) => b.notVar).length;

  int get toplamNotSayisi => bolumler.fold(0, (toplam, b) => toplam + b.notSayisi);

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

  /// Kalan tahmini sayfa sayısı.
  int? get kalanSayfaSayisi {
    final bolumSayfalari = bolumler
        .where((b) => !b.tamamlandi && b.sayfaSayisi != null)
        .fold<int>(0, (toplam, b) => toplam + b.sayfaSayisi!);
    if (bolumSayfalari > 0) return bolumSayfalari;
    if (toplamSayfa != null && toplamSayfa! > 0) {
      final kalan = (toplamSayfa! * (1.0 - ilerlemeOrani)).round();
      return kalan >= 0 ? kalan : 0;
    }
    return null;
  }

  /// Kalan gün tahmini:
  /// Hedef girildiyse hedefe göre, girilmediyse son 14 günün otomatik ortalama hızına göre.
  int? tahminiKalanGun(double? otomatikGunlukHiz) {
    if (tamamlandi) return 0;
    final kalan = kalanSayfaSayisi;
    if (kalan == null || kalan <= 0) return null;
    if (gunlukSayfaHedefi != null && gunlukSayfaHedefi! > 0) {
      return (kalan / gunlukSayfaHedefi!).ceil();
    }
    if (otomatikGunlukHiz != null && otomatikGunlukHiz > 0) {
      return (kalan / otomatikGunlukHiz).ceil();
    }
    return null;
  }

  Kitap kopya({
    String? id,
    String? ad,
    int? dersId,
    String? dersAdi,
    String? klasorAdi,
    bool klasoruTemizle = false,
    int? toplamSayfa,
    int? gunlukSayfaHedefi,
    bool hedefiTemizle = false,
    DateTime? eklenmeTarihi,
    List<KitapBolumu>? bolumler,
  }) {
    return Kitap(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      dersId: dersId ?? this.dersId,
      dersAdi: dersAdi ?? this.dersAdi,
      klasorAdi: klasoruTemizle ? null : (klasorAdi ?? this.klasorAdi),
      toplamSayfa: toplamSayfa ?? this.toplamSayfa,
      gunlukSayfaHedefi: hedefiTemizle ? null : (gunlukSayfaHedefi ?? this.gunlukSayfaHedefi),
      eklenmeTarihi: eklenmeTarihi ?? this.eklenmeTarihi,
      bolumler: bolumler ?? this.bolumler,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ad': ad,
        if (dersId != null) 'dersId': dersId,
        if (dersAdi != null) 'dersAdi': dersAdi,
        if (klasorAdi != null && klasorAdi!.trim().isNotEmpty)
          'klasorAdi': klasorAdi!.trim(),
        if (toplamSayfa != null) 'toplamSayfa': toplamSayfa,
        if (gunlukSayfaHedefi != null) 'gunlukSayfaHedefi': gunlukSayfaHedefi,
        'eklenmeTarihi': eklenmeTarihi.toIso8601String(),
        'bolumler': [for (final b in bolumler) b.toJson()],
      };

  factory Kitap.fromJson(Map<String, dynamic> json) {
    final rawBolumler = json['bolumler'] as List<dynamic>? ?? [];
    final hamKlasor = json['klasorAdi'] as String?;
    return Kitap(
      id: json['id'] as String? ?? '',
      ad: json['ad'] as String? ?? '',
      dersId: json['dersId'] as int?,
      dersAdi: json['dersAdi'] as String?,
      klasorAdi: (hamKlasor != null && hamKlasor.trim().isNotEmpty)
          ? hamKlasor.trim()
          : null,
      toplamSayfa: json['toplamSayfa'] as int?,
      gunlukSayfaHedefi: json['gunlukSayfaHedefi'] as int?,
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
      r'[\(\[]?\s*(?:s\.?|sayfa|\.{2,}|[-–—])?\s*(\d{1,4})\s*[-–—]\s*(\d{1,4})\s*[\)\]]?$',
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
    satir = satir.replaceAll(RegExp(r'[\.\-_:,([\s]+$'), '').trim();

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

/// Kullanıcıya kütüphanenin nasıl çalıştığını göstermek için zengin örnek TUS kitabı.
Kitap ornekKitapUret() {
  return Kitap(
    id: 'k_ornek_patoloji',
    ad: 'TUSDATA Patoloji Konu Kitabı',
    dersAdi: 'Patoloji',
    dersId: 5,
    toplamSayfa: 260,
    eklenmeTarihi: DateTime.now(),
    bolumler: [
      KitapBolumu(
        id: 'b_ornek_1',
        ad: 'Hücre Hasarı, Adaptasyon ve Hücre Ölümü',
        baslangicSayfa: 1,
        bitisSayfa: 36,
        tamamlandi: true,
        tamamlanmaTarihi: DateTime.now().subtract(const Duration(days: 3)),
      ),
      KitapBolumu(
        id: 'b_ornek_2',
        ad: 'Akut ve Kronik İltihap, Doku Onarımı',
        baslangicSayfa: 37,
        bitisSayfa: 72,
        tamamlandi: true,
        tamamlanmaTarihi: DateTime.now().subtract(const Duration(days: 1)),
      ),
      const KitapBolumu(
        id: 'b_ornek_3',
        ad: 'Hemodinamik Bozukluklar, Tromboz ve Şok',
        baslangicSayfa: 73,
        bitisSayfa: 108,
        tamamlandi: false,
      ),
      KitapBolumu(
        id: 'b_ornek_4',
        ad: 'İmmün Sistem Hastalıkları ve Otoimmünite',
        baslangicSayfa: 109,
        bitisSayfa: 154,
        tamamlandi: false,
        notlar: [
          BolumNotu(
            id: 'n_ornek_1',
            metin: 'Tip 2 Aşırı Duyarlılık: Antikor (IgG/IgM) aracılıdır.\n'
                'Örnekler: Goodpasture (tip 4 kollajen), Myastenia Gravis (ACh reseptörü), '
                'Pemfigus Vulgaris (desmoglein-3), Graves (TSH reseptörü).\n'
                '⚠️ Sınav Tuzağı: Serum hastalığı ve Arthus reaksiyonu Tip 3 immün kompleks hastalığıdır!',
            olusturmaTarihi: DateTime.now().subtract(const Duration(hours: 4)),
          ),
        ],
      ),
      const KitapBolumu(
        id: 'b_ornek_5',
        ad: 'Neoplazi, Onkogenler ve Tümör Biyolojisi',
        baslangicSayfa: 155,
        bitisSayfa: 215,
        tamamlandi: false,
      ),
      const KitapBolumu(
        id: 'b_ornek_6',
        ad: 'Genetik Hastalıklar ve Çevre Patolojisi',
        baslangicSayfa: 216,
        bitisSayfa: 260,
        tamamlandi: false,
      ),
    ],
  );
}
