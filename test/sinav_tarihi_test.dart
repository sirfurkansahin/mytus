// Sınav dönemi seçimi (25 Kasım 2026 kararı): 27 Mart veya 22 Ağustos 2027.

import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'yardimci.dart';

void main() {
  testWidgets('Karşılamada 27 Mart 2027 seçilip plan kurulur', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
    await tester.runAsync(depo.yukle);

    await tester.pumpWidget(MyTusApp(deposu: depo, ftNative: SahteNative()));
    await tester.pumpAndSettle();
    expect(find.text('22 Ağustos 2027'), findsOneWidget);
    expect(find.text('27 Mart 2027'), findsOneWidget);

    await tester.tap(find.text('27 Mart 2027'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();

    expect(depo.karsilamaTamam, isTrue);
    expect(depo.sinavTarihi, DateTime(2027, 3, 27));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Ayarlar: sınav dönemi değiştirilebilir', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = await doluDepo(tester);

    await tester.pumpWidget(MyTusApp(deposu: depo, ftNative: SahteNative()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ayarlar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sınav tarihi'));
    await tester.pumpAndSettle();
    expect(find.text('Hangi TUS dönemine gireceksin?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sinav_donemi_3')));
    await tester.pumpAndSettle();
    expect(find.text('Sınav tarihi değişsin mi?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Değiştir'));
    await tester.pumpAndSettle();

    expect(depo.sinavTarihi, DateTime(2027, 3, 27));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
