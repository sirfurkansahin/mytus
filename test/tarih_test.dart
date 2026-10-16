import 'package:app/core/tarih.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tarihYaz Türkçe ay adı kullanır', () {
    expect(tarihYaz(DateTime(2026, 10, 16)), '16 Ekim 2026');
    expect(tarihYaz(DateTime(2027, 1, 5)), '5 Ocak 2027');
    expect(tarihYaz(DateTime(2027, 2, 1)), '1 Şubat 2027');
  });

  test('tarihAnahtari ve tarihCoz birbirinin tersi', () {
    final t = DateTime(2026, 10, 6);
    expect(tarihAnahtari(t), '2026-10-06');
    expect(tarihCoz('2026-10-06'), t);
  });

  test('tarihCoz geçersiz metinde null döner', () {
    expect(tarihCoz(null), isNull);
    expect(tarihCoz(''), isNull);
    expect(tarihCoz('2026-10'), isNull);
    expect(tarihCoz('abc-de-fg'), isNull);
    expect(tarihCoz('2027-02-31'), isNull);
    expect(tarihCoz('2027-13-01'), isNull);
  });

  test('gunFarki saatleri yok sayar', () {
    final bugun = DateTime(2026, 10, 16, 23, 59);
    final sinav = DateTime(2026, 10, 23, 0, 1);
    expect(gunFarki(sinav, bugun), 7);
    expect(gunFarki(bugun, bugun), 0);
    expect(gunFarki(bugun, sinav), -7);
  });
}
