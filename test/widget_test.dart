import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/hazir_dersler.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Karşılaması tamamlanmış, hazır derslerle dolu bir depo hazırlar.
Future<PlanDeposu> doluDepo(WidgetTester tester) async {
  final depo = await tester.runAsync(() async {
    final d = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
    await d.yukle();
    await d.karsilamayiTamamla(
      sinavTarihi: DateTime(2030, 4, 1),
      secilenDersler: hazirDersler,
    );
    return d;
  });
  return depo!;
}

void main() {
  testWidgets('İlk açılışta karşılama gelir, tarih seçilmeden Başla kapalıdır',
      (tester) async {
    final depo = await tester.runAsync(() async {
      final d = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
      await d.yukle();
      return d;
    });
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    expect(find.text('Çalışma planını kuralım'), findsOneWidget);
    expect(find.text('Anatomi'), findsOneWidget);
    expect(find.text('Dahiliye'), findsOneWidget);
    final basla = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Başla'),
    );
    expect(basla.onPressed, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Dersten konu ekleme ve nota yazma depoya gider', (tester) async {
    final depo = await doluDepo(tester);
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    // Bugün sekmesi: sınava kalan gün yazısı görünür.
    expect(find.textContaining('Sınava'), findsOneWidget);

    await tester.tap(find.text('Dersler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anatomi'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Üst ekstremite');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Üst ekstremite'), findsOneWidget);

    await tester.tap(find.text('Üst ekstremite'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Plexus brachialis');
    await tester.pump();

    final anatomi = depo.dersler(DersGrubu.temel).first;
    expect(depo.konular(anatomi.id).single.not, 'Plexus brachialis');

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Klinik sekmesi klinik dersleri gösterir', (tester) async {
    final depo = await doluDepo(tester);
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dersler'));
    await tester.pumpAndSettle();
    expect(find.text('Anatomi'), findsOneWidget);
    expect(find.text('Dahiliye'), findsNothing);

    await tester.tap(find.text('Klinik'));
    await tester.pumpAndSettle();
    expect(find.text('Dahiliye'), findsOneWidget);
    expect(find.text('Anatomi'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('F.T. time sekmesi sayaç testini açar, süre seçimi çalışır',
      (tester) async {
    final depo = await doluDepo(tester);
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('F.T. time'));
    await tester.pumpAndSettle();
    expect(find.text('25:00'), findsOneWidget);

    await tester.tap(find.text('5 dk'));
    await tester.pumpAndSettle();
    expect(find.text('05:00'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  takvimTestleri();
}

void takvimTestleri() {
  testWidgets('Takvimde konu yerleştirilir, Bugün\'de Çalıştım denir',
      (tester) async {
    // Uzun ekran: takvimin altındaki liste de çizilsin.
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = await doluDepo(tester);
    final anatomi = depo.dersler(DersGrubu.temel).first;
    depo.konuEkle(anatomi.id, 'Üst ekstremite');
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Takvim'));
    await tester.pumpAndSettle();
    expect(find.text('Bu güne planlanmış bir şey yok.'), findsOneWidget);

    await tester.tap(find.text('+ Konu yerleştir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anatomi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Üst ekstremite'));
    await tester.pumpAndSettle();

    expect(depo.tumCalismalar().length, 1);
    expect(find.text('Üst ekstremite'), findsOneWidget);

    await tester.tap(find.text('Bugün'));
    await tester.pumpAndSettle();
    expect(find.text('Bugünün planı'), findsOneWidget);

    await tester.tap(find.byTooltip('Çalıştım'));
    await tester.pumpAndSettle();
    final c = depo.tumCalismalar().single;
    expect(c.tamam, isTrue);
    expect(depo.konuCalisildi(c.konuId), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Konu ekranında tekrar planı görünür', (tester) async {
    final depo = await doluDepo(tester);
    final anatomi = depo.dersler(DersGrubu.temel).first;
    final konu = depo.konuEkle(anatomi.id, 'Alt ekstremite')!;
    final c = depo.calismaEkle(konu.id, DateTime.now())!;
    depo.calistim(c.id, DateTime.now());
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dersler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anatomi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alt ekstremite'));
    await tester.pumpAndSettle();

    expect(find.text('Tekrar planı'), findsOneWidget);
    expect(find.textContaining('Tur 1/'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
