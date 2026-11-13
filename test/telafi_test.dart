import 'package:app/core/tarih.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/takvim/calisma.dart';
import 'package:app/features/takvim/telafi_plani.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Telafi Planı ve Erteleme Birim Testleri', () {
    test('tekrarErtele tek bir tekrarı ve sonraki tekrarları kaydırır', () async {
      final kayit = BellekKaydi();
      final depo = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
      await depo.yukle();
      final sinav = DateTime(2027, 4, 1);
      await depo.karsilamayiTamamla(
        sinavTarihi: sinav,
        secilenDersler: const [HazirDers('Fizyoloji', DersGrubu.temel)],
      );
      final ders = depo.tumDersler.single;
      final konu = depo.konuEkle(ders.id, 'Hücre fizyolojisi')!;

      final calismaGunu = DateTime(2026, 10, 16);
      final c = depo.calismaEkle(konu.id, calismaGunu)!;
      depo.calistim(c.id, calismaGunu);

      // İlk tekrarlar
      var tekrarlar = depo.tekrarlar(calismaGunu);
      final r1 = tekrarlar.firstWhere((t) => t.calismaId == c.id && t.no == 1);
      final r2 = tekrarlar.firstWhere((t) => t.calismaId == c.id && t.no == 2);
      expect(r1.tarih, DateTime(2026, 10, 17)); // G+1
      expect(r2.tarih, DateTime(2026, 10, 23)); // G+7

      // R1'i 2 gün ertele (19 Ekim'e)
      final basarili = depo.tekrarErtele(c.id, 1, DateTime(2026, 10, 19), calismaGunu);
      expect(basarili, isTrue);

      tekrarlar = depo.tekrarlar(calismaGunu);
      final r1Yeni = tekrarlar.firstWhere((t) => t.calismaId == c.id && t.no == 1);
      final r2Yeni = tekrarlar.firstWhere((t) => t.calismaId == c.id && t.no == 2);

      expect(r1Yeni.tarih, DateTime(2026, 10, 19));
      // Gecikme kayması kuralı: sonraki tekrar da 2 gün kaymalı (23 -> 25 Ekim)
      expect(r2Yeni.tarih, DateTime(2026, 10, 25));
    });

    test('telafiPlani geciken çalışmaları günlük sınıra göre yayar', () {
      final bugun = DateTime(2026, 10, 20);
      final gecmis1 = DateTime(2026, 10, 15);
      final gecmis2 = DateTime(2026, 10, 16);
      final gecmis3 = DateTime(2026, 10, 17);

      final calismalar = [
        Calisma(id: 1, konuId: 101, tarih: gecmis1, tamam: false),
        Calisma(id: 2, konuId: 102, tarih: gecmis2, tamam: false),
        Calisma(id: 3, konuId: 103, tarih: gecmis3, tamam: false),
      ];

      // Günlük yeni konu sınırı = 2
      final plan = telafiPlaniHesapla(
        calismalar: calismalar,
        bugun: bugun,
        sonGun: DateTime(2027, 4, 1),
        gunlukYeniKonuSiniri: 2,
        gunlukTekrarSiniri: 10,
      );

      expect(plan.calismaSayisi, 3);
      // İlk 2 çalışma bugüne (20 Ekim), 3. çalışma ertesi güne (21 Ekim)
      expect(plan.yeniGunler[1], DateTime(2026, 10, 20));
      expect(plan.yeniGunler[2], DateTime(2026, 10, 20));
      expect(plan.yeniGunler[3], DateTime(2026, 10, 21));
    });

    test('depo.telafiPlaniUygula geciken işleri tek seferde önümüzdeki günlere taşır', () async {
      final kayit = BellekKaydi();
      final depo = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
      await depo.yukle();
      final sinav = DateTime(2027, 4, 1);
      await depo.karsilamayiTamamla(
        sinavTarihi: sinav,
        secilenDersler: const [HazirDers('Anatomi', DersGrubu.temel)],
      );
      final ders = depo.tumDersler.single;
      final k1 = depo.konuEkle(ders.id, 'Kemikler')!;
      final k2 = depo.konuEkle(ders.id, 'Eklemler')!;

      final gecmis = DateTime(2026, 10, 15);
      final bugun = DateTime(2026, 10, 20);

      depo.calismaEkle(k1.id, gecmis);
      depo.calismaEkle(k2.id, gecmis);

      expect(depo.calismalarGun(gecmis).length, 2);

      final tasinanSayisi = depo.telafiPlaniUygula(bugun);
      expect(tasinanSayisi, 2);
      expect(depo.calismalarGun(gecmis), isEmpty);
      expect(depo.calismalarGun(bugun).length, 2);
    });
  });
}
