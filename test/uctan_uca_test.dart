import 'dart:convert';

import 'package:app/core/tarih.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'yardimci.dart';

/// Ekran boyutunu ve görünümü ayarlar; test bitince sıfırlar.
void ekranAyarla(
  WidgetTester tester, {
  Size boyut = const Size(800, 2000),
  double yaziOlcegi = 1.0,
  bool koyu = false,
}) {
  tester.view.physicalSize = boyut;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = yaziOlcegi;
  tester.platformDispatcher.platformBrightnessTestValue =
      koyu ? Brightness.dark : Brightness.light;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

Future<PlanDeposu> bosDepo(WidgetTester tester, BellekKaydi kayit) async {
  final depo = await tester.runAsync(() async {
    final d = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
    await d.yukle();
    return d;
  });
  return depo!;
}

void main() {
  testWidgets('Baştan sona: karşılama, ders/konu/not, yeniden açılış', (tester) async {
    ekranAyarla(tester);
    final kayit = BellekKaydi();
    var depo = await bosDepo(tester, kayit);
    await tester.pumpWidget(MyTusApp(deposu: depo, ftNative: SahteNative()));
    await tester.pumpAndSettle();

    // Karşılama: tarih seçmeden Başla kapalı.
    expect(find.text('Çalışma planını kuralım'), findsOneWidget);
    await tester.tap(find.text('Tarih seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect(find.text('Tarih seç'), findsNothing);
    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    expect(depo.karsilamaTamam, isTrue);
    expect(depo.sinavTarihi, isNotNull);
    expect(find.textContaining('Sınava'), findsOneWidget);

    // Dersler: konu ekle, not yaz.
    await tester.tap(find.text('Dersler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fizyoloji'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Kalp döngüsü');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Kalp döngüsü'), findsOneWidget);
    await tester.tap(find.text('Kalp döngüsü'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Sistol ve diyastol');
    await tester.pump();
    // Kayıt bellek tabanlı ve gecikmesizdir; bekleyen yazmaların bitmesi için bir kare daha.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    // Uygulama kapanıp yeniden açılır: depodaki veri aynen yeni depoya yüklenir.
    // (Disk yazma zinciri ayrıca birim testlerde sınanıyor; widget testinde sahte
    // zaman yüzünden zincir tamamlanmıyor.)
    final yeniKayit = BellekKaydi(icerik: jsonEncode(depo.toJson()));
    depo = await bosDepo(tester, yeniKayit);
    expect(depo.karsilamaTamam, isTrue);
    await tester.pumpWidget(MyTusApp(deposu: depo, ftNative: SahteNative()));
    await tester.pumpAndSettle();
    expect(find.text('Çalışma planını kuralım'), findsNothing);
    await tester.tap(find.text('Dersler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fizyoloji'));
    await tester.pumpAndSettle();
    expect(find.text('Kalp döngüsü'), findsOneWidget);
    expect(find.text('Notu var'), findsOneWidget);
    final fizyoloji = depo.dersler(DersGrubu.temel).firstWhere((d) => d.ad == 'Fizyoloji');
    expect(depo.konular(fizyoloji.id).single.not, 'Sistol ve diyastol');

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Takvim, Bugün ve tekrar zinciri', (tester) async {
    ekranAyarla(tester);
    final depo = await doluDepo(tester);
    final ders = depo.dersler(DersGrubu.temel).first;
    final konu = depo.konuEkle(ders.id, 'Üst ekstremite')!;
    await tester.pumpWidget(MyTusApp(deposu: depo, ftNative: SahteNative()));
    await tester.pumpAndSettle();

    // Takvim'de bugüne yerleştir.
    await tester.tap(find.text('Takvim'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Konu yerleştir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ders.ad));
    await tester.pumpAndSettle();
    await tester.tap(find.text(konu.ad));
    await tester.pumpAndSettle();
    expect(depo.tumCalismalar().length, 1);

    // Bugün'de Çalıştım de.
    await tester.tap(find.text('Bugün'));
    await tester.pumpAndSettle();
    expect(find.text('Bugünün planı'), findsOneWidget);
    await tester.tap(find.byTooltip('Çalıştım'));
    await tester.pumpAndSettle();
    final c = depo.tumCalismalar().single;
    expect(c.tamam, isTrue);

    // Tekrarlar oluştu; yarın için ilk tekrar var ve Takvim'de görünür.
    final bugun = gunBasi(DateTime.now());
    final tekrarlar = depo.tekrarlar(bugun);
    expect(tekrarlar.length, 4);
    expect(tekrarlar.first.tarih, gunEkle(bugun, 1));
    expect(tekrarlar.first.eylemYapilabilir, isTrue);
    expect(tekrarlar[1].eylemYapilabilir, isFalse);

    await tester.tap(find.text('Takvim'));
    await tester.pumpAndSettle();
    final yarin = gunEkle(bugun, 1);
    if (yarin.month != bugun.month) {
      await tester.tap(find.byTooltip('Sonraki ay'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('${yarin.day}'));
    await tester.pumpAndSettle();
    expect(find.text('Tekrar 1/4'), findsOneWidget);

    // Tekrarı yaptım; sıradaki tekrar açılır.
    await tester.tap(find.byTooltip('Tekrar yaptım'));
    await tester.pumpAndSettle();
    expect(depo.calismaBul(c.id)!.tekrarlar.length, 1);
    final sonra = depo.tekrarlar(bugun);
    expect(sonra.first.yapildi, isTrue);
    expect(sonra[1].eylemYapilabilir, isTrue);

    // Konu ekranında tekrar planı görünür.
    await tester.tap(find.text('Dersler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ders.ad));
    await tester.pumpAndSettle();
    await tester.tap(find.text(konu.ad));
    await tester.pumpAndSettle();
    expect(find.text('Tekrar planı'), findsOneWidget);
    expect(find.textContaining('Tur 1/'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('F.T. time: döngü biter, mola, sonraki döngü, puan', (tester) async {
    ekranAyarla(tester);
    final depo = await doluDepo(tester);
    depo.ftAyarBelirle(depo.ftAyar.kopya(donguSayisi: 2));
    await tester.pumpWidget(MyTusApp(deposu: depo, ftNative: SahteNative()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('F.T. time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Başlat'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Döngü 1 / 2'), findsOneWidget);

    // Süre doldu (uygulama açıkken): döngü puanlanır, mola önerilir.
    final simdi = DateTime.now().millisecondsSinceEpoch;
    depo.oturumuTazele(simdi + 26 * 60 * 1000);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Döngü tamamlandı'), findsOneWidget);
    expect(find.text('Molayı başlat'), findsOneWidget);
    expect(depo.toplamPuan, 25);

    await tester.tap(find.text('Molayı başlat'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Kısa mola'), findsOneWidget);
    expect(find.text('Molayı atla'), findsOneWidget);

    await tester.tap(find.text('Molayı atla'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Döngü 2 / 2'), findsOneWidget);
    expect(find.text('Çalışma'), findsOneWidget);

    // İkinci döngü de biter: oturum tamamlanır, toplam 50 puan.
    depo.oturumuTazele(simdi + 120 * 60 * 1000);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Oturum tamamlandı'), findsOneWidget);
    expect(depo.toplamPuan, 50);

    await tester.tap(find.text('Bitir'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(depo.oturum, isNull);
    expect(find.text('Başlat'), findsOneWidget);
    expect(depo.toplamPuan, 50);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final kosul in <({String ad, Size boyut, double olcek, bool koyu})>[
    (ad: 'küçük telefon', boyut: const Size(320, 568), olcek: 1.0, koyu: false),
    (ad: 'büyük yazı', boyut: const Size(360, 740), olcek: 1.6, koyu: false),
    (ad: 'koyu tema', boyut: const Size(390, 844), olcek: 1.0, koyu: true),
  ]) {
    testWidgets('Tüm ekranlar taşma olmadan açılır: ${kosul.ad}', (tester) async {
      ekranAyarla(
        tester,
        boyut: kosul.boyut,
        yaziOlcegi: kosul.olcek,
        koyu: kosul.koyu,
      );
      final depo = await doluDepo(tester);
      final ders = depo.dersler(DersGrubu.temel).first;
      final konu = depo.konuEkle(ders.id, 'Üst ekstremitenin arteriyel dolaşımı')!;
      final bugun = gunBasi(DateTime.now());
      final c = depo.calismaEkle(konu.id, bugun)!;
      depo.calistim(c.id, bugun);
      depo.calismaEkle(konu.id, gunEkle(bugun, 3));
      depo.konuEkle(ders.id, 'Brachial plexus');
      depo.calismaEkle(depo.konular(ders.id).last.id, gunEkle(bugun, -2));
      await tester.pumpWidget(MyTusApp(deposu: depo, ftNative: SahteNative()));
      await tester.pumpAndSettle();

      void kontrol(String adim) {
        final e = tester.takeException();
        if (e != null) {
          final satirlar = e
              .toString()
              .split('\n')
              .where((l) => l.contains('overflowed') || l.contains('lib/'))
              .map((l) => l.trim())
              .take(6)
              .join(' | ');
          fail('[$adim] $satirlar');
        }
      }

      Future<void> dokun(String adim, Finder f) async {
        if (f.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            f,
            300,
            scrollable: find.byType(Scrollable).first,
          );
        }
        expect(f, findsWidgets, reason: '[$adim] bulunamadi');
        await tester.ensureVisible(f.first);
        await tester.pumpAndSettle();
        await tester.tap(f.first);
        await tester.pumpAndSettle();
        kontrol(adim);
      }

      Future<void> geri(String adim) async {
        final b = find.byType(BackButton);
        expect(b, findsWidgets, reason: '[$adim] geri dugmesi yok');
        await tester.tap(b.first);
        await tester.pumpAndSettle();
        kontrol(adim);
      }

      await dokun('sekme Dersler', find.text('Dersler'));
      await dokun('Klinik', find.text('Klinik'));
      await dokun('Temel', find.text('Temel'));
      await dokun('ders ekrani', find.text(ders.ad));
      await dokun('konu ekrani', find.text('Üst ekstremitenin arteriyel dolaşımı'));
      await geri('konudan geri');
      await geri('dersten geri');

      await dokun('sekme Takvim', find.text('Takvim'));
      await dokun('konu sec', find.text('+ Konu yerleştir'));
      await geri('konu secten geri');

      await dokun('sekme Bugun', find.text('Bugün'));
      await dokun('Ilerleme', find.byTooltip('İlerleme'));
      await geri('ilerlemeden geri');
      await dokun('Ayarlar', find.byTooltip('Ayarlar'));
      await geri('ayarlardan geri');

      await dokun('sekme F.T. time', find.text('F.T. time'));
      final baslat = find.text('Başlat');
      if (baslat.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          baslat,
          300,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await tester.ensureVisible(baslat.first);
      await tester.pump();
      await tester.tap(baslat.first);
      await tester.pump(const Duration(milliseconds: 300));
      kontrol('F.T. time Baslat');

      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
