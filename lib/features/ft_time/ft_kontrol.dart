import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/ft_time/ft_native.dart';
import 'package:app/features/ft_time/ft_oturum.dart';
import 'package:app/features/ft_time/ft_timer.dart';

/// Oturum bittiğinde ekrana gösterilecek özet.
class FtOzet {
  const FtOzet({
    required this.tamamlananDongu,
    required this.puan,
    this.konuId,
  });

  final int tamamlananDongu;
  final int puan;
  final int? konuId;
}

/// F.T. time oturumunu yönetir: önce depoyu (ekran hemen güncellensin), sonra
/// Android alarmını/bildirimini günceller.
class FtKontrol {
  FtKontrol(this.depo, [this.native = const FtNative()]);

  final PlanDeposu depo;
  final FtNative native;

  int _simdi() => DateTime.now().millisecondsSinceEpoch;

  /// Yeni oturum açar ve ilk çalışma bölümünü başlatır.
  Future<void> baslat({required int toplamDongu, int? konuId}) async {
    final o = depo.oturumBaslat(toplamDongu: toplamDongu, konuId: konuId);
    await _bolumuBaslat(o, bildirimIzniIste: true);
  }

  Future<void> _bolumuBaslat(FtOturum o, {bool bildirimIzniIste = false}) async {
    final yeni = o.baslat(_simdi());
    depo.oturumGuncelle(yeni);
    final bitis = yeni.sayac.endAtMs;
    if (yeni.sayac.phase != FtPhase.calisiyor || bitis == null) return;
    if (bildirimIzniIste && await native.bildirimAcik() == false) {
      await native.bildirimIzniIste();
    }
    await native.alarmKur(bitis);
  }

  Future<void> duraklat() async {
    final o = depo.oturum;
    if (o == null) return;
    depo.oturumGuncelle(o.duraklat(_simdi()));
    await native.alarmIptal();
  }

  /// Duraklatılmış ya da hazır bölümü başlatır.
  Future<void> devam() async {
    final o = depo.oturum;
    if (o == null) return;
    await _bolumuBaslat(o);
  }

  /// Biten bölümden sonrakine geçer ve başlatır (mola ya da sonraki çalışma).
  Future<void> ilerle() async {
    final o = depo.oturum;
    final sonraki = o?.ilerle();
    if (sonraki == null) return;
    await native.bitenBildirimiKaldir();
    await _bolumuBaslat(sonraki);
  }

  /// Molayı atlayıp sonraki çalışmayı başlatır.
  Future<void> molayiAtla() async {
    final o = depo.oturum;
    final sonraki = o?.molayiAtla();
    if (sonraki == null) return;
    await native.alarmIptal();
    await _bolumuBaslat(sonraki);
  }

  /// Oturumun şu anki özeti (süresi dolmuş bölüm varsa önce işlenir). Oturum yoksa null.
  FtOzet? ozet() {
    if (depo.oturum == null) return null;
    // Süre dolmuş ama henüz işlenmemişse önce onu işle (puan kaybolmasın).
    depo.oturumuTazele(_simdi());
    final o = depo.oturum;
    if (o == null) return null;
    return FtOzet(
      tamamlananDongu: o.tamamlananDongu,
      puan: o.kazanilanDakika,
      konuId: o.konuId,
    );
  }

  /// Oturumu kapatır ve özetini döndürür. Biten döngülerin puanı zaten kayıtlıdır;
  /// yarım döngü puan getirmez.
  Future<FtOzet?> bitir() async {
    final ozet = this.ozet();
    if (ozet == null) return null;
    depo.oturumKapat();
    await native.alarmIptal();
    await native.bitenBildirimiKaldir();
    return ozet;
  }

  /// Süresi dolan bölümü işler (puanlar) ve "çalışıyor" bildirimini kaldırır.
  Future<void> tazele() async {
    if (depo.oturumuTazele(_simdi())) {
      await native.calisanBildirimiKaldir();
    }
  }
}
