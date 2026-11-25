// KANIT TESTLERİ (main ve son dal için ortak)
//
// Bu dosyadaki testler bilerek "olması gereken" davranışı ister.
// Test BAŞARISIZ olursa, raporlanan hata gerçekten var demektir.
// Uygulama kodu değiştirilmedi; yalnızca bu test dosyası eklendi.

import 'package:app/core/tarih.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:app/features/dersler/hazir_dersler.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/takvim/calisma.dart';
import 'package:app/features/takvim/tekrar_motoru.dart';
import 'package:flutter_test/flutter_test.dart';

Future<PlanDeposu> bosDepo([BellekKaydi? kayit]) async {
  final depo = PlanDeposu(
    kayit: kayit ?? BellekKaydi(),
    kayitGecikmesi: Duration.zero,
  );
  await depo.yukle();
  return depo;
}

void main() {
  test(
    'KANIT-01 eski kayıt (müfredat alanı yok, Klinik ders var) Klasik olarak tanınmalı',
    () async {
      // 3 Kasım 2026 öncesi kayıt biçimi: "mufredatTuru" anahtarı yok,
      // dersler Temel/Klinik gruplu (Klasik Branşlar).
      const eskiKayit = '{"surum":1,"sonId":2,"karsilamaTamam":true,'
          '"sinavTarihi":"2027-08-22",'
          '"dersler":[{"id":1,"ad":"Anatomi","grup":"temel"},'
          '{"id":2,"ad":"Dahiliye","grup":"klinik"}],'
          '"konular":[],"calismalar":[]}';
      final depo = await bosDepo(BellekKaydi(icerik: eskiKayit));

      expect(depo.tumDersler.length, 2);
      expect(
        depo.mufredatTuru,
        MufredatTuru.klasik,
        reason: 'Klinik grupta ders olan eski kayıt Klasik müfredat sayılmalı. '
            'plan_deposu.dart, yeni okunan dersler yerine bellekteki (boş) '
            '_dersler listesine baktığı için SpeeTUS sanıyor.',
      );
    },
  );

  test(
    'KANIT-02 müfredat değiştirilince deneme kayıtları da siliniyor (uyarıda yazmıyor)',
    () async {
      final depo = await bosDepo();
      await depo.karsilamayiTamamla(
        sinavTarihi: DateTime(2027, 8, 22),
        secilenDersler: klasikDersler,
        mufredatTuru: MufredatTuru.klasik,
      );
      await depo.denemeEkle(
        DenemeSinavi(
          id: 'deneme_1',
          ad: 'Kasım denemesi',
          tarih: DateTime(2026, 11, 20),
          temel: const DenemeOturumu(dogru: 60, yanlis: 20, bos: 20),
        ),
      );
      expect(depo.denemeler.length, 1);

      // Ayarlar > Müfredat değiştir uyarı metni yalnızca
      // "Mevcut çalışma ve not kayıtların sıfırlanır" diyor.
      await depo.mufredatSifirlaVeDegistir(
        yeniTur: MufredatTuru.speetus,
        yeniDersler: speetusDersler,
      );

      expect(
        depo.denemeler.length,
        1,
        reason: 'Deneme sınavı kayıtları müfredatla ilgili değil ve uyarıda '
            'silineceği yazmıyor; yine de mufredatSifirlaVeDegistir hepsini siliyor.',
      );
    },
  );

  test(
    'KANIT-03 %70 Kurtarma Modu açıkken yeni konu ve R3-R4 tekrarları sürüyor',
    () async {
      final bugun = gunBasi(DateTime.now());
      final depo = await bosDepo();
      await depo.karsilamayiTamamla(
        sinavTarihi: gunEkle(bugun, 300),
        secilenDersler: const [HazirDers('Patoloji', DersGrubu.temel)],
        mufredatTuru: MufredatTuru.klasik,
      );
      final ders = depo.tumDersler.first;
      final konu = depo.konuEkle(ders.id, 'Kanıt konusu')!;
      final calisma = depo.calismaEkle(konu.id, bugun)!;
      expect(depo.calistim(calisma.id, bugun), isTrue);

      // Bilişsel ekranındaki anahtar: "Etkinleştirildiğinde yeni konular askıya
      // alınır, sadece R1-R2 tekrarları yapılır."
      await depo.kurtarmaModuAyarla(true);

      final r3r4 = depo
          .tekrarlar(bugun)
          .where((t) => t.calismaId == calisma.id && t.no >= 3)
          .length;
      final yeniYerlestirme = depo.calismaEkle(konu.id, gunEkle(bugun, 1));

      expect(
        {'R3-R4 tekrar sayısı': r3r4, 'yeni konu eklendi': yeniYerlestirme != null},
        {'R3-R4 tekrar sayısı': 0, 'yeni konu eklendi': false},
        reason: 'Kurtarma Modu yalnızca ekranda yazı/rozet gösteriyor; '
            'plan ve tekrar hesabında hiçbir yerde kullanılmıyor.',
      );
    },
  );

  test(
    'KANIT-04 tahmini ÖSYM puanı 45 altını göstermiyor (0 net de 45 çıkıyor)',
    () {
      final sifirNet = DenemeSinavi(
        id: 'd0',
        ad: 'Sıfır net',
        tarih: DateTime(2026, 11, 1),
      );
      expect(
        sifirNet.tahminiEbapPuani,
        lessThan(45.0),
        reason: '45, TUS tercih barajıdır. Formül 45 altını da üretebilir; '
            'kod sonucu 45-85 arasına sıkıştırdığı için hiç neti olmayan '
            'adaya baraj puanı gösteriliyor.',
      );
    },
  );

  test(
    'KANIT-05 henüz çalışılmamış konuların tekrarları günlük sınırı dolduruyor',
    () {
      final bugun = DateTime(2026, 12, 1);
      final calismalar = <Calisma>[
        // 10 konu bugüne planlandı ama henüz "Çalıştım" denmedi.
        for (var i = 1; i <= 10; i++) Calisma(id: i, konuId: i, tarih: bugun),
        // Bu konu bugün gerçekten çalışıldı.
        Calisma(id: 11, konuId: 11, tarih: bugun, tamam: true),
      ];
      final tekrarlar = tekrarlariHesapla(
        calismalar: calismalar,
        sinavTarihi: DateTime(2027, 8, 22),
        bugun: bugun,
        gunlukSinir: 10,
      );
      final r1 = tekrarlar.firstWhere((t) => t.calismaId == 11 && t.no == 1);

      expect(
        r1.tarih,
        DateTime(2026, 12, 2),
        reason: 'Çalışılan konunun R1 tekrarı ertesi gün olmalı. Çalışılmamış '
            '10 konunun (yapılamayan) tekrarları günlük 10 sınırını doldurduğu '
            'için gerçek tekrar bir gün sonraya itiliyor.',
      );
    },
  );

  test(
    'KANIT-06 geçersiz alan içeren yedek, verileri yarıda değiştirip hata fırlatıyor',
    () async {
      final depo = await bosDepo();
      await depo.karsilamayiTamamla(
        sinavTarihi: DateTime(2027, 8, 22),
        secilenDersler: const [
          HazirDers('Anatomi', DersGrubu.temel),
          HazirDers('Dahiliye', DersGrubu.klinik),
        ],
        mufredatTuru: MufredatTuru.klasik,
      );
      final onceki = depo.tumDersler.map((d) => d.ad).toList();

      // Geçerli JSON, ama bir deneme kaydındaki "temel" alanı bozuk.
      const bozukYedek = '{"karsilamaTamam":true,"sinavTarihi":"2027-08-22",'
          '"dersler":[{"id":1,"ad":"Yedekteki Ders","grup":"temel"}],'
          '"denemeler":[{"id":"d1","ad":"Bozuk","tarih":"2026-11-01",'
          '"temel":"bozuk"}]}';
      Object? hata;
      var sonuc = true;
      try {
        sonuc = depo.yedektenYukle(bozukYedek);
      } catch (e) {
        hata = e;
      }

      expect(
        {
          'hata': hata?.runtimeType.toString(),
          'sonuc': sonuc,
          'dersler': depo.tumDersler.map((d) => d.ad).toList(),
        },
        {'hata': null, 'sonuc': false, 'dersler': onceki},
        reason: 'Geçersiz yedek "Yedek metni geçersiz, mevcut verilerine '
            'dokunulmadı" demeli ve hiçbir veriyi değiştirmemeli. '
            '_jsonYukle yalnızca FormatException yakalıyor; dersler '
            'değiştirildikten sonra tür hatası fırlıyor.',
      );
    },
  );
}
