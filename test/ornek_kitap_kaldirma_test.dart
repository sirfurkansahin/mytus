// Örnek kitap kaldırıldı ve mevcut kütüphanelerden de silinir
// (25 Kasım 2026 kararı: "Herkesten de silinsin").

import 'dart:convert';

import 'package:app/core/tarih.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/auth/kimlik_servisi.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/kutuphane/modeller.dart';
import 'package:app/features/senkronizasyon/bolum_ayirici.dart';
import 'package:app/features/senkronizasyon/bulut_kaynagi.dart';
import 'package:app/features/senkronizasyon/bulut_senkron_servisi.dart';
import 'package:flutter_test/flutter_test.dart';

/// Eski sürümün kendiliğinden eklediği örnek kitabın kayıttaki hâli.
Map<String, dynamic> _eskiOrnekKitap() => Kitap(
      id: kaldirilanOrnekKitapId,
      ad: 'TUSDATA Patoloji Konu Kitabı',
      dersAdi: 'Patoloji',
      eklenmeTarihi: DateTime(2026, 10, 1),
      bolumler: const [KitapBolumu(id: 'b_ornek_1', ad: 'Hücre Hasarı')],
    ).toJson();

Kitap _kendiKitabim() => Kitap(
      id: 'k_kendi',
      ad: 'Dahiliye Notlarım',
      eklenmeTarihi: DateTime(2026, 11, 2),
      bolumler: const [KitapBolumu(id: 'b_k1', ad: 'Kardiyoloji')],
    );

/// Kayıt metnindeki kütüphaneye eski örnek kitabı ekler.
String _ornekKitapEkle(String kayitMetni) {
  final veri = jsonDecode(kayitMetni) as Map<String, dynamic>;
  veri['kitaplar'] = [_eskiOrnekKitap(), ...(veri['kitaplar'] as List)];
  return jsonEncode(veri);
}

class _Cihaz {
  _Cihaz(BulutKaynagi bulut, String cihazId, {BellekKaydi? kayit})
      : yerel = kayit ?? BellekKaydi() {
    senkron = BulutSenkronServisi(
      yerelKayit: yerel,
      bulutKaynagi: bulut,
      gonderimGecikmesi: Duration.zero,
      cihazId: cihazId,
    );
    depo = PlanDeposu(kayit: senkron, kayitGecikmesi: Duration.zero);
    senkron.depoBagla(depo);
  }

  final BellekKaydi yerel;
  late final BulutSenkronServisi senkron;
  late final PlanDeposu depo;
}

