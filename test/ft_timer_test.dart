import 'package:app/features/ft_time/ft_timer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const dakika = 60 * 1000;
  const baslangic = 1000000;

  group('FtTimerState', () {
    test('hazır sayaç tam süreyi gösterir', () {
      const s = FtTimerState.bosta(25 * dakika);
      expect(s.phase, FtPhase.bosta);
      expect(s.kalanMs(baslangic), 25 * dakika);
    });

    test('başlatınca bitiş saati = şimdi + süre', () {
      const s = FtTimerState.bosta(25 * dakika);
      final c = s.baslat(baslangic);
      expect(c.phase, FtPhase.calisiyor);
      expect(c.endAtMs, baslangic + 25 * dakika);
      expect(c.kalanMs(baslangic + 5 * dakika), 20 * dakika);
    });

    test('süre dolunca bitti olur ve kalan 0 olur', () {
      final c = const FtTimerState.bosta(dakika).baslat(baslangic);
      expect(c.guncelle(baslangic + dakika - 1).phase, FtPhase.calisiyor);
      final b = c.guncelle(baslangic + dakika);
      expect(b.phase, FtPhase.bitti);
      expect(b.kalanMs(baslangic + 10 * dakika), 0);
      expect(b.endAtMs, baslangic + dakika);
    });

    test('duraklatınca kalan süre saklanır, devamda doğru bitiş çıkar', () {
      final c = const FtTimerState.bosta(10 * dakika).baslat(baslangic);
      final d = c.duraklat(baslangic + 4 * dakika);
      expect(d.phase, FtPhase.duraklatildi);
      expect(d.kalanMs(baslangic + 99 * dakika), 6 * dakika);
      final devam = d.baslat(baslangic + 50 * dakika);
      expect(devam.phase, FtPhase.calisiyor);
      expect(devam.endAtMs, baslangic + 56 * dakika);
    });

    test('süre dolduktan sonra duraklatmak bitti yapar', () {
      final c = const FtTimerState.bosta(dakika).baslat(baslangic);
      expect(c.duraklat(baslangic + 2 * dakika).phase, FtPhase.bitti);
    });

    test('sıfırlama süre seçimini korur', () {
      final c = const FtTimerState.bosta(5 * dakika).baslat(baslangic);
      final s = c.sifirla();
      expect(s.phase, FtPhase.bosta);
      expect(s.durationMs, 5 * dakika);
      expect(s.endAtMs, isNull);
    });

    test('hazır veya biten sayaç tekrar başlatılamaz (bitti)', () {
      final b = const FtTimerState.bosta(dakika)
          .baslat(baslangic)
          .guncelle(baslangic + dakika);
      expect(b.baslat(baslangic + 2 * dakika).phase, FtPhase.bitti);
    });

    test('kayıt ve geri yükleme: çalışan sayaç', () {
      final c = const FtTimerState.bosta(25 * dakika).baslat(baslangic);
      final geri = FtTimerState.fromJsonString(c.toJsonString());
      expect(geri, isNotNull);
      expect(geri!.phase, FtPhase.calisiyor);
      expect(geri.endAtMs, c.endAtMs);
      expect(geri.durationMs, 25 * dakika);
    });

    test('kayıt ve geri yükleme: duraklatılmış sayaç', () {
      final d = const FtTimerState.bosta(10 * dakika)
          .baslat(baslangic)
          .duraklat(baslangic + dakika);
      final geri = FtTimerState.fromJsonString(d.toJsonString());
      expect(geri!.phase, FtPhase.duraklatildi);
      expect(geri.remainingMs, 9 * dakika);
    });

    test('bozuk kayıt null döner', () {
      expect(FtTimerState.fromJsonString(null), isNull);
      expect(FtTimerState.fromJsonString(''), isNull);
      expect(FtTimerState.fromJsonString('bozuk{'), isNull);
      expect(FtTimerState.fromJsonString('[]'), isNull);
      expect(
        FtTimerState.fromJsonString('{"phase":"calisiyor","durationMs":60000}'),
        isNull,
      );
      expect(
        FtTimerState.fromJsonString('{"phase":"yok","durationMs":60000}'),
        isNull,
      );
    });
  });

  group('sureYaz', () {
    test('biçimlendirme', () {
      expect(sureYaz(25 * dakika), '25:00');
      expect(sureYaz(61 * 1000), '01:01');
      expect(sureYaz(0), '00:00');
      expect(sureYaz(-5), '00:00');
    });

    test('saniye yukarı yuvarlanır', () {
      expect(sureYaz(1), '00:01');
      expect(sureYaz(59001), '01:00');
    });
  });
}
