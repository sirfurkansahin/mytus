// Kayıt güvenliği (A1): cihaza yazılamadığında hata sessiz kalmaz,
// fotoğraflar cihazda tek kopya tutulur ve silinen notun fotoğrafı kalmaz.

import 'package:app/app/kayit_hatasi_seridi.dart';
import 'package:app/core/tarih.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/auth/kimlik_servisi.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/kutuphane/modeller.dart';
import 'package:app/features/senkronizasyon/bulut_kaynagi.dart';
import 'package:app/features/senkronizasyon/bulut_senkron_servisi.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'yardimci.dart';

/// Bir cihazı (yerel kayıt + eşitleme + depo) birlikte kurar.
class _Cihaz {
  _Cihaz(BulutKaynagi bulut, String cihazId) : yerel = BellekKaydi() {
    senkron = BulutSenkronServisi(
      yerelKayit: yerel,
      bulutKaynagi: bulut,
      gonderimGecikmesi: Duration.zero,
      cihazId: cihazId,
    );
    depo = PlanDeposu(kayit: senkron, kayitGecikmesi: Duration.zero);
    senkron.depoBagla(depo);
  }

  final BellekKaydi yerel;
  late final BulutSenkronServisi senkron;
  late final PlanDeposu depo;

  Future<void> planKur() async {
    await depo.yukle();
    await depo.karsilamayiTamamla(
      sinavTarihi: resmiSinavTarihi,
      secilenDersler: const [HazirDers('Patoloji', DersGrubu.temel)],
      mufredatTuru: MufredatTuru.klasik,
    );
    await depo.kitapEkle(
      Kitap(
        id: 'k_patoloji',
        ad: 'Patoloji Notlarım',
        eklenmeTarihi: DateTime(2026, 11, 25),
        bolumler: const [KitapBolumu(id: 'b_1', ad: 'Hücre Hasarı')],
      ),
    );
  }
}

int _kacKez(String metin, String aranan) {
  var sayi = 0;
  var i = metin.indexOf(aranan);
  while (i >= 0) {
    sayi++;
    i = metin.indexOf(aranan, i + aranan.length);
  }
  return sayi;
}

