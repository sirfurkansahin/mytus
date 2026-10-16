import 'package:app/features/takvim/calisma.dart';
import 'package:app/features/takvim/tekrar_motoru.dart';
import 'package:flutter_test/flutter_test.dart';

Calisma calisma(
  int id,
  DateTime tarih, {
  bool tamam = true,
  List<TekrarKaydi> tekrarlar = const [],
}) =>
    Calisma(id: id, konuId: 1, tarih: tarih, tamam: tamam, tekrarlar: tekrarlar);

List<DateTime> gunler(List<TekrarOgesi> l) => [for (final o in l) o.tarih];

void main() {
  final sinav = DateTime(2027, 4, 1);

  group('tekrarGunleri (onaylı tablo)', () {
    test('tablo satırları aynen döner', () {
      expect(tekrarGunleri(7), [1, 3, 4]);
      expect(tekrarGunleri(14), [1, 4, 7, 9]);
      expect(tekrarGunleri(30), [1, 7, 12, 16]);
      expect(tekrarGunleri(60), [1, 8, 17, 25]);
      expect(tekrarGunleri(120), [1, 8, 21, 33]);
      expect(tekrarGunleri(180), [1, 8, 26, 43]);
      expect(tekrarGunleri(300), [1, 8, 29, 53]);
    });

    test('ara değerlerde kalan günden büyük olmayan en yakın satır', () {
      expect(tekrarGunleri(13), [1, 3, 4]);
      expect(tekrarGunleri(29), [1, 4, 7, 9]);
      expect(tekrarGunleri(45), [1, 7, 12, 16]);
      expect(tekrarGunleri(167), [1, 8, 21, 33]);
      expect(tekrarGunleri(1000), [1, 8, 29, 53]);
    });

    test('çok kısa sürede tekrar sığdığı kadar olur, sınav gününe düşmez', () {
      expect(tekrarGunleri(0), isEmpty);
      expect(tekrarGunleri(1), isEmpty);
      expect(tekrarGunleri(2), [1]);
      expect(tekrarGunleri(3), [1]);
      expect(tekrarGunleri(4), [1, 3]);
      expect(tekrarGunleri(5), [1, 3, 4]);
      expect(tekrarGunleri(-4), isEmpty);
    });

    test('hiçbir satırda 4 tekrardan fazla yok', () {
      for (final satir in tekrarTablosu.values) {
        expect(satir.length, lessThanOrEqualTo(4));
      }
    });
  });

  group('tekrarlariHesapla', () {
    test('tasarımdaki örnek: 16 Ekim çalışması, 120 günlük satır', () {
      final l = tekrarlariHesapla(
        calismalar: [calisma(1, DateTime(2026, 10, 16))],
        sinavTarihi: sinav,
        bugun: DateTime(2026, 10, 16),
        gunlukSinir: 10,
      );
      expect(gunler(l), [
        DateTime(2026, 10, 17),
        DateTime(2026, 10, 24),
        DateTime(2026, 11, 6),
        DateTime(2026, 11, 18),
      ]);
      expect([for (final o in l) o.no], [1, 2, 3, 4]);
      expect(l.every((o) => o.toplam == 4), isTrue);
      expect(l.first.siradaki, isTrue);
      expect(l[1].siradaki, isFalse);
    });

    test('çalışma bitmemişse tekrarlar yine hesaplanır ama yapılamaz', () {
      final l = tekrarlariHesapla(
        calismalar: [calisma(1, DateTime(2026, 10, 16), tamam: false)],
        sinavTarihi: sinav,
        bugun: DateTime(2026, 10, 16),
        gunlukSinir: 10,
      );
      expect(l.length, 4);
      expect(l.any((o) => o.eylemYapilabilir), isFalse);
    });

    test('geç yapılan tekrar sonrakileri aynı gün sayısı kadar kaydırır', () {
      // Tekrar 1 normalde 17 Ekim; 19 Ekim'de yapıldı (2 gün geç).
      final l = tekrarlariHesapla(
        calismalar: [
          calisma(1, DateTime(2026, 10, 16), tekrarlar: [
            TekrarKaydi(no: 1, tarih: DateTime(2026, 10, 19)),
          ]),
        ],
        sinavTarihi: sinav,
        bugun: DateTime(2026, 10, 19),
        gunlukSinir: 10,
      );
      expect(l.first.yapildi, isTrue);
      expect(l.first.yapilanTarih, DateTime(2026, 10, 19));
      expect(l[1].tarih, DateTime(2026, 10, 26));
      expect(l[2].tarih, DateTime(2026, 11, 8));
      expect(l[3].tarih, DateTime(2026, 11, 20));
      expect(l[1].siradaki, isTrue);
    });

    test('erken yapılan tekrar kaydırma yapmaz', () {
      final l = tekrarlariHesapla(
        calismalar: [
          calisma(1, DateTime(2026, 10, 16), tekrarlar: [
            TekrarKaydi(no: 1, tarih: DateTime(2026, 10, 16)),
          ]),
        ],
        sinavTarihi: sinav,
        bugun: DateTime(2026, 10, 16),
        gunlukSinir: 10,
      );
      expect(l[1].tarih, DateTime(2026, 10, 24));
    });

    test('kayma birikir: iki geç tekrar', () {
      final l = tekrarlariHesapla(
        calismalar: [
          calisma(1, DateTime(2026, 10, 16), tekrarlar: [
            TekrarKaydi(no: 1, tarih: DateTime(2026, 10, 19)), // 2 gün geç
            TekrarKaydi(no: 2, tarih: DateTime(2026, 10, 27)), // 26 Ekim'de olmalıydı: 1 gün geç
          ]),
        ],
        sinavTarihi: sinav,
        bugun: DateTime(2026, 10, 27),
        gunlukSinir: 10,
      );
      // Tekrar 3 ideal: 16 Ekim + 21 gün + 3 gün kayma = 9 Kasım.
      expect(l[2].tarih, DateTime(2026, 11, 9));
    });

    test('hiçbir tekrar sınavdan bir gün öncesini aşmaz', () {
      final kisaSinav = DateTime(2026, 11, 10);
      final l = tekrarlariHesapla(
        calismalar: [
          calisma(1, DateTime(2026, 10, 16), tekrarlar: [
            TekrarKaydi(no: 1, tarih: DateTime(2026, 11, 8)), // çok geç
          ]),
        ],
        sinavTarihi: kisaSinav,
        bugun: DateTime(2026, 11, 8),
        gunlukSinir: 10,
      );
      for (final o in l) {
        expect(o.tarih.isAfter(DateTime(2026, 11, 9)), isFalse);
      }
      expect(l.last.tarih, DateTime(2026, 11, 9));
    });

    test('sınav gününe veya sonrasına yerleşen çalışmanın tekrarı yok', () {
      final l = tekrarlariHesapla(
        calismalar: [
          calisma(1, DateTime(2027, 4, 1)),
          calisma(2, DateTime(2027, 4, 5)),
        ],
        sinavTarihi: sinav,
        bugun: DateTime(2027, 3, 1),
        gunlukSinir: 10,
      );
      expect(l, isEmpty);
    });

    test('günlük sınırı aşan tekrarlar ertesi güne kayar', () {
      final l = tekrarlariHesapla(
        calismalar: [
          calisma(1, DateTime(2026, 10, 16)),
          calisma(2, DateTime(2026, 10, 16)),
          calisma(3, DateTime(2026, 10, 16)),
        ],
        sinavTarihi: sinav,
        bugun: DateTime(2026, 10, 16),
        gunlukSinir: 2,
      );
      final tekrar1 = l.where((o) => o.no == 1).toList();
      expect(tekrar1.map((o) => o.calismaId).toList(), [1, 2, 3]);
      expect(tekrar1[0].tarih, DateTime(2026, 10, 17));
      expect(tekrar1[1].tarih, DateTime(2026, 10, 17));
      expect(tekrar1[2].tarih, DateTime(2026, 10, 18));
      // Her güne en çok 2 tekrar düşer.
      final sayac = <DateTime, int>{};
      for (final o in l) {
        sayac[o.tarih] = (sayac[o.tarih] ?? 0) + 1;
      }
      expect(sayac.values.every((n) => n <= 2), isTrue);
    });

    test('kaydırılan tekrardan sonraki tekrar onun önüne geçmez', () {
      final l = tekrarlariHesapla(
        calismalar: [
          calisma(1, DateTime(2027, 3, 20)),
          calisma(2, DateTime(2027, 3, 20)),
          calisma(3, DateTime(2027, 3, 20)),
        ],
        sinavTarihi: sinav,
        bugun: DateTime(2027, 3, 20),
        gunlukSinir: 1,
      );
      for (final id in [1, 2, 3]) {
        final kendi = l.where((o) => o.calismaId == id).toList()
          ..sort((a, b) => a.no.compareTo(b.no));
        for (var i = 1; i < kendi.length; i++) {
          expect(kendi[i].tarih.isAfter(kendi[i - 1].tarih) ||
              kendi[i].tarih == kendi[i - 1].tarih, isTrue);
        }
      }
    });

    test('geciken tekrar yerinde kalır, günlük sınıra sayılmaz', () {
      final l = tekrarlariHesapla(
        calismalar: [calisma(1, DateTime(2026, 10, 16))],
        sinavTarihi: sinav,
        bugun: DateTime(2026, 10, 20),
        gunlukSinir: 1,
      );
      expect(l.first.tarih, DateTime(2026, 10, 17));
      expect(l.first.yapildi, isFalse);
      expect(l.first.eylemYapilabilir, isTrue);
      expect(l[1].tarih, DateTime(2026, 10, 24));
    });

    test('aynı konunun iki çalışması ayrı tekrar dizileri üretir', () {
      final l = tekrarlariHesapla(
        calismalar: [
          calisma(1, DateTime(2026, 10, 16)),
          calisma(2, DateTime(2026, 12, 1)),
        ],
        sinavTarihi: sinav,
        bugun: DateTime(2026, 10, 16),
        gunlukSinir: 10,
      );
      expect(l.where((o) => o.calismaId == 1).length, 4);
      expect(l.where((o) => o.calismaId == 2).length, 4);
    });

    test('sonuç tarihe göre sıralıdır', () {
      final l = tekrarlariHesapla(
        calismalar: [
          calisma(1, DateTime(2026, 10, 20)),
          calisma(2, DateTime(2026, 10, 16)),
        ],
        sinavTarihi: sinav,
        bugun: DateTime(2026, 10, 16),
        gunlukSinir: 10,
      );
      for (var i = 1; i < l.length; i++) {
        expect(l[i].tarih.isBefore(l[i - 1].tarih), isFalse);
      }
    });
  });
}
