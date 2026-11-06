import 'dart:convert';

import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/kutuphane/modeller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Kütüphane Modelleri ve Toplu Ayrıştırma', () {
    test('topluBolumleriAyristir metni satır satır ve sayfa aralıklarıyla ayrıştırır', () {
      const hamMetin = '''
1. Hücre Hasarı ve Nekroz (s. 1-35)
2. İltihap ve Doku Onarımı ... 36-70
3. Hemodinamik Bozukluklar (71-105)
4. İmmünopatoloji
5. Neoplazi (s. 140-200)
''';

      final bolumler = topluBolumleriAyristir(hamMetin);
      expect(bolumler.length, 5);

      expect(bolumler[0].ad, '1. Hücre Hasarı ve Nekroz');
      expect(bolumler[0].baslangicSayfa, 1);
      expect(bolumler[0].bitisSayfa, 35);
      expect(bolumler[0].sayfaSayisi, 35);
      expect(bolumler[0].sayfaAraligiMetni, 's. 1–35');

      expect(bolumler[1].ad, '2. İltihap ve Doku Onarımı');
      expect(bolumler[1].baslangicSayfa, 36);
      expect(bolumler[1].bitisSayfa, 70);

      expect(bolumler[3].ad, '4. İmmünopatoloji');
      expect(bolumler[3].baslangicSayfa, isNull);
      expect(bolumler[3].bitisSayfa, isNull);
      expect(bolumler[3].sayfaAraligiMetni, '');
    });

    test('Kitap ilerleme, sıradaki bölüm ve tamamlanma hesapları', () {
      final bolumler = [
        const KitapBolumu(id: 'b1', ad: 'Bölüm 1', tamamlandi: true),
        const KitapBolumu(id: 'b2', ad: 'Bölüm 2', tamamlandi: false),
        const KitapBolumu(id: 'b3', ad: 'Bölüm 3', tamamlandi: false),
        const KitapBolumu(id: 'b4', ad: 'Bölüm 4', tamamlandi: false),
      ];

      final kitap = Kitap(
        id: 'k1',
        ad: 'Patoloji Konu Kitabı',
        dersAdi: 'Patoloji',
        toplamSayfa: 400,
        eklenmeTarihi: DateTime.now(),
        bolumler: bolumler,
      );

      expect(kitap.toplamBolumSayisi, 4);
      expect(kitap.tamamlananBolumSayisi, 1);
      expect(kitap.kalanBolumSayisi, 3);
      expect(kitap.ilerlemeOrani, 0.25);
      expect(kitap.yuzde, 25);
      expect(kitap.tamamlandi, isFalse);
      expect(kitap.siradakiBolum?.id, 'b2');

      // Tüm bölümler tamamlanınca
      final hepsiTamam = kitap.kopya(
        bolumler: [for (final b in bolumler) b.kopya(tamamlandi: true)],
      );
      expect(hepsiTamam.tamamlananBolumSayisi, 4);
      expect(hepsiTamam.ilerlemeOrani, 1.0);
      expect(hepsiTamam.yuzde, 100);
      expect(hepsiTamam.tamamlandi, isTrue);
      expect(hepsiTamam.siradakiBolum, isNull);
    });

    test('Kitap ve KitapBolumu JSON serileştirme döngüsü', () {
      final bolum = KitapBolumu(
        id: 'b_test',
        ad: 'Kardiyovasküler Patoloji',
        baslangicSayfa: 100,
        bitisSayfa: 150,
        tamamlandi: true,
        tamamlanmaTarihi: DateTime(2026, 11, 6),
      );

      final kitap = Kitap(
        id: 'k_test',
        ad: 'TUSDATA Patoloji',
        dersId: 5,
        dersAdi: 'Patoloji',
        toplamSayfa: 450,
        eklenmeTarihi: DateTime(2026, 11, 6),
        bolumler: [bolum],
      );

      final json = kitap.toJson();
      final geri = Kitap.fromJson(json);

      expect(geri.id, kitap.id);
      expect(geri.ad, kitap.ad);
      expect(geri.dersId, 5);
      expect(geri.dersAdi, 'Patoloji');
      expect(geri.toplamSayfa, 450);
      expect(geri.bolumler.length, 1);
      expect(geri.bolumler.first.ad, 'Kardiyovasküler Patoloji');
      expect(geri.bolumler.first.baslangicSayfa, 100);
      expect(geri.bolumler.first.bitisSayfa, 150);
      expect(geri.bolumler.first.tamamlandi, isTrue);
    });
  });

  group('PlanDeposu Kütüphane Entegrasyonu', () {
    test('kitap ekleme, bölüm tamamlama, güncelleme ve silme', () async {
      final kayit = BellekKaydi();
      final depo = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
      await depo.yukle();

      expect(depo.kitaplar, isEmpty);

      final yeni = Kitap(
        id: 'k1',
        ad: 'Dahiliye Konu Kitabı',
        dersAdi: 'Dahiliye',
        eklenmeTarihi: DateTime.now(),
        bolumler: const [
          KitapBolumu(id: 'b1', ad: 'Gastroenteroloji'),
          KitapBolumu(id: 'b2', ad: 'Hematoloji'),
        ],
      );

      await depo.kitapEkle(yeni);
      expect(depo.kitaplar.length, 1);
      expect(depo.kitapBul('k1')?.ad, 'Dahiliye Konu Kitabı');

      // Bölüm tamamlama
      await depo.kitapBolumDurumuDegistir('k1', 'b1', true);
      final guncel = depo.kitapBul('k1')!;
      expect(guncel.bolumler.first.tamamlandi, isTrue);
      expect(guncel.bolumler.first.tamamlanmaTarihi, isNotNull);
      expect(guncel.tamamlananBolumSayisi, 1);

      // Kalıcılık testi (yeni depo yüklenince aynen gelmeli)
      final depo2 = PlanDeposu(
        kayit: BellekKaydi(icerik: jsonEncode(depo.toJson())),
        kayitGecikmesi: Duration.zero,
      );
      await depo2.yukle();
      expect(depo2.kitaplar.length, 1);
      expect(depo2.kitaplar.first.tamamlananBolumSayisi, 1);

      // Kitap silme
      await depo.kitapSil('k1');
      expect(depo.kitaplar, isEmpty);
    });
  });
}
