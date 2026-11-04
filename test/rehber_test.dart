library;

import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/karsilama/karsilama_ekrani.dart';
import 'package:app/features/rehber/rehber_ekrani.dart';
import 'package:app/features/rehber/tanitim_turu_ekrani.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'yardimci.dart';

void main() {
  group('Tanıtım Turu ve Kullanım Rehberi Testleri', () {
    testWidgets('TanitimTuruEkrani: 5 slayt gezilir, geri gidilir ve tamamlanır',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: TanitimTuruEkrani()),
      );
      await tester.pumpAndSettle();

      // 1. Slayt: Planlama & Tekrar
      expect(find.text('1. Akıllı Planlama & Tekrar Sistemi (R0–R4)'), findsOneWidget);
      expect(find.text('Atla'), findsOneWidget);
      expect(find.text('İlerle'), findsOneWidget);

      // 2. Slayta ilerle
      await tester.tap(find.text('İlerle'));
      await tester.pumpAndSettle();
      expect(find.text('2. F.T. Time & Bilişsel Kapasite (3–4 Saat Kuralı)'), findsOneWidget);
      expect(find.text('Geri'), findsOneWidget);

      // Geri dön
      await tester.tap(find.text('Geri'));
      await tester.pumpAndSettle();
      expect(find.text('1. Akıllı Planlama & Tekrar Sistemi (R0–R4)'), findsOneWidget);

      // Sona kadar ilerle (Slayt 2 -> 3 -> 4 -> 5)
      await tester.tap(find.text('İlerle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('İlerle'));
      await tester.pumpAndSettle();
      expect(find.text('3. Deneme Analizi & Özel Defterler'), findsOneWidget);

      await tester.tap(find.text('İlerle'));
      await tester.pumpAndSettle();
      expect(find.text('4. Sınav Anı, Panik Protokolü & Provalar'), findsOneWidget);

      await tester.tap(find.text('İlerle'));
      await tester.pumpAndSettle();
      expect(find.text('5. Master Yönetim Kokpiti & Karar Asistanı'), findsOneWidget);
      expect(find.text('Anladım, Başla!'), findsOneWidget);
      expect(find.text('Atla'), findsNothing);

      // Bitir
      await tester.tap(find.text('Anladım, Başla!'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('RehberEkrani: SSS kategorileri ve soru-cevap akordeonu açılır',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: RehberEkrani()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kullanım Rehberi & SSS'), findsOneWidget);
      expect(find.text('Tanıtım Turunu Başlat (5 Slayt)'), findsOneWidget);

      // Kategoriler
      expect(find.text('1. Hızlı Başlangıç & Günlük Kullanım'), findsOneWidget);
      expect(find.text('2. Akıllı Tekrar Motoru (R1–R4)'), findsOneWidget);
      expect(find.text('3. F.T. Time & Nörobiyolojik Performans'), findsOneWidget);
      expect(find.text('4. Deneme Analizi & Özel Defterler'), findsOneWidget);
      expect(find.text('5. Sınav Anı, Panik ve Stratejiler'), findsOneWidget);
      expect(find.text('6. Master Yönetim Kokpiti & Karar Asistanı'), findsOneWidget);

      // Bir soruyu tıkla ve cevabı gör
      await tester.tap(find.text('R0 Akşam Tekrarı (Beyaz Sayfa) nedir?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Günün en son çalışma bloğudur'), findsOneWidget);

      // Tanıtım turu butonuna dokun
      await tester.tap(find.text('Tanıtım Turunu Başlat (5 Slayt)'));
      await tester.pumpAndSettle();
      expect(find.text('1. Akıllı Planlama & Tekrar Sistemi (R0–R4)'), findsOneWidget);

      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Karşılama ekranından tanıtım turu açılır', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final depo = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
      await depo.yukle();

      await tester.pumpWidget(
        MaterialApp(
          home: DepoKapsami(deposu: depo, child: const KarsilamaEkrani()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Uygulama Nasıl Kullanılır? (Tanıtım Turu)'), findsOneWidget);
      await tester.tap(find.text('Uygulama Nasıl Kullanılır? (Tanıtım Turu)'));
      await tester.pumpAndSettle();

      expect(find.text('1. Akıllı Planlama & Tekrar Sistemi (R0–R4)'), findsOneWidget);
      await tester.tap(find.text('Atla'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Bugün ekranından Rehber ikonu ve hızlı tanıtım kartı açılır',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final depo = await doluDepo(tester);
      await tester.pumpWidget(MyTusApp(deposu: depo));
      await tester.pumpAndSettle();

      // Hızlı rehber kartına dokun
      expect(find.text('Kullanım Rehberi & 1 Dk Tanıtım Turu'), findsOneWidget);
      await tester.tap(find.text('Kullanım Rehberi & 1 Dk Tanıtım Turu'));
      await tester.pumpAndSettle();

      expect(find.text('Kullanım Rehberi & SSS'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // AppBar'daki Rehber ikonuna dokun
      await tester.tap(find.byTooltip('Kullanım Rehberi & SSS'));
      await tester.pumpAndSettle();
      expect(find.text('Kullanım Rehberi & SSS'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
