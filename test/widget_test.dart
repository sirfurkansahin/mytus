import 'dart:convert';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/kutuphane/modeller.dart';
import 'package:app/features/kutuphane/resim_secici.dart';
import 'package:app/features/dersler/hazir_dersler.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/kokpit/kokpit_ekrani.dart';
import 'package:app/features/ft_time/ft_ekrani.dart';
import 'package:app/features/ft_time/ft_kontrol.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'yardimci.dart';

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
    expect(find.text('Klasik Branşlar'), findsOneWidget);
    expect(find.text('SpeeTUS Sarmal'), findsOneWidget);
    expect(find.text('1. Tıbbın Temelleri'), findsOneWidget);
    expect(find.text('22 Ağustos 2027'), findsOneWidget);

    await tester.tap(find.text('Klasik Branşlar'));
    await tester.pumpAndSettle();
    expect(find.text('Anatomi'), findsOneWidget);
    expect(find.text('TEMEL'), findsOneWidget);
    expect(find.text('KLİNİK'), findsOneWidget);

    await tester.tap(find.text('SpeeTUS Sarmal'));
    await tester.pumpAndSettle();
    expect(find.text('1. Tıbbın Temelleri'), findsOneWidget);

    await tester.tap(find.text('Tümünü kaldır'));
    await tester.pumpAndSettle();
    final basla = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Başla'),
    );
    expect(basla.onPressed, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Dersten konu ekleme ve nota yazma depoya gider', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = await doluDepo(tester);
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    // Bugün sekmesi: sınava kalan gün yazısı görünür.
    expect(find.textContaining('Sınava'), findsOneWidget);

    final ilkDers = depo.tumDersler.first;

    await tester.tap(find.text('Dersler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ilkDers.ad));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Yeni özel konu');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Yeni özel konu'), findsOneWidget);

    await tester.tap(find.text('Yeni özel konu'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Plexus brachialis');
    await tester.pump();

    expect(
      depo.konular(ilkDers.id).firstWhere((k) => k.ad == 'Yeni özel konu').not,
      'Plexus brachialis',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Dersler sekmesinde SpeeTUS tüm dersleri tek liste olarak gösterir',
      (tester) async {
    final depo = await doluDepo(tester);
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dersler'));
    await tester.pumpAndSettle();
    expect(find.text('1. Tıbbın Temelleri'), findsOneWidget);
    expect(find.text('2. Periferik Sinir Sistemi ve Kas'), findsOneWidget);
    expect(find.text('Klinik'), findsNothing);
    expect(find.text('Temel'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Klasik müfredat seçildiğinde Dersler sekmesinde Temel ve Klinik sekmeleri görünür',
      (tester) async {
    final depo = await tester.runAsync(() async {
      final d = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
      await d.yukle();
      await d.karsilamayiTamamla(
        sinavTarihi: DateTime(2030, 4, 1),
        secilenDersler: klasikDersler,
        mufredatTuru: MufredatTuru.klasik,
      );
      return d;
    });
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dersler'));
    await tester.pumpAndSettle();
    expect(find.text('Temel'), findsOneWidget);
    expect(find.text('Klinik'), findsOneWidget);
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
  denemeTestleri();
  defterlerTestleri();
  bilisselTestleri();
  provaTestleri();
  kokpitTestleri();
  rehberTestleri();
  kutuphaneTestleri();
}

void takvimTestleri() {
  testWidgets('Takvimde konu yerleştirilir, Bugün\'de Çalıştım denir',
      (tester) async {
    // Uzun ekran: takvimin altındaki liste de çizilsin.
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = await doluDepo(tester);
    final ilkDers = depo.tumDersler.first;
    depo.konuEkle(ilkDers.id, 'Özel takvim konusu');
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Takvim'));
    await tester.pumpAndSettle();
    expect(find.text('Bu güne planlanmış bir şey yok.'), findsOneWidget);

    await tester.tap(find.text('+ Konu yerleştir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ilkDers.ad));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Özel takvim konusu'));
    await tester.pumpAndSettle();

    expect(depo.tumCalismalar().length, 1);
    expect(find.text('Özel takvim konusu'), findsOneWidget);

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
    final ilkDers = depo.tumDersler.first;
    final konu = depo.konular(ilkDers.id).first;
    final c = depo.calismaEkle(konu.id, DateTime.now())!;
    depo.calistim(c.id, DateTime.now());
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dersler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ilkDers.ad));
    await tester.pumpAndSettle();
    await tester.tap(find.text(konu.ad));
    await tester.pumpAndSettle();

    expect(find.text('Tekrar planı'), findsOneWidget);
    expect(find.textContaining('Tur 1/'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

void ftTestleri() {
  testWidgets('Pil kısıtlaması varsa sayaç ekranında uyarı çıkar, kapatılabilir',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = await doluDepo(tester);
    final kontrol = FtKontrol(depo, KisitliNative());
    await tester.pumpWidget(
      MaterialApp(
        home: DepoKapsami(
          deposu: depo,
          child: Scaffold(body: FtEkrani(kontrol: kontrol)),
        ),
      ),
    );
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
    final kontrol = FtKontrol(depo, native);
    await tester.pumpWidget(
      MaterialApp(
        home: DepoKapsami(
          deposu: depo,
          child: Scaffold(body: FtEkrani(kontrol: kontrol)),
        ),
      ),
    );
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
    final ilkDers = depo.tumDersler.first;
    final konu = depo.konuEkle(ilkDers.id, 'Alt ekstremite')!;
    final su = DateTime.now().millisecondsSinceEpoch;
    var o = depo.oturumBaslat(toplamDongu: 1, konuId: konu.id);
    o = o.baslat(su - 30 * 60 * 1000).guncelle(su);
    depo.oturumGuncelle(o);
    expect(depo.toplamPuan, 25);

    final kontrol = FtKontrol(depo, SahteNative());
    await tester.pumpWidget(
      MaterialApp(
        home: DepoKapsami(
          deposu: depo,
          child: Scaffold(body: FtEkrani(kontrol: kontrol)),
        ),
      ),
    );
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

    final calismaFinder = find.byWidgetPredicate((w) => w is Text && w.data != null && w.data!.endsWith('resi') && w.data!.length < 20);
    await tester.scrollUntilVisible(calismaFinder, 100);
    await tester.pumpAndSettle();
    await tester.tap(calismaFinder);
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
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = await doluDepo(tester);
    final ilkDers = depo.tumDersler.first;
    final konu = depo.konuEkle(ilkDers.id, 'Alt ekstremite')!;
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
    expect(find.text(ilkDers.ad), findsOneWidget);
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

void denemeTestleri() {
  testWidgets('Bugün ekranından Denemeler açılır ve yeni deneme eklenir',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final depo = await doluDepo(tester);
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Denemeler & Analiz'));
    await tester.pumpAndSettle();
    expect(find.text('Deneme Sınavları & Analiz'), findsOneWidget);
    expect(find.text('Henüz deneme kaydı yok'), findsOneWidget);

    await tester.tap(find.text('İlk Denemeni Ekle'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni Deneme Ekle'), findsOneWidget);
    expect(find.textContaining('TTBT'), findsOneWidget);
    expect(find.textContaining('KTBT'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Deneme Adı veya Yayın'),
        'Test Denemesi 1');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Denemeyi ve Netleri Kaydet'));
    await tester.pumpAndSettle();

    expect(depo.denemeler.length, 1);
    expect(depo.denemeler.first.ad, 'Test Denemesi 1');

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

void defterlerTestleri() {
  testWidgets('Bugün ekranından Özel Defterler açılır ve sekmeler gezilir',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final depo = await doluDepo(tester);
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Özel Defterler'));
    await tester.pumpAndSettle();
    expect(find.text('Defter'), findsOneWidget);
    expect(find.text('Hata & Çeldirici'), findsOneWidget);
    expect(find.text('Referans'), findsOneWidget);

    // K3 & K4: Mekanizma Zincirleri ve Vaka Kartı arayüzden gizlidir
    expect(find.text('Mekanizma Zincirleri'), findsNothing);
    expect(find.text('3 Dk Vaka Kartı'), findsNothing);

    // Referans sekmesine geç
    await tester.tap(find.text('Referans'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hinchey'), findsWidgets);
    expect(find.textContaining('Hodgkin'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

void bilisselTestleri() {
  testWidgets('Bugün ekranından Bilişsel & Uyku Yönetimi açılır ve öğeler listelenir',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final depo = await doluDepo(tester);
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bilişsel & Uyku'));
    await tester.pumpAndSettle();

    expect(find.text('Bilişsel & Uyku Yönetimi'), findsOneWidget);
    expect(find.textContaining('Zor Bilişsel İş Tavanı'), findsOneWidget);
    // K1: sirkadiyen grafik ve günlük uyku girişi gizli; hedef/kafein kartı açık.
    expect(find.textContaining('Sirkadiyen Odak'), findsNothing);
    expect(find.text('Dün Geceki Uykuyu Kaydet'), findsNothing);
    expect(find.textContaining('Uyku & Kafein Disiplini'), findsOneWidget);
    expect(find.textContaining('Prefrontal Korteks (PFC) & Kurtarma'), findsOneWidget);

    // Kurtarma Modu anahtarına tıkla
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(depo.kurtarmaModuAktif, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

void provaTestleri() {
  testWidgets('Denemeler ekranından Sınav Provası açılır, başlar ve panik protokolü çalışır',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final depo = await doluDepo(tester);
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Denemeler & Analiz'));
    await tester.pumpAndSettle();

    // Prova butonuna dokun
    await tester.tap(find.textContaining('Sınav Provası'));
    await tester.pumpAndSettle();

    expect(find.text('Gerçek Saat Sınav Provası'), findsOneWidget);
    expect(find.text('135 Dakika · 100 Soru'), findsOneWidget);
    expect(find.text('1. Oturum: TTBT (10:15)'), findsOneWidget);
    expect(find.text('2. Oturum: KTBT (14:45)'), findsOneWidget);

    // Panik protokolü butonuna tıkla
    await tester.tap(find.byTooltip('90 sn Panik / Nefes'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('90 sn Döngüsel İç Çekme'), findsOneWidget);
    expect(find.textContaining('Bilişsel Yeniden Değerlendirme'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Provayı başlat
    await tester.tap(find.text('Provayı Başlat (135 Dakika)'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('KALAN SÜRE'), findsOneWidget);
    expect(find.textContaining('Soru: 1 / 100'), findsOneWidget);
    expect(find.text('Provayı Bitir'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

void kokpitTestleri() {
  testWidgets('Bugün ekranından Master Kokpit açılır ve 8+4 göstergeler görünür',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final depo = await doluDepo(tester);
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    // K2: Bugün ekranında Master Kokpit gizlidir
    expect(find.byTooltip('Master Kokpit'), findsNothing);

    // Doğrudan Kokpit ekranı açılır
    await tester.pumpWidget(
      MaterialApp(
        home: DepoKapsami(
          deposu: depo,
          child: const KokpitEkrani(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Master Yönetim Kokpiti'), findsOneWidget);
    expect(find.text('BİLİŞSEL SAĞLIK & KOKPİT SKORU'), findsOneWidget);
    expect(find.text('Otomatik "Eğer–O Zaman" Kararları'), findsOneWidget);
    expect(find.text('8 Bilişsel Gösterge (Haftalık Teşhis)'), findsOneWidget);
    expect(find.text('4 Sınav & Net Göstergesi'), findsOneWidget);

    // 8 Göstergenin başlıkları
    expect(find.text('Kalibrasyon Farkı'), findsOneWidget);
    expect(find.text('Uyku Düzeni & Sapma'), findsOneWidget);
    expect(find.text('Prefrontal Korteks (PFC)'), findsOneWidget);
    expect(find.text('Test Kaygısı'), findsOneWidget);
    expect(find.text('R1 Tekrar Geçişi'), findsOneWidget);
    expect(find.text('R3 Tekrar Geçişi'), findsOneWidget);
    expect(find.text('Odak & Bilişsel Tavan'), findsOneWidget);

    // Hızlı araç: Beklenen Değer kartını aç
    await tester.tap(find.text('Beklenen Değer (EV)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Beklenen Değer (EV)'), findsWidgets);
    await tester.tap(find.text('Anladım'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

void rehberTestleri() {
  testWidgets('Bugün ekranından Rehber ve Tanıtım Turu açılır', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final depo = await doluDepo(tester);
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    // Bugün ekranındaki Rehber kartına dokun
    expect(find.text('Kullanım Rehberi & 1 Dk Tanıtım Turu'), findsOneWidget);
    await tester.tap(find.text('Kullanım Rehberi & 1 Dk Tanıtım Turu'));
    await tester.pumpAndSettle();

    expect(find.text('Kullanım Rehberi & SSS'), findsOneWidget);
    expect(find.text('Tanıtım Turunu Başlat (5 Slayt)'), findsOneWidget);

    // Tanıtım turunu başlat
    await tester.tap(find.text('Tanıtım Turunu Başlat (5 Slayt)'));
    await tester.pumpAndSettle();

    expect(find.text('1. Akıllı Planlama & Tekrar Sistemi (R0–R4)'), findsOneWidget);
    await tester.tap(find.text('Atla'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
  });
}


void kutuphaneTestleri() {
  testWidgets('Kütüphane sekmesi açılır, boş ekran ve kitap ekleme penceresi görünür',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final depo = await doluDepo(tester);
    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kütüphane'));
    await tester.pumpAndSettle();

    expect(find.text('Kütüphane İlerlemesi'), findsOneWidget);
    expect(find.text('Kütüphaneniz Henüz Boş'), findsOneWidget);

    await tester.tap(find.text('Kitap Ekle'));
    await tester.pumpAndSettle();
    expect(find.text('Kütüphaneye Kitap Ekle'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Bölüm Notları: Not ekleme, fotoğraf ve metin görüntüleme', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const base64Png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
    final testBytes = base64Decode(base64Png);
    ResimSecici.ornek = SahteResimSecici(donusBytes: testBytes);

    final depo = await doluDepo(tester);
    final kitap = Kitap(
      id: 'k_test',
      ad: 'Patoloji Kitabı',
      eklenmeTarihi: DateTime.now(),
      bolumler: const [
        KitapBolumu(id: 'b_test', ad: 'Hücre Hasarı'),
      ],
    );
    await depo.kitapEkle(kitap);

    await tester.pumpWidget(MyTusApp(deposu: depo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kütüphane'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Patoloji Kitabı'));
    await tester.pumpAndSettle();

    // Bölüm notları butonuna dokun
    await tester.tap(find.byTooltip('Bölüm Notları').first);
    await tester.pumpAndSettle();

    expect(find.text('Bu Bölüme Henüz Not Eklenmedi'), findsOneWidget);

    // Yeni not ekle butonuna dokun
    await tester.tap(find.text('İlk Notunu Ekle'));
    await tester.pumpAndSettle();

    expect(find.text('Bölüme Not Ekle'), findsOneWidget);

    // Galeriden seç butonuna dokun (SahteResimSecici tetiklenir)
    await tester.tap(find.text('Galeriden Seç'));
    await tester.pumpAndSettle();

    // Metin gir
    await tester.enterText(
      find.widgetWithText(TextField, 'Bölüm Notu / Bilgi Girişi'),
      'Goodpasture sendromu antikor aracılıdır.',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Goodpasture sendromu antikor aracılıdır.'), findsOneWidget);
    expect(find.text('1 Not'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
