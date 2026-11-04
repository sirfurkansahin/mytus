library;

import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/bilissel/modeller.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/kokpit/modeller.dart';
import 'package:app/features/kokpit/strateji_motoru.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Master Yönetim Kokpiti Modelleri ve Göstergeleri', () {
    test('Boş depoda varsayılan bilişsel göstergeler dengeli başlar', () async {
      final depo = PlanDeposu(kayit: BellekKaydi());
      await depo.yukle();

      final gostergeler = kokpitGostergeleriHesapla(depo);

      expect(gostergeler.denemeSayisi, 0);
      expect(gostergeler.kalibrasyonFarki, 0.0);
      expect(gostergeler.asiriGuvenVarMi, isFalse);
      expect(gostergeler.cTipiOkumaHatasiOrani, 0.0);
      expect(gostergeler.r1GecisOrani, 100.0);
      expect(gostergeler.r3GecisOrani, 100.0);
      expect(gostergeler.genelSaglikSkoru, greaterThanOrEqualTo(80));
      expect(gostergeler.sonToplamNet, 0.0);
    });

    test('Deneme verileriyle 4 sınav ve kalibrasyon göstergeleri doğru hesaplanır', () async {
      final depo = PlanDeposu(kayit: BellekKaydi());
      await depo.yukle();

      // Deneme ekle: 70 Temel Net, 80 Klinik Net
      // Soru güvenleri: 4 soru Emin + Doğru, 1 soru Emin + Yanlış (Aşırı güven)
      final deneme = DenemeSinavi(
        id: 'd1',
        ad: 'TUS Deneme 1',
        tarih: DateTime.now(),
        temel: const DenemeOturumu(dogru: 75, yanlis: 20, bos: 5), // Net: 70.0
        klinik: const DenemeOturumu(dogru: 84, yanlis: 16, bos: 0), // Net: 80.0
        kaygiPuani: 8, // Yüksek kaygı
        soruHatalari: [
          const DenemeSorusu(
            id: 's1',
            soruNo: 5,
            oturumTemelMi: true,
            guven: GuvenSeviyesi.emin,
            dogruMu: true,
          ),
          const DenemeSorusu(
            id: 's2',
            soruNo: 15,
            oturumTemelMi: true,
            guven: GuvenSeviyesi.emin,
            dogruMu: true,
          ),
          const DenemeSorusu(
            id: 's3',
            soruNo: 80,
            oturumTemelMi: false,
            guven: GuvenSeviyesi.emin,
            dogruMu: false,
            hataSinifi: HataSinifi.c,
          ),
          const DenemeSorusu(
            id: 's4',
            soruNo: 85,
            oturumTemelMi: false,
            guven: GuvenSeviyesi.emin,
            dogruMu: false,
            hataSinifi: HataSinifi.c,
          ),
          const DenemeSorusu(
            id: 's5',
            soruNo: 90,
            oturumTemelMi: false,
            guven: GuvenSeviyesi.emin,
            dogruMu: false,
            hataSinifi: HataSinifi.c,
          ),
        ],
      );

      await depo.denemeEkle(deneme);

      final g = kokpitGostergeleriHesapla(depo);

      expect(g.denemeSayisi, 1);
      expect(g.sonTemelNet, 70.0);
      expect(g.sonKlinikNet, 80.0);
      expect(g.sonToplamNet, 150.0);
      // K Puanı = 0.4 * 70 + 0.6 * 80 = 28 + 48 = 76.0
      expect(g.sonKlinikAgirlikliPuan, 76.0);
      expect(g.tahminiEbapPuani, greaterThan(70.0));
      expect(g.sonKaygiPuani, 8);

      // Soru analizi: 5 sorunun 2'si doğru (%40), tümü Emin (%100 güven). Kalibrasyon farkı: 100 - 40 = +%60.0
      expect(g.asiriGuvenVarMi, isTrue);

      // C tipi hata oranı: 3 hata var, 3'ü de C (%100)
      expect(g.cTipiOkumaHatasiOrani, 100.0);

      // Çeyrek analizi: İlk çeyrek 0 hata, son çeyrek 3 hata (yorgunluk alarmı)
      expect(g.sonCeyrekHataOraniYuksek, isFalse); // İlk çeyrek 0 olduğu için bölünemez
    });

    test('Çeyrek dilim yorgunluk analizi son 25 soruda 1.5 kat hata durumunu yakalar', () async {
      final depo = PlanDeposu(kayit: BellekKaydi());
      await depo.yukle();

      final deneme = DenemeSinavi(
        id: 'd_yorgunluk',
        ad: 'Tempo Testi',
        tarih: DateTime.now(),
        soruHatalari: [
          // İlk çeyrek (1-25): 2 hata
          const DenemeSorusu(id: '1', soruNo: 5, oturumTemelMi: true, dogruMu: false, hataSinifi: HataSinifi.a),
          const DenemeSorusu(id: '2', soruNo: 15, oturumTemelMi: true, dogruMu: false, hataSinifi: HataSinifi.a),
          // Son çeyrek (76-100): 4 hata (4 >= 2 * 1.5)
          const DenemeSorusu(id: '3', soruNo: 80, oturumTemelMi: true, dogruMu: false, hataSinifi: HataSinifi.e),
          const DenemeSorusu(id: '4', soruNo: 85, oturumTemelMi: true, dogruMu: false, hataSinifi: HataSinifi.e),
          const DenemeSorusu(id: '5', soruNo: 90, oturumTemelMi: true, dogruMu: false, hataSinifi: HataSinifi.e),
          const DenemeSorusu(id: '6', soruNo: 95, oturumTemelMi: true, dogruMu: false, hataSinifi: HataSinifi.e),
        ],
      );

      await depo.denemeEkle(deneme);
      final g = kokpitGostergeleriHesapla(depo);

      expect(g.sonCeyrekHataOraniYuksek, isTrue);
    });

    test('Uyku ve sirkadiyen sapma ortalaması doğru hesaplanır', () async {
      final depo = PlanDeposu(kayit: BellekKaydi());
      await depo.yukle();
      await depo.hedefUykuAyarla(yatis: '23:30', kalkis: '07:30');

      // 2 uyku kaydı: biri 8 saat (sapma 0), biri 6 saat (sapma 60 dk)
      await depo.uykuKaydet(
        const UykuKaydi(
          tarih: '2026-11-01',
          uykuSuresiDakika: 480,
          yatisSaati: '23:30',
          kalkisSaati: '07:30',
          kalite: 5,
        ),
      );
      await depo.uykuKaydet(
        const UykuKaydi(
          tarih: '2026-11-02',
          uykuSuresiDakika: 360,
          yatisSaati: '00:30',
          kalkisSaati: '06:30',
          kalite: 3,
        ),
      );

      final g = kokpitGostergeleriHesapla(depo);

      // Ortalama süre: (8 + 6) / 2 = 7.0 saat
      expect(g.uykuSuresiOrtalama, 7.0);
      // Ortalama sapma: (0 + 60) / 2 = 30 dk
      expect(g.sirkadiyenSapmaDakika, 30);
      expect(g.uykuDuzenliMi, isTrue); // 7.0 sa ve <= 30 dk
    });
  });

  group('Otomatik "Eğer–O Zaman" Karar ve Strateji Motoru', () {
    test('PFC okuma hatası > %15 ise Kurtarma Modu kuralı kritik tetiklenir', () async {
      final depo = PlanDeposu(kayit: BellekKaydi());
      await depo.yukle();

      // C hatası %50 olan deneme
      await depo.denemeEkle(
        DenemeSinavi(
          id: 'pfc_deneme',
          ad: 'PFC Test',
          tarih: DateTime.now(),
          soruHatalari: const [
            DenemeSorusu(id: '1', soruNo: 1, oturumTemelMi: true, dogruMu: false, hataSinifi: HataSinifi.c),
            DenemeSorusu(id: '2', soruNo: 2, oturumTemelMi: true, dogruMu: false, hataSinifi: HataSinifi.a),
          ],
        ),
      );

      final g = kokpitGostergeleriHesapla(depo);
      final kurallar = stratejiAnaliziYap(g, depo);

      final pfcKurali = kurallar.firstWhere((k) => k.id == 'pfc_c_hatasi_alarm');
      expect(pfcKurali.oncelik, OncelikSeviyesi.kritik);
      expect(pfcKurali.eylemTuru, KokpitEylemTuru.kurtarmaModu);
    });

    test('Kurtarma modu aktifken bilgilendirme kuralı devreye girer', () async {
      final depo = PlanDeposu(kayit: BellekKaydi());
      await depo.yukle();
      await depo.kurtarmaModuAyarla(true);

      final g = kokpitGostergeleriHesapla(depo);
      final kurallar = stratejiAnaliziYap(g, depo);

      expect(kurallar.any((k) => k.id == 'pfc_kurtarma_aktif'), isTrue);
    });

    test('Aşırı güven (+%8 üzeri kalibrasyon farkı) kuralı tetiklenir', () async {
      final depo = PlanDeposu(kayit: BellekKaydi());
      await depo.yukle();

      // Kalibrasyon farkı +%50
      await depo.denemeEkle(
        DenemeSinavi(
          id: 'guven_deneme',
          ad: 'Aşırı Güven',
          tarih: DateTime.now(),
          soruHatalari: const [
            DenemeSorusu(id: '1', soruNo: 1, oturumTemelMi: true, guven: GuvenSeviyesi.emin, dogruMu: false, hataSinifi: HataSinifi.b),
            DenemeSorusu(id: '2', soruNo: 2, oturumTemelMi: true, guven: GuvenSeviyesi.emin, dogruMu: true),
          ],
        ),
      );

      final g = kokpitGostergeleriHesapla(depo);
      final kurallar = stratejiAnaliziYap(g, depo);

      final asiriGuvenKurali = kurallar.firstWhere((k) => k.id == 'asiri_guven_alarm');
      expect(asiriGuvenKurali.oncelik, OncelikSeviyesi.kritik);
      expect(asiriGuvenKurali.eylemTuru, KokpitEylemTuru.celdiriciBankasi);
    });

    test('Yüksek test kaygısı (>= 7) kuralı panik protokolünü önerir', () async {
      final depo = PlanDeposu(kayit: BellekKaydi());
      await depo.yukle();

      await depo.denemeEkle(
        DenemeSinavi(
          id: 'kaygi_deneme',
          ad: 'Kaygı Test',
          tarih: DateTime.now(),
          kaygiPuani: 9,
        ),
      );

      final g = kokpitGostergeleriHesapla(depo);
      final kurallar = stratejiAnaliziYap(g, depo);

      final kaygiKurali = kurallar.firstWhere((k) => k.id == 'kaygi_uyarisi');
      expect(kaygiKurali.oncelik, OncelikSeviyesi.uyari);
      expect(kaygiKurali.eylemTuru, KokpitEylemTuru.panikProtokolu);
    });

    test('Ağır analitik tavan dolduğunda (> 240 dk) tavan kuralı tetiklenir', () async {
      final depo = PlanDeposu(kayit: BellekKaydi());
      await depo.yukle();

      final bugunMs = DateTime.now().millisecondsSinceEpoch;
      depo.yedektenYukle(
        '{"surum":1,"sonId":10,"karsilamaTamam":true,"turSayisi":3,"gunlukTekrarSiniri":10,'
        '"ftAyar":{"calismaDk":45,"kisaMolaDk":5,"uzunMolaDk":15,"uzunMolaAraligi":4,"donguSayisi":4},'
        '"dersler":[],"konular":[],"calismalar":[],'
        '"odaklar":['
        '{"anahtar":"t1","tarihMs":$bugunMs,"dakika":120,"odakPuani":5,"zorBilissel":true},'
        '{"anahtar":"t2","tarihMs":$bugunMs,"dakika":130,"odakPuani":4,"zorBilissel":true}'
        ']}',
      );

      final g = kokpitGostergeleriHesapla(depo);
      final kurallar = stratejiAnaliziYap(g, depo);

      expect(kurallar.any((k) => k.id == 'zor_bilissel_tavan'), isTrue);
    });

    test('Beklenen Değer (EV) kuralı her zaman mevcuttur', () async {
      final depo = PlanDeposu(kayit: BellekKaydi());
      await depo.yukle();

      final g = kokpitGostergeleriHesapla(depo);
      final kurallar = stratejiAnaliziYap(g, depo);

      expect(kurallar.any((k) => k.id == 'beklenen_deger_disiplini'), isTrue);
    });

    test('Kritik uyarı yokken Optimal Zirve kuralı en başta listelenir', () async {
      final depo = PlanDeposu(kayit: BellekKaydi());
      await depo.yukle();

      final g = kokpitGostergeleriHesapla(depo);
      final kurallar = stratejiAnaliziYap(g, depo);

      expect(kurallar.first.id, 'optimal_zirve');
      expect(kurallar.first.oncelik, OncelikSeviyesi.basarili);
    });
  });
}
