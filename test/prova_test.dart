import 'package:app/features/prova/modeller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sınav Provası ve Çeyrek Dilim Tempo Modeli', () {
    test('100 soru 130 dakikada biter, 5 dk kontrol payı bırakılır', () {
      expect(hedefGecenDakika(25), 32.5);
      expect(hedefGecenDakika(50), 65.0);
      expect(hedefGecenDakika(75), 97.5);
      expect(hedefGecenDakika(100), 130.0);
    });

    test('Tempo analizi önde, zamanında ve geride durumlarını doğru belirler', () {
      // 25. soruya 25. dakikada geldi (hedef 32.5 dk -> 7 dk önde)
      final onde = tempoAnalizi(soruNo: 25, gecenSaniye: 25 * 60);
      expect(onde.durum, TempoDurumu.onde);
      expect(onde.farkDakika >= 6, isTrue);

      // 50. soruya 65. dakikada geldi (tam hedef)
      final zamaninda = tempoAnalizi(soruNo: 50, gecenSaniye: 65 * 60);
      expect(zamaninda.durum, TempoDurumu.zamaninda);

      // 50. soruya 75. dakikada geldi (10 dk geride)
      final geride = tempoAnalizi(soruNo: 50, gecenSaniye: 75 * 60);
      expect(geride.durum, TempoDurumu.geride);
      expect(geride.farkDakika, 10);
    });

    test('Resmi çeyrek dilim hedefleri 4 kritik kontrol noktasını içerir', () {
      expect(resmiCeyrekDilimler.length, 4);
      expect(resmiCeyrekDilimler[0].soruNo, 25);
      expect(resmiCeyrekDilimler[0].hedefDakika, 32);

      expect(resmiCeyrekDilimler[1].soruNo, 50);
      expect(resmiCeyrekDilimler[1].hedefDakika, 65);

      expect(resmiCeyrekDilimler[2].soruNo, 75);
      expect(resmiCeyrekDilimler[2].hedefDakika, 98);

      expect(resmiCeyrekDilimler[3].soruNo, 100);
      expect(resmiCeyrekDilimler[3].hedefDakika, 130);
    });
  });

  group('Beklenen Değer (EV) ve Matematiksel Getiri', () {
    test('0 şık elendiğinde beklenen değer sıfırdır', () {
      expect(beklenenDegerHesapla(0), 0.0);
    });

    test('1 şık elendiğinde beklenen değer pozitiftir (+0.063)', () {
      expect(beklenenDegerHesapla(1), 0.063);
    });

    test('2 şık elendiğinde beklenen değer güçlü pozitiftir (+0.167)', () {
      expect(beklenenDegerHesapla(2), 0.167);
    });

    test('3 şık elendiğinde (ikilem) beklenen değer çok yüksektir (+0.375)', () {
      expect(beklenenDegerHesapla(3), 0.375);
    });
  });
}
