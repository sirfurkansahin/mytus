import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/hazir_dersler.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/ft_time/ft_native.dart';
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

/// Android köprüsü olmadan (testte) her çağrı hemen tamamlanır.
class SahteNative extends FtNative {
  SahteNative();

  final List<String> cagrilar = [];

  @override
  Future<bool> kullanilabilir() async => true;
  @override
  Future<String?> derlemeNo() async => '1';
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

