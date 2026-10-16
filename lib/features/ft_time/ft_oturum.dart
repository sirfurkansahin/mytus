import 'dart:convert';

import 'package:app/features/ft_time/ft_timer.dart';

/// Bir odak oturumunun içinde sırayla gelen bölümler.
enum FtFaz { calisma, kisaMola, uzunMola }

const int _dakikaMs = 60 * 1000;

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

/// Çalışan bir F.T. time oturumu: döngüler ve aralardaki molalar.
///
/// Bölümler sırayla gelir: çalışma 1, mola, çalışma 2, ... çalışma N (son
/// çalışmadan sonra mola yoktur). Bir bölüm bitince bir sonrakine kullanıcı
/// düğmeyle geçer (otomatik başlamaz). Her bölümün süresi, oturum başlarken
/// alınan ayarlarla sabitlenir; sonradan ayar değişse bile oturum etkilenmez.
class FtOturum {
  const FtOturum._({
    required this.id,
    required this.toplamDongu,
    required this.calismaMs,
    required this.kisaMolaMs,
    required this.uzunMolaMs,
    required this.uzunMolaAraligi,
    required this.dongu,
    required this.faz,
    required this.sayac,
    this.konuId,
  });

  /// Yeni oturum: 1. döngünün çalışma bölümü hazır bekler.
  factory FtOturum.yeni({
    required int id,
    required int toplamDongu,
    required FtAyarlari ayar,
    int? konuId,
  }) {
    return FtOturum._(
      id: id,
      toplamDongu: toplamDongu < 1 ? 1 : toplamDongu,
      konuId: konuId,
      calismaMs: ayar.calismaDk * _dakikaMs,
      kisaMolaMs: ayar.kisaMolaDk * _dakikaMs,
      uzunMolaMs: ayar.uzunMolaDk * _dakikaMs,
      uzunMolaAraligi: ayar.uzunMolaAraligi,
      dongu: 1,
      faz: FtFaz.calisma,
      sayac: FtTimerState.bosta(ayar.calismaDk * _dakikaMs),
    );
  }

  final int id;
  final int toplamDongu;
  final int? konuId;
  final int calismaMs;
  final int kisaMolaMs;
  final int uzunMolaMs;
  final int uzunMolaAraligi;

  /// Şu anki döngü (1'den başlar).
  final int dongu;
  final FtFaz faz;

  /// Şu anki bölümün sayacı.
  final FtTimerState sayac;

  FtOturum _sayacla(FtTimerState yeni) => FtOturum._(
        id: id,
        toplamDongu: toplamDongu,
        konuId: konuId,
        calismaMs: calismaMs,
        kisaMolaMs: kisaMolaMs,
        uzunMolaMs: uzunMolaMs,
        uzunMolaAraligi: uzunMolaAraligi,
        dongu: dongu,
        faz: faz,
        sayac: yeni,
      );

  /// Bağlı konu silinirse oturum konusuz devam eder.
  FtOturum konuSiz() => FtOturum._(
        id: id,
        toplamDongu: toplamDongu,
        calismaMs: calismaMs,
        kisaMolaMs: kisaMolaMs,
        uzunMolaMs: uzunMolaMs,
        uzunMolaAraligi: uzunMolaAraligi,
        dongu: dongu,
        faz: faz,
        sayac: sayac,
      );

  FtOturum baslat(int nowMs) => _sayacla(sayac.baslat(nowMs));

  FtOturum duraklat(int nowMs) => _sayacla(sayac.duraklat(nowMs));

  /// Süre dolduysa bölümü "bitti" yapar.
  FtOturum guncelle(int nowMs) {
    final yeni = sayac.guncelle(nowMs);
    return identical(yeni, sayac) ? this : _sayacla(yeni);
  }

  bool get bolumBitti => sayac.phase == FtPhase.bitti;

  /// Son döngünün çalışması bittiyse oturum tamamlanmıştır.
  bool get tamamlandi =>
      faz == FtFaz.calisma && dongu >= toplamDongu && bolumBitti;

  /// Puanlanmış (bitmiş) çalışma döngüsü sayısı.
  int get tamamlananDongu {
    if (faz == FtFaz.calisma) return bolumBitti ? dongu : dongu - 1;
    return dongu;
  }

