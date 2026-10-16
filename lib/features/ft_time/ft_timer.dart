import 'dart:convert';

/// Sayacın bulunabileceği durumlar.
enum FtPhase { bosta, calisiyor, duraklatildi, bitti }

/// F.T. time sayacının durumu. Değişmez (immutable) bir nesnedir.
///
/// Temel fikir: saniye saymayız. Çalışırken "bitiş saatini" (endAtMs) saklarız
/// ve kalan süreyi her seferinde saatten hesaplarız. Böylece uygulama
/// kapansa, telefon uykuya dalsa bile kalan süre doğru çıkar.
class FtTimerState {
  const FtTimerState._({
    required this.phase,
    required this.durationMs,
    this.endAtMs,
    this.remainingMs,
  });

  /// Hazır (başlamamış) sayaç.
  const FtTimerState.bosta(int durationMs)
      : this._(phase: FtPhase.bosta, durationMs: durationMs);

  final FtPhase phase;

  /// Seçilen toplam süre (milisaniye).
  final int durationMs;

  /// Çalışırken ve bittiğinde: bitiş saati (epoch milisaniye).
  final int? endAtMs;

  /// Duraklatılmışken: kalan süre (milisaniye).
  final int? remainingMs;

  /// Başlat veya duraklatılmışsa devam et.
  FtTimerState baslat(int nowMs) {
    if (phase == FtPhase.bosta) {
      return FtTimerState._(
        phase: FtPhase.calisiyor,
        durationMs: durationMs,
        endAtMs: nowMs + durationMs,
      );
    }
    if (phase == FtPhase.duraklatildi) {
      return FtTimerState._(
        phase: FtPhase.calisiyor,
        durationMs: durationMs,
        endAtMs: nowMs + (remainingMs ?? durationMs),
      );
    }
    return this;
  }

  /// Çalışan sayacı duraklat. Süre zaten dolmuşsa "bitti" olur.
  FtTimerState duraklat(int nowMs) {
    if (phase != FtPhase.calisiyor) return this;
    final kalan = (endAtMs ?? nowMs) - nowMs;
    if (kalan <= 0) return guncelle(nowMs);
    return FtTimerState._(
      phase: FtPhase.duraklatildi,
      durationMs: durationMs,
      remainingMs: kalan,
    );
  }

  /// Başa dön (süre seçimi korunur).
  FtTimerState sifirla() => FtTimerState.bosta(durationMs);

  /// Çalışırken süre dolduysa "bitti" durumuna geçirir.
  FtTimerState guncelle(int nowMs) {
    if (phase == FtPhase.calisiyor && nowMs >= (endAtMs ?? 0)) {
      return FtTimerState._(
        phase: FtPhase.bitti,
        durationMs: durationMs,
        endAtMs: endAtMs,
      );
    }
    return this;
  }

  /// Şu an kalan süre (milisaniye, asla negatif olmaz).
  int kalanMs(int nowMs) {
    switch (phase) {
      case FtPhase.bosta:
        return durationMs;
      case FtPhase.calisiyor:
        final kalan = (endAtMs ?? nowMs) - nowMs;
        return kalan < 0 ? 0 : kalan;
      case FtPhase.duraklatildi:
        return remainingMs ?? durationMs;
      case FtPhase.bitti:
        return 0;
    }
  }

  Map<String, Object?> toJson() => {
        'phase': phase.name,
        'durationMs': durationMs,
        'endAtMs': endAtMs,
        'remainingMs': remainingMs,
      };

  String toJsonString() => jsonEncode(toJson());

  /// Kayıtlı metinden durumu geri kurar. Bozuk veya boşsa null döner.
  static FtTimerState? fromJsonString(String? kayit) {
    if (kayit == null || kayit.isEmpty) return null;
    try {
      final veri = jsonDecode(kayit);
      if (veri is! Map<String, dynamic>) return null;
      final ad = veri['phase'];
      final sure = veri['durationMs'];
      if (ad is! String || sure is! int || sure <= 0) return null;
      FtPhase? faz;
      for (final f in FtPhase.values) {
        if (f.name == ad) faz = f;
      }
      if (faz == null) return null;
      final bitis = veri['endAtMs'];
      final kalan = veri['remainingMs'];
      if (faz == FtPhase.calisiyor && bitis is! int) return null;
      if (faz == FtPhase.duraklatildi && kalan is! int) return null;
      return FtTimerState._(
        phase: faz,
        durationMs: sure,
        endAtMs: bitis is int ? bitis : null,
        remainingMs: kalan is int ? kalan : null,
      );
    } on FormatException {
      return null;
    }
  }
}

/// Milisaniyeyi "dd:ss" olarak yazar. Saniye yukarı yuvarlanır (0:01 görünür, bitince 00:00).
String sureYaz(int ms) {
  final toplamSn = ms <= 0 ? 0 : (ms + 999) ~/ 1000;
  final dk = toplamSn ~/ 60;
  final sn = toplamSn % 60;
  return '${dk.toString().padLeft(2, '0')}:${sn.toString().padLeft(2, '0')}';
}

/// Epoch milisaniyeyi "ss:dd:ss" saat olarak yazar (telefonun yerel saati).
String saatYaz(int epochMs) {
  final t = DateTime.fromMillisecondsSinceEpoch(epochMs);
  String iki(int n) => n.toString().padLeft(2, '0');
  return '${iki(t.hour)}:${iki(t.minute)}:${iki(t.second)}';
}

/// Dakikayı "45 dk", "2 sa", "1 sa 55 dk" biçiminde yazar.
String dakikaYaz(int dakika) {
  if (dakika < 60) return '$dakika dk';
  final sa = dakika ~/ 60;
  final dk = dakika % 60;
  return dk == 0 ? '$sa sa' : '$sa sa $dk dk';
}
