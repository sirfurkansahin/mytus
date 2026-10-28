// F.T. time süre ayarları ve sınırlama yardımcısı (ft_oturum.dart içinden ayrıldı).

int _sinirla(Object? deger, int en, int cok, int varsayilan) {
  if (deger is! int) return varsayilan;
  if (deger < en) return en;
  if (deger > cok) return cok;
  return deger;
}

/// F.T. time süre ayarları (varsayılanlar onaylı kural: 25 / 5 / 15, her 4 döngüde uzun mola).
class FtAyarlari {
  const FtAyarlari({
    this.calismaDk = 25,
    this.kisaMolaDk = 5,
    this.uzunMolaDk = 15,
    this.uzunMolaAraligi = 4,
    this.donguSayisi = 4,
  });

  final int calismaDk;
  final int kisaMolaDk;
  final int uzunMolaDk;

  /// Her kaç döngüden sonra uzun mola verileceği.
  final int uzunMolaAraligi;

  /// Yeni oturumda önerilen döngü sayısı.
  final int donguSayisi;

  static const int calismaEnAz = 1;
  static const int calismaEnCok = 180;
  static const int molaEnAz = 1;
  static const int molaEnCok = 60;
  static const int uzunMolaEnCok = 120;
  static const int araligiEnAz = 2;
  static const int araligiEnCok = 10;
  static const int donguEnAz = 1;
  static const int donguEnCok = 12;

  FtAyarlari kopya({
    int? calismaDk,
    int? kisaMolaDk,
    int? uzunMolaDk,
    int? uzunMolaAraligi,
    int? donguSayisi,
  }) {
    return FtAyarlari(
      calismaDk: _sinirla(
        calismaDk ?? this.calismaDk,
        calismaEnAz,
        calismaEnCok,
        25,
      ),
      kisaMolaDk: _sinirla(kisaMolaDk ?? this.kisaMolaDk, molaEnAz, molaEnCok, 5),
      uzunMolaDk: _sinirla(
        uzunMolaDk ?? this.uzunMolaDk,
        molaEnAz,
        uzunMolaEnCok,
        15,
      ),
      uzunMolaAraligi: _sinirla(
        uzunMolaAraligi ?? this.uzunMolaAraligi,
        araligiEnAz,
        araligiEnCok,
        4,
      ),
      donguSayisi: _sinirla(
        donguSayisi ?? this.donguSayisi,
        donguEnAz,
        donguEnCok,
        4,
      ),
    );
  }

  /// [dongu] döngülük oturumun yaklaşık toplam süresi (dakika). Son döngüden sonra mola yok.
  int toplamDakika(int dongu) {
    var toplam = dongu * calismaDk;
    for (var k = 1; k < dongu; k++) {
      toplam += k % uzunMolaAraligi == 0 ? uzunMolaDk : kisaMolaDk;
    }
    return toplam;
  }

  Map<String, Object?> toJson() => {
        'calismaDk': calismaDk,
        'kisaMolaDk': kisaMolaDk,
        'uzunMolaDk': uzunMolaDk,
        'uzunMolaAraligi': uzunMolaAraligi,
        'donguSayisi': donguSayisi,
      };

  /// Bozuk veya eksik alanlar varsayılana döner.
  static FtAyarlari fromJson(Object? veri) {
    if (veri is! Map) return const FtAyarlari();
    return const FtAyarlari().kopya(
      calismaDk: veri['calismaDk'] is int ? veri['calismaDk'] as int : null,
      kisaMolaDk: veri['kisaMolaDk'] is int ? veri['kisaMolaDk'] as int : null,
      uzunMolaDk: veri['uzunMolaDk'] is int ? veri['uzunMolaDk'] as int : null,
      uzunMolaAraligi:
          veri['uzunMolaAraligi'] is int ? veri['uzunMolaAraligi'] as int : null,
      donguSayisi: veri['donguSayisi'] is int ? veri['donguSayisi'] as int : null,
    );
  }
}
