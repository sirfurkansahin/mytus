import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/ft_time/ft_oturum.dart';
import 'package:app/features/ft_time/ft_timer.dart';
import 'package:flutter_test/flutter_test.dart';

const int dk = 60 * 1000;
final int t0 = DateTime(2026, 10, 16, 10).millisecondsSinceEpoch;

/// Bir bölümü baştan sona yaşatır: başlat, süre dolsun, güncelle.
FtOturum bolumuBitir(FtOturum o, int baslangic) {
  final basladi = o.baslat(baslangic);
  final bitis = basladi.sayac.endAtMs!;
  return basladi.guncelle(bitis + 1);
}

void main() {
  group('FtAyarlari', () {
    test('varsayılanlar onaylı kural: 25 / 5 / 15, her 4 döngüde uzun mola', () {
      const a = FtAyarlari();
      expect(a.calismaDk, 25);
      expect(a.kisaMolaDk, 5);
      expect(a.uzunMolaDk, 15);
      expect(a.uzunMolaAraligi, 4);
    });

    test('toplam süre tasarımdaki örnekle uyuşur (4 döngü = 1 sa 55 dk)', () {
      const a = FtAyarlari();
      expect(a.toplamDakika(4), 115);
      expect(dakikaYaz(115), '1 sa 55 dk');
      expect(a.toplamDakika(1), 25);
      // 5. döngüye kadar: 4. döngüden sonra uzun mola araya girer.
      expect(a.toplamDakika(5), 5 * 25 + 5 + 5 + 5 + 15);
    });

    test('sınırlar dışındaki değerler kırpılır, bozuk veri varsayılana döner', () {
      final a = const FtAyarlari().kopya(calismaDk: 0, kisaMolaDk: 999, donguSayisi: 50);
      expect(a.calismaDk, FtAyarlari.calismaEnAz);
      expect(a.kisaMolaDk, FtAyarlari.molaEnCok);
      expect(a.donguSayisi, FtAyarlari.donguEnCok);
      expect(FtAyarlari.fromJson('bozuk').calismaDk, 25);
      expect(FtAyarlari.fromJson({'calismaDk': 'x'}).calismaDk, 25);
      expect(FtAyarlari.fromJson(a.toJson()).kisaMolaDk, FtAyarlari.molaEnCok);
    });

    test('dakikaYaz', () {
      expect(dakikaYaz(45), '45 dk');
      expect(dakikaYaz(120), '2 sa');
      expect(dakikaYaz(61), '1 sa 1 dk');
    });
  });

  group('FtOturum akışı', () {
    test('çalışma, mola, çalışma sırası ve son döngüden sonra mola yok', () {
      var o = FtOturum.yeni(id: 1, toplamDongu: 2, ayar: const FtAyarlari());
      expect(o.faz, FtFaz.calisma);
      expect(o.dongu, 1);
      expect(o.sayac.durationMs, 25 * dk);
      expect(o.ilerlenebilir, isFalse);

      o = bolumuBitir(o, t0);
      expect(o.bolumBitti, isTrue);
      expect(o.tamamlananDongu, 1);
      expect(o.tamamlandi, isFalse);

      o = o.ilerle()!;
      expect(o.faz, FtFaz.kisaMola);
      expect(o.dongu, 1);
      expect(o.sayac.durationMs, 5 * dk);
      expect(o.tamamlananDongu, 1);

      o = bolumuBitir(o, t0 + 40 * dk);
      o = o.ilerle()!;
      expect(o.faz, FtFaz.calisma);
      expect(o.dongu, 2);
      expect(o.tamamlananDongu, 1);

      o = bolumuBitir(o, t0 + 80 * dk);
      expect(o.tamamlandi, isTrue);
      expect(o.tamamlananDongu, 2);
      expect(o.kazanilanDakika, 50);
      expect(o.ilerle(), isNull);
    });

    test('her 4. döngüden sonra uzun mola gelir', () {
      var o = FtOturum.yeni(id: 1, toplamDongu: 5, ayar: const FtAyarlari());
      final molalar = <FtFaz>[];
      var t = t0;
      for (var i = 0; i < 4; i++) {
        o = bolumuBitir(o, t);
        t += 30 * dk;
        o = o.ilerle()!;
        molalar.add(o.faz);
        expect(o.dongu, i + 1);
        o = bolumuBitir(o, t);
        t += 20 * dk;
        o = o.ilerle()!;
      }
      expect(molalar, [
        FtFaz.kisaMola,
        FtFaz.kisaMola,
        FtFaz.kisaMola,
        FtFaz.uzunMola,
      ]);
      expect(o.sayac.durationMs, 25 * dk);
      expect(o.dongu, 5);
    });

    test('molayı atlamak sonraki çalışmaya geçirir; çalışmada atlanamaz', () {
      var o = FtOturum.yeni(id: 1, toplamDongu: 3, ayar: const FtAyarlari());
      expect(o.molayiAtla(), isNull);
      o = bolumuBitir(o, t0).ilerle()!;
      expect(o.faz, FtFaz.kisaMola);
      o = o.baslat(t0 + 30 * dk);
      final atlandi = o.molayiAtla()!;
      expect(atlandi.faz, FtFaz.calisma);
      expect(atlandi.dongu, 2);
      expect(atlandi.sayac.phase, FtPhase.bosta);
    });

    test('yarım kalan döngü puan saymaz', () {
      var o = FtOturum.yeni(id: 1, toplamDongu: 4, ayar: const FtAyarlari());
      o = bolumuBitir(o, t0).ilerle()!;
      o = bolumuBitir(o, t0 + 30 * dk).ilerle()!;
      expect(o.dongu, 2);
      o = o.baslat(t0 + 60 * dk).guncelle(t0 + 70 * dk);
      expect(o.bolumBitti, isFalse);
      expect(o.tamamlananDongu, 1);
      expect(o.kazanilanDakika, 25);
    });

    test('ayar sonradan değişse de oturum süreleri sabit kalır', () {
      final o = FtOturum.yeni(
        id: 1,
        toplamDongu: 2,
        ayar: const FtAyarlari(calismaDk: 10, kisaMolaDk: 2),
      );
      expect(o.sayac.durationMs, 10 * dk);
      expect(bolumuBitir(o, t0).ilerle()!.sayac.durationMs, 2 * dk);
    });

    test('kayıt ve geri yükleme; bozuk kayıt null döner', () {
      var o = FtOturum.yeni(id: 7, toplamDongu: 3, ayar: const FtAyarlari(), konuId: 4);
      o = bolumuBitir(o, t0).ilerle()!.baslat(t0 + 30 * dk);
      final geri = FtOturum.fromJson(o.toJson())!;
      expect(geri.id, 7);
      expect(geri.konuId, 4);
      expect(geri.faz, FtFaz.kisaMola);
      expect(geri.sayac.phase, FtPhase.calisiyor);
      expect(geri.sayac.endAtMs, o.sayac.endAtMs);
      expect(FtOturum.fromJson({'id': 1}), isNull);
      expect(FtOturum.fromJson('x'), isNull);
      expect(o.konuSiz().konuId, isNull);
    });
  });

  group('Depo: puan ve oturum', () {
    Future<({PlanDeposu depo, BellekKaydi kayit, int konuId})> hazirla() async {
      final kayit = BellekKaydi();
      final depo = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
      await depo.yukle();
      await depo.karsilamayiTamamla(
        sinavTarihi: DateTime(2027, 4, 1),
        secilenDersler: const [HazirDers('Fizyoloji', DersGrubu.temel)],
      );
      final ders = depo.dersler(DersGrubu.temel).single;
      return (depo: depo, kayit: kayit, konuId: depo.konuEkle(ders.id, 'Kalp')!.id);
    }

    test('biten çalışma bölümü puanlanır, aynı döngü iki kez puanlanmaz', () async {
      final h = await hazirla();
      final o = h.depo.oturumBaslat(toplamDongu: 2, konuId: h.konuId);
      h.depo.oturumGuncelle(o.baslat(t0));
      expect(h.depo.toplamPuan, 0);

      final bitis = t0 + 25 * dk;
      expect(h.depo.oturumuTazele(bitis - 1), isFalse);
      expect(h.depo.oturumuTazele(bitis + 1000), isTrue);
      expect(h.depo.toplamPuan, 25);
      expect(h.depo.odaklar.single.konuId, h.konuId);
      // Tekrar tazelemek ve aynı durumu yeniden kaydetmek puanı artırmaz.
      expect(h.depo.oturumuTazele(bitis + 5000), isFalse);
      h.depo.oturumGuncelle(h.depo.oturum!);
      expect(h.depo.toplamPuan, 25);
    });

    test('mola puan getirmez, ikinci döngü ayrı puanlanır', () async {
      final h = await hazirla();
      var o = h.depo.oturumBaslat(toplamDongu: 2);
      o = bolumuBitir(o, t0);
      h.depo.oturumGuncelle(o);
      o = bolumuBitir(o.ilerle()!, t0 + 30 * dk);
      h.depo.oturumGuncelle(o);
      expect(h.depo.toplamPuan, 25);
      o = bolumuBitir(o.ilerle()!, t0 + 60 * dk);
      h.depo.oturumGuncelle(o);
      expect(h.depo.toplamPuan, 50);
      expect(h.depo.oturum!.tamamlandi, isTrue);
    });

    test('gün ve hafta puanı tarihe göre toplanır', () async {
      final h = await hazirla();
      // Cuma 16 Ekim 2026'da bitti.
      var o = h.depo.oturumBaslat(toplamDongu: 1);
      o = bolumuBitir(o, DateTime(2026, 10, 16, 10).millisecondsSinceEpoch);
      h.depo.oturumGuncelle(o);
      expect(h.depo.puanGun(DateTime(2026, 10, 16)), 25);
      expect(h.depo.puanGun(DateTime(2026, 10, 17)), 0);
      expect(h.depo.puanHafta(DateTime(2026, 10, 16)), 25);
      expect(h.depo.puanHafta(DateTime(2026, 10, 12)), 25); // aynı haftanın pazartesisi
      expect(h.depo.puanHafta(DateTime(2026, 10, 19)), 0); // sonraki hafta
    });

    test('oturum ve puanlar kayıttan aynen geri gelir', () async {
      final h = await hazirla();
      h.depo.ftAyarBelirle(const FtAyarlari(calismaDk: 30, donguSayisi: 3));
      h.depo.turSayisiBelirle(3);
      h.depo.gunlukSinirBelirle(8);
      var o = h.depo.oturumBaslat(toplamDongu: 2, konuId: h.konuId);
      o = bolumuBitir(o, t0);
      h.depo.oturumGuncelle(o.ilerle()!.baslat(t0 + 40 * dk));
      await h.depo.hemenKaydet();

      final yeni = PlanDeposu(kayit: h.kayit, kayitGecikmesi: Duration.zero);
      await yeni.yukle();
      expect(yeni.ftAyar.calismaDk, 30);
      expect(yeni.ftAyar.donguSayisi, 3);
      expect(yeni.turSayisi, 3);
      expect(yeni.gunlukTekrarSiniri, 8);
      expect(yeni.toplamPuan, 30);
      expect(yeni.oturum!.faz, FtFaz.kisaMola);
      expect(yeni.oturum!.sayac.phase, FtPhase.calisiyor);
      // Yeni oturum numarası eskisiyle çakışmaz.
      final sonraki = yeni.oturumBaslat(toplamDongu: 1);
      expect(sonraki.id, greaterThan(h.depo.oturum!.id));
    });

    test('konu silinince oturum ve kayıtlar konusuz kalır, puan silinmez', () async {
      final h = await hazirla();
      var o = h.depo.oturumBaslat(toplamDongu: 2, konuId: h.konuId);
      o = bolumuBitir(o, t0);
      h.depo.oturumGuncelle(o);
      h.depo.konuSil(h.konuId);
      expect(h.depo.oturum!.konuId, isNull);
      expect(h.depo.odaklar.single.konuId, isNull);
      expect(h.depo.toplamPuan, 25);
    });

    test('oturumKapat oturumu kaldırır, puan kalır', () async {
      final h = await hazirla();
      final o = bolumuBitir(h.depo.oturumBaslat(toplamDongu: 1), t0);
      h.depo.oturumGuncelle(o);
      h.depo.oturumKapat();
      expect(h.depo.oturum, isNull);
      expect(h.depo.toplamPuan, 25);
    });

    test('olmayan konu seçilirse oturum konusuz açılır', () async {
      final h = await hazirla();
      expect(h.depo.oturumBaslat(toplamDongu: 1, konuId: 9999).konuId, isNull);
    });

    test('ayar sınırları', () async {
      final h = await hazirla();
      h.depo.turSayisiBelirle(99);
      expect(h.depo.turSayisi, 5);
      h.depo.turSayisiBelirle(0);
      expect(h.depo.turSayisi, 1);
      h.depo.gunlukSinirBelirle(1);
      expect(h.depo.gunlukTekrarSiniri, 3);
      h.depo.gunlukSinirBelirle(500);
      expect(h.depo.gunlukTekrarSiniri, 30);
    });

    test('odak sonrası Çalıştım: bekleyen yerleştirme bugüne alınır', () async {
      final h = await hazirla();
      final bugun = DateTime(2026, 10, 16);
      final c = h.depo.calismaEkle(h.konuId, DateTime(2026, 10, 20))!;
      expect(h.depo.konuCalistimIsaretle(h.konuId, bugun), isTrue);
      final guncel = h.depo.calismaBul(c.id)!;
      expect(guncel.tamam, isTrue);
      expect(guncel.tarih, bugun);
      expect(h.depo.calismalarKonu(h.konuId).length, 1);
    });

    test('odak sonrası Çalıştım: yerleştirme yoksa bugüne yenisi açılır', () async {
      final h = await hazirla();
      final bugun = DateTime(2026, 10, 16);
      expect(h.depo.konuCalistimIsaretle(h.konuId, bugun), isTrue);
      final c = h.depo.calismalarKonu(h.konuId).single;
      expect(c.tamam, isTrue);
      expect(c.tarih, bugun);
      expect(h.depo.konuCalistimIsaretle(9999, bugun), isFalse);
    });
  });
}
