import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DenemeOturumu', () {
    test('net hesabı doğru yapılır (Doğru - Yanlış/4)', () {
      const oturum = DenemeOturumu(dogru: 80, yanlis: 20, bos: 0);
      expect(oturum.toplamSoru, 100);
      expect(oturum.net, 75.0);
    });

    test('yanlış sayısı doğruyu aşarsa net sıfırın altına inmez', () {
      const oturum = DenemeOturumu(dogru: 2, yanlis: 20, bos: 78);
      expect(oturum.net, 0.0);
    });
  });

  group('DenemeSinavi Puan Hesaplamaları', () {
    test('200 soru üzerinden toplam net, K ve T puanları hesaplanır', () {
      final deneme = DenemeSinavi(
        id: 'd1',
        ad: 'TUSDATA 1',
        tarih: DateTime(2026, 11, 1),
        temel: const DenemeOturumu(dogru: 80, yanlis: 20, bos: 0), // 75 net
        klinik: const DenemeOturumu(dogru: 85, yanlis: 12, bos: 3), // 82 net
      );

      expect(deneme.toplamNet, 157.0);

      // K = 0.4 * 75 + 0.6 * 82 = 30 + 49.2 = 79.2
      expect(deneme.klinikAgirlikliPuan, closeTo(79.2, 0.01));

      // T = 0.6 * 75 + 0.4 * 82 = 45 + 32.8 = 77.8
      expect(deneme.temelAgirlikliPuan, closeTo(77.8, 0.01));

      // 85 EBAP tavan formülü geçerli TUS puanı üretir
      expect(deneme.tahminiEbapPuani, greaterThanOrEqualTo(45.0));
      expect(deneme.tahminiEbapPuani, lessThanOrEqualTo(85.0));
    });
  });

  group('A–F Hata Sınıfları ve Güven Matrisi', () {
    test('Emin + Yanlış sorusu hiperdüzeltme alarmı tetikler', () {
      const soru = DenemeSorusu(
        id: 's1',
        soruNo: 14,
        oturumTemelMi: true,
        guven: GuvenSeviyesi.emin,
        dogruMu: false,
        hataSinifi: HataSinifi.b,
        celdirici: 'PSC',
        ayiranKriter: 'AMA pozitifliği',
      );

      expect(soru.hiperDuzeltmeGerektirir, isTrue);
    });

    test('Emin + Doğru sorusu hiperdüzeltme tetiklemez', () {
      const soru = DenemeSorusu(
        id: 's2',
        soruNo: 15,
        oturumTemelMi: true,
        guven: GuvenSeviyesi.emin,
        dogruMu: true,
      );

      expect(soru.hiperDuzeltmeGerektirir, isFalse);
    });

    test('Kalibrasyon farkı ve hata dağılımı doğru hesaplanır', () {
      final deneme = DenemeSinavi(
        id: 'd2',
        ad: 'TUSEM Deneme',
        tarih: DateTime(2026, 11, 2),
        soruHatalari: const [
          DenemeSorusu(
            id: '1',
            soruNo: 1,
            oturumTemelMi: true,
            guven: GuvenSeviyesi.emin,
            dogruMu: true,
          ),
          DenemeSorusu(
            id: '2',
            soruNo: 2,
            oturumTemelMi: true,
            guven: GuvenSeviyesi.emin,
            dogruMu: false,
            hataSinifi: HataSinifi.b,
          ),
          DenemeSorusu(
            id: '3',
            soruNo: 3,
            oturumTemelMi: false,
            guven: GuvenSeviyesi.kararsiz,
            dogruMu: false,
            hataSinifi: HataSinifi.c,
          ),
        ],
      );

      expect(deneme.hiperDuzeltmeSayisi, 1);
      expect(deneme.hataDagilimi[HataSinifi.b], 1);
      expect(deneme.hataDagilimi[HataSinifi.c], 1);
      expect(deneme.hataDagilimi[HataSinifi.a], 0);

      // 2 Emin sorudan 1'i doğru: %50 doğruluk
      expect(deneme.eminDogrulukOrani, 50.0);
    });
  });

  group('PlanDeposu Deneme Entegrasyonu', () {
    test('deneme eklenir, güncellenir, silinir ve kalıcı olarak saklanır', () async {
      final depo = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
      await depo.yukle();
      expect(depo.denemeler, isEmpty);

      final deneme = DenemeSinavi(
        id: 'test-1',
        ad: 'Deneme 1',
        tarih: DateTime(2026, 11, 3),
        temel: const DenemeOturumu(dogru: 70, yanlis: 20, bos: 10),
        klinik: const DenemeOturumu(dogru: 75, yanlis: 15, bos: 10),
      );

      await depo.denemeEkle(deneme);
      expect(depo.denemeler.length, 1);
      expect(depo.denemeBul('test-1')?.ad, 'Deneme 1');

      // Güncelleme
      final guncel = DenemeSinavi(
        id: 'test-1',
        ad: 'Deneme 1 (Düzeltildi)',
        tarih: deneme.tarih,
        temel: const DenemeOturumu(dogru: 72, yanlis: 18, bos: 10),
        klinik: deneme.klinik,
      );
      await depo.denemeGuncelle(guncel);
      expect(depo.denemeBul('test-1')?.ad, 'Deneme 1 (Düzeltildi)');
      expect(depo.denemeBul('test-1')?.temel.dogru, 72);

      // Silme
      await depo.denemeSil('test-1');
      expect(depo.denemeler, isEmpty);
    });
  });
}
