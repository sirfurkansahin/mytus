import 'package:app/core/veri_kaydi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('BellekKaydi okuma ve yazma calisir', () async {
    final kayit = BellekKaydi();
    expect(await kayit.oku(), isNull);
    await kayit.yaz('test veri');
    expect(await kayit.oku(), 'test veri');
    expect(kayit.yazmaSayisi, 1);
  });

  test('DosyaKaydi ornegi olusturulabilir', () {
    const kayit = DosyaKaydi();
    expect(kayit, isNotNull);
  });
}
