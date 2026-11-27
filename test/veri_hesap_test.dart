// Veri ve hesap düzeltmeleri (A4, A5, A6, A8). Bu testler önce kanıt testi
// olarak hatayı gösterdi (KANIT-01, 05, 06, 15, 16); düzeltmeden sonra kalıcı.

import 'dart:convert';

import 'package:app/core/tarih.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/auth/kimlik_servisi.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/grup/modeller.dart';
import 'package:app/features/takvim/calisma.dart';
import 'package:app/features/takvim/tekrar_motoru.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firebase'deki "yakın zamanda giriş gerekli" durumunu taklit eder: şifreyle
/// yeniden doğrulanmadan hesap silinemez.
class _YeniGirisIsteyenKimlik extends SahteKimlikServisi {
  _YeniGirisIsteyenKimlik({super.baslangicKullanicisi});

  @override
  Future<void> hesabiSil() async {
    if (!yenidenDogrulandi) {
      throw const KimlikHatasi(
        'Güvenlik için önce tekrar giriş yapmanız gerekiyor.',
        kod: 'requires-recent-login',
      );
    }
    await super.hesabiSil();
  }
}

void main() {
  group('Eski kayıtların müfredatı', () {
    Future<PlanDeposu> yukle(List<Map<String, Object>> dersler) async {
      final depo = PlanDeposu(
        kayit: BellekKaydi(
          icerik: jsonEncode({'karsilamaTamam': true, 'dersler': dersler}),
        ),
        kayitGecikmesi: Duration.zero,
      );
      await depo.yukle();
      return depo;
    }

    test('müfredat alanı yoksa Klinik dersi olan kayıt Klasik açılır', () async {
      final depo = await yukle([
        {'id': 1, 'ad': 'Patoloji', 'grup': 'temel'},
        {'id': 2, 'ad': 'Dahiliye', 'grup': 'klinik'},
      ]);
      expect(depo.mufredatTuru, MufredatTuru.klasik);
    });

    test('müfredat alanı yoksa yalnız Temel dersli kayıt SpeeTUS açılır',
        () async {
      final depo = await yukle([
        {'id': 1, 'ad': 'Sistem 1', 'grup': 'temel'},
      ]);
      expect(depo.mufredatTuru, MufredatTuru.speetus);
    });
  });

  test('geçersiz alan içeren yedek hiçbir veriyi değiştirmez', () async {
    final depo = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
    await depo.yukle();
    await depo.karsilamayiTamamla(
      sinavTarihi: DateTime(2027, 8, 22),
      secilenDersler: const [
        HazirDers('Anatomi', DersGrubu.temel),
        HazirDers('Dahiliye', DersGrubu.klinik),
      ],
      mufredatTuru: MufredatTuru.klasik,
    );
    final onceki = depo.tumDersler.map((d) => d.ad).toList();

    const bozukYedek = '{"karsilamaTamam":true,"sinavTarihi":"2027-08-22",'
        '"dersler":[{"id":1,"ad":"Yedekteki Ders","grup":"temel"}],'
        '"denemeler":[{"id":"d1","ad":"Bozuk","tarih":"2026-11-01",'
        '"temel":"bozuk"}]}';

    expect(depo.yedektenYukle(bozukYedek), isFalse);
    expect(depo.tumDersler.map((d) => d.ad).toList(), onceki);
    expect(depo.mufredatTuru, MufredatTuru.klasik);
  });

  test('henüz çalışılmamış konuların tekrarları günlük sınıra sayılmaz', () {
    final bugun = DateTime(2026, 12, 1);
    final calismalar = <Calisma>[
      for (var i = 1; i <= 10; i++) Calisma(id: i, konuId: i, tarih: bugun),
      Calisma(id: 11, konuId: 11, tarih: bugun, tamam: true),
    ];
    final tekrarlar = tekrarlariHesapla(
      calismalar: calismalar,
      sinavTarihi: DateTime(2027, 8, 22),
      bugun: bugun,
      gunlukSinir: 10,
    );
    final r1 = tekrarlar.firstWhere((t) => t.calismaId == 11 && t.no == 1);
    expect(r1.tarih, DateTime(2026, 12, 2));
    // Çalışılmamış konuların taslak tekrarları yine de takvimde görünür.
    expect(tekrarlar.where((t) => t.calismaId == 1), isNotEmpty);
  });

  group('Grup puanı haftalık', () {
    final buHafta = haftaBasi(DateTime.now());
    final gecenHafta = gunEkle(buHafta, -7);
    GrupUyesi uye(String uid, DateTime hafta, int konu, int soru) => GrupUyesi(
          uid: uid,
          takmaAd: uid,
          haftaBaslangici: tarihAnahtari(hafta),
          konuSayisi: konu,
          soruSayisi: soru,
          guncellemeTarihi: hafta,
        );
    final grup = Grup(
      id: 'g1',
      ad: 'Grup',
      davetKodu: 'ABCDEF',
      olusturanUid: 'eski',
      olusturmaTarihi: gecenHafta,
    );

    test('geçen haftanın sayıları bu haftanın hedefine sayılmaz', () {
      final durum = GrupHedefDurumu.hesapla(
        uyeler: [uye('eski', gecenHafta, 5, 300), uye('yeni', buHafta, 1, 20)],
        grup: grup,
      );
      expect(durum.toplamKonu, 1);
      expect(durum.toplamSoru, 20);
    });

    test('sıralamada geçen haftanın puanı sıfır sayılır', () {
      final sira = GrupUyesi.haftalikSirala(
        [uye('eski', gecenHafta, 5, 300), uye('yeni', buHafta, 1, 20)],
        DateTime.now(),
      );
      expect(sira.first.uid, 'yeni');
      expect(sira.last.puan, 0);
    });
  });

  group('Hesap silme', () {
    const kullanici = KullaniciBilgisi(
      uid: 'uid_sil',
      eposta: 'sil@mytus.com',
      takmaAd: 'Silinecek',
    );

    test('şifre yanlışsa hiçbir şey silinmez', () async {
      final kimlik = _YeniGirisIsteyenKimlik(baslangicKullanicisi: kullanici);
      var veriSilindi = false;
      await expectLater(
        hesabiGuvenliSil(
          kimlik: kimlik,
          sifre: 'yanlis',
          verileriSil: () async {
          veriSilindi = true;
        },
        ),
        throwsA(isA<KimlikHatasi>()),
      );
      expect(veriSilindi, isFalse);
      expect(kimlik.aktifKullanici, isNotNull);
    });

    test('şifre doğruysa önce doğrulanır, sonra veri ve hesap silinir',
        () async {
      final kimlik = _YeniGirisIsteyenKimlik(baslangicKullanicisi: kullanici);
      var veriSilindi = false;
      await hesabiGuvenliSil(
        kimlik: kimlik,
        sifre: '123456',
        verileriSil: () async {
          veriSilindi = true;
        },
      );
      expect(veriSilindi, isTrue);
      expect(kimlik.aktifKullanici, isNull);
    });
  });
}
