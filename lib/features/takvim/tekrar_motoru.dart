import 'package:app/core/tarih.dart';
import 'package:app/features/takvim/calisma.dart';

/// Onaylı tekrar tablosu: sınava kalan gün sayısı -> ilk çalışmadan kaç gün sonra tekrar.
/// Her konu için en fazla 4 kısa tekrar. Dayanak: Cepeda 2008, Kerfoot ve ark.
/// TUS'a özgü akademik veri yoktur; oranlar ara değerleme, kesin değer değildir.
const Map<int, List<int>> tekrarTablosu = {
  7: [1, 3, 4],
  14: [1, 4, 7, 9],
  30: [1, 7, 12, 16],
  60: [1, 8, 17, 25],
  120: [1, 8, 21, 33],
  180: [1, 8, 26, 43],
  300: [1, 8, 29, 53],
};

/// [kalanGun]: ilk çalışma gününden sınava kalan gün.
///
/// Tablodaki satırlar arasında kalan değerlerde (ör. 45 gün) kalan günden büyük
/// olmayan en yakın satır kullanılır (ör. 30). 300'ün üstü 300 satırını, 7'nin altı
/// 7 satırını kullanır. Tekrar en geç sınavdan bir gün önce olabilir; sığmayanlar atılır.
List<int> tekrarGunleri(int kalanGun) {
  if (kalanGun <= 1) return const [];
  int? anahtar;
  for (final k in tekrarTablosu.keys) {
    if (k <= kalanGun && (anahtar == null || k > anahtar)) anahtar = k;
  }
  final satir = tekrarTablosu[anahtar ?? 7]!;
  return [
    for (final g in satir)
      if (g <= kalanGun - 1) g,
  ];
}

/// Takvimde görünen tek bir tekrar.
class TekrarOgesi {
  const TekrarOgesi({
    required this.calismaId,
    required this.konuId,
    required this.no,
    required this.toplam,
    required this.tarih,
    required this.yapildi,
    required this.calismaTamam,
    required this.siradaki,
    this.yapilanTarih,
  });

  final int calismaId;
  final int konuId;

  /// Kaçıncı tekrar (1'den başlar) ve bu çalışma için toplam tekrar sayısı.
  final int no;
  final int toplam;

  /// Takvimde gösterilen gün (kayma ve günlük sınır uygulanmış).
  final DateTime tarih;

  final bool yapildi;

  /// Tekrarın bağlı olduğu çalışma "Çalıştım" işaretli mi?
  final bool calismaTamam;

  /// Bu çalışmanın yapılmamış ilk tekrarı mı?
  final bool siradaki;

  /// Yapıldıysa gerçekten yapıldığı gün.
  final DateTime? yapilanTarih;

  /// Şimdi "Tekrar yaptım" denebilir mi? (Çalışma bitmiş ve sıra bunda.)
  bool get eylemYapilabilir => calismaTamam && siradaki && !yapildi;
}

class _Ham {
  _Ham(this.calisma, this.no, this.toplam, this.ideal, this.kayit);

  final Calisma calisma;
  final int no;
  final int toplam;

  /// Kayma ve sınav sınırı uygulanmış ama günlük sınırdan önceki gün.
  final DateTime ideal;
  final TekrarKaydi? kayit;
  late DateTime gun;
}

