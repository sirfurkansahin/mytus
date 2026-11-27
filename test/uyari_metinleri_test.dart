// Ayarlar'daki silme uyarıları gerçekte silineni söyler. Önce kanıt
// testleriydi: KANIT-02 (müfredat değişince denemeler de siliniyordu ama
// uyarıda yazmıyordu) ve KANIT-12 (giriş yapılmışken "Tüm verileri sıfırla"
// buluttaki veriyi de siliyordu ama uyarı yalnız cihazı söylüyordu).

import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/auth/kimlik_servisi.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:app/features/dersler/hazir_dersler.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/senkronizasyon/bulut_kaynagi.dart';
import 'package:app/features/senkronizasyon/bulut_senkron_servisi.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'yardimci.dart';

Finder _pencerede(Finder f) =>
    find.descendant(of: find.byType(AlertDialog), matching: f);

void _ekran(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _ayarlardaDokun(WidgetTester tester, String yazi) async {
  await tester.tap(find.byTooltip('Ayarlar'));
  await tester.pumpAndSettle();
  final hedef = find.text(yazi);
  await tester.scrollUntilVisible(hedef, 200);
  await tester.pumpAndSettle();
  await tester.tap(hedef);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('müfredat değişince denemelerin de silineceği yazar ve öyle olur',
      (tester) async {
    _ekran(tester);
    final depo = await doluDepo(tester);
    await tester.runAsync(
      () => depo.denemeEkle(
        DenemeSinavi(
          id: 'd1',
          ad: 'Deneme 1',
          tarih: DateTime(2026, 11, 20),
          temel: const DenemeOturumu(dogru: 50, yanlis: 10, bos: 40),
        ),
      ),
    );
    expect(depo.denemeler, isNotEmpty);

    await tester.pumpWidget(MyTusApp(deposu: depo, ftNative: SahteNative()));
    await tester.pumpAndSettle();
    await _ayarlardaDokun(tester, 'Müfredat tarzı');

    expect(_pencerede(find.textContaining('DENEME')), findsOneWidget);
    await tester.tap(_pencerede(find.text('Değiştir')));
    await tester.pumpAndSettle();
    expect(depo.denemeler, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('giriş yokken sıfırlama uyarısı yalnız bu cihazı söyler',
      (tester) async {
    _ekran(tester);
    final depo = await doluDepo(tester);
    await tester.pumpWidget(MyTusApp(deposu: depo, ftNative: SahteNative()));
    await tester.pumpAndSettle();
    await _ayarlardaDokun(tester, 'Tüm verileri sıfırla');

    expect(
      _pencerede(find.textContaining('bu cihazdan kalıcı olarak silinecek')),
      findsOneWidget,
    );
    expect(_pencerede(find.textContaining('buluttan')), findsNothing);
    await tester.tap(_pencerede(find.text('Vazgeç')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('giriş yapılmışken sıfırlama uyarısı hesaptan da silineceğini söyler',
      (tester) async {
    _ekran(tester);
    final yerel = BellekKaydi();
    final senkron = BulutSenkronServisi(
      yerelKayit: yerel,
      bulutKaynagi: SahteBulutKaynagi(),
      gonderimGecikmesi: Duration.zero,
      cihazId: 'telefon',
    );
    final depo = (await tester.runAsync(() async {
      final d = PlanDeposu(kayit: senkron, kayitGecikmesi: Duration.zero);
      senkron.depoBagla(d);
      await d.yukle();
      await d.karsilamayiTamamla(
        sinavTarihi: DateTime(2030, 4, 1),
        secilenDersler: hazirDersler,
      );
      return d;
    }))!;

    await tester.pumpWidget(
      MyTusApp(
        deposu: depo,
        ftNative: SahteNative(),
        kimlikServisi: SahteKimlikServisi(
          baslangicKullanicisi:
              const KullaniciBilgisi(uid: 'uid_sifir', eposta: 's@mytus.com'),
        ),
        senkronServisi: senkron,
      ),
    );
    await tester.pumpAndSettle();
    await _ayarlardaDokun(tester, 'Tüm verileri sıfırla');

    expect(_pencerede(find.textContaining('hesabından (buluttan)')),
        findsOneWidget);
    await tester.tap(_pencerede(find.text('Vazgeç')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
