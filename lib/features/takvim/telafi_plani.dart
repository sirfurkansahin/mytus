import 'package:app/core/tarih.dart';
import 'package:app/features/takvim/calisma.dart';
import 'package:app/features/takvim/tekrar_motoru.dart';

/// Nöbet sonrası "Telafi Planı": biriken (geciken) işleri günlük sınırları aşmadan
/// önümüzdeki günlere yayar. Saf hesap; veriyi değiştirmez, [uygula] ile uygulanır.
///
/// - Geciken konular (yapılmamış çalışmalar): bugünden başlayarak, günlük yeni konu
///   sınırı dolmayan ilk güne sırayla yerleştirilir.
/// - Geciken tekrarlar: "yapıldı" SAYILMAZ; bugüne ertelenir. Tekrar motorunun günlük
///   tekrar sınırı fazlasını kendiliğinden sonraki günlere taşır. Erteleme, gecikme
///   kayması gibi o çalışmanın sonraki tekrarlarını da aynı gün kadar kaydırır.
class TelafiPlani {
  const TelafiPlani({
    this.yeniGunler = const {},
    this.ekErtelemeler = const {},
    this.tekrarGunleri = const [],
  });

  /// Geciken çalışmalar: çalışma no -> yeni gün.
  final Map<int, DateTime> yeniGunler;

  /// Geciken tekrarlar: çalışma no -> (tekrar no, eklenecek gün).
  final Map<int, ({int no, int gun})> ekErtelemeler;

  /// Taşınan tekrarların plan sonrası günleri (önizleme için).
  final List<DateTime> tekrarGunleri;

  int get calismaSayisi => yeniGunler.length;
  int get tekrarSayisi => ekErtelemeler.length;
  bool get bos => calismaSayisi == 0 && tekrarSayisi == 0;

  /// Planın kaç farklı güne yayıldığı.
  int get gunSayisi => {
        for (final g in yeniGunler.values) gunAnahtari(g),
        for (final g in tekrarGunleri) gunAnahtari(g),
      }.length;

  /// Plandaki en geç gün.
  DateTime? get sonGun {
    DateTime? en;
    for (final g in [...yeniGunler.values, ...tekrarGunleri]) {
      if (en == null || g.isAfter(en)) en = g;
    }
    return en;
  }

  /// Planı çalışma listesine uygular (yeni liste döner).
  List<Calisma> uygula(List<Calisma> calismalar) => [
        for (final c in calismalar)
          _uygulaTek(c),
      ];

  Calisma _uygulaTek(Calisma c) {
    var sonuc = c;
    final gun = yeniGunler[c.id];
    if (gun != null) sonuc = sonuc.kopya(tarih: gun);
    final ek = ekErtelemeler[c.id];
    if (ek != null) sonuc = sonuc.ertelemeEkle(ek.no, ek.gun);
    return sonuc;
  }
}

/// Telafi planını hesaplar.
///
/// [sonGun]: en geç yerleştirme günü (sınavdan bir gün önce). Sığmayanlar bu güne yığılır.
/// [gunlukYeniKonuSiniri] veya [gunlukTekrarSiniri] 0 ya da eksiyse sınırsız sayılır.
TelafiPlani telafiPlaniHesapla({
  required List<Calisma> calismalar,
  required DateTime bugun,
  required DateTime sonGun,
  DateTime? sinavTarihi,
  required int gunlukYeniKonuSiniri,
  required int gunlukTekrarSiniri,
}) {
  final g = gunBasi(bugun);
  final son = sonGun.isBefore(g) ? g : gunBasi(sonGun);

  // 1) Geciken konular.
  final geciken = [
    for (final c in calismalar)
      if (!c.tamam && c.tarih.isBefore(g)) c,
  ]..sort((a, b) {
      final k = a.tarih.compareTo(b.tarih);
      return k != 0 ? k : a.id.compareTo(b.id);
    });
  final gecikenIdler = {for (final c in geciken) c.id};
  final yuk = <int, int>{};
  for (final c in calismalar) {
    if (gecikenIdler.contains(c.id)) continue;
    yuk[gunAnahtari(c.tarih)] = (yuk[gunAnahtari(c.tarih)] ?? 0) + 1;
  }
  final yeniGunler = <int, DateTime>{};
  var gun = g;
  for (final c in geciken) {
    if (gunlukYeniKonuSiniri > 0) {
      while ((yuk[gunAnahtari(gun)] ?? 0) >= gunlukYeniKonuSiniri &&
          gun.isBefore(son)) {
        gun = gunEkle(gun, 1);
      }
    }
    yeniGunler[c.id] = gun;
    yuk[gunAnahtari(gun)] = (yuk[gunAnahtari(gun)] ?? 0) + 1;
  }

  // 2) Geciken tekrarlar (sınav tarihi yoksa tekrar da yok).
  if (sinavTarihi == null) return TelafiPlani(yeniGunler: yeniGunler);
  final ekErtelemeler = <int, ({int no, int gun})>{};
  final once = tekrarlariHesapla(
    calismalar: calismalar,
    sinavTarihi: sinavTarihi,
    bugun: g,
    gunlukSinir: gunlukTekrarSiniri,
  );
  for (final t in once) {
    if (!t.eylemYapilabilir || !t.tarih.isBefore(g)) continue;
    final fark = gunFarki(g, t.idealTarih);
    if (fark > 0) ekErtelemeler[t.calismaId] = (no: t.no, gun: fark);
  }

  // 3) Önizleme: plan uygulanınca taşınan tekrarlar hangi günlere düşüyor?
  final taslak = TelafiPlani(
    yeniGunler: yeniGunler,
    ekErtelemeler: ekErtelemeler,
  );
  final sonra = tekrarlariHesapla(
    calismalar: taslak.uygula(calismalar),
    sinavTarihi: sinavTarihi,
    bugun: g,
    gunlukSinir: gunlukTekrarSiniri,
  );
  final tekrarGunleri = [
    for (final t in sonra)
      if (ekErtelemeler[t.calismaId]?.no == t.no) t.tarih,
  ];
  return TelafiPlani(
    yeniGunler: yeniGunler,
    ekErtelemeler: ekErtelemeler,
    tekrarGunleri: tekrarGunleri,
  );
}
