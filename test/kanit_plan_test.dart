// KANIT TESTLERİ (yalnızca son dal: plan ve tekrar akışları)
//
// Testler bilerek "olması gereken" davranışı ister; BAŞARISIZ olan test,
// raporlanan hatanın gerçekten var olduğunu gösterir.
// Uygulama kodu değiştirilmedi; yalnızca test dosyası eklendi.

import 'package:app/core/tarih.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'KANIT-17 "Tekrarları affet & dağıt" geciken tekrarı yapılmış sayıyor',
    () async {
      final bugun = gunBasi(DateTime.now());
      final depo = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
      await depo.yukle();
      await depo.karsilamayiTamamla(
        sinavTarihi: gunEkle(bugun, 300),
        secilenDersler: const [HazirDers('Patoloji', DersGrubu.temel)],
        mufredatTuru: MufredatTuru.klasik,
      );
      final konu = depo.konuEkle(depo.tumDersler.first.id, 'Geciken konu')!;
      final besGunOnce = gunEkle(bugun, -5);
      final calisma = depo.calismaEkle(konu.id, besGunOnce)!;
      expect(depo.calistim(calisma.id, besGunOnce), isTrue);

      // Bugün ekranındaki düğme bunu çağırıyor ve
      // "... geciken tekrar bugünden itibaren yeniden dağıtıldı." diyor.
      final sayi = depo.gecikenTekrarlariSifirla(bugun);
      final r1 = depo
          .tekrarlar(bugun)
          .firstWhere((t) => t.calismaId == calisma.id && t.no == 1);

      expect(
        {'işlenen': sayi, 'R1 yapıldı sayılıyor': r1.yapildi},
        {'işlenen': 1, 'R1 yapıldı sayılıyor': false},
        reason: 'Mesaj "yeniden dağıtıldı" diyor ama kod tekrarı bugün '
            'YAPILDI olarak kaydediyor; tekrar hiç yapılmadan zincirden '
            'düşüyor, toplam tekrar sayısı ve seri şişiyor.',
      );
    },
  );
}
