// KANIT TESTİ (yalnızca main): eski sürümün yeni kaydı açıp kaydetmesi
//
// deploy-web.yml main'de "main" ve "model2/*" gönderimlerinde siteyi yayınlıyor.
// Canlı sitede şu an son dal (claude/esnek-giris-bulut) çalışıyor. main'deki
// (daha eski) kod yeniden yayınlanırsa kullanıcının tarayıcısındaki yeni biçimli
// kaydı açar. Bu test, o durumda neler olduğunu gösterir.
// Test bilerek "olması gereken" davranışı ister; BAŞARISIZ olması hatanın kanıtıdır.

import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'KANIT-18 eski sürüm, yeni sürümün kaydını açıp kaydedince bilmediği alanları siliyor',
    () async {
      // Son dalın yazdığı kayıttan kısaltılmış örnek: kütüphane, grup ve misafir modu.
      const yeniSurumKaydi = '{"surum":1,"sonId":2,"karsilamaTamam":true,'
          '"misafirModu":true,"aktifGrupId":"grup_1",'
          '"sinavTarihi":"2027-08-22","mufredatTuru":"klasik",'
          '"dersler":[{"id":1,"ad":"Patoloji","grup":"temel"}],'
          '"konular":[],"calismalar":[],'
          '"kitaplar":[{"id":"k1","ad":"Kendi kitabım","bolumler":[]}]}';
      final kayit = BellekKaydi(icerik: yeniSurumKaydi);
      final depo = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
      await depo.yukle();

      // Kullanıcı herhangi bir değişiklik yapar; kayıt yeniden yazılır.
      depo.dersEkle('Yeni ders');
      await depo.hemenKaydet();

      final icerik = kayit.icerik ?? '';
      expect(
        {
          'kitaplar': icerik.contains('"kitaplar"'),
          'aktifGrupId': icerik.contains('"aktifGrupId"'),
          'misafirModu': icerik.contains('"misafirModu"'),
        },
        {'kitaplar': true, 'aktifGrupId': true, 'misafirModu': true},
        reason: 'toJson yalnızca bildiği alanları yazıyor; eski kod yayına '
            'girerse kullanıcının kitapları/fotoğraflı notları ve grup bağı '
            'ilk kayıtta kalıcı olarak siliniyor.',
      );
    },
  );
}
