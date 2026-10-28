// Tamamlanan odak döngüsü kaydı (ft_oturum.dart içinden ayrıldı).

/// Tamamlanan bir odak döngüsü. 1 dakika = 1 puan (onaylı kural).
class OdakKaydi {
  const OdakKaydi({
    required this.anahtar,
    required this.tarihMs,
    required this.dakika,
    this.konuId,
  });

  /// "oturumNo:döngüNo". Aynı döngü iki kez puanlanmasın diye kullanılır.
  final String anahtar;

  /// Döngünün bittiği an (epoch milisaniye).
  final int tarihMs;
  final int dakika;
  final int? konuId;

  int get puan => dakika;

  DateTime get tarih => DateTime.fromMillisecondsSinceEpoch(tarihMs);

  OdakKaydi konuSiz() => OdakKaydi(anahtar: anahtar, tarihMs: tarihMs, dakika: dakika);

  Map<String, Object?> toJson() => {
        'anahtar': anahtar,
        'tarihMs': tarihMs,
        'dakika': dakika,
        'konuId': konuId,
      };

  static OdakKaydi? fromJson(Object? veri) {
    if (veri is! Map) return null;
    final anahtar = veri['anahtar'];
    final tarih = veri['tarihMs'];
    final dakika = veri['dakika'];
    final konu = veri['konuId'];
    if (anahtar is! String || tarih is! int || dakika is! int || dakika < 0) {
      return null;
    }
    return OdakKaydi(
      anahtar: anahtar,
      tarihMs: tarih,
      dakika: dakika,
      konuId: konu is int ? konu : null,
    );
  }
}
