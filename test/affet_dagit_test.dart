// "Tekrarları affet & dağıt" (25 Kasım 2026 kararı): geciken tekrar yapılmış
// SAYILMAZ, önümüzdeki günlere dağıtılır. Önce kanıt testiydi (KANIT-17).

import 'package:app/core/tarih.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('geciken tekrar yapılmış sayılmaz, bugünden itibaren dağıtılır',
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

    final once = depo
        .tekrarlar(bugun)
        .firstWhere((t) => t.calismaId == calisma.id && t.no == 1);
    expect(once.tarih.isBefore(bugun), isTrue, reason: 'R1 gecikmiş olmalı');

    final sayi = depo.gecikenTekrarlariDagit(bugun);
    final sonra = depo
        .tekrarlar(bugun)
        .firstWhere((t) => t.calismaId == calisma.id && t.no == 1);

    expect(sayi, 1);
    expect(sonra.yapildi, isFalse);
    expect(sonra.tarih.isBefore(bugun), isFalse);
  });
}
