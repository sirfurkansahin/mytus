import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/auth/kimlik_servisi.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'yardimci.dart';

void main() {
  group('SahteKimlikServisi ve hata mesajları', () {
    test('kayıt ol, çıkış yap ve tekrar giriş yap akışı çalışır', () async {
      final servis = SahteKimlikServisi();
      expect(servis.aktifKullanici, isNull);
      expect(servis.hazirMi, isTrue);

      final kullanici = await servis.kayitOl(
        eposta: 'doktor@mytus.com',
        sifre: '123456',
        takmaAd: 'Dr. Furkan',
      );
      expect(kullanici.eposta, 'doktor@mytus.com');
      expect(kullanici.takmaAd, 'Dr. Furkan');
      expect(servis.aktifKullanici?.uid, kullanici.uid);

      await servis.cikisYap();
      expect(servis.aktifKullanici, isNull);

      final tekrar = await servis.girisYap(
        eposta: 'doktor@mytus.com',
        sifre: '123456',
      );
      expect(tekrar.uid, kullanici.uid);
    });

    test('hatalı şifre ve zayıf şifrede anlamlı Türkçe hata fırlatır', () async {
      final servis = SahteKimlikServisi();

      expect(
        () => servis.kayitOl(eposta: 'test@mytus.com', sifre: '123'),
        throwsA(isA<KimlikHatasi>().having(
          (e) => e.kod,
          'kod',
          'weak-password',
        )),
      );

      await servis.kayitOl(eposta: 'test@mytus.com', sifre: '123456');
      await servis.cikisYap();

      expect(
        () => servis.girisYap(eposta: 'test@mytus.com', sifre: 'yanlis'),
        throwsA(isA<KimlikHatasi>().having(
          (e) => e.kod,
          'kod',
          'invalid-credential',
        )),
      );
    });

    test('şifre sıfırlama ve hesap silme çalışır', () async {
      final servis = SahteKimlikServisi();
      await servis.kayitOl(eposta: 'sil@mytus.com', sifre: '123456');
      await servis.sifreSifirlamaGonder(eposta: 'sil@mytus.com');
      expect(servis.sifirlamaGonderilenler, ['sil@mytus.com']);

      await servis.hesabiSil();
      expect(servis.aktifKullanici, isNull);
      expect(servis.silmeSayisi, 1);
    });

    test('Firebase hata kodları Türkçe mesajlara çevrilir', () {
      expect(
        FirebaseKimlikServisi.firebaseHataMesaji('email-already-in-use'),
        contains('zaten bir hesap var'),
      );
      expect(
        FirebaseKimlikServisi.firebaseHataMesaji('invalid-credential'),
        contains('hatalı'),
      );
    });

    testWidgets(
      'oturum yokken GirisEkrani açılır, kayıt olunca uygulamaya geçer',
      (tester) async {
        final depo = PlanDeposu(kayit: BellekKaydi());
        await depo.yukle();
        final kimlik = SahteKimlikServisi();

        await tester.pumpWidget(
          MyTusApp(
            deposu: depo,
            ftNative: SahteNative(),
            kimlikServisi: kimlik,
          ),
        );
        await tester.pumpAndSettle();

        // Başlangıçta giriş ekranı görünür.
        expect(find.text('Hesabına Giriş Yap'), findsOneWidget);

        // Kayıt Ol sekmesine geç.
        await tester.tap(find.text('Kayıt Ol'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('giris_takma_ad')),
          'Dr. Furkan',
        );
        await tester.enterText(
          find.byKey(const ValueKey('giris_eposta')),
          'furkan@mytus.com',
        );
        await tester.enterText(
          find.byKey(const ValueKey('giris_sifre')),
          '123456',
        );

        // KVKK onayını işaretlemeden gönderince uyarı verir.
        final onayButonu = find.byKey(const ValueKey('giris_onay_butonu'));
        await tester.ensureVisible(onayButonu);
        await tester.pumpAndSettle();
        await tester.tap(onayButonu);
        await tester.pumpAndSettle();
        expect(find.textContaining('KVKK'), findsWidgets);

        // KVKK kutusunu işaretle ve kayıt ol.
        final kvkkKutusu = find.byKey(const ValueKey('giris_kvkk_onay'));
        await tester.ensureVisible(kvkkKutusu);
        await tester.pumpAndSettle();
        await tester.tap(kvkkKutusu);
        await tester.pumpAndSettle();
        await tester.ensureVisible(onayButonu);
        await tester.pumpAndSettle();
        await tester.tap(onayButonu);
        await tester.pumpAndSettle();

        // Oturum açıldı, Karşılama ekranına geçildi.
        expect(kimlik.aktifKullanici?.eposta, 'furkan@mytus.com');
        expect(find.text('Çalışma planını kuralım'), findsOneWidget);
      },
    );

    testWidgets(
      'giriş ekranında "Hesap Açmadan Devam Et" seçilince misafir modunda karşılama/ana ekrana geçer',
      (tester) async {
        final depo = PlanDeposu(kayit: BellekKaydi());
        await depo.yukle();
        final kimlik = SahteKimlikServisi();

        await tester.pumpWidget(
          MyTusApp(
            deposu: depo,
            ftNative: SahteNative(),
            kimlikServisi: kimlik,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hesabına Giriş Yap'), findsOneWidget);
        expect(depo.misafirModu, isFalse);

        // Hesapsız devam et butonuna dokun.
        final misafirButonu = find.byKey(const ValueKey('hesapsiz_devam_et_butonu'));
        await tester.ensureVisible(misafirButonu);
        await tester.pumpAndSettle();
        await tester.tap(misafirButonu);
        await tester.pumpAndSettle();

        // Karşılama ekranına geçildi ve misafir modu aktif oldu.
        expect(depo.misafirModu, isTrue);
        expect(find.text('Çalışma planını kuralım'), findsOneWidget);
        expect(kimlik.aktifKullanici, isNull);
      },
    );

    testWidgets(
      'misafir modundayken Ayarlar ekranında Buluta Bağlan kartı görünür ve giriş yapılınca hesaba bağlanır',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final depo = PlanDeposu(kayit: BellekKaydi());
        await depo.yukle();
        await depo.karsilamayiTamamla(
          sinavTarihi: DateTime(2027, 8, 22),
          secilenDersler: const [],
          mufredatTuru: MufredatTuru.speetus,
        );
        await depo.misafirModunuAyarla(true);
        final kimlik = SahteKimlikServisi();

        await tester.pumpWidget(
          MyTusApp(
            deposu: depo,
            ftNative: SahteNative(),
            kimlikServisi: kimlik,
          ),
        );
        await tester.pumpAndSettle();

        // Ayarlar ikonuna bas
        final ayarlarDugmesi = find.byTooltip('Ayarlar');
        if (ayarlarDugmesi.evaluate().isNotEmpty) {
          await tester.tap(ayarlarDugmesi);
          await tester.pumpAndSettle();
        }

        // Bulut Hesabına Bağlan kartı görünmeli
        expect(find.text('Bulut Hesabına Bağlan'), findsOneWidget);
        expect(find.text('Şu an yerel (hesapsız) moddasın'), findsOneWidget);

        // Giriş Yap / Hesap Oluştur butonuna dokun
        final girisButonu = find.byKey(const ValueKey('ayarlar_giris_yap_butonu'));
        await tester.ensureVisible(girisButonu);
        await tester.pumpAndSettle();
        await tester.tap(girisButonu);
        await tester.pumpAndSettle();

        // Giriş ekranı açılır (kapatma butonu ile)
        expect(find.text('Bulut Hesabı'), findsOneWidget);

        // Kayıt Ol sekmesine geç
        await tester.tap(find.text('Kayıt Ol'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('giris_takma_ad')),
          'Dr. Furkan',
        );
        await tester.enterText(
          find.byKey(const ValueKey('giris_eposta')),
          'doktor@mytus.com',
        );
        await tester.enterText(
          find.byKey(const ValueKey('giris_sifre')),
          '123456',
        );

        final kvkkKutusu = find.byKey(const ValueKey('giris_kvkk_onay'));
        await tester.ensureVisible(kvkkKutusu);
        await tester.pumpAndSettle();
        await tester.tap(kvkkKutusu);
        await tester.pumpAndSettle();

        final onayla = find.byKey(const ValueKey('giris_onay_butonu'));
        await tester.ensureVisible(onayla);
        await tester.pumpAndSettle();
        await tester.tap(onayla);
        await tester.pumpAndSettle();

        // Başarılı kayıttan sonra Ayarlar'a döner ve HesapKarti görünür
        expect(kimlik.aktifKullanici?.eposta, 'doktor@mytus.com');
        expect(depo.misafirModu, isFalse);
        final cikisButonu = find.byKey(const ValueKey('hesap_cikis_butonu'));
        await tester.ensureVisible(cikisButonu);
        expect(cikisButonu, findsOneWidget);
      },
    );
  });
}