  /// Bu oturumdan kazanılan toplam dakika (puan).
  int get kazanilanDakika => tamamlananDongu * (calismaMs ~/ _dakikaMs);

  /// Bu döngünün çalışması bittiyse kazandırdığı puan (dakika).
  int get donguPuani => calismaMs ~/ _dakikaMs;

  /// Bölüm bitti ve sırada başka bölüm var mı?
  bool get ilerlenebilir => bolumBitti && !tamamlandi;

  /// Çalışma bittikten sonra gelecek molanın türü.
  FtFaz get siradakiMolaTuru =>
      dongu % uzunMolaAraligi == 0 ? FtFaz.uzunMola : FtFaz.kisaMola;

  /// Bitmiş bölümden sonrakine geçer (mola ya da sonraki döngünün çalışması).
  FtOturum? ilerle() => ilerlenebilir ? _sonraki() : null;

  /// Moladaysan molayı atlayıp sonraki çalışmaya geçer.
  FtOturum? molayiAtla() => faz == FtFaz.calisma ? null : _sonraki();

  FtOturum _sonraki() {
    if (faz == FtFaz.calisma) {
      final tur = siradakiMolaTuru;
      final sure = tur == FtFaz.uzunMola ? uzunMolaMs : kisaMolaMs;
      return FtOturum._(
        id: id,
        toplamDongu: toplamDongu,
        konuId: konuId,
        calismaMs: calismaMs,
        kisaMolaMs: kisaMolaMs,
        uzunMolaMs: uzunMolaMs,
        uzunMolaAraligi: uzunMolaAraligi,
        dongu: dongu,
        faz: tur,
        sayac: FtTimerState.bosta(sure),
      );
    }
    return FtOturum._(
      id: id,
      toplamDongu: toplamDongu,
      konuId: konuId,
      calismaMs: calismaMs,
      kisaMolaMs: kisaMolaMs,
      uzunMolaMs: uzunMolaMs,
      uzunMolaAraligi: uzunMolaAraligi,
      dongu: dongu + 1,
      faz: FtFaz.calisma,
      sayac: FtTimerState.bosta(calismaMs),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'toplamDongu': toplamDongu,
        'konuId': konuId,
        'calismaMs': calismaMs,
        'kisaMolaMs': kisaMolaMs,
        'uzunMolaMs': uzunMolaMs,
        'uzunMolaAraligi': uzunMolaAraligi,
        'dongu': dongu,
        'faz': faz.name,
        'sayac': sayac.toJsonString(),
      };

  /// Bozuk kayıt null döner (oturum yok sayılır).
  static FtOturum? fromJson(Object? veri) {
    if (veri is! Map) return null;
    final id = veri['id'];
    final toplam = veri['toplamDongu'];
    final calisma = veri['calismaMs'];
    final kisa = veri['kisaMolaMs'];
    final uzun = veri['uzunMolaMs'];
    final aralik = veri['uzunMolaAraligi'];
    final dongu = veri['dongu'];
    final fazAdi = veri['faz'];
    final sayacMetni = veri['sayac'];
    final konu = veri['konuId'];
    if (id is! int ||
        toplam is! int ||
        toplam < 1 ||
        calisma is! int ||
        calisma <= 0 ||
        kisa is! int ||
        kisa <= 0 ||
        uzun is! int ||
        uzun <= 0 ||
        aralik is! int ||
        aralik < 1 ||
        dongu is! int ||
        dongu < 1 ||
        dongu > toplam ||
        fazAdi is! String ||
        sayacMetni is! String) {
      return null;
    }
    FtFaz? faz;
    for (final f in FtFaz.values) {
      if (f.name == fazAdi) faz = f;
    }
    final sayac = FtTimerState.fromJsonString(sayacMetni);
    if (faz == null || sayac == null) return null;
    return FtOturum._(
      id: id,
      toplamDongu: toplam,
      konuId: konu is int ? konu : null,
      calismaMs: calisma,
      kisaMolaMs: kisa,
      uzunMolaMs: uzun,
      uzunMolaAraligi: aralik,
      dongu: dongu,
      faz: faz,
      sayac: sayac,
    );
  }

  String toJsonString() => jsonEncode(toJson());
}