void main() {
  const kullanici = KullaniciBilgisi(uid: 'uid_ornek', eposta: 'o@mytus.com');

  test('cihazdaki kayıtta duran örnek kitap açılışta silinir, diğerleri kalır',
      () async {
    final ilk = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
    await ilk.yukle();
    await ilk.karsilamayiTamamla(
      sinavTarihi: resmiSinavTarihi,
      secilenDersler: const [HazirDers('Patoloji', DersGrubu.temel)],
    );
    await ilk.kitapEkle(_kendiKitabim());
    final eskiKayit = _ornekKitapEkle(jsonEncode(ilk.toJson()));

    final kayit = BellekKaydi(icerik: eskiKayit);
    final depo = PlanDeposu(kayit: kayit, kayitGecikmesi: Duration.zero);
    await depo.yukle();
    await depo.hemenKaydet();

    expect(depo.kitapBul(kaldirilanOrnekKitapId), isNull);
    expect(depo.kitaplar.map((k) => k.id), ['k_kendi']);
    // Temiz hâl cihaza da yazıldı.
    expect(kayit.icerik, isNot(contains(kaldirilanOrnekKitapId)));
    expect(kayit.icerik, contains('k_kendi'));
  });

  test('bölümlere ayırırken örnek kitap buluta gönderilmez', () {
    final bolumler = BolumAyirici.ayir({
      'kitaplar': [_eskiOrnekKitap(), _kendiKitabim().toJson()],
    }).bolumler;
    expect(bolumler['kutuphane'], isNot(contains(kaldirilanOrnekKitapId)));
    expect(bolumler['kutuphane'], contains('k_kendi'));
  });

  test('buluttan gelen bölümden örnek kitap ayıklanır; temiz bölüm aynen kalır',
      () {
    final temiz = BolumAyirici.ayir({
      'kitaplar': [_kendiKitabim().toJson()],
    }).bolumler;
    // Örnek kitap yoksa metin hiç değişmez (karşılaştırmalar bozulmasın).
    expect(BolumAyirici.kaldirilanlariAyikla(temiz), same(temiz));

    final eski = {
      ...temiz,
      'kutuphane': jsonEncode({
        'kitaplar': [_eskiOrnekKitap(), _kendiKitabim().toJson()],
      }),
    };
    final ayiklanmis = BolumAyirici.kaldirilanlariAyikla(eski);
    expect(ayiklanmis['kutuphane'], temiz['kutuphane']);
    expect(ayiklanmis['plan'], eski['plan']);
  });

  test(
      'önceki sürümden geçiş: örnek kitap çakışma sordurmaz, '
      'cihazdan ve buluttan silinir', () async {
    final bulut = SahteBulutKaynagi();
    final a = _Cihaz(bulut, 'cihaz_a');
    await a.depo.yukle();
    await a.depo.karsilamayiTamamla(
      sinavTarihi: resmiSinavTarihi,
      secilenDersler: const [HazirDers('Patoloji', DersGrubu.temel)],
    );
    await a.depo.kitapEkle(_kendiKitabim());
    await a.senkron.oturumAcildi(kullanici);
    final buluttaki = bulut.kullaniciBolumleri[kullanici.uid]!;
    expect(buluttaki['kutuphane'], contains('k_kendi'));

    // Eski sürüm: hem cihazda hem bulutta örnek kitap var, cihaz durumu yok.
    buluttaki['kutuphane'] = jsonEncode({
      'kitaplar': [
        _eskiOrnekKitap(),
        ...(jsonDecode(buluttaki['kutuphane']!)['kitaplar'] as List),
      ],
    });
    final eski = _Cihaz(
      bulut,
      'eski_surum',
      kayit: BellekKaydi(icerik: _ornekKitapEkle(a.yerel.icerik!)),
    );
    await eski.depo.yukle();
    await eski.senkron.oturumAcildi(kullanici);

    expect(eski.senkron.bekleyenCakisma, isNull);
    expect(eski.depo.kitapBul(kaldirilanOrnekKitapId), isNull);
    expect(eski.depo.kitapBul('k_kendi'), isNotNull);
    expect(eski.yerel.icerik, isNot(contains(kaldirilanOrnekKitapId)));
    // Bulut da temizlendi; kullanıcının kendi kitabı duruyor.
    final sonra = bulut.kullaniciBolumleri[kullanici.uid]!['kutuphane']!;
    expect(sonra, isNot(contains(kaldirilanOrnekKitapId)));
    expect(sonra, contains('k_kendi'));
  });

  test('eski sürümlü başka cihaz örnek kitabı gönderirse burada görünmez',
      () async {
    final bulut = SahteBulutKaynagi();
    final a = _Cihaz(bulut, 'cihaz_a');
    await a.depo.yukle();
    await a.depo.karsilamayiTamamla(
      sinavTarihi: resmiSinavTarihi,
      secilenDersler: const [HazirDers('Patoloji', DersGrubu.temel)],
    );
    await a.depo.kitapEkle(_kendiKitabim());
    await a.senkron.oturumAcildi(kullanici);

    final yeniKitap = Kitap(
      id: 'k_yeni',
      ad: 'Öbür cihazda eklenen kitap',
      eklenmeTarihi: DateTime(2026, 11, 20),
    );
    bulut.uzaktanDegisiklikSimuleEt(
      uid: kullanici.uid,
      bolumler: {
        'kutuphane': jsonEncode({
          'kitaplar': [
            _eskiOrnekKitap(),
            _kendiKitabim().toJson(),
            yeniKitap.toJson(),
          ],
        }),
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));

    // Öbür cihazın değişikliği geldi, ama örnek kitap gelmedi.
    expect(a.depo.kitapBul('k_yeni'), isNotNull);
    expect(a.depo.kitapBul(kaldirilanOrnekKitapId), isNull);
    expect(a.depo.kitapBul('k_kendi'), isNotNull);
    expect(a.yerel.icerik, isNot(contains(kaldirilanOrnekKitapId)));
  });
}
