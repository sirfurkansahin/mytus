// Son çalışılan ders paylaşımı isteğe bağlı (25 Kasım 2026 kararı).

import 'dart:convert';

import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/grup/modeller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('varsayılan kapalı; açılınca kayda yazılır ve yeniden açılınca korunur',
      () async {
    final kayit = BellekKaydi();
    final depo = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
    await depo.yukle();
    expect(depo.sonDersPaylas, isFalse);

    depo.sonDersPaylasimiAyarla(true);
    await depo.hemenKaydet();
    expect((jsonDecode(kayit.icerik!) as Map)['sonDersPaylas'], isTrue);

    final yeniden = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
    await yeniden.yukle();
    expect(yeniden.sonDersPaylas, isTrue);
  });

  test('paylaşım kapalıyken üye kaydı son dersi boş yazar (gruptan silinir)',
      () {
    final uye = GrupUyesi(
      uid: 'u1',
      takmaAd: 'Dr. A',
      haftaBaslangici: '2026-11-23',
      guncellemeTarihi: DateTime(2026, 11, 25),
    );
    final json = uye.toJson();
    expect(json.containsKey('sonDers'), isTrue);
    expect(json['sonDers'], isNull);
  });
}
