import 'package:app/core/tarih.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/auth/kimlik_servisi.dart';
import 'package:app/features/dersler/hazir_dersler.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/kutuphane/modeller.dart';
import 'package:app/features/senkronizasyon/bulut_kaynagi.dart';
import 'package:app/features/senkronizasyon/bulut_senkron_servisi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BulutSenkronServisi ve Göç / Çoklu Cihaz Testleri', () {
    test(
      'İlk giriş göçü: cihazdaki yerel veriler yeni açılan bulut hesabına aktarılır ve fotoğraflar cihazda korunur',
      () async {
        final yerel = BellekKaydi();
        final bulut = SahteBulutKaynagi();
        final senkron = BulutSenkronServisi(
          yerelKayit: yerel,
          bulutKaynagi: bulut,
          gonderimGecikmesi: Duration.zero,
          cihazId: 'telefon_1',
        );
        final depo = PlanDeposu(
          kayit: senkron,
          kayitGecikmesi: Duration.zero,
        );
        senkron.depoBagla(depo);
        await depo.yukle();

        // Kullanıcı henüz giriş yapmadan yerel veri oluşturur ve fotoğraflı not ekler.
        await depo.karsilamayiTamamla(
          sinavTarihi: resmiSinavTarihi,
          secilenDersler: const [HazirDers('Patoloji', DersGrubu.temel)],
          mufredatTuru: MufredatTuru.klasik,
        );
        await depo.kitapBolumNotuEkle(
          'k_ornek_patoloji',
          'b_ornek_1',
          BolumNotu(
            id: 'not_foto_1',
            metin: 'Önemli patoloji notu',
            resimBase64: 'BASE64_FOTO_VERISI',
            olusturmaTarihi: DateTime(2026, 11, 8),
          ),
        );

        // Şimdi ilk kez hesap oluşturup giriş yapar.
        const kullanici = KullaniciBilgisi(
          uid: 'uid_furkan',
          eposta: 'furkan@mytus.com',
          takmaAd: 'Dr. Furkan',
        );
        await senkron.oturumAcildi(kullanici);

        // Bulutta bölümler oluşmuş olmalı.
        final buluttakiBolumler = bulut.kullaniciBolumleri['uid_furkan'];
        expect(buluttakiBolumler, isNotNull);
        expect(buluttakiBolumler!['plan'], contains('Patoloji'));
        expect(
          buluttakiBolumler['kutuphane'],
          contains('Önemli patoloji notu'),
        );
        // Fotoğraf buluta gitmemeli!
        expect(
          buluttakiBolumler['kutuphane']!.contains('BASE64_FOTO_VERISI'),
          isFalse,
        );
        // Ama cihazda hesaba özel anahtarda saklanmış olmalı!
        expect(
          yerel.ekAnahtarlar['mytus_photos_uid_furkan'],
          contains('BASE64_FOTO_VERISI'),
        );

        // Kullanıcı çıkış yapar -> cihazdaki çalışma verisi sıfırlanır ama fotoğraflar korunur.
        await senkron.oturumKapatildi(hesabiTamamenSil: false);
        expect(depo.karsilamaTamam, isFalse);
        expect(
          yerel.ekAnahtarlar['mytus_photos_uid_furkan'],
          contains('BASE64_FOTO_VERISI'),
        );

        // Aynı cihazdan tekrar giriş yaptığında buluttaki veriler + cihazdaki fotoğraf birleşip geri gelir!
        await senkron.oturumAcildi(kullanici);
        expect(depo.karsilamaTamam, isTrue);
        expect(depo.tumDersler.first.ad, 'Patoloji');
        final kitap = depo.kitapBul('k_ornek_patoloji')!;
        final bolum1 = kitap.bolumler.firstWhere((b) => b.id == 'b_ornek_1');
        expect(bolum1.notlar.first.metin, 'Önemli patoloji notu');
        expect(bolum1.notlar.first.resimBase64, 'BASE64_FOTO_VERISI');
      },
    );

    test(
      'Çevrimdışı dayanıklılık ve çoklu cihaz eşitlemesi çalışır',
      () async {
        final yerel = BellekKaydi();
        final bulut = SahteBulutKaynagi();
        final senkron = BulutSenkronServisi(
          yerelKayit: yerel,
          bulutKaynagi: bulut,
          gonderimGecikmesi: Duration.zero,
          cihazId: 'cihaz_a',
        );
        final depo = PlanDeposu(
          kayit: senkron,
          kayitGecikmesi: Duration.zero,
        );
        senkron.depoBagla(depo);
        await depo.yukle();

        const kullanici = KullaniciBilgisi(
          uid: 'uid_1',
          eposta: 'test@mytus.com',
        );
        await senkron.oturumAcildi(kullanici);

        // İnternet kesilir.
        bulut.cevrimdisi = true;
        await depo.karsilamayiTamamla(
          sinavTarihi: resmiSinavTarihi,
          secilenDersler: const [HazirDers('Dahiliye', DersGrubu.klinik)],
          mufredatTuru: MufredatTuru.klasik,
        );

        // Uygulama çökmez, yerel kayıt güncellenir ve durum çevrimdışı olur.
        expect(yerel.icerik, contains('Dahiliye'));
        expect(senkron.durum, SenkronDurumu.cevrimdisi);
        expect(senkron.bekleyenVarMi, isTrue);

        // İnternet geri gelir ve bekleyenler gönderilir.
        bulut.cevrimdisi = false;
        await senkron.bekleyenleriSimdiGonder();
        expect(senkron.durum, SenkronDurumu.esitlendi);
        expect(senkron.bekleyenVarMi, isFalse);
        expect(
          bulut.kullaniciBolumleri['uid_1']!['plan'],
          contains('Dahiliye'),
        );

        // İkinci bir cihaz (cihaz_b) aynı hesaba bağlandığında verileri anında indirir.
        final yerelB = BellekKaydi();
        final senkronB = BulutSenkronServisi(
          yerelKayit: yerelB,
          bulutKaynagi: bulut,
          gonderimGecikmesi: Duration.zero,
          cihazId: 'cihaz_b',
        );
        final depoB = PlanDeposu(
          kayit: senkronB,
          kayitGecikmesi: Duration.zero,
        );
        senkronB.depoBagla(depoB);
        await depoB.yukle();
        await senkronB.oturumAcildi(kullanici);

        expect(depoB.karsilamaTamam, isTrue);
        expect(depoB.tumDersler.map((d) => d.ad), contains('Dahiliye'));
      },
    );
  });
}
