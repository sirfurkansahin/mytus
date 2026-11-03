// Tamamlanan odak döngüsü kaydı (ft_oturum.dart içinden ayrıldı).

/// Tamamlanan bir odak döngüsü. 1 dakika = 1 puan (onaylı kural).
class OdakKaydi {
  const OdakKaydi({
    required this.anahtar,
    required this.tarihMs,
    required this.dakika,
    this.konuId,
    this.odakPuani = 4,
    this.zorBilissel = true,
  });

  /// "oturumNo:döngüNo". Aynı döngü iki kez puanlanmasın diye kullanılır.
  final String anahtar;

  /// Döngünün bittiği an (epoch milisaniye).
  final int tarihMs;
  final int dakika;
  final int? konuId;

  /// 1-5 odak puanı (1: Çok Düşük, 2: Düşük, 3: Orta, 4: Yüksek, 5: Zirve Akış / Flow State).
  final int odakPuani;

  /// Ağır analitik iş mi? (Yeni konu, deneme, derin hata analizi = true; hafif tekrar, skor kartları = false).
  final bool zorBilissel;

  int get puan => dakika;

  DateTime get tarih => DateTime.fromMillisecondsSinceEpoch(tarihMs);

  OdakKaydi konuSiz() => OdakKaydi(
        anahtar: anahtar,
        tarihMs: tarihMs,
        dakika: dakika,
        odakPuani: odakPuani,
        zorBilissel: zorBilissel,
      );

  OdakKaydi kopyala({
    int? odakPuani,
    bool? zorBilissel,
  }) =>
      OdakKaydi(
        anahtar: anahtar,
        tarihMs: tarihMs,
        dakika: dakika,
        konuId: konuId,
        odakPuani: odakPuani ?? this.odakPuani,
        zorBilissel: zorBilissel ?? this.zorBilissel,
      );

  Map<String, Object?> toJson() => {
        'anahtar': anahtar,
        'tarihMs': tarihMs,
        'dakika': dakika,
        'konuId': konuId,
        'odakPuani': odakPuani,
        'zorBilissel': zorBilissel,
      };

  static OdakKaydi? fromJson(Object? veri) {
    if (veri is! Map) return null;
    final anahtar = veri['anahtar'];
    final tarih = veri['tarihMs'];
    final dakika = veri['dakika'];
    final konu = veri['konuId'];
    final odak = veri['odakPuani'];
    final zor = veri['zorBilissel'];
    if (anahtar is! String || tarih is! int || dakika is! int || dakika < 0) {
      return null;
    }
    return OdakKaydi(
      anahtar: anahtar,
      tarihMs: tarih,
      dakika: dakika,
      konuId: konu is int ? konu : null,
      odakPuani: odak is int && odak >= 1 && odak <= 5 ? odak : 4,
      zorBilissel: zor is bool ? zor : true,
    );
  }
}
