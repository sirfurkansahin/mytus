// Ekran metinleri ve küçük ekran (B1, B2, C4): sayılar boş kalmaz, küçük
// ekranda rakamlar taşmaz, tahmini puan 45'in altını gizlemez.

import 'package:app/features/denemeler/deneme_ekle_ekrani.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'yardimci.dart';

void main() {
  group('Tahmini TUS puanı', () {
    test('0 net 45\'e yükseltilmez; baraj altı olduğu görünür', () {
      final deneme = DenemeSinavi(
        id: 'sifir',
        ad: 'Boş deneme',
        tarih: DateTime(2026, 11, 25),
      );
      expect(deneme.tahminiEbapPuani, lessThan(45));
      expect(deneme.tahminiEbapPuani, closeTo(27.14, 0.01));
      expect(deneme.barajAltinda, isTrue);
    });

    test('tavan 85\'i geçmez', () {
      final deneme = DenemeSinavi(
        id: 'tam',
        ad: 'Tam deneme',
        tarih: DateTime(2026, 11, 25),
        temel: const DenemeOturumu(dogru: 100, yanlis: 0, bos: 0),
        klinik: const DenemeOturumu(dogru: 100, yanlis: 0, bos: 0),
      );
      expect(deneme.tahminiEbapPuani, 85);
      expect(deneme.barajAltinda, isFalse);
    });
  });

  testWidgets('Ayarlar: günlük yeni konu sınırı sayısıyla görünür',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = await doluDepo(tester);
    await tester.pumpWidget(MyTusApp(deposu: depo, ftNative: SahteNative()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ayarlar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Günlük yeni konu sınırı'), 100);
    expect(find.text('${depo.gunlukYeniKonuSiniri} konu'), findsOneWidget);
    expect(find.text(' konu'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('İlerleme: son deneme adı, neti ve puanıyla yazılır',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = await doluDepo(tester);
    await tester.runAsync(
      () => depo.denemeEkle(
        DenemeSinavi(
          id: 'd_son',
          ad: 'Kurum 3',
          tarih: DateTime(2026, 11, 20),
          temel: const DenemeOturumu(dogru: 60, yanlis: 8, bos: 32),
          klinik: const DenemeOturumu(dogru: 70, yanlis: 12, bos: 18),
        ),
      ),
    );

    await tester.pumpWidget(MyTusApp(deposu: depo, ftNative: SahteNative()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('İlerleme'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Son: Kurum 3 (125.0 net'), findsOneWidget);
    expect(find.textContaining('( net'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Yeni deneme ekranı 320 px genişlikte taşmaz', (tester) async {
    // Genişlik küçük telefon (320 px); yükseklik tüm alanlar çizilsin diye uzun.
    tester.view.physicalSize = const Size(320, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = await doluDepo(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: DepoKapsami(deposu: depo, child: const DenemeEkleEkrani()),
      ),
    );
    await tester.pumpAndSettle();

    final dogrular = find.widgetWithText(TextFormField, 'Doğru');
    expect(dogrular, findsNWidgets(2));
    await tester.enterText(dogrular.at(0), '100');
    await tester.enterText(dogrular.at(1), '100');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('200.00 / 200'), findsOneWidget);
    expect(find.text('85.0'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
