// KANIT TESTLERİ (yalnızca son dal: claude/esnek-giris-bulut)
//
// Bulut eşitleme, hesap ve çalışma grubu akışlarındaki şüpheli hatalar.
// Testler bilerek "olması gereken" davranışı ister; BAŞARISIZ olan test,
// raporlanan hatanın gerçekten var olduğunu gösterir.
// Uygulama kodu değiştirilmedi; yalnızca test dosyaları eklendi.

import 'dart:async';

import 'package:app/core/tarih.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/auth/kimlik_servisi.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/grup/modeller.dart';
import 'package:app/features/kutuphane/modeller.dart';
import 'package:app/features/senkronizasyon/bulut_kaynagi.dart';
import 'package:app/features/senkronizasyon/bulut_senkron_servisi.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'yardimci.dart';

/// Bir cihazı (yerel kayıt + eşitleme + depo) birlikte kurar.
class Cihaz {
  Cihaz(BulutKaynagi bulut, String cihazId, {BellekKaydi? kayit})
      : yerel = kayit ?? BellekKaydi() {
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

  Future<void> planKur(String dersAdi, DersGrubu grup) async {
    await depo.yukle();
    await depo.karsilamayiTamamla(
      sinavTarihi: resmiSinavTarihi,
      secilenDersler: [HazirDers(dersAdi, grup)],
      mufredatTuru: MufredatTuru.klasik,
    );
  }
}

/// Firestore'daki gibi davranan sahte kaynak: her bölüm ayrı belge, her belgede
/// onu son yazan cihazın kimliği durur. Dinleme olayı, FirestoreBulutKaynagi
/// .bolumleriDinle ile aynı kuralı izler: belgeler kimliğe göre sıralı gelir ve
/// sonCihazId = listedeki SON belgenin cihazId değeri.
class BelgeBazliKaynak implements BulutKaynagi {
  final Map<String, ({String veri, String cihazId})> belgeler = {};
  final StreamController<({Map<String, String> bolumler, String? sonCihazId})>
      _kanal = StreamController.broadcast();

  ({Map<String, String> bolumler, String? sonCihazId}) _goruntu() {
    final kimlikler = belgeler.keys.toList()..sort();
    final bolumler = <String, String>{};
    String? sonCihaz;
    for (final k in kimlikler) {
      bolumler[k] = belgeler[k]!.veri;
      sonCihaz = belgeler[k]!.cihazId;
    }
    return (bolumler: bolumler, sonCihazId: sonCihaz);
  }

  @override
  Future<void> profilKaydet({
    required String uid,
    required String eposta,
    String? takmaAd,
  }) async {}

  @override
  Future<Map<String, String>> bolumleriOku(String uid) async =>
      _goruntu().bolumler;

  @override
  Future<void> bolumleriYaz({
    required String uid,
    required Map<String, String> degisenBolumler,
    required String cihazId,
  }) async {
    for (final e in degisenBolumler.entries) {
      belgeler[e.key] = (veri: e.value, cihazId: cihazId);
    }
    _kanal.add(_goruntu());
  }

  @override
  Stream<({Map<String, String> bolumler, String? sonCihazId})> bolumleriDinle(
    String uid,
  ) =>
      _kanal.stream;

  @override
  Future<void> kullaniciVerileriniSil(String uid) async => belgeler.clear();
}

/// Firebase'deki "requires-recent-login" durumunu taklit eder: hesap silinemez.
class YeniGirisIsteyenKimlik extends SahteKimlikServisi {
  YeniGirisIsteyenKimlik({super.baslangicKullanicisi});

