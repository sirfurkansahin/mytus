// Puan her yerde Seçenek C (25 Kasım 2026 kararı): 1 konu = 10, 1 soru = 1.
// Odak süresi puana çevrilmez.

import 'package:app/core/tarih.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/ilerleme/ilerleme_hesabi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('haftalık özet puanı konu ve sorudan gelir, odak dakikasından değil',
      () async {
    final depo = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
    await depo.yukle();
    final bugun = gunBasi(DateTime.now());
    final ders = depo.dersEkle('Farmakoloji', DersGrubu.temel)!;
    final konu = depo.konuEkle(ders.id, 'Antibiyotikler')!;

    // 25 dakikalık bir odak döngüsü: puan getirmemeli.
    final su = DateTime.now().millisecondsSinceEpoch;
    var o = depo.oturumBaslat(toplamDongu: 1, konuId: konu.id);
    o = o.baslat(su - 30 * 60 * 1000).guncelle(su);
    depo.oturumGuncelle(o);
    depo.oturumKapat();

    var ozet = haftaOzetiHesapla(depo, bugun);
    expect(ozet.odakDakika, greaterThan(0));
    expect(ozet.puan, 0);

    // Bir konu bitir + 7 soru çöz: 10 + 7 = 17 puan.
    final c = depo.calismaEkle(konu.id, bugun)!;
    expect(depo.calistim(c.id, bugun), isTrue);
    depo.soruEkle(bugun, 7);

    ozet = haftaOzetiHesapla(depo, bugun);
    expect(ozet.puan, 17);
    expect(ozet.puan, depo.haftalikGrupPuani(bugun));
  });
}
