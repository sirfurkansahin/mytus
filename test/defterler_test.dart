import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/defterler/hazir_skorlar.dart';
import 'package:app/features/defterler/modeller.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HataDefteri Modeli', () {
    test('Emin + Yanlış (B Sınıfı) hiperdüzeltme gerektirir', () {
      final hata = HataKaydi(
        id: 'h1',
        baslik: 'PSC vs PBC Ayırıcı Tanı',
        hataSinifi: HataSinifi.b,
        guven: GuvenSeviyesi.emin,
        celdirici: 'Primer Biliyer Kolanjit',
        ayiranKriter: 'AMA (+) ve kadın = PBC; p-ANCA ve ERCP = PSC',
        kural: 'Kolestaz görünce hemen AMA ve ERCP ayrımına bak',
        tarih: DateTime(2026, 11, 3),
      );

      expect(hata.hiperDuzeltmeGerektirir, isTrue);

      final pekiştirilmiş = hata.copyWith(pekiştirildi: true);
      expect(pekiştirilmiş.hiperDuzeltmeGerektirir, isFalse);
    });

    test('JSON serileştirme ve geri yükleme çalışır', () {
      final hata = HataKaydi(
        id: 'h2',
        baslik: 'Hinchey Evrelemesi',
        dersAdi: 'Genel Cerrahi',
        hataSinifi: HataSinifi.a,
        guven: GuvenSeviyesi.kararsiz,
        celdirici: 'Evre 2',
        ayiranKriter: 'Pelvik apse = Evre 2, Perkütan drenaj',
        kural: 'Apse boyutuna ve yerine bak',
        tarih: DateTime(2026, 11, 3),
      );

      final json = hata.toJson();
      final geri = HataKaydi.fromJson(json);

      expect(geri.id, hata.id);
      expect(geri.baslik, hata.baslik);
      expect(geri.dersAdi, hata.dersAdi);
      expect(geri.hataSinifi, HataSinifi.a);
      expect(geri.ayiranKriter, hata.ayiranKriter);
    });
  });

  group('SkorDefteri ve Hazır Skorlar', () {
    test('Hazır TUS skorları kütüphanesi en az 10 kritik skor içerir', () {
      expect(hazirSkorlar.length, greaterThanOrEqualTo(10));
      expect(hazirSkorlar.any((s) => s.ad.contains('Hinchey')), isTrue);
      expect(hazirSkorlar.any((s) => s.ad.contains('Hodgkin')), isTrue);
      expect(hazirSkorlar.any((s) => s.ad.contains('Child-Pugh')), isTrue);
      expect(hazirSkorlar.any((s) => s.ad.contains('Wells')), isTrue);
    });

    test('Özel skor eklenebilir ve hazır skorlarla birleşir', () async {
      final depo = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
      await depo.yukle();

      expect(depo.tumSkorlar.length, hazirSkorlar.length);

      const ozel = SkorKarti(
        id: 'ozel-1',
        ad: 'Centor Farenjit Skoru',
        brans: 'KBB / Pediatri',
        parametreler: ['Ateş', 'Eksüda', 'Öksürük yokluğu', 'LAP'],
        klinikKarar: '≥3 puan: Hızlı antijen testi ve antibiyotik',
        ozelMi: true,
      );

      await depo.skorEkle(ozel);
      expect(depo.tumSkorlar.length, hazirSkorlar.length + 1);
      expect(depo.tumSkorlar.first.ad, 'Centor Farenjit Skoru');

      await depo.skorSil('ozel-1');
      expect(depo.tumSkorlar.length, hazirSkorlar.length);
    });
  });

  group('Mekanizma Zincirleri (Illness Scripts)', () {
    test('6 branş şablonunun her birinde 5 halka tanımlıdır', () {
      for (final t in ZincirTuru.values) {
        expect(t.halkaAdlari.length, 5);
      }
    });

    test('zincir ekleme ve silme depoda çalışır', () async {
      final depo = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
      await depo.yukle();

      const zincir = MekanizmaZinciri(
        id: 'z1',
        baslik: 'Graves Hastalığı',
        tur: ZincirTuru.dahiliye,
        halkalar: [
          'Otoimmün / TSHR antikorları',
          'TSHR sürekli uyarımı',
          'Tirotoksikoz + Oftalmopati + Pretibial Miksödem',
          'TSH baskılı, sT3/sT4 yüksek, Diffüz RAI uptake',
          'Metimazol / Propiltiourasil / RAI / Cerrahi',
        ],
        ayiranOzellik: 'Tiroiditte RAI uptake düşüktür, Graves\'te yüksektir',
        nedenCevabi: 'Antikorlar reseptörü ligand gibi sürekli uyarır',
      );

      await depo.zincirEkle(zincir);
      expect(depo.zincirler.length, 1);
      expect(depo.zincirler.first.baslik, 'Graves Hastalığı');

      await depo.zincirSil('z1');
      expect(depo.zincirler, isEmpty);
    });
  });

  group('3 Dakikalık Vaka Kartları', () {
    test('klinik vaka kartı oluşturulup depolanabilir', () async {
      final depo = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
      await depo.yukle();

      final vaka = VakaKarti(
        id: 'v1',
        tarih: DateTime(2026, 11, 3),
        hastaOzeti: 'Epigastrik ağrı ve sırta vuran kuşak tarzı acı',
        belirleyiciHalka: 'Lipaz 3 kat artmış ve safra kesesinde taş',
        olasiSoruKoku: 'En olası tanı nedir?',
        celdirici: 'Akut Kolesistit veya MI',
        ayiranKriter: 'Lipaz yüksekliği pankreatiti spesifik olarak doğrular',
        dersAdi: 'Genel Cerrahi',
      );

      await depo.vakaEkle(vaka);
      expect(depo.vakaKartlari.length, 1);
      expect(depo.vakaKartlari.first.ayiranKriter, contains('Lipaz'));

      await depo.vakaSil('v1');
      expect(depo.vakaKartlari, isEmpty);
    });
  });
}
