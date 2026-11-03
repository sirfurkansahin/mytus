/// Bilişsel performans, uyku mimarisi ve nörobiyoloji modelleri.
/// (Master Araştırma Raporu Bölüm 1.1, 1.3, 1.6 ve 6.4)

/// İki "SS:dd" saat dizesi arasındaki dairesel dakika farkını hesaplar.
/// Örneğin 23:50 ile 00:10 arasındaki fark 20 dakikadır.
int daireselDakikaFarki(String saat1, String saat2) {
  int dk(String s) {
    final parcalar = s.split(':');
    if (parcalar.length != 2) return 0;
    final s1 = int.tryParse(parcalar[0]) ?? 0;
    final d1 = int.tryParse(parcalar[1]) ?? 0;
    return s1 * 60 + d1;
  }

  var fark = (dk(saat1) - dk(saat2)).abs();
  if (fark > 720) fark = 1440 - fark;
  return fark;
}

/// Yatış saatinden 8 saat (480 dk) öncesini "SS:dd" olarak döndürür.
/// Master Rapor Kuralı: Adenozin temizliği için yatmadan 8 saat önce kafein kesilir.
String kafeinKesilmeSaatiHesapla(String yatisSaati) {
  final parcalar = yatisSaati.split(':');
  if (parcalar.length != 2) return '15:30';
  final s = int.tryParse(parcalar[0]) ?? 23;
  final d = int.tryParse(parcalar[1]) ?? 30;
  final toplamDk = s * 60 + d;
  var kafeinDk = (toplamDk - 480) % 1440;
  if (kafeinDk < 0) kafeinDk += 1440;
  final sa = (kafeinDk ~/ 60).toString().padLeft(2, '0');
  final da = (kafeinDk % 60).toString().padLeft(2, '0');
  return '$sa:$da';
}

/// Adayın günlük uyku ve sirkadiyen ritim kaydı.
class UykuKaydi {
  const UykuKaydi({
    required this.tarih,
    required this.uykuSuresiDakika,
    required this.yatisSaati,
    required this.kalkisSaati,
    this.hedefYatisSaati = '23:30',
    this.sonKafeinSaati,
    this.kalite = 4,
  });

  /// "yyyy-MM-dd" biçiminde tarih.
  final String tarih;

  /// Toplam uyku süresi (dakika). Hedef: 420-540 dk (7-9 saat).
  final int uykuSuresiDakika;

  /// Gerçek yatış saati ("23:45").
  final String yatisSaati;

  /// Gerçek kalkış saati ("07:30").
  final String kalkisSaati;

  /// Hedeflenen yatış saati ("23:30").
  final String hedefYatisSaati;

  /// O gün son kafein alınan saat ("15:00").
  final String? sonKafeinSaati;

  /// Uyku dinlendiriciliği (1: Çok Kötü, 5: Dinç/Zinde).
  final int kalite;

  double get uykuSuresiSaat => uykuSuresiDakika / 60.0;

  /// Hedef yatış saatinden sapma dakikası.
  int get yatisSapmasiDakika => daireselDakikaFarki(yatisSaati, hedefYatisSaati);

  /// Rapor kuralı: Hedef yatıştan maksimum ±30 dakika sapma toleransı vardır.
  bool get yatisSaatiDengeli => yatisSapmasiDakika <= 30;

  /// Hedef: 7-9 saat uyku.
  bool get sureDengeli => uykuSuresiDakika >= 420 && uykuSuresiDakika <= 540;

  /// Rapor kuralı: ±30 dk yatış sapması ve 7-9 saat uyku birlikte sağlanıyorsa altın uyum.
  bool get sirkadiyenUyumlu => yatisSaatiDengeli && sureDengeli;

  /// Bu yatış için tavsiye edilen son kafein alma saati (8 saat önce).
  String get tavsiyeEdilenSonKafein => kafeinKesilmeSaatiHesapla(yatisSaati);

  Map<String, dynamic> toJson() => {
        'tarih': tarih,
        'uykuSuresiDakika': uykuSuresiDakika,
        'yatisSaati': yatisSaati,
        'kalkisSaati': kalkisSaati,
        'hedefYatisSaati': hedefYatisSaati,
        'sonKafeinSaati': sonKafeinSaati,
        'kalite': kalite,
      };

  factory UykuKaydi.fromJson(Map<String, dynamic> json) {
    return UykuKaydi(
      tarih: json['tarih'] as String? ?? '',
      uykuSuresiDakika: json['uykuSuresiDakika'] as int? ?? 480,
      yatisSaati: json['yatisSaati'] as String? ?? '23:30',
      kalkisSaati: json['kalkisSaati'] as String? ?? '07:30',
      hedefYatisSaati: json['hedefYatisSaati'] as String? ?? '23:30',
      sonKafeinSaati: json['sonKafeinSaati'] as String?,
      kalite: json['kalite'] as int? ?? 4,
    );
  }
}
