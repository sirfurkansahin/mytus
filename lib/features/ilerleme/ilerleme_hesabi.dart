import 'package:app/core/tarih.dart';
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
    required this.bitenDongu,
    required this.odakDakika,
    required this.gunlukDakika,
    required this.dersler,
  });

  /// Haftanın Pazartesi'si.
  final DateTime baslangic;

  /// O hafta "Çalıştım" denen farklı konu sayısı.
  final int calisilanKonu;

  /// O hafta biten odak döngüsü sayısı.
  final int bitenDongu;

  /// O haftaki toplam odak süresi (dakika). 1 dakika = 1 puan.
  final int odakDakika;

  /// Pazartesi'den Pazar'a günlük odak dakikası (7 eleman).
  final List<int> gunlukDakika;

  /// Konuya bağlı odaklardan derse göre süre, çoktan aza.
  final List<DersOzeti> dersler;

  int get puan => odakDakika;
  DateTime get bitis => gunEkle(baslangic, 6);
  bool get bos => calisilanKonu == 0 && bitenDongu == 0;
}

/// [gun]'ün içinde olduğu haftanın özetini hesaplar.
HaftaOzeti haftaOzetiHesapla(PlanDeposu depo, DateTime gun) {
  final bas = haftaBasi(gun);
  final son = gunEkle(bas, 7);

  final konular = <int>{};
  for (final c in depo.tumCalismalar()) {
    if (c.tamam && !c.tarih.isBefore(bas) && c.tarih.isBefore(son)) {
      konular.add(c.konuId);
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
    final sira = gunFarki(gunBasi(t), bas);
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
    bitenDongu: dongu,
    odakDakika: toplam,
    gunlukDakika: gunluk,
    dersler: dersler,
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
