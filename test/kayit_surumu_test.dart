// Kayıt sürümü (A3): farklı sürümler aynı kaydı açtığında veri silinmemeli.

import 'dart:convert';

import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _cozumle(String? metin) =>
    jsonDecode(metin!) as Map<String, dynamic>;

void main() {
  test('tanınmayan (daha yeni sürümün yazdığı) alanlar kaydederken korunur',
      () async {
    final kayit = BellekKaydi(
      icerik: jsonEncode({
        'surum': 9,
        'karsilamaTamam': true,
        'mufredatTuru': 'klasik',
        'dersler': [
          {'id': 1, 'ad': 'Patoloji', 'grup': 'temel'},
        ],
        'yeniSurumAlani': {'liste': [1, 2, 3], 'acik': true},
      }),
    );
    final depo = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
    await depo.yukle();
    expect(depo.durum, YuklemeDurumu.hazir);

    depo.dersEkle('Dahiliye');
    await depo.hemenKaydet();

    final yazilan = _cozumle(kayit.icerik);
    expect(yazilan['yeniSurumAlani'], {
      'liste': [1, 2, 3],
      'acik': true,
    });
    expect(yazilan['surum'], PlanDeposu.kayitSurumu);
    expect(
      (yazilan['dersler'] as List).map((d) => (d as Map)['ad']),
      containsAll(['Patoloji', 'Dahiliye']),
    );
  });

  test('"kitaplar" alanı olmayan kayıt açılınca kütüphaneye örnek kitap eklenmez',
      () async {
    final kayit = BellekKaydi(
      icerik: jsonEncode({
        'surum': 1,
        'karsilamaTamam': true,
        'mufredatTuru': 'klasik',
        'dersler': [
          {'id': 1, 'ad': 'Patoloji', 'grup': 'temel'},
        ],
      }),
    );
    final depo = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
    await depo.yukle();
    expect(depo.kitaplar, isEmpty);
  });

  test('tüm veriler sıfırlanınca tanınmayan alanlar da silinir', () async {
    final kayit = BellekKaydi(
      icerik: jsonEncode({
        'karsilamaTamam': true,
        'yeniSurumAlani': 'eski veri',
      }),
    );
    final depo = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
    await depo.yukle();
    await depo.tumVerileriSifirla();
    await depo.hemenKaydet();
    expect(_cozumle(kayit.icerik).containsKey('yeniSurumAlani'), isFalse);
  });
}
