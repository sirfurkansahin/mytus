import 'dart:convert';

import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/kutuphane/kitap_detay_ekrani.dart';
import 'package:app/features/kutuphane/kutuphane_ekrani.dart';
import 'package:app/features/kutuphane/modeller.dart';
import 'package:flutter/material.dart';
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

    test('Kitap.notluBolumSayisi ve not filtresi hesabı', () {
      final bolumler = [
        KitapBolumu(
          id: 'b1',
          ad: 'Bölüm 1',
          notlar: [
            BolumNotu(
              id: 'n1',
              metin: 'Önemli not',
              olusturmaTarihi: DateTime.now(),
            ),
          ],
        ),
        const KitapBolumu(id: 'b2', ad: 'Bölüm 2'),
      ];

      final kitap = Kitap(
        id: 'k1',
        ad: 'Dahiliye',
        eklenmeTarihi: DateTime.now(),
        bolumler: bolumler,
      );

      expect(kitap.notluBolumSayisi, 1);
      expect(kitap.toplamNotSayisi, 1);
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

    test('bölüm notu ekleme, güncelleme, silme ve kalıcılık', () async {
      final kayit = BellekKaydi();
      final depo = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
      await depo.yukle();

      final kitap = Kitap(
        id: 'k_not',
        ad: 'Patoloji',
        eklenmeTarihi: DateTime.now(),
        bolumler: const [
          KitapBolumu(id: 'b_not', ad: 'Hücre Hasarı'),
        ],
      );
      await depo.kitapEkle(kitap);

      expect(depo.kitapBul('k_not')!.bolumler.first.notVar, isFalse);
      expect(depo.kitapBul('k_not')!.toplamNotSayisi, 0);

      // 1. Not ekleme (metin + base64 sahte resim)
      final not1 = BolumNotu(
        id: 'n1',
        metin: 'Goodpasture sendromu Tip 2 aşırı duyarlılık örneğidir.',
        resimBase64: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
        olusturmaTarihi: DateTime(2026, 11, 6, 20, 0),
      );

      await depo.kitapBolumNotuEkle('k_not', 'b_not', not1);
      var guncelBolum = depo.kitapBul('k_not')!.bolumler.first;
      expect(guncelBolum.notSayisi, 1);
      expect(guncelBolum.notVar, isTrue);
      expect(guncelBolum.notlar.first.metin, contains('Goodpasture'));
      expect(guncelBolum.notlar.first.resimVar, isTrue);
      expect(depo.kitapBul('k_not')!.toplamNotSayisi, 1);

      // 2. Not güncelleme
      final guncelNot1 = not1.kopya(metin: 'Tip 2 aşırı duyarlılık (antikor aracılı)');
      await depo.kitapBolumNotuGuncelle('k_not', 'b_not', guncelNot1);
      guncelBolum = depo.kitapBul('k_not')!.bolumler.first;
      expect(guncelBolum.notlar.first.metin, 'Tip 2 aşırı duyarlılık (antikor aracılı)');

      // 3. Kalıcılık kontrolü
      final depo2 = PlanDeposu(
        kayit: BellekKaydi(icerik: jsonEncode(depo.toJson())),
        kayitGecikmesi: Duration.zero,
      );
      await depo2.yukle();
      final bolum2 = depo2.kitapBul('k_not')!.bolumler.first;
      expect(bolum2.notSayisi, 1);
      expect(bolum2.notlar.first.metin, 'Tip 2 aşırı duyarlılık (antikor aracılı)');
      expect(bolum2.notlar.first.resimVar, isTrue);

      // 4. Not silme
      await depo2.kitapBolumNotuSil('k_not', 'b_not', 'n1');
      expect(depo2.kitapBul('k_not')!.bolumler.first.notVar, isFalse);
      expect(depo2.kitapBul('k_not')!.bolumler.first.notSayisi, 0);
    });

    test('ornekKitapUret ve ornekKitapYukle kütüphaneye hazır kitap ekler', () async {
      final kayit = BellekKaydi();
      final depo = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
      await depo.yukle();

      expect(depo.kitaplar, isEmpty);

      await depo.ornekKitapYukle();
      expect(depo.kitaplar.length, 1);

      final ornek = depo.kitaplar.first;
      expect(ornek.ad, 'TUSDATA Patoloji Konu Kitabı');
      expect(ornek.dersAdi, 'Patoloji');
      expect(ornek.toplamBolumSayisi, 6);
      expect(ornek.tamamlananBolumSayisi, 2);
      expect(ornek.yuzde, 33);
      expect(ornek.siradakiBolum?.ad, 'Hemodinamik Bozukluklar, Tromboz ve Şok');
      expect(ornek.toplamNotSayisi, 1);

      // Tekrar çağrılırsa mükerrer eklemez
      await depo.ornekKitapYukle();
      expect(depo.kitaplar.length, 1);
    });
  });

  group('Kütüphane Ergonomisi ve Arama Widget Testleri', () {
    testWidgets('KitapDetayEkrani içinde bölüm arama ve Notlular filtresi çalışır', (tester) async {
      final kayit = BellekKaydi();
      final depo = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
      await depo.yukle();

      final kitap = Kitap(
        id: 'k_test',
        ad: 'Patoloji Kitabı',
        eklenmeTarihi: DateTime.now(),
        bolumler: [
          KitapBolumu(
            id: 'b1',
            ad: 'Hücre Hasarı ve Nekroz',
            baslangicSayfa: 1,
            bitisSayfa: 20,
            notlar: [
              BolumNotu(
                id: 'n1',
                metin: 'Apoptoz kaspaz bağımlıdır.',
                olusturmaTarihi: DateTime.now(),
              ),
            ],
          ),
          const KitapBolumu(
            id: 'b2',
            ad: 'İltihap ve Doku Onarımı',
            baslangicSayfa: 21,
            bitisSayfa: 50,
          ),
        ],
      );
      await depo.kitapEkle(kitap);

      await tester.pumpWidget(
        DepoKapsami(
          deposu: depo,
          child: const MaterialApp(
            home: KitapDetayEkrani(kitapId: 'k_test'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Başlangıçta "Hücre Hasarı" hem Sıradaki Çalışma kartında hem liste satırında görünür
      expect(find.text('Hücre Hasarı ve Nekroz'), findsNWidgets(2));
      expect(find.text('İltihap ve Doku Onarımı'), findsOneWidget);

      // Arama kutusuna "iltihap" yaz
      await tester.enterText(find.byType(TextField).first, 'iltihap');
      await tester.pumpAndSettle();

      expect(find.text('İltihap ve Doku Onarımı'), findsOneWidget);
      expect(find.text('Hücre Hasarı ve Nekroz'), findsNothing);

      // Aramayı temizle
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Hücre Hasarı ve Nekroz'), findsNWidgets(2));
      expect(find.text('İltihap ve Doku Onarımı'), findsOneWidget);

      // Notlular filtresini seç (filtre seçildiğinde sıradaki kartı gizlenir, sadece 1 tane Hücre Hasarı kalır)
      await tester.tap(find.text('Notlular (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Hücre Hasarı ve Nekroz'), findsOneWidget);
      expect(find.text('İltihap ve Doku Onarımı'), findsNothing);

      // Bölüm satırına dokunulduğunda ergonomik hızlı not alt penceresi (BottomSheet) açılır
      await tester.tap(find.text('Hücre Hasarı ve Nekroz'));
      await tester.pumpAndSettle();

      expect(find.text('Apoptoz kaspaz bağımlıdır.'), findsOneWidget);
      expect(find.text('Tüm Notları Yönet'), findsOneWidget);
    });

    testWidgets('KutuphaneEkrani içinde kitap arama çubuğu çalışır', (tester) async {
      final kayit = BellekKaydi();
      final depo = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
      await depo.yukle();

      await depo.kitapEkle(
        Kitap(
          id: 'k1',
          ad: 'SpeeTUS Farmakoloji',
          dersAdi: 'Farmakoloji',
          klasorAdi: 'SpeeTUS (5. Baskı)',
          eklenmeTarihi: DateTime.now(),
        ),
      );
      await depo.kitapEkle(
        Kitap(
          id: 'k2',
          ad: 'TUSDATA Patoloji',
          dersAdi: 'Patoloji',
          klasorAdi: 'TUSDATA',
          eklenmeTarihi: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        DepoKapsami(
          deposu: depo,
          child: const MaterialApp(
            home: KutuphaneEkrani(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kütüphane İlerlemesi'), findsOneWidget);

      // Arama çubuğuna "Farma" yaz
      final aramaInput = find.byType(TextField);
      expect(aramaInput, findsOneWidget);
      await tester.enterText(aramaInput, 'Farma');
      await tester.pumpAndSettle();

      expect(find.text('ARAMA SONUÇLARI (1)'), findsOneWidget);
      expect(find.text('SpeeTUS Farmakoloji'), findsOneWidget);
      expect(find.text('TUSDATA Patoloji'), findsNothing);
    });
  });
}
