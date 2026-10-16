import 'package:app/core/tarih.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/ft_time/ft_oturum.dart';
import 'package:app/features/ilerleme/ilerleme_hesabi.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tek döngülük bir oturumu verilen gün/saatte bitirir ve puanlar.
void odakEkle(
  PlanDeposu depo,
  DateTime bitis, {
  int? konuId,
  int dakika = 25,
}) {
  final ayar = const FtAyarlari().kopya(calismaDk: dakika);
  final o = FtOturum.yeni(
    id: depo.oturumBaslat(toplamDongu: 1).id,
    toplamDongu: 1,
    ayar: ayar,
    konuId: konuId,
  );
  final basla = bitis.subtract(Duration(minutes: dakika)).millisecondsSinceEpoch;
  depo.oturumGuncelle(o.baslat(basla).guncelle(bitis.millisecondsSinceEpoch + 1));
  depo.oturumKapat();
}

void main() {
  Future<({PlanDeposu depo, int fizyoloji, int biyokimya, int kalp, int ritim, int enzim})>
      hazirla() async {
    final depo = PlanDeposu(kayit: BellekKaydi(), kayitGecikmesi: Duration.zero);
    await depo.yukle();
    await depo.karsilamayiTamamla(
      sinavTarihi: DateTime(2027, 4, 1),
      secilenDersler: const [
        HazirDers('Fizyoloji', DersGrubu.temel),
        HazirDers('Biyokimya', DersGrubu.temel),
      ],
    );
    final f = depo.dersler(DersGrubu.temel).firstWhere((d) => d.ad == 'Fizyoloji');
    final b = depo.dersler(DersGrubu.temel).firstWhere((d) => d.ad == 'Biyokimya');
    return (
      depo: depo,
      fizyoloji: f.id,
      biyokimya: b.id,
      kalp: depo.konuEkle(f.id, 'Kalp döngüsü')!.id,
      ritim: depo.konuEkle(f.id, 'Ritim')!.id,
      enzim: depo.konuEkle(b.id, 'Enzimler')!.id,
    );
  }

  // 12 Ekim 2026 Pazartesi; hafta 12-18 Ekim.
  final hafta = DateTime(2026, 10, 14);

  test('haftaBasi pazartesiyi verir', () {
    expect(haftaBasi(DateTime(2026, 10, 18, 23)), DateTime(2026, 10, 12));
    expect(haftaBasi(DateTime(2026, 10, 12)), DateTime(2026, 10, 12));
    expect(haftaBasi(DateTime(2026, 10, 19)), DateTime(2026, 10, 19));
  });

  test('boş hafta sıfırlarla döner', () async {
    final h = await hazirla();
    final o = haftaOzetiHesapla(h.depo, hafta);
    expect(o.bos, isTrue);
    expect(o.odakDakika, 0);
    expect(o.gunlukDakika, List<int>.filled(7, 0));
    expect(o.dersler, isEmpty);
  });

  test('odaklar güne, derse ve haftaya göre toplanır', () async {
    final h = await hazirla();
    odakEkle(h.depo, DateTime(2026, 10, 12, 10), konuId: h.kalp); // Pzt, Fizyoloji
    odakEkle(h.depo, DateTime(2026, 10, 14, 10), konuId: h.ritim, dakika: 50); // Çar
    odakEkle(h.depo, DateTime(2026, 10, 14, 15), konuId: h.enzim); // Çar, Biyokimya
    odakEkle(h.depo, DateTime(2026, 10, 18, 20)); // Paz, konusuz
    odakEkle(h.depo, DateTime(2026, 10, 19, 9), konuId: h.kalp); // sonraki hafta
    odakEkle(h.depo, DateTime(2026, 10, 11, 9), konuId: h.kalp); // önceki hafta

    final o = haftaOzetiHesapla(h.depo, hafta);
    expect(o.bitenDongu, 4);
    expect(o.odakDakika, 25 + 50 + 25 + 25);
    expect(o.puan, o.odakDakika);
    expect(o.gunlukDakika, [25, 0, 75, 0, 0, 0, 25]);
    expect(o.dersler.map((d) => d.ad), ['Fizyoloji', 'Biyokimya']);
    expect(o.dersler.first.dakika, 75);
    expect(o.dersler.last.dakika, 25);
    expect(o.baslangic, DateTime(2026, 10, 12));
    expect(o.bitis, DateTime(2026, 10, 18));

    final onceki = haftaOzetiHesapla(h.depo, DateTime(2026, 10, 8));
    expect(onceki.bitenDongu, 1);
    expect(onceki.gunlukDakika[6], 25);
  });

  test('çalışılan konu: o hafta Çalıştım denen farklı konular', () async {
    final h = await hazirla();
    final a = h.depo.calismaEkle(h.kalp, DateTime(2026, 10, 13))!;
    final b = h.depo.calismaEkle(h.kalp, DateTime(2026, 10, 15))!; // aynı konu, 2. tur
    final c = h.depo.calismaEkle(h.enzim, DateTime(2026, 10, 16))!;
    final d = h.depo.calismaEkle(h.ritim, DateTime(2026, 10, 20))!; // sonraki hafta
    h.depo.calistim(a.id, DateTime(2026, 10, 13));
    h.depo.calistim(b.id, DateTime(2026, 10, 15));
    h.depo.calistim(c.id, DateTime(2026, 10, 16));
    // d işaretlenmedi, planlı kaldı.
    expect(h.depo.calismaBul(d.id)!.tamam, isFalse);
    final o = haftaOzetiHesapla(h.depo, hafta);
    expect(o.calisilanKonu, 2);
    expect(haftaOzetiHesapla(h.depo, DateTime(2026, 10, 20)).calisilanKonu, 0);
  });

  test('silinen konunun odağı derse yazılmaz ama toplama girer', () async {
    final h = await hazirla();
    odakEkle(h.depo, DateTime(2026, 10, 13, 10), konuId: h.kalp);
    h.depo.konuSil(h.kalp);
    final o = haftaOzetiHesapla(h.depo, hafta);
    expect(o.odakDakika, 25);
    expect(o.dersler, isEmpty);
  });

  test('süre ve hafta yazımı', () {
    expect(odakSuresiYaz(0), '0 dk');
    expect(odakSuresiYaz(45), '45 dk');
    expect(odakSuresiYaz(60), '1 sa');
    expect(odakSuresiYaz(348), '5,8 sa');
    expect(odakSuresiYaz(126), '2,1 sa');
    expect(haftaAraligiYaz(DateTime(2026, 10, 12)), '12 – 18 Ekim');
    expect(haftaAraligiYaz(DateTime(2026, 10, 26)), '26 Eki – 1 Kas');
  });
}