  @override
  Future<void> hesabiSil() async {
    throw const KimlikHatasi(
      'Güvenlik için önce çıkış yapıp tekrar giriş yapmanız gerekiyor.',
      kod: 'requires-recent-login',
    );
  }
}

Future<void> biraz() => Future<void>.delayed(const Duration(milliseconds: 30));

DenemeSinavi deneme(String id) => DenemeSinavi(
      id: id,
      ad: 'Deneme $id',
      tarih: DateTime(2026, 11, 20),
      temel: const DenemeOturumu(dogru: 50, yanlis: 10, bos: 40),
    );

int kacKez(String metin, String aranan) {
  var sayi = 0;
  var i = metin.indexOf(aranan);
  while (i >= 0) {
    sayi++;
    i = metin.indexOf(aranan, i + aranan.length);
  }
  return sayi;
}

void main() {
  test(
    'KANIT-07 başka cihazdan değişiklik gelince aktif çalışma grubu bağlantısı siliniyor',
    () async {
      final bulut = SahteBulutKaynagi();
      final telefon = Cihaz(bulut, 'telefon');
      await telefon.planKur('Patoloji', DersGrubu.temel);
      const kullanici = KullaniciBilgisi(uid: 'uid_7', eposta: 'yedi@mytus.com');
      await telefon.senkron.oturumAcildi(kullanici);

      telefon.depo.aktifGrupAyarla('grup_abc');
      await telefon.depo.hemenKaydet();
      expect(telefon.depo.aktifGrupId, 'grup_abc');

      // Aynı hesaptaki tablet bir deneme ekler (yalnızca "denemeler" bölümü).
      final tablet = Cihaz(bulut, 'tablet');
      await tablet.depo.yukle();
      await tablet.senkron.oturumAcildi(kullanici);
      await tablet.depo.denemeEkle(deneme('tablet_1'));
      await biraz();

      expect(
        telefon.depo.aktifGrupId,
        'grup_abc',
        reason: 'aktifGrupId, bolum_ayirici.dart bölüm listesinde yok; buluttan '
            'gelen veri uygulanınca telefon gruptan düşmüş görünüyor.',
      );
    },
  );

  test(
    'KANIT-08 çevrimdışıyken yapılan değişiklik uygulama yeniden açılınca kayboluyor',
    () async {
      final bulut = SahteBulutKaynagi();
      final yerel = BellekKaydi();
      final ilkAcilis = Cihaz(bulut, 'telefon', kayit: yerel);
      await ilkAcilis.planKur('Patoloji', DersGrubu.temel);
      const kullanici = KullaniciBilgisi(uid: 'uid_8', eposta: 'sekiz@mytus.com');
      await ilkAcilis.senkron.oturumAcildi(kullanici);

      // Nöbette internet yok: yeni ders eklenir, yalnız cihaza yazılır.
      bulut.cevrimdisi = true;
      ilkAcilis.depo.dersEkle('Nöbette eklenen ders');
      await ilkAcilis.depo.hemenKaydet();
      expect(yerel.icerik, contains('Nöbette eklenen ders'));
      ilkAcilis.senkron.dispose();

      // Uygulama kapanıp açılır, internet gelmiştir; oturum hâlâ açıktır.
      bulut.cevrimdisi = false;
      final ikinciAcilis = Cihaz(bulut, 'telefon_yeniden', kayit: yerel);
      await ikinciAcilis.depo.yukle();
      await ikinciAcilis.senkron.oturumAcildi(kullanici);

      expect(
        ikinciAcilis.depo.tumDersler.map((d) => d.ad),
        contains('Nöbette eklenen ders'),
        reason: 'Gönderilemeyen değişiklikler yalnız bellekte tutuluyor; açılışta '
            'bulut verisi her zaman cihazdakinin üstüne yazılıyor (cihazdaki '
            'hâli gizli mytus_backup_<uid> anahtarına taşınıyor).',
      );
    },
  );

  test(
    'KANIT-09 giriş anında bulut okunamazsa cihazın eski verisi sonradan buluttakini siliyor',
    () async {
      final bulut = SahteBulutKaynagi();
      const kullanici = KullaniciBilgisi(uid: 'uid_9', eposta: 'dokuz@mytus.com');

      // A cihazı: hesapta bir deneme kaydı var.
      final a = Cihaz(bulut, 'cihaz_a');
      await a.planKur('Patoloji', DersGrubu.temel);
      await a.senkron.oturumAcildi(kullanici);
      await a.depo.denemeEkle(deneme('a_1'));
      expect(bulut.kullaniciBolumleri['uid_9']!['denemeler'], contains('a_1'));

      // B cihazı: kendi (misafir) verisi var; giriş anında bağlantı yok.
      final b = Cihaz(bulut, 'cihaz_b');
      await b.planKur('Dahiliye', DersGrubu.klinik);
      bulut.cevrimdisi = true;
      await b.senkron.oturumAcildi(kullanici);
      bulut.cevrimdisi = false;

      // B'de küçük bir değişiklik: bekleyen tüm bölümler gönderilir.
      b.depo.soruEkle(DateTime(2026, 11, 25), 5);
      await b.depo.hemenKaydet();
      await biraz();

      expect(
        bulut.kullaniciBolumleri['uid_9']!['denemeler'],
        contains('a_1'),
        reason: 'Bulut okunamadığı için B "bulut boş" sanıp ilk giriş göçü '
            'yapıyor; bekleyen eski bölümleri sonra buluta yazınca A cihazının '
            'deneme kaydı siliniyor.',
      );
    },
  );

  test(
    'KANIT-10 cihazda ve bulutta veri varken giriş yapınca kullanıcıya sorulmuyor',
    () async {
      final bulut = SahteBulutKaynagi();
      const kullanici = KullaniciBilgisi(uid: 'uid_10', eposta: 'on@mytus.com');
      final a = Cihaz(bulut, 'cihaz_a');
      await a.planKur('Patoloji', DersGrubu.temel);
      await a.senkron.oturumAcildi(kullanici);

      // B cihazında misafir modunda haftalarca çalışılmış veri.
      final b = Cihaz(bulut, 'cihaz_b');
      await b.planKur('Dahiliye', DersGrubu.klinik);
      await b.senkron.oturumAcildi(kullanici);

      expect(
        b.depo.tumDersler.map((d) => d.ad),
        contains('Dahiliye'),
        reason: 'DECISIONS.md: "İkisinde de varsa kullanıcıya sorulur". Kod '
            'sormadan bulut verisini uyguluyor; cihazdaki veri ekrandan '
            'kayboluyor, yalnızca gizli yedek anahtarında kalıyor '
            '(${b.yerel.ekAnahtarlar.keys.toList()}).',
      );
    },
  );

  test(
    'KANIT-11 son "plan" belgesini yazan cihaz, öteki cihazın değişikliklerini görmüyor',
    () async {
      final kaynak = BelgeBazliKaynak();
      const kullanici = KullaniciBilgisi(uid: 'uid_11', eposta: 'onbir@mytus.com');
      final a = Cihaz(kaynak, 'cihaz_a');
      await a.planKur('Patoloji', DersGrubu.temel);
      await a.senkron.oturumAcildi(kullanici);

      final b = Cihaz(kaynak, 'cihaz_b');
      await b.depo.yukle();
      await b.senkron.oturumAcildi(kullanici);

      // A bir ders ekler: "plan" belgesini en son A yazmış olur.
      a.depo.dersEkle('A cihazının dersi');
      await a.depo.hemenKaydet();
      await biraz();

      // B bir deneme ekler: yalnızca "denemeler" belgesi B ile yazılır.
      await b.depo.denemeEkle(deneme('b_1'));
      await biraz();

      final yazanlar = {
        for (final e in kaynak.belgeler.entries) e.key: e.value.cihazId,
      };
      expect(
        a.depo.denemeler.map((d) => d.id),
        contains('b_1'),
        reason: 'bolumleriDinle, sonCihazId olarak değişikliği yapan cihazı '
            'değil, sıradaki son belgeyi ("plan") yazan cihazı veriyor; A bunu '
            'kendi değişikliği sanıp yok sayıyor. Belgeyi yazanlar: $yazanlar',
      );
    },
  );

  test(
    'KANIT-12 giriş yapılmışken "Tüm verileri sıfırla" buluttaki veriyi de siliyor',
    () async {
      final bulut = SahteBulutKaynagi();
      const kullanici = KullaniciBilgisi(uid: 'uid_12', eposta: 'oniki@mytus.com');
      final telefon = Cihaz(bulut, 'telefon');
      await telefon.planKur('Patoloji', DersGrubu.temel);
      await telefon.senkron.oturumAcildi(kullanici);
      expect(bulut.kullaniciBolumleri['uid_12']!['plan'], contains('Patoloji'));

      // Ayarlar > "Tüm verileri sıfırla" uyarısı: "...bu telefondan kalıcı
      // olarak silinecek." Ekran doğrudan bu metodu çağırıyor.
      await telefon.depo.tumVerileriSifirla();
      await biraz();

      expect(
        bulut.kullaniciBolumleri['uid_12']!['plan'],
        contains('Patoloji'),
        reason: 'Uyarı yalnız bu telefonu söylüyor; boş veri buluta da '
            'gönderiliyor ve öteki cihazlara yayılıyor.',
      );
    },
  );

  test(
    'KANIT-13 fotoğraflı not, giriş yapılmışken tarayıcı belleğinde iki kez saklanıyor',
    () async {
      final bulut = SahteBulutKaynagi();
      const kullanici = KullaniciBilgisi(uid: 'uid_13', eposta: 'onuc@mytus.com');
      final telefon = Cihaz(bulut, 'telefon');
      await telefon.planKur('Patoloji', DersGrubu.temel);
      await telefon.senkron.oturumAcildi(kullanici);

      final foto = List.filled(2000, 'QUJD').join();
      await telefon.depo.kitapBolumNotuEkle(
        'k_ornek_patoloji',
        'b_ornek_1',
        BolumNotu(
          id: 'not_foto',
          metin: 'Tablo',
          resimBase64: foto,
          olusturmaTarihi: DateTime(2026, 11, 25),
        ),
      );
      await biraz();

      final tumDepolama = [
        telefon.yerel.icerik ?? '',
        ...telefon.yerel.ekAnahtarlar.values,
      ].join('\n');
      expect(
        kacKez(tumDepolama, foto),
        1,
        reason: 'Fotoğraf hem ana kayıtta (mytus_data.json) hem de '
            'mytus_photos_<uid> anahtarında tutuluyor; tarayıcı kotası '
            'iki kat hızlı doluyor.',
      );
    },
  );

  test(
    'KANIT-14 silinen fotoğraflı not, cihazdaki fotoğraf deposundan silinmiyor',
    () async {
      final bulut = SahteBulutKaynagi();
      const kullanici = KullaniciBilgisi(uid: 'uid_14', eposta: 'ondort@mytus.com');
      final telefon = Cihaz(bulut, 'telefon');
      await telefon.planKur('Patoloji', DersGrubu.temel);
      await telefon.senkron.oturumAcildi(kullanici);

      final foto = List.filled(2000, 'WFla').join();
      await telefon.depo.kitapBolumNotuEkle(
        'k_ornek_patoloji',
        'b_ornek_1',
        BolumNotu(
          id: 'silinecek_not',
          resimBase64: foto,
          olusturmaTarihi: DateTime(2026, 11, 25),
        ),
      );
      await telefon.depo.kitapBolumNotuSil(
        'k_ornek_patoloji',
        'b_ornek_1',
        'silinecek_not',
      );
      await biraz();

      expect(
        telefon.yerel.ekAnahtarlar['mytus_photos_uid_14'] ?? '',
        isNot(contains(foto)),
        reason: 'Fotoğraf deposu yalnızca ekleniyor (addAll), hiç '
            'temizlenmiyor; silinen fotoğraflar kotayı doldurmaya devam ediyor.',
      );
    },
  );

  test(
    'KANIT-15 geçen haftanın puanı bu haftanın grup hedefine ve sırasına sayılıyor',
    () {
      final buHafta = haftaBasi(DateTime.now());
      final gecenHafta = gunEkle(buHafta, -7);
      final uyeler = [
        GrupUyesi(
          uid: 'u_eski',
          takmaAd: 'Bu hafta uygulamayı açmayan üye',
          haftaBaslangici: tarihAnahtari(gecenHafta),
          konuSayisi: 5,
          soruSayisi: 300,
          guncellemeTarihi: gunEkle(gecenHafta, 3),
        ),
      ];
      final grup = Grup(
        id: 'g1',
        ad: 'Kanıt grubu',
        davetKodu: 'ABCDEF',
        olusturanUid: 'u_eski',
        olusturmaTarihi: gecenHafta,
      );
      final durum = GrupHedefDurumu.hesapla(uyeler: uyeler, grup: grup);

      expect(
        {'konu': durum.toplamKonu, 'soru': durum.toplamSoru},
        {'konu': 0, 'soru': 0},
        reason: 'Karar: "Puan tablosu haftalık sıfırlanır". haftaBaslangici '
            'alanı yazılıyor ama hiçbir yerde okunmuyor; üye bu hafta '
            'uygulamayı açmadıkça eski puanı sıralamada ve hedefte kalıyor.',
      );
    },
  );

  testWidgets(
    'KANIT-16 hesap silinemezse (yeniden giriş gerekirse) veriler yine de siliniyor',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const kullanici = KullaniciBilgisi(
        uid: 'uid_16',
        eposta: 'onalti@mytus.com',
        takmaAd: 'Kanıt',
      );
      final bulut = SahteBulutKaynagi();
      final telefon = Cihaz(bulut, 'telefon');
      await tester.runAsync(() async {
        await telefon.planKur('Patoloji', DersGrubu.temel);
        await telefon.senkron.oturumAcildi(kullanici);
      });
      expect(bulut.kullaniciBolumleri['uid_16'], isNotNull);

      final kimlik = YeniGirisIsteyenKimlik(baslangicKullanicisi: kullanici);
      await tester.pumpWidget(
        MyTusApp(
          deposu: telefon.depo,
          ftNative: SahteNative(),
          kimlikServisi: kimlik,
          senkronServisi: telefon.senkron,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Ayarlar'));
      await tester.pumpAndSettle();
      final silDugmesi = find.byKey(const ValueKey('hesap_sil_butonu'));
      await tester.ensureVisible(silDugmesi);
      await tester.pumpAndSettle();
      await tester.tap(silDugmesi);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hesabımı Sil'));
      await tester.pumpAndSettle();

      // Hesap silinemedi: kullanıcı hâlâ oturumda.
      expect(kimlik.aktifKullanici, isNotNull);
      expect(
        bulut.kullaniciBolumleri['uid_16'],
        isNotNull,
        reason: 'hesap_karti.dart önce buluttaki ve cihazdaki verileri siliyor, '
            'sonra hesabı silmeyi deniyor. Firebase "requires-recent-login" '
            'verince hesap kalıyor ama veriler gitmiş oluyor.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
