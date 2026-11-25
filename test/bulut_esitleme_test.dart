// Bulut eşitleme (A2): veri kaybı senaryoları. Bu testler önce "kanıt testi"
// olarak hatayı gösterdi (KANIT-07…11); düzeltmeden sonra kalıcı test oldu.

import 'dart:async';

import 'package:app/core/tarih.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/auth/kimlik_servisi.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/senkronizasyon/bulut_kaynagi.dart';
import 'package:app/features/senkronizasyon/bulut_senkron_servisi.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'yardimci.dart';

/// Bir cihazı (yerel kayıt + eşitleme + depo) birlikte kurar.
class _Cihaz {
  _Cihaz(BulutKaynagi bulut, String cihazId, {BellekKaydi? kayit})
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

  Iterable<String> get dersAdlari => depo.tumDersler.map((d) => d.ad);
}

/// Firestore'daki gibi her bölümü ayrı belge tutan sahte kaynak; olaylarda
/// tüm bölümler gelir, sonCihazId son sıradaki belgeyi yazan cihazdır.
class _BelgeBazliKaynak implements BulutKaynagi {
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

Future<void> _biraz() =>
    Future<void>.delayed(const Duration(milliseconds: 30));

DenemeSinavi _deneme(String id) => DenemeSinavi(
      id: id,
      ad: 'Deneme $id',
      tarih: DateTime(2026, 11, 20),
      temel: const DenemeOturumu(dogru: 50, yanlis: 10, bos: 40),
    );

void main() {
  test('başka cihazdan değişiklik gelince aktif çalışma grubu korunur',
      () async {
    final bulut = SahteBulutKaynagi();
    final telefon = _Cihaz(bulut, 'telefon');
    await telefon.planKur('Patoloji', DersGrubu.temel);
    const kullanici = KullaniciBilgisi(uid: 'uid_7', eposta: 'yedi@mytus.com');
    await telefon.senkron.oturumAcildi(kullanici);

    telefon.depo.aktifGrupAyarla('grup_abc');
    await telefon.depo.hemenKaydet();

    final tablet = _Cihaz(bulut, 'tablet');
    await tablet.depo.yukle();
    await tablet.senkron.oturumAcildi(kullanici);
    // Grup hesaba bağlıdır: tablette de görünür.
    expect(tablet.depo.aktifGrupId, 'grup_abc');

    await tablet.depo.denemeEkle(_deneme('tablet_1'));
    await _biraz();

    expect(telefon.depo.denemeler.map((d) => d.id), contains('tablet_1'));
    expect(telefon.depo.aktifGrupId, 'grup_abc');
  });

  test('çevrimdışı değişiklik, uygulama yeniden açılınca kaybolmaz ve gönderilir',
      () async {
    final bulut = SahteBulutKaynagi();
    final yerel = BellekKaydi();
    final ilkAcilis = _Cihaz(bulut, 'telefon', kayit: yerel);
    await ilkAcilis.planKur('Patoloji', DersGrubu.temel);
    const kullanici = KullaniciBilgisi(uid: 'uid_8', eposta: 'sekiz@mytus.com');
    await ilkAcilis.senkron.oturumAcildi(kullanici);

    bulut.cevrimdisi = true;
    ilkAcilis.depo.dersEkle('Nöbette eklenen ders');
    await ilkAcilis.depo.hemenKaydet();
    expect(ilkAcilis.senkron.bekleyenVarMi, isTrue);
    ilkAcilis.senkron.dispose();

    // Uygulama kapanıp açılır, internet gelmiştir; oturum hâlâ açıktır.
    bulut.cevrimdisi = false;
    final ikinciAcilis = _Cihaz(bulut, 'telefon_yeniden', kayit: yerel);
    await ikinciAcilis.depo.yukle();
    await ikinciAcilis.senkron.oturumAcildi(kullanici);

    expect(ikinciAcilis.dersAdlari, contains('Nöbette eklenen ders'));
    expect(ikinciAcilis.senkron.bekleyenCakisma, isNull);
    expect(
      bulut.kullaniciBolumleri['uid_8']!['plan'],
      contains('Nöbette eklenen ders'),
    );
  });

  test('girişte bulut okunamazsa hiçbir şey gönderilmez; okununca sorulur',
      () async {
    final bulut = SahteBulutKaynagi();
    const kullanici = KullaniciBilgisi(uid: 'uid_9', eposta: 'dokuz@mytus.com');

    final a = _Cihaz(bulut, 'cihaz_a');
    await a.planKur('Patoloji', DersGrubu.temel);
    await a.senkron.oturumAcildi(kullanici);
    await a.depo.denemeEkle(_deneme('a_1'));

    final b = _Cihaz(bulut, 'cihaz_b');
    await b.planKur('Dahiliye', DersGrubu.klinik);
    bulut.cevrimdisi = true;
    await b.senkron.oturumAcildi(kullanici);
    bulut.cevrimdisi = false;

    b.depo.soruEkle(DateTime(2026, 11, 25), 5);
    await b.depo.hemenKaydet();
    await _biraz();

    expect(bulut.kullaniciBolumleri['uid_9']!['denemeler'], contains('a_1'));
    expect(bulut.kullaniciBolumleri['uid_9']!['plan'], contains('Patoloji'));
    expect(b.senkron.bekleyenCakisma, isNotNull);
    b.senkron.dispose();
  });

  test(
      'cihazda ve hesapta farklı veri varsa sorulur; hesaptaki seçilince '
      'cihazdaki yedeklenir ve geri getirilebilir', () async {
    final bulut = SahteBulutKaynagi();
    const kullanici = KullaniciBilgisi(uid: 'uid_10', eposta: 'on@mytus.com');
    final a = _Cihaz(bulut, 'cihaz_a');
    await a.planKur('Patoloji', DersGrubu.temel);
    await a.senkron.oturumAcildi(kullanici);

    final b = _Cihaz(bulut, 'cihaz_b');
    await b.planKur('Dahiliye', DersGrubu.klinik);
    await b.senkron.oturumAcildi(kullanici);

    final cakisma = b.senkron.bekleyenCakisma;
    expect(cakisma, isNotNull);
    expect(cakisma!.yerelOzet, contains('1 ders'));
    expect(b.dersAdlari, contains('Dahiliye'), reason: 'sormadan değişmez');

    await b.senkron.cakismayiCoz(cihazdakiKalsin: false);
    expect(b.senkron.bekleyenCakisma, isNull);
    expect(b.dersAdlari, contains('Patoloji'));
    expect(b.dersAdlari, isNot(contains('Dahiliye')));
    expect(b.yerel.ekAnahtarlar['mytus_backup_uid_10'], contains('Dahiliye'));
    expect(b.senkron.yedekVar, isTrue);

    // Kullanıcı vazgeçer: yedeği geri getirir (iki taraf yer değiştirir).
    expect(await b.senkron.yedegiGeriYukle(), isTrue);
    expect(b.dersAdlari, contains('Dahiliye'));
    expect(b.yerel.ekAnahtarlar['mytus_backup_uid_10'], contains('Patoloji'));
    expect(bulut.kullaniciBolumleri['uid_10']!['plan'], contains('Dahiliye'));
  });

  test('çakışmada bu cihazdaki seçilirse hesaptaki veri cihazda yedeklenir',
      () async {
    final bulut = SahteBulutKaynagi();
    const kullanici = KullaniciBilgisi(uid: 'uid_10b', eposta: 'o@mytus.com');
    final a = _Cihaz(bulut, 'cihaz_a');
    await a.planKur('Patoloji', DersGrubu.temel);
    await a.senkron.oturumAcildi(kullanici);

    final b = _Cihaz(bulut, 'cihaz_b');
    await b.planKur('Dahiliye', DersGrubu.klinik);
    await b.senkron.oturumAcildi(kullanici);
    await b.senkron.cakismayiCoz(cihazdakiKalsin: true);

    expect(b.dersAdlari, contains('Dahiliye'));
    expect(bulut.kullaniciBolumleri['uid_10b']!['plan'], contains('Dahiliye'));
    expect(b.yerel.ekAnahtarlar['mytus_backup_uid_10b'], contains('Patoloji'));
  });

  test('iki cihaz: her biri öbürünün değişikliğini alır', () async {
    final kaynak = _BelgeBazliKaynak();
    const kullanici =
        KullaniciBilgisi(uid: 'uid_11', eposta: 'onbir@mytus.com');
    final a = _Cihaz(kaynak, 'cihaz_a');
    await a.planKur('Patoloji', DersGrubu.temel);
    await a.senkron.oturumAcildi(kullanici);

    final b = _Cihaz(kaynak, 'cihaz_b');
    await b.depo.yukle();
    await b.senkron.oturumAcildi(kullanici);

    a.depo.dersEkle('A cihazının dersi');
    await a.depo.hemenKaydet();
    await _biraz();
    expect(b.dersAdlari, contains('A cihazının dersi'));

    await b.depo.denemeEkle(_deneme('b_1'));
    await _biraz();
    expect(a.depo.denemeler.map((d) => d.id), contains('b_1'));
    expect(a.dersAdlari, contains('A cihazının dersi'));
  });

  test('cihazda bulutla aynı veri varsa (önceki sürümden geçiş) sorulmaz',
      () async {
    final bulut = SahteBulutKaynagi();
    const kullanici =
        KullaniciBilgisi(uid: 'uid_ayni', eposta: 'ayni@mytus.com');
    final a = _Cihaz(bulut, 'cihaz_a');
    await a.planKur('Patoloji', DersGrubu.temel);
    await a.senkron.oturumAcildi(kullanici);

    // Önceki sürüm cihaz durumunu (sahip) yazmıyordu: yalnız ana kayıt var.
    final eski = _Cihaz(
      bulut,
      'eski_surum',
      kayit: BellekKaydi(icerik: a.yerel.icerik),
    );
    await eski.depo.yukle();
    await eski.senkron.oturumAcildi(kullanici);

    expect(eski.senkron.bekleyenCakisma, isNull);
    expect(eski.dersAdlari, contains('Patoloji'));
  });

  testWidgets('çakışma penceresi açılır, "Hesabımdakini kullan" bulutu getirir',
      (tester) async {
    final bulut = SahteBulutKaynagi();
    const kullanici =
        KullaniciBilgisi(uid: 'uid_pencere', eposta: 'p@mytus.com');
    final a = _Cihaz(bulut, 'cihaz_a');
    await a.planKur('Patoloji', DersGrubu.temel);
    await a.senkron.oturumAcildi(kullanici);

    final b = _Cihaz(bulut, 'cihaz_b');
    await b.planKur('Dahiliye', DersGrubu.klinik);

    await tester.pumpWidget(
      MyTusApp(
        deposu: b.depo,
        ftNative: SahteNative(),
        kimlikServisi: SahteKimlikServisi(baslangicKullanicisi: kullanici),
        senkronServisi: b.senkron,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cakisma_dialogu')), findsOneWidget);
    expect(find.text('Hesabındaki (bulut)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cakisma_buluttaki')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cakisma_dialogu')), findsNothing);
    expect(b.dersAdlari, contains('Patoloji'));
    expect(b.yerel.ekAnahtarlar['mytus_backup_uid_pencere'], contains('Dahiliye'));
  });
}
