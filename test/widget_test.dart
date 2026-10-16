import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/hazir_dersler.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/ft_time/ft_native.dart';
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

  ftTestleri();
  ilerlemeTestleri();

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

/// Android köprüsü olmadan (testte) her çağrı hemen tamamlanır.
class SahteNative extends FtNative {
  SahteNative();

  final List<String> cagrilar = [];

  @override
  Future<bool> kullanilabilir() async => true;
  @override
  Future<void> alarmKur(int bitisMs) async => cagrilar.add('kur');
  @override
  Future<void> alarmIptal() async => cagrilar.add('iptal');
  @override
  Future<void> calisanBildirimiKaldir() async {}
  @override
  Future<void> bitenBildirimiKaldir() async {}
  @override
  Future<bool?> bildirimAcik() async => true;
  @override
  Future<void> bildirimIzniIste() async {}
  @override
  Future<bool?> pilKisitsiz() async => true;
  @override
  Future<void> pilAyarlariniAc() async {}
  @override
  Future<void> uygulamaAyarlariniAc() async {}
  @override
  Future<String?> kayitOku(String anahtar) async => '1';
  @override
  Future<void> kayitYaz(String anahtar, String deger) async {}
}

/// Pil kısıtlaması olan telefonu taklit eder.
class KisitliNative extends SahteNative {
  @override
  Future<bool?> pilKisitsiz() async => false;
}

void ftTestleri() {
  testWidgets('Pil kısıtlaması varsa sayaç ekranında uyarı çıkar, kapatılabilir',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = await doluDepo(tester);
    await tester.pumpWidget(MyTusApp(deposu: depo, ftNative: KisitliNative()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('F.T. time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Başlat'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('pil tasarrufu'), findsOneWidget);
    await tester.tap(find.byTooltip('Uyarıyı kapat'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('pil tasarrufu'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('F.T. time: hazırlıktan oturum başlar, duraklar, bitirilir',
      (tester) async {
    // Uzun ekran: hazırlık ekranının altındaki satırlar da çizilsin.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = await doluDepo(tester);
    final native = SahteNative();
    await tester.pumpWidget(MyTusApp(deposu: depo, ftNative: native));
    await tester.pumpAndSettle();

    await tester.tap(find.text('F.T. time'));
    await tester.pumpAndSettle();
    expect(find.text('Toplam yaklaşık süre'), findsOneWidget);
    expect(find.text('1 sa 55 dk'), findsOneWidget);

    await tester.tap(find.text('Başlat'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(depo.oturum, isNotNull);
    expect(find.text('Döngü 1 / 4'), findsOneWidget);
    expect(find.text('Konusuz çalışma'), findsOneWidget);
    expect(native.cagrilar, contains('kur'));

    await tester.tap(find.text('Duraklat'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Devam et'), findsOneWidget);
    expect(native.cagrilar, contains('iptal'));

    await tester.tap(find.text('Bitir'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Oturum bitirilsin mi?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Bitir'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(depo.oturum, isNull);
    expect(find.text('Toplam yaklaşık süre'), findsOneWidget);
    expect(depo.toplamPuan, 0);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Tamamlanan oturumda konu için Çalıştım sorusu gelir',
      (tester) async {
    final depo = await doluDepo(tester);
    final anatomi = depo.dersler(DersGrubu.temel).first;
    final konu = depo.konuEkle(anatomi.id, 'Alt ekstremite')!;
    final su = DateTime.now().millisecondsSinceEpoch;
    var o = depo.oturumBaslat(toplamDongu: 1, konuId: konu.id);
    o = o.baslat(su - 30 * 60 * 1000).guncelle(su);
    depo.oturumGuncelle(o);
    expect(depo.toplamPuan, 25);

    await tester.pumpWidget(MyTusApp(deposu: depo, ftNative: SahteNative()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('F.T. time'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Oturum tamamlandı'), findsOneWidget);
    expect(find.textContaining('+25 puan'), findsOneWidget);
    expect(find.text('Alt ekstremite'), findsOneWidget);

    await tester.tap(find.text('Bitir'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Konuyu çalıştım olarak işaretleyeyim mi?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Evet, işaretle'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(depo.konuCalisildi(konu.id), isTrue);
    expect(depo.oturum, isNull);
    expect(depo.toplamPuan, 25);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Ayarlar: Bugün ekranından açılır, tur sayısı değişir',
      (tester) async {
    final depo = await doluDepo(tester);
    await tester.pumpWidget(MyTusApp(deposu: depo, ftNative: SahteNative()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ayarlar'));
    await tester.pumpAndSettle();
    expect(find.text('Tur sayısı'), findsOneWidget);
    expect(find.text('Günlük tekrar sınırı'), findsOneWidget);

    await tester.tap(find.text('Tur sayısı'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '3');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(depo.turSayisi, 3);

    await tester.tap(find.text('Çalışma süresi'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '40');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(depo.ftAyar.calismaDk, 40);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

void ilerlemeTestleri() {
  testWidgets('İlerleme: Bugün ekranından açılır, hafta özeti ve gezinme çalışır',
      (tester) async {
    final depo = await doluDepo(tester);
    final anatomi = depo.dersler(DersGrubu.temel).first;
    final konu = depo.konuEkle(anatomi.id, 'Alt ekstremite')!;
    final su = DateTime.now().millisecondsSinceEpoch;
    var o = depo.oturumBaslat(toplamDongu: 1, konuId: konu.id);
    o = o.baslat(su - 30 * 60 * 1000).guncelle(su);
    depo.oturumGuncelle(o);
    depo.oturumKapat();

    await tester.pumpWidget(MyTusApp(deposu: depo, ftNative: SahteNative()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('İlerleme'));
    await tester.pumpAndSettle();
    expect(find.text('Bu hafta'), findsOneWidget);
    expect(find.text('Biten döngü'), findsOneWidget);
    expect(find.text('25 dk'), findsWidgets);
    expect(find.text('Anatomi'), findsOneWidget);
    expect(find.textContaining('25 puan'), findsOneWidget);

    await tester.tap(find.byTooltip('Önceki hafta'));
    await tester.pumpAndSettle();
    expect(find.text('Bu hafta'), findsNothing);
    expect(find.textContaining('henüz kayıt yok'), findsOneWidget);

    await tester.tap(find.byTooltip('Sonraki hafta'));
    await tester.pumpAndSettle();
    expect(find.text('Bu hafta'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