void main() {
  group('Cihaza yazılamayınca (depo dolu)', () {
    test('hata işaretlenir; yer açılınca "Tekrar dene" verinin tamamını yazar',
        () async {
      final kayit = BellekKaydi();
      final depo = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
      await depo.yukle();
      await depo.karsilamayiTamamla(
        sinavTarihi: resmiSinavTarihi,
        secilenDersler: const [HazirDers('Patoloji', DersGrubu.temel)],
        mufredatTuru: MufredatTuru.klasik,
      );
      expect(depo.kayitHatasi, isFalse);

      kayit.yazmaHatasi = true;
      depo.dersEkle('Depo doluyken eklenen ders');
      await depo.hemenKaydet();
      expect(depo.kayitHatasi, isTrue);
      expect(kayit.icerik, isNot(contains('Depo doluyken eklenen ders')));

      // Kullanıcı yer açar ve "Tekrar dene"ye basar.
      kayit.yazmaHatasi = false;
      await depo.kaydetmeyiYenidenDene();
      expect(depo.kayitHatasi, isFalse);
      expect(kayit.icerik, contains('Depo doluyken eklenen ders'));
    });

    test('giriş yapılmışsa değişiklik cihaza yazılamasa da buluta gider',
        () async {
      final bulut = SahteBulutKaynagi();
      final telefon = _Cihaz(bulut, 'telefon');
      await telefon.planKur();
      await telefon.senkron.oturumAcildi(
        const KullaniciBilgisi(uid: 'uid_dolu', eposta: 'dolu@mytus.com'),
      );

      telefon.yerel.yazmaHatasi = true;
      telefon.depo.dersEkle('Bulutta korunan ders');
      await telefon.depo.hemenKaydet();

      expect(telefon.depo.kayitHatasi, isTrue);
      expect(
        bulut.kullaniciBolumleri['uid_dolu']!['plan'],
        contains('Bulutta korunan ders'),
      );
    });

    testWidgets('ekranın üstünde uyarı şeridi çıkar, kayıt olunca kaybolur',
        (tester) async {
      final kayit = BellekKaydi();
      final depo = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
      await depo.yukle();
      await depo.karsilamayiTamamla(
        sinavTarihi: resmiSinavTarihi,
        secilenDersler: const [HazirDers('Patoloji', DersGrubu.temel)],
        mufredatTuru: MufredatTuru.klasik,
      );

      await tester.pumpWidget(MyTusApp(deposu: depo, ftNative: SahteNative()));
      await tester.pumpAndSettle();
      expect(find.byType(KayitHatasiSeridi), findsNothing);

      // Yazma denemesi yalnız mikro görevlerle ilerler; pump bunları bitirir.
      kayit.yazmaHatasi = true;
      depo.soruEkle(DateTime(2026, 11, 25), 20);
      await tester.pumpAndSettle();
      expect(depo.kayitHatasi, isTrue);
      expect(find.byType(KayitHatasiSeridi), findsOneWidget);
      expect(find.textContaining('kaydedilemedi'), findsOneWidget);

      kayit.yazmaHatasi = false;
      await tester.tap(find.byKey(const ValueKey('kayit_hatasi_tekrar_dene')));
      await tester.pumpAndSettle();
      expect(depo.kayitHatasi, isFalse);
      expect(find.byType(KayitHatasiSeridi), findsNothing);
      expect(kayit.icerik, contains('"2026-11-25":20'));
    });
  });

  group('Fotoğraflı notlar', () {
    test('giriş yapılmışken fotoğraf cihazda tek kopya saklanır', () async {
      final bulut = SahteBulutKaynagi();
      final telefon = _Cihaz(bulut, 'telefon');
      await telefon.planKur();
      await telefon.senkron.oturumAcildi(
        const KullaniciBilgisi(uid: 'uid_foto', eposta: 'foto@mytus.com'),
      );

      final foto = List.filled(2000, 'QUJD').join();
      await telefon.depo.kitapBolumNotuEkle(
        'k_patoloji',
        'b_1',
        BolumNotu(
          id: 'not_foto',
          metin: 'Tablo',
          resimBase64: foto,
          olusturmaTarihi: DateTime(2026, 11, 25),
        ),
      );

      final tumDepolama = [
        telefon.yerel.icerik ?? '',
        ...telefon.yerel.ekAnahtarlar.values,
      ].join('\n');
      expect(_kacKez(tumDepolama, foto), 1);
      // Fotoğraf buluta gitmez.
      expect(
        bulut.kullaniciBolumleri['uid_foto']!.values.join(),
        isNot(contains(foto)),
      );
    });

    test('silinen notun fotoğrafı cihazda kalmaz (çıkışta da taşınmaz)',
        () async {
      final bulut = SahteBulutKaynagi();
      final telefon = _Cihaz(bulut, 'telefon');
      await telefon.planKur();
      await telefon.senkron.oturumAcildi(
        const KullaniciBilgisi(uid: 'uid_sil', eposta: 'sil@mytus.com'),
      );

      final foto = List.filled(2000, 'WFla').join();
      await telefon.depo.kitapBolumNotuEkle(
        'k_patoloji',
        'b_1',
        BolumNotu(
          id: 'silinecek_not',
          resimBase64: foto,
          olusturmaTarihi: DateTime(2026, 11, 25),
        ),
      );
      await telefon.depo.kitapBolumNotuSil(
        'k_patoloji',
        'b_1',
        'silinecek_not',
      );
      expect(telefon.yerel.icerik, isNot(contains(foto)));

      await telefon.senkron.oturumKapatildi();
      expect(
        telefon.yerel.ekAnahtarlar['mytus_photos_uid_sil'] ?? '',
        isNot(contains(foto)),
      );
    });
  });
}