/// Tüm çalışmaların tekrarlarını hesaplar. Saf fonksiyon: aynı girdi, aynı sonuç.
///
/// Kurallar (kullanıcı onaylı):
/// - Tekrar günleri, çalışma gününden sınava kalan güne göre [tekrarTablosu]'ndan gelir.
/// - Bir tekrar geç yapılırsa sonraki tekrarlar aynı gün sayısı kadar kayar (aralıklar korunur).
/// - Hiçbir tekrar sınavdan bir gün öncesinden sonraya taşmaz.
/// - Bir güne düşen bekleyen tekrar sayısı [gunlukSinir]'ı aşarsa fazlası ertesi güne kayar
///   (sınır 0 veya eksiyse sınırsız). Geçmişte kalmış (geciken) tekrarlar sınıra sayılmaz.
List<TekrarOgesi> tekrarlariHesapla({
  required List<Calisma> calismalar,
  required DateTime sinavTarihi,
  required DateTime bugun,
  required int gunlukSinir,
}) {
  final sinav = gunBasi(sinavTarihi);
  final sonGun = gunEkle(sinav, -1);
  final bugunGun = gunBasi(bugun);

  // 1) Her çalışma için ideal günleri bul (kayma ve sınav sınırıyla).
  final hamlar = <_Ham>[];
  for (final c in calismalar) {
    final gunler = tekrarGunleri(gunFarki(sinav, c.tarih));
    var kayma = 0;
    for (var i = 0; i < gunler.length; i++) {
      final no = i + 1;
      var ideal = gunEkle(c.tarih, gunler[i] + kayma);
      if (ideal.isAfter(sonGun)) ideal = sonGun;
      final kayit = c.tekrarKaydi(no);
      if (kayit != null) {
        final gec = gunFarki(kayit.tarih, ideal);
        if (gec > 0) kayma += gec;
      }
      hamlar.add(_Ham(c, no, gunler.length, ideal, kayit));
    }
  }

  // 2) Günlük sınırı uygula: erken tarihliden başlayarak yerleştir.
  final sirali = [...hamlar]..sort((a, b) {
      final k = a.ideal.compareTo(b.ideal);
      if (k != 0) return k;
      final c = a.calisma.id.compareTo(b.calisma.id);
      if (c != 0) return c;
      return a.no.compareTo(b.no);
    });
  final yuk = <int, int>{};
  final sonYerlesen = <int, DateTime>{};
  for (final h in sirali) {
    if (h.kayit != null || h.ideal.isBefore(bugunGun)) {
      // Yapılmış veya gecikmiş: yerinde kalır, sınıra sayılmaz.
      h.gun = h.ideal;
      if (h.kayit == null) sonYerlesen[h.calisma.id] = h.ideal;
      continue;
    }
    var gun = h.ideal;
    final onceki = sonYerlesen[h.calisma.id];
    if (onceki != null && !gun.isAfter(onceki)) gun = gunEkle(onceki, 1);
    if (gun.isAfter(sonGun)) gun = sonGun;
    if (gunlukSinir > 0) {
      while ((yuk[gunAnahtari(gun)] ?? 0) >= gunlukSinir &&
          gun.isBefore(sonGun)) {
        gun = gunEkle(gun, 1);
      }
    }
    yuk[gunAnahtari(gun)] = (yuk[gunAnahtari(gun)] ?? 0) + 1;
    sonYerlesen[h.calisma.id] = gun;
    h.gun = gun;
  }

  // 3) Her çalışmanın yapılmamış ilk tekrarını işaretle ve sonucu sırala.
  final ilkBekleyen = <int, int>{};
  for (final h in hamlar) {
    if (h.kayit != null) continue;
    final mevcut = ilkBekleyen[h.calisma.id];
    if (mevcut == null || h.no < mevcut) ilkBekleyen[h.calisma.id] = h.no;
  }
  final sonuc = [
    for (final h in hamlar)
      TekrarOgesi(
        calismaId: h.calisma.id,
        konuId: h.calisma.konuId,
        no: h.no,
        toplam: h.toplam,
        tarih: h.gun,
        yapildi: h.kayit != null,
        calismaTamam: h.calisma.tamam,
        siradaki: ilkBekleyen[h.calisma.id] == h.no,
        yapilanTarih: h.kayit?.tarih,
      ),
  ]..sort((a, b) {
      final k = a.tarih.compareTo(b.tarih);
      if (k != 0) return k;
      final c = a.calismaId.compareTo(b.calismaId);
      if (c != 0) return c;
      return a.no.compareTo(b.no);
    });
  return sonuc;
}
