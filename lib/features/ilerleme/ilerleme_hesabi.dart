import 'package:app/core/tarih.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';

/// Bir dersin haftalık odak süresi.
class DersOzeti {
  const DersOzeti({required this.ad, required this.dakika});

  final String ad;
  final int dakika;
}

/// Pazartesi'den Pazar'a bir haftanın özeti.
class HaftaOzeti {
  const HaftaOzeti({
    required this.baslangic,
    required this.calisilanKonu,
    required this.bitenTekrar,
    required this.bitenDongu,
    required this.odakDakika,
    required this.aktifGun,
    required this.gunlukDakika,
    required this.dersler,
  });

  /// Haftanın Pazartesi'si.
  final DateTime baslangic;

  /// O hafta "Çalıştım" denen farklı konu sayısı.
  final int calisilanKonu;

  /// O hafta tamamlanan tekrar sayısı.
  final int bitenTekrar;

  /// O hafta biten odak döngüsü sayısı.
  final int bitenDongu;

  /// O haftaki toplam odak süresi (dakika). 1 dakika = 1 puan.
  final int odakDakika;

  /// O hafta en az bir görev veya odak yapılan gün sayısı (0-7).
  final int aktifGun;

  /// Pazartesi'den Pazar'a günlük odak dakikası (7 eleman).
  final List<int> gunlukDakika;

  /// Konuya bağlı odaklardan derse göre süre, çoktan aza.
  final List<DersOzeti> dersler;

  int get puan => odakDakika;
  DateTime get bitis => gunEkle(baslangic, 6);
  bool get bos => calisilanKonu == 0 && bitenTekrar == 0 && bitenDongu == 0;
}

/// Tüm TUS müfredatının genel ilerleme özeti (toplam konu, çalışılan konu, tekrar, seri).
class GenelIlerleme {
  const GenelIlerleme({
    required this.toplamKonu,
    required this.calisilanKonu,
    required this.toplamTekrar,
    required this.seriGun,
  });

  final int toplamKonu;
  final int calisilanKonu;
  final int toplamTekrar;
  final int seriGun;

  double get oran => toplamKonu == 0 ? 0.0 : calisilanKonu / toplamKonu;
  int get yuzde => (oran * 100).round();
}

/// [gun]'ün içinde olduğu haftanın özetini hesaplar.
HaftaOzeti haftaOzetiHesapla(PlanDeposu depo, DateTime gun) {
  final bas = haftaBasi(gun);
  final son = gunEkle(bas, 7);

  final konular = <int>{};
  var tekrarSayisi = 0;
  final aktifGunler = <DateTime>{};

  for (final c in depo.tumCalismalar()) {
    if (c.tamam && !c.tarih.isBefore(bas) && c.tarih.isBefore(son)) {
      konular.add(c.konuId);
      aktifGunler.add(gunBasi(c.tarih));
    }
    for (final tk in c.tekrarlar) {
      if (!tk.tarih.isBefore(bas) && tk.tarih.isBefore(son)) {
        tekrarSayisi++;
        aktifGunler.add(gunBasi(tk.tarih));
      }
    }
  }

  var dongu = 0;
  var toplam = 0;
  final gunluk = List<int>.filled(7, 0);
  final dersDakika = <int, int>{};
  for (final o in depo.odaklar) {
    final t = o.tarih;
    if (t.isBefore(bas) || !t.isBefore(son)) continue;
    dongu++;
    toplam += o.dakika;
    final g = gunBasi(t);
    aktifGunler.add(g);
    final sira = gunFarki(g, bas);
    gunluk[sira < 0 ? 0 : (sira > 6 ? 6 : sira)] += o.dakika;
    final konuId = o.konuId;
    if (konuId == null) continue;
    final konu = depo.konuBul(konuId);
    if (konu == null) continue;
    dersDakika[konu.dersId] = (dersDakika[konu.dersId] ?? 0) + o.dakika;
  }

  final dersler = <DersOzeti>[];
  dersDakika.forEach((dersId, dk) {
    final ders = depo.dersBul(dersId);
    if (ders != null) dersler.add(DersOzeti(ad: ders.ad, dakika: dk));
  });
  dersler.sort((a, b) {
    final k = b.dakika.compareTo(a.dakika);
    return k != 0 ? k : a.ad.compareTo(b.ad);
  });

  return HaftaOzeti(
    baslangic: bas,
    calisilanKonu: konular.length,
    bitenTekrar: tekrarSayisi,
    bitenDongu: dongu,
    odakDakika: toplam,
    aktifGun: aktifGunler.length,
    gunlukDakika: gunluk,
    dersler: dersler,
  );
}

/// Genel müfredat ilerlemesini ve bugüne/düne kadar aralıksız çalışma serisini hesaplar.
GenelIlerleme genelIlerlemeHesapla(PlanDeposu depo, DateTime bugun) {
  var toplamKonu = 0;
  var calisilanKonu = 0;
  for (final grup in DersGrubu.values) {
    for (final d in depo.dersler(grup)) {
      toplamKonu += depo.konuSayisi(d.id);
      calisilanKonu += depo.calisilanSayisi(d.id);
    }
  }

  var toplamTekrar = 0;
  final aktifGunler = <String>{};
  for (final c in depo.tumCalismalar()) {
    if (c.tamam) aktifGunler.add(tarihAnahtari(c.tarih));
    for (final tk in c.tekrarlar) {
      toplamTekrar++;
      aktifGunler.add(tarihAnahtari(tk.tarih));
    }
  }
  for (final o in depo.odaklar) {
    aktifGunler.add(tarihAnahtari(gunBasi(o.tarih)));
  }

  // Seri hesabı: bugün aktifse bugünden, değilse dünden geriye doğru kesintisiz gün sayısı.
  var kontrolGunu = gunBasi(bugun);
  if (!aktifGunler.contains(tarihAnahtari(kontrolGunu))) {
    kontrolGunu = gunEkle(kontrolGunu, -1);
  }
  var seri = 0;
  while (aktifGunler.contains(tarihAnahtari(kontrolGunu))) {
    seri++;
    kontrolGunu = gunEkle(kontrolGunu, -1);
  }

  return GenelIlerleme(
    toplamKonu: toplamKonu,
    calisilanKonu: calisilanKonu,
    toplamTekrar: toplamTekrar,
    seriGun: seri,
  );
}

/// Odak süresini yazar: 45 dk altı "45 dk", üstü "5,8 sa".
String odakSuresiYaz(int dakika) {
  if (dakika < 60) return '$dakika dk';
  final saat = (dakika / 60).toStringAsFixed(1).replaceAll('.', ',');
  return '${saat.endsWith(',0') ? saat.substring(0, saat.length - 2) : saat} sa';
}

/// Hafta aralığı başlığı: "12 – 18 Ekim" ya da "28 Eki – 3 Kas".
String haftaAraligiYaz(DateTime bas) {
  final son = gunEkle(bas, 6);
  if (bas.month == son.month) {
    return '${bas.day} – ${son.day} ${ayAdi(son.month)}';
  }
  String kisa(DateTime t) => '${t.day} ${ayAdi(t.month).substring(0, 3)}';
  return '${kisa(bas)} – ${kisa(son)}';
}
