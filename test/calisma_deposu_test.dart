import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime bugun = DateTime(2026, 10, 16);

Future<({PlanDeposu depo, BellekKaydi kayit, int konuId, int dersId})>
    hazirla() async {
  final kayit = BellekKaydi();
  final depo = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
  await depo.yukle();
  await depo.karsilamayiTamamla(
    sinavTarihi: DateTime(2027, 4, 1),
    secilenDersler: const [HazirDers('Fizyoloji', DersGrubu.temel)],
  );
  final ders = depo.dersler(DersGrubu.temel).single;
  final konu = depo.konuEkle(ders.id, 'Kalp döngüsü')!;
  return (depo: depo, kayit: kayit, konuId: konu.id, dersId: ders.id);
}

void main() {
  test('konuyu yerleştirme, aynı konu ikinci kez de yerleştirilebilir', () async {
    final h = await hazirla();
    final a = h.depo.calismaEkle(h.konuId, DateTime(2026, 10, 16, 14, 30))!;
    final b = h.depo.calismaEkle(h.konuId, DateTime(2026, 12, 1))!;
    expect(a.tarih, DateTime(2026, 10, 16));
    expect(h.depo.calismalarGun(bugun).single.id, a.id);
    expect(h.depo.calismalarKonu(h.konuId).length, 2);
    expect(h.depo.turNo(a), 1);
    expect(h.depo.turNo(b), 2);
    expect(h.depo.calismaEkle(9999, bugun), isNull);
  });

  test('Çalıştım: tarih bugüne taşınır, konu çalışıldı sayılır', () async {
    final h = await hazirla();
    final c = h.depo.calismaEkle(h.konuId, DateTime(2026, 10, 12))!;
    expect(h.depo.konuCalisildi(h.konuId), isFalse);
    expect(h.depo.calisilanSayisi(h.dersId), 0);
    expect(h.depo.calistim(c.id, bugun), isTrue);
    expect(h.depo.calismaBul(c.id)!.tarih, bugun);
    expect(h.depo.calismaBul(c.id)!.tamam, isTrue);
    expect(h.depo.konuCalisildi(h.konuId), isTrue);
    expect(h.depo.ilkCalisma(h.konuId), bugun);
    expect(h.depo.calisilanSayisi(h.dersId), 1);
    // İkinci kez işaretlenemez.
    expect(h.depo.calistim(c.id, bugun), isFalse);
  });

  test('geciken çalışma bugüne alınır; çalışılmış olanın günü değişmez', () async {
    final h = await hazirla();
    final c = h.depo.calismaEkle(h.konuId, DateTime(2026, 10, 12))!;
    expect(h.depo.calismaGunuDegistir(c.id, bugun), isTrue);
    expect(h.depo.calismaBul(c.id)!.tarih, bugun);
    h.depo.calistim(c.id, bugun);
    expect(h.depo.calismaGunuDegistir(c.id, DateTime(2026, 10, 30)), isFalse);
  });

  test('tekrar sırayla yapılır, atlama ve çalışılmamış çalışma reddedilir', () async {
    final h = await hazirla();
    final c = h.depo.calismaEkle(h.konuId, bugun)!;
    expect(h.depo.tekrarYapildi(c.id, 1, bugun), isFalse); // çalışma bitmedi
    h.depo.calistim(c.id, bugun);
    expect(h.depo.tekrarYapildi(c.id, 2, bugun), isFalse); // 1 atlanamaz
    expect(h.depo.tekrarYapildi(c.id, 1, DateTime(2026, 10, 17)), isTrue);
    expect(h.depo.tekrarYapildi(c.id, 1, DateTime(2026, 10, 17)), isFalse);
    expect(h.depo.tekrarYapildi(c.id, 5, bugun), isFalse); // en çok 4
  });

  test('geç yapılan tekrar sonrakini kaydırır (depo üzerinden)', () async {
    final h = await hazirla();
    final c = h.depo.calismaEkle(h.konuId, bugun)!;
    h.depo.calistim(c.id, bugun);
    h.depo.tekrarYapildi(c.id, 1, DateTime(2026, 10, 19)); // 2 gün geç
    final liste = h.depo.tekrarlar(DateTime(2026, 10, 19));
    expect(liste.firstWhere((o) => o.no == 2).tarih, DateTime(2026, 10, 26));
  });

  test('tekrarı geri almak ondan sonrakileri de siler', () async {
    final h = await hazirla();
    final c = h.depo.calismaEkle(h.konuId, bugun)!;
    h.depo.calistim(c.id, bugun);
    h.depo.tekrarYapildi(c.id, 1, DateTime(2026, 10, 17));
    h.depo.tekrarYapildi(c.id, 2, DateTime(2026, 10, 24));
    expect(h.depo.tekrarGeriAl(c.id, 1), isTrue);
    expect(h.depo.calismaBul(c.id)!.tekrarlar, isEmpty);
    expect(h.depo.tekrarGeriAl(c.id, 1), isFalse);
  });

  test('Çalıştım geri alınınca tekrar kayıtları da silinir', () async {
    final h = await hazirla();
    final c = h.depo.calismaEkle(h.konuId, bugun)!;
    h.depo.calistim(c.id, bugun);
    h.depo.tekrarYapildi(c.id, 1, DateTime(2026, 10, 17));
    expect(h.depo.calismaGeriAl(c.id), isTrue);
    final k = h.depo.calismaBul(c.id)!;
    expect(k.tamam, isFalse);
    expect(k.tekrarlar, isEmpty);
  });

  test('konu veya ders silinince çalışmaları da silinir', () async {
    final h = await hazirla();
    h.depo.calismaEkle(h.konuId, bugun);
    h.depo.konuSil(h.konuId);
    expect(h.depo.tumCalismalar(), isEmpty);

    final konu2 = h.depo.konuEkle(h.dersId, 'Böbrek')!;
    h.depo.calismaEkle(konu2.id, bugun);
    h.depo.dersSil(h.dersId);
    expect(h.depo.tumCalismalar(), isEmpty);
  });

  test('çalışmalar ve ayarlar kayıttan aynen geri gelir', () async {
    final h = await hazirla();
    final c = h.depo.calismaEkle(h.konuId, bugun)!;
    h.depo.calistim(c.id, bugun);
    h.depo.tekrarYapildi(c.id, 1, DateTime(2026, 10, 18));
    await h.depo.hemenKaydet();

    final yeni = PlanDeposu(kayit: h.kayit, kayitGecikmesi: Duration.zero);
    await yeni.yukle();
    final k = yeni.calismaBul(c.id)!;
    expect(k.tamam, isTrue);
    expect(k.tarih, bugun);
    expect(k.tekrarKaydi(1)!.tarih, DateTime(2026, 10, 18));
    expect(yeni.turSayisi, 2);
    expect(yeni.gunlukTekrarSiniri, 10);
    // Yeni kayıtlar eski numaralarla çakışmaz.
    final c2 = yeni.calismaEkle(h.konuId, bugun)!;
    expect(c2.id, isNot(c.id));
  });

  test('sınav tarihi yoksa tekrar listesi boş', () async {
    final depo = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
    await depo.yukle();
    expect(depo.tekrarlar(bugun), isEmpty);
  });
}
