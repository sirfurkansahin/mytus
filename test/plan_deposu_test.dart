import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/hazir_dersler.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter_test/flutter_test.dart';

PlanDeposu yeniDepo(BellekKaydi kayit) =>
    PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);

Future<PlanDeposu> hazirDepo([BellekKaydi? kayit]) async {
  final depo = yeniDepo(kayit ?? BellekKaydi());
  await depo.yukle();
  return depo;
}

void main() {
  group('yükleme', () {
    test('kayıt yoksa boş ve karşılama tamamlanmamış açılır', () async {
      final d = await hazirDepo();
      expect(d.durum, YuklemeDurumu.hazir);
      expect(d.karsilamaTamam, isFalse);
      expect(d.sinavTarihi, isNull);
      expect(d.dersler(DersGrubu.temel), isEmpty);
    });

    test('okuma hatasında hata durumuna geçer', () async {
      final d = yeniDepo(BellekKaydi(okumaHatasi: true));
      await d.yukle();
      expect(d.durum, YuklemeDurumu.hata);
    });

    test('bozuk dosyada hata verir ve üstüne yazmaz', () async {
      final kayit = BellekKaydi(icerik: 'bozuk{');
      final d = yeniDepo(kayit);
      await d.yukle();
      expect(d.durum, YuklemeDurumu.hata);
      expect(kayit.yazmaSayisi, 0);
      expect(kayit.icerik, 'bozuk{');
    });
  });

  group('karşılama', () {
    test('tarih ve seçilen dersleri kaydeder, hazır liste doğru', () async {
      final d = await hazirDepo();
      await d.karsilamayiTamamla(
        sinavTarihi: DateTime(2027, 4, 1, 15, 30),
        secilenDersler: hazirDersler,
      );
      expect(d.karsilamaTamam, isTrue);
      expect(d.sinavTarihi, DateTime(2027, 4, 1));
      expect(d.dersler(DersGrubu.temel).length, 7);
      expect(d.dersler(DersGrubu.klinik).length, 4);
    });
  });

  group('ders', () {
    test('ekleme adı temizler, boş ve tekrar edeni reddeder', () async {
      final d = await hazirDepo();
      final a = d.dersEkle('  Anatomi   ', DersGrubu.temel);
      expect(a, isNotNull);
      expect(a!.ad, 'Anatomi');
      expect(d.dersEkle('   ', DersGrubu.temel), isNull);
      expect(d.dersEkle('anatomi', DersGrubu.temel), isNull);
      // Aynı ad başka grupta olabilir.
      expect(d.dersEkle('Anatomi', DersGrubu.klinik), isNotNull);
    });

    test('silince konuları da gider', () async {
      final d = await hazirDepo();
      final ders = d.dersEkle('Fizyoloji', DersGrubu.temel)!;
      d.konuEkle(ders.id, 'Kalp döngüsü');
      d.konuEkle(ders.id, 'Böbrek');
      expect(d.konuSayisi(ders.id), 2);
      d.dersSil(ders.id);
      expect(d.dersBul(ders.id), isNull);
      expect(d.konular(ders.id), isEmpty);
    });

    test('ad değiştirme: boş ve çakışan ad reddedilir', () async {
      final d = await hazirDepo();
      final a = d.dersEkle('Anatomi', DersGrubu.temel)!;
      d.dersEkle('Fizyoloji', DersGrubu.temel);
      expect(d.dersAdiDegistir(a.id, ''), isFalse);
      expect(d.dersAdiDegistir(a.id, 'fizyoloji'), isFalse);
      expect(d.dersAdiDegistir(a.id, 'Genel Anatomi'), isTrue);
      expect(d.dersBul(a.id)!.ad, 'Genel Anatomi');
    });
  });

  group('konu ve not', () {
    test('ekleme, çift ve boş ad, silme', () async {
      final d = await hazirDepo();
      final ders = d.dersEkle('Fizyoloji', DersGrubu.temel)!;
      final k = d.konuEkle(ders.id, 'Kalp döngüsü');
      expect(k, isNotNull);
      expect(d.konuEkle(ders.id, 'kalp döngüsü'), isNull);
      expect(d.konuEkle(ders.id, ' '), isNull);
      expect(d.konuEkle(9999, 'Olmayan ders'), isNull);
      d.konuSil(k!.id);
      expect(d.konuSayisi(ders.id), 0);
    });

    test('not yazılır ve kaydedilir', () async {
      final kayit = BellekKaydi();
      final d = await hazirDepo(kayit);
      final ders = d.dersEkle('Fizyoloji', DersGrubu.temel)!;
      final k = d.konuEkle(ders.id, 'Kalp döngüsü')!;
      d.notYaz(k.id, 'Sistol ve diyastol');
      await d.hemenKaydet();
      expect(d.konuBul(k.id)!.not, 'Sistol ve diyastol');
      expect(kayit.icerik, contains('Sistol ve diyastol'));
    });

    test('hiç çalışılmamış konu çalışıldı sayısına girmez', () async {
      final d = await hazirDepo();
      final ders = d.dersEkle('Fizyoloji', DersGrubu.temel)!;
      d.konuEkle(ders.id, 'Kalp döngüsü');
      expect(d.calisilanSayisi(ders.id), 0);
    });
  });

  group('kalıcılık', () {
    test('kaydedilen veri yeni depoda aynen geri gelir', () async {
      final kayit = BellekKaydi();
      final d = await hazirDepo(kayit);
      await d.karsilamayiTamamla(
        sinavTarihi: DateTime(2027, 4, 1),
        secilenDersler: const [HazirDers('Anatomi', DersGrubu.temel)],
      );
      final ders = d.dersler(DersGrubu.temel).first;
      final k = d.konuEkle(ders.id, 'Üst ekstremite')!;
      d.notYaz(k.id, 'Plexus brachialis');
      await d.hemenKaydet();

      final d2 = await hazirDepo(kayit);
      expect(d2.karsilamaTamam, isTrue);
      expect(d2.sinavTarihi, DateTime(2027, 4, 1));
      expect(d2.dersler(DersGrubu.temel).single.ad, 'Anatomi');
      expect(d2.konular(ders.id).single.ad, 'Üst ekstremite');
      expect(d2.konular(ders.id).single.not, 'Plexus brachialis');
    });

    test('yeniden yüklenince yeni kayıtlar eski numaralarla çakışmaz', () async {
      final kayit = BellekKaydi();
      final d = await hazirDepo(kayit);
      final a = d.dersEkle('Anatomi', DersGrubu.temel)!;
      d.dersSil(a.id);
      await d.hemenKaydet();
      final d2 = await hazirDepo(kayit);
      final b = d2.dersEkle('Fizyoloji', DersGrubu.temel)!;
      expect(b.id, isNot(a.id));
    });

    test('dersi olmayan konu yüklenirken atılır', () async {
      final kayit = BellekKaydi(
        icerik:
            '{"surum":1,"sonId":5,"karsilamaTamam":true,"sinavTarihi":null,'
            '"dersler":[{"id":1,"ad":"Anatomi","grup":"temel"}],'
            '"konular":[{"id":2,"dersId":1,"ad":"Var","not":"x","ilkCalisma":null},'
            '{"id":3,"dersId":99,"ad":"Yetim","not":"","ilkCalisma":null}]}',
      );
      final d = await hazirDepo(kayit);
      expect(d.durum, YuklemeDurumu.hazir);
      expect(d.konular(1).length, 1);
      expect(d.konuBul(3), isNull);
    });
  });
}
