import 'package:app/features/auth/kimlik_servisi.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
}
