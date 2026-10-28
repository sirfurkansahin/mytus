import 'dart:convert';

import 'package:app/features/ft_time/ft_ayarlari.dart';
import 'package:app/features/ft_time/ft_timer.dart';

// Eski içe aktarmalar bozulmasın diye ayrılan sınıflar buradan da görünür.
export 'package:app/features/ft_time/ft_ayarlari.dart';
export 'package:app/features/ft_time/odak_kaydi.dart';

/// Bir odak oturumunun içinde sırayla gelen bölümler.
enum FtFaz { calisma, kisaMola, uzunMola }

const int _dakikaMs = 60 * 1000;

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
