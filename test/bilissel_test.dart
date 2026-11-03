import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/bilissel/modeller.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/ft_time/odak_kaydi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Nörobiyoloji ve Sirkadiyen Modelleri', () {
    test('Dairesel saat farkı gece yarısı geçişlerini doğru hesaplar', () {
      expect(daireselDakikaFarki('23:50', '00:10'), 20);
      expect(daireselDakikaFarki('23:00', '23:30'), 30);
      expect(daireselDakikaFarki('07:30', '08:00'), 30);
      expect(daireselDakikaFarki('01:15', '23:45'), 90);
    });

    test('8 saat öncesi kafein kesilme saati kuralı doğru hesaplanır', () {
      expect(kafeinKesilmeSaatiHesapla('23:30'), '15:30');
      expect(kafeinKesilmeSaatiHesapla('00:00'), '16:00');
      expect(kafeinKesilmeSaatiHesapla('22:15'), '14:15');
      expect(kafeinKesilmeSaatiHesapla('01:00'), '17:00');
    });

    test('UykuKaydi sapma ve sirkadiyen uyum kriterleri', () {
      final kayit = UykuKaydi(
        tarih: '2026-11-03',
        uykuSuresiDakika: 480, // 8 saat
        yatisSaati: '23:45',
        kalkisSaati: '07:45',
        hedefYatisSaati: '23:30',
        kalite: 5,
      );

      expect(kayit.uykuSuresiSaat, 8.0);
      expect(kayit.yatisSapmasiDakika, 15);
      expect(kayit.yatisSaatiDengeli, isTrue); // <= 30 dk
      expect(kayit.sureDengeli, isTrue); // 7 - 9 saat
      expect(kayit.sirkadiyenUyumlu, isTrue);
      expect(kayit.tavsiyeEdilenSonKafein, '15:45');

      final bozukKayit = UykuKaydi(
        tarih: '2026-11-04',
        uykuSuresiDakika: 330, // 5.5 saat
        yatisSaati: '01:30',
        kalkisSaati: '07:00',
        hedefYatisSaati: '23:30',
      );

      expect(bozukKayit.yatisSapmasiDakika, 120);
      expect(bozukKayit.yatisSaatiDengeli, isFalse);
      expect(bozukKayit.sureDengeli, isFalse);
      expect(bozukKayit.sirkadiyenUyumlu, isFalse);
    });

    test('UykuKaydi JSON serileştirme ve geri yükleme', () {
      final kayit = UykuKaydi(
        tarih: '2026-11-03',
        uykuSuresiDakika: 450,
        yatisSaati: '23:15',
        kalkisSaati: '06:45',
        hedefYatisSaati: '23:00',
        sonKafeinSaati: '14:30',
        kalite: 4,
      );

      final json = kayit.toJson();
      final geri = UykuKaydi.fromJson(json);

      expect(geri.tarih, kayit.tarih);
      expect(geri.uykuSuresiDakika, 450);
      expect(geri.yatisSaati, '23:15');
      expect(geri.sonKafeinSaati, '14:30');
      expect(geri.kalite, 4);
    });
  });

  group('OdakKaydi ve Bilişsel Tavan', () {
    test('OdakKaydi varsayılan değerleri ve kopyalama', () {
      const o = OdakKaydi(
        anahtar: '1:1',
        tarihMs: 1000000,
        dakika: 45,
      );

      expect(o.odakPuani, 4);
      expect(o.zorBilissel, isTrue);

      final guncel = o.kopyala(odakPuani: 5, zorBilissel: false);
      expect(guncel.odakPuani, 5);
      expect(guncel.zorBilissel, isFalse);
      expect(guncel.dakika, 45);
    });

    test('PlanDeposu zor bilişsel iş tavanı (180-240 dk) ve odak ortalaması', () async {
      final depo = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
      await depo.yukle();

      final bugunMs = DateTime.now().millisecondsSinceEpoch;

      // 3 blok x 50 dk = 150 dk ağır iş
      for (var i = 1; i <= 3; i++) {
        await depo.sonOdakGuncelle(
          anahtar: 'oturum:$i',
          odakPuani: 4,
          zorBilissel: true,
        );
      }

      // Manuel olarak odak kayıtları ekleyelim test için
      final json = depo.toJson();
      final odaklar = [
        {
          'anahtar': 'o:1',
          'tarihMs': bugunMs,
          'dakika': 50,
          'odakPuani': 5,
          'zorBilissel': true,
        },
        {
          'anahtar': 'o:2',
          'tarihMs': bugunMs,
          'dakika': 60,
          'odakPuani': 4,
          'zorBilissel': true,
        },
        {
          'anahtar': 'o:3',
          'tarihMs': bugunMs,
          'dakika': 50,
          'odakPuani': 3,
          'zorBilissel': false, // Hafif iş
        },
      ];
      json['odaklar'] = odaklar;

      depo.yedektenYukle(Stream.value(json).toString());
      final d2 = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
      // Depoya doğrudan yükleme
      d2.yedektenYukle(
        '{"surum":1,"sonId":10,"karsilamaTamam":true,"turSayisi":3,"gunlukTekrarSiniri":10,'
        '"ftAyar":{"calismaDk":45,"kisaMolaDk":5,"uzunMolaDk":15,"uzunMolaAraligi":4,"donguSayisi":4},'
        '"dersler":[],"konular":[],"calismalar":[],'
        '"odaklar":['
        '{"anahtar":"t1","tarihMs":$bugunMs,"dakika":60,"odakPuani":5,"zorBilissel":true},'
        '{"anahtar":"t2","tarihMs":$bugunMs,"dakika":60,"odakPuani":4,"zorBilissel":true},'
        '{"anahtar":"t3","tarihMs":$bugunMs,"dakika":70,"odakPuani":5,"zorBilissel":true},'
        '{"anahtar":"t4","tarihMs":$bugunMs,"dakika":30,"odakPuani":3,"zorBilissel":false}'
        ']}',
      );

      // Toplam zor bilişsel: 60 + 60 + 70 = 190 dk (>= 180 dk, yaklaştı)
      expect(d2.zorBilisselDakikaBugun(), 190);
      expect(d2.toplamOdakDakikaBugun(), 220);
      expect(d2.zorBilisselYaklasti, isTrue);
      expect(d2.zorBilisselTavanAsildi, isFalse);

      // 4. zor bloğu ekleyince (toplam 250 dk):
      d2.yedektenYukle(
        '{"surum":1,"sonId":10,"karsilamaTamam":true,"turSayisi":3,"gunlukTekrarSiniri":10,'
        '"ftAyar":{"calismaDk":45,"kisaMolaDk":5,"uzunMolaDk":15,"uzunMolaAraligi":4,"donguSayisi":4},'
        '"dersler":[],"konular":[],"calismalar":[],'
        '"odaklar":['
        '{"anahtar":"t1","tarihMs":$bugunMs,"dakika":120,"odakPuani":5,"zorBilissel":true},'
        '{"anahtar":"t2","tarihMs":$bugunMs,"dakika":130,"odakPuani":4,"zorBilissel":true}'
        ']}',
      );

      expect(d2.zorBilisselDakikaBugun(), 250);
      expect(d2.zorBilisselTavanAsildi, isTrue);
    });

    test('PFC Erken Uyarı (C tipi hata > %15) ve Kurtarma Modu', () async {
      final depo = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
      await depo.yukle();

      expect(depo.sonOkumaHatasiOrani, 0.0);
      expect(depo.pfcErkenUyariAktif, isFalse);

      // Deneme sınavı ekleyelim: 10 yanlış, 3 tanesi C sınıfı (%30 okuma hatası)
      final deneme = DenemeSinavi(
        id: 'd1',
        baslik: 'TUS Deneme 1',
        tarih: DateTime.now(),
        ttbtNet: 60,
        ktbtNet: 65,
        sorular: [
          for (var i = 1; i <= 3; i++)
            DenemeSorusu(
              soruNo: i,
              dersAdi: 'Dahiliye',
              dogruMu: false,
              hataSinifi: HataSinifi.c, // Okuma / dikkat
            ),
          for (var i = 4; i <= 10; i++)
            DenemeSorusu(
              soruNo: i,
              dersAdi: 'Pediatri',
              dogruMu: false,
              hataSinifi: HataSinifi.a, // Bilgi
            ),
        ],
      );

      await depo.denemeEkle(deneme);

      expect(depo.sonOkumaHatasiOrani, 0.3); // %30 > %15
      expect(depo.pfcErkenUyariAktif, isTrue);

      // Kurtarma modunu etkinleştirme
      expect(depo.kurtarmaModuAktif, isFalse);
      await depo.kurtarmaModuAyarla(true);
      expect(depo.kurtarmaModuAktif, isTrue);
    });

    test('Uyku kayıtları CRUD ve hedef uyku ayarı', () async {
      final depo = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
      await depo.yukle();

      expect(depo.hedefYatisSaati, '23:30');
      expect(depo.hedefKalkisSaati, '07:30');

      await depo.hedefUykuAyarla(yatis: '23:00', kalkis: '07:00');
      expect(depo.hedefYatisSaati, '23:00');
      expect(depo.hedefKalkisSaati, '07:00');

      final kayit = UykuKaydi(
        tarih: '2026-11-03',
        uykuSuresiDakika: 480,
        yatisSaati: '23:00',
        kalkisSaati: '07:00',
      );

      await depo.uykuKaydet(kayit);
      expect(depo.uykular.length, 1);
      expect(depo.bugunkuUyku(DateTime(2026, 11, 3))?.yatisSaati, '23:00');

      await depo.uykuSil('2026-11-03');
      expect(depo.uykular, isEmpty);
    });
  });
}
