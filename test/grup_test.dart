import 'package:app/core/tarih.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/grup/grup_servisi.dart';
import 'package:app/features/grup/modeller.dart';
import 'package:app/features/auth/kimlik_servisi.dart';
import 'package:app/features/grup/grup_ekrani.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Grup Modelleri ve Davet Kodu Testleri', () {
    test('davetKoduUret 6 karakterlik kafa karıştırmayan kod üretir', () {
      final kod1 = davetKoduUret();
      final kod2 = davetKoduUret();

      expect(kod1.length, 6);
      expect(kod2.length, 6);
      expect(kod1, isNot(contains('0')));
      expect(kod1, isNot(contains('O')));
      expect(kod1, isNot(contains('1')));
      expect(kod1, isNot(contains('I')));
    });

    test('GrupUyesi puan hesabı (Seçenek C: 1 Konu = 10 Puan, 1 Soru = 1 Puan)', () {
      const u = GrupUyesi(
        uid: 'user1',
        takmaAd: 'Dr. Ahmet',
        haftaBaslangici: '2026-11-02',
        konuSayisi: 3,
        soruSayisi: 85,
        sonDers: 'Farmakoloji',
        guncellemeTarihi: null ?? DateTime(2026, 11, 8),
      );

      // (3 * 10) + 85 = 115
      expect(u.puan, 115);

      final json = u.toJson();
      final geri = GrupUyesi.fromJson(json, docId: 'user1');
      expect(geri.takmaAd, 'Dr. Ahmet');
      expect(geri.puan, 115);
      expect(geri.sonDers, 'Farmakoloji');
    });

    test('GrupHedefDurumu ortak hedef yüzdesini doğru hesaplar', () {
      final grup = Grup(
        id: 'g1',
        ad: 'Hacettepe TUS 2027',
        davetKodu: 'TUS84X',
        olusturanUid: 'u1',
        olusturmaTarihi: DateTime(2026, 11, 1),
        hedefKonu: 20,
        hedefSoru: 500,
      );

      final uyeler = [
        GrupUyesi(
          uid: 'u1',
          takmaAd: 'Dr. Ali',
          haftaBaslangici: '2026-11-02',
          konuSayisi: 6,
          soruSayisi: 150,
          guncellemeTarihi: DateTime.now(),
        ),
        GrupUyesi(
          uid: 'u2',
          takmaAd: 'Dr. Ayşe',
          haftaBaslangici: '2026-11-02',
          konuSayisi: 4,
          soruSayisi: 100,
          guncellemeTarihi: DateTime.now(),
        ),
      ];

      final durum = GrupHedefDurumu.hesapla(uyeler: uyeler, grup: grup);
      // Toplam konu: 10/20 (%50), Toplam soru: 250/500 (%50) -> Genel %50
      expect(durum.toplamKonu, 10);
      expect(durum.toplamSoru, 250);
      expect(durum.konuOrani, 0.5);
      expect(durum.soruOrani, 0.5);
      expect(durum.genelYuzde, 50);
    });
  });

  group('SahteGrupServisi Akış Testleri', () {
    late SahteGrupServisi servis;

    setUp(() {
      servis = SahteGrupServisi();
    });

    test('Grup oluşturma, davet koduyla bulma ve üye sıralaması', () async {
      // 1. Grup oluştur
      final grup = await servis.grupOlustur(
        grupAdi: 'Dahiliye Tayfa',
        olusturanUid: 'kurucu_1',
        takmaAd: 'Dr. Kurucu',
        hedefKonu: 30,
        hedefSoru: 600,
      );

      expect(grup.ad, 'Dahiliye Tayfa');
      expect(grup.davetKodu.length, 6);

      // 2. Davet kodu ile grubu bul (küçük harf toleransı)
      final bulunan = await servis.kodIleGrupBul(grup.davetKodu.toLowerCase());
      expect(bulunan, isNotNull);
      expect(bulunan!.id, grup.id);

      // 3. İkinci üye katılsın
      await servis.grubaKatil(
        grupId: grup.id,
        uid: 'uye_2',
        takmaAd: 'Dr. Çalışkan',
        konuSayisi: 5, // 50 puan
        soruSayisi: 100, // 100 puan -> Toplam 150
        sonDers: 'Patoloji',
      );

      // Kurucunun puanını güncelle
      await servis.puanGuncelle(
        grupId: grup.id,
        uid: 'kurucu_1',
        takmaAd: 'Dr. Kurucu',
        konuSayisi: 2, // 20 puan
        soruSayisi: 30, // 30 puan -> Toplam 50
        sonDers: 'Anatomi',
      );

      // 4. Sıralı üyeleri al
      final uyeler = await servis.uyeleriGetir(grup.id);
      expect(uyeler.length, 2);
      // En yüksek puanlı ilk sırada olmalı
      expect(uyeler[0].uid, 'uye_2');
      expect(uyeler[0].puan, 150);
      expect(uyeler[1].uid, 'kurucu_1');
      expect(uyeler[1].puan, 50);

      // 5. Üye gruptan ayrılsın
      await servis.gruptanAyril(grupId: grup.id, uid: 'uye_2');
      final kalanlar = await servis.uyeleriGetir(grup.id);
      expect(kalanlar.length, 1);
      expect(kalanlar.single.uid, 'kurucu_1');
    });
  });

  group('PlanDeposu Haftalık Grup Puanı ve Konu/Soru Entegrasyonu', () {
    test('Haftalık tamamlanan konu ve çözülen soru doğru puanlanır', () async {
      final kayit = const BellekKaydi();
      final depo = PlanDeposu(kayit: kayit);
      await depo.yukle();

      final bugun = DateTime.now();
      final ders = depo.dersEkle('Farmakoloji', null)!;
      final k1 = depo.konuEkle(ders.id, 'Antibiyotikler')!;
      final k2 = depo.konuEkle(ders.id, 'Otonom')!;

      // 2 konuyu yerleştirip "Çalıştım" yap
      final c1 = depo.calismaEkle(k1.id, bugun)!;
      depo.calistim(c1.id, bugun);

      final c2 = depo.calismaEkle(k2.id, bugun)!;
      depo.calistim(c2.id, bugun);

      // Bugün 40 soru ekle
      depo.soruEkle(bugun, 40);

      expect(depo.haftalikTamamlananKonuSayisi(bugun), 2);
      expect(depo.haftalikCozulenSoruSayisi(bugun), 40);
      // Puan = (2 * 10) + 40 = 60
      expect(depo.haftalikGrupPuani(bugun), 60);

      // Aktif grup kimliği kaydı
      depo.aktifGrupAyarla('grup_test_123');
      expect(depo.aktifGrupId, 'grup_test_123');
    });

    testWidgets('GrupEkrani boş durum ve arayüz elemanları görüntülenir', (tester) async {
      final kayit = const BellekKaydi();
      final depo = PlanDeposu(kayit: kayit);
      await depo.yukle();

      final kimlik = SahteKimlikServisi(
        baslangicKullanicisi: const KullaniciBilgisi(
          uid: 'doktor_1',
          eposta: 'doktor@tus.com',
          takmaAd: 'Dr. Alp',
        ),
      );
      final servis = SahteGrupServisi();

      await tester.pumpWidget(
        KimlikKapsami(
          servis: kimlik,
          child: DepoKapsami(
            depo: depo,
            child: MaterialApp(
              home: GrupEkrani(servis: servis),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Çalışma Grubu & Puan Tablosu'), findsOneWidget);
      expect(find.text('Gruba Katıl'), findsOneWidget);
      expect(find.text('Yeni Grup Oluştur'), findsOneWidget);
    });
  });
}
