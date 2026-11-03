library;

import 'dart:math' as math;
import 'package:app/core/tarih.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// Master Yönetim Kokpiti Haftalık 8+4 Bilişsel ve Sınav Göstergeleri
/// (Master Araştırma Raporu Bölüm 6.3).
class KokpitGostergeleri {
  const KokpitGostergeleri({
    required this.kalibrasyonFarki,
    required this.asiriGuvenVarMi,
    required this.uykuSuresiOrtalama,
    required this.sirkadiyenSapmaDakika,
    required this.uykuDuzenliMi,
    required this.sonKaygiPuani,
    required this.r1GecisOrani,
    required this.r3GecisOrani,
    required this.cTipiOkumaHatasiOrani,
    required this.ortalamaOdakPuani,
    required this.zorBilisselDakikaBugun,
    required this.zorBilisselTavanAsildi,
    required this.zorBilisselTavanYaklasti,
    required this.hataDagilimi,
    required this.enBuyukHataSinifi,
    required this.sonTemelNet,
    required this.sonKlinikNet,
    required this.sonToplamNet,
    required this.sonKlinikAgirlikliPuan,
    required this.tahminiEbapPuani,
    required this.denemeSayisi,
    required this.sonCeyrekHataOraniYuksek,
    required this.genelSaglikSkoru,
    required this.saglikDurumEtiketi,
    required this.saglikDurumRengi,
  });

  // --- 8 Bilişsel Gösterge ---
  /// 1. Kalibrasyon Farkı: Ortalama Güven - Doğruluk (hedef: mutlak değer <= %5).
  final double kalibrasyonFarki;

  /// 2. Aşırı Güven Alarmı: kalibrasyon farkı > +%8 ise tetiklenir.
  final bool asiriGuvenVarMi;

  /// 3. Uyku Süresi: Son 7 günün ortalama uyku süresi (hedef: 7-9 saat).
  final double uykuSuresiOrtalama;

  /// 4. Sirkadiyen Sapma: Hedef yatış saati ile gerçek saat arası ortalama sapma (hedef: <= 30 dk).
  final int sirkadiyenSapmaDakika;

  /// Uyku düzeni hedef bantta mı? (7-9 saat ve <= 30 dk sapma).
  final bool uykuDuzenliMi;

  /// 5. Test Kaygısı: Son denemenin sınav öncesi kaygı puanı (0-10 skala, hedef: <= 6).
  final int? sonKaygiPuani;

  /// 6. R1 Tekrar Geçiş Oranı: G+1 tekrarlarının zamanında yapılma oranı (hedef: >= %75).
  final double r1GecisOrani;

  /// 7. R3 Tekrar Geçiş Oranı: G+30 tekrarlarının zamanında yapılma oranı (hedef: >= %70).
  final double r3GecisOrani;

  /// 8. Prefrontal Korteks Okuma Hatası Oranı: C tipi hata yüzdesi (hedef: <%10-15).
  final double cTipiOkumaHatasiOrani;

  /// Bilişsel Odak Puanı: Son 7 günün çalışma bloklarında verilen odak ortalaması (1-5 skala).
  final double ortalamaOdakPuani;

  /// Bugünkü ağır analitik (zor bilişsel) çalışma süresi (dk).
  final int zorBilisselDakikaBugun;

  /// Bilişsel tavan aşıldı mı? (> 240 dk / 4 saat).
  final bool zorBilisselTavanAsildi;

  /// Bilişsel tavana yaklaşıldı mı? (>= 180 dk / 3 saat).
  final bool zorBilisselTavanYaklasti;

  /// A–F sınıflarına göre son denemedeki hata adetleri dağılımı.
  final Map<HataSinifi, int> hataDagilimi;

  /// En çok kayıp nete yol açan birincil hata sınıfı.
  final HataSinifi? enBuyukHataSinifi;

  // --- 4 Sınav & Net Göstergesi ---
  /// Son deneme Temel Bilimler (TTBT) neti (0-100).
  final double sonTemelNet;

  /// Son deneme Klinik Bilimler (KTBT) neti (0-100).
  final double sonKlinikNet;

  /// Son deneme toplam neti (0-200).
  final double sonToplamNet;

  /// Klinik Ağırlıklı K Puanı: 0.4 * TTBT + 0.6 * KTBT.
  final double sonKlinikAgirlikliPuan;

  /// ÖSYM 85 EBAP tavanlı tahmin puanı.
  final double tahminiEbapPuani;

  /// Kayıtlı toplam deneme sınavı adedi.
  final int denemeSayisi;

  /// Denemenin son çeyreğindeki (76-100. soru) hata sayısı ilk çeyreğin >= 1.5 katı mı?
  final bool sonCeyrekHataOraniYuksek;

  // --- Kompozit Bilişsel Sağlık Skoru ---
  /// 0-100 arası kompozit bilişsel performans ve zihinsel sağlık skoru.
  final int genelSaglikSkoru;

  /// Sağlık skoru metin etiketi (Örn: "Optimal Zirve (Türkiye 1.liği Hattı)").
  final String saglikDurumEtiketi;

  /// Durum rengi.
  final Color saglikDurumRengi;
}

/// [PlanDeposu] verilerinden haftalık 8+4 bilişsel ve sınav göstergelerini hesaplar.
KokpitGostergeleri kokpitGostergeleriHesapla(PlanDeposu depo, [DateTime? referansTarih]) {
  final bugun = gunBasi(referansTarih ?? DateTime.now());
  final denemeler = depo.denemeler;
  final uykular = depo.uykular;
  final odaklar = depo.odaklar;

  // 1. Deneme & Sınav Göstergeleri
  double temelNet = 0.0;
  double klinikNet = 0.0;
  double toplamNet = 0.0;
  double kPuani = 0.0;
  double ebapPuani = 45.0;
  double kalibrasyon = 0.0;
  int? kaygiPuani;
  var hataHaritasi = <HataSinifi, int>{for (final s in HataSinifi.values) s: 0};
  HataSinifi? enBuyukSinif;
  bool sonCeyrekYuksek = false;

  if (denemeler.isNotEmpty) {
    final son = denemeler.first;
    temelNet = son.temel.net;
    klinikNet = son.klinik.net;
    toplamNet = son.toplamNet;
    kPuani = son.klinikAgirlikliPuan;
    ebapPuani = son.tahminiEbapPuani;
    kalibrasyon = son.kalibrasyonFarki;
    kaygiPuani = son.kaygiPuani;
    hataHaritasi = son.hataDagilimi;

    // En büyük hata sınıfını bul
    var enCok = 0;
    for (final entry in hataHaritasi.entries) {
      if (entry.value > enCok) {
        enCok = entry.value;
        enBuyukSinif = entry.key;
      }
    }

    // Çeyrek dilim yorgunluk analizi (Soru 76-100 vs Soru 1-25)
    final ilkCeyrekHata = son.soruHatalari
        .where((s) => !s.dogruMu && s.soruNo <= 25)
        .length;
    final sonCeyrekHata = son.soruHatalari
        .where((s) => !s.dogruMu && s.soruNo > 75)
        .length;
    if (ilkCeyrekHata > 0 && sonCeyrekHata >= (ilkCeyrekHata * 1.5)) {
      sonCeyrekYuksek = true;
    }
  }

  final asiriGuven = kalibrasyon > 8.0;
  final cOrani = double.parse((depo.sonOkumaHatasiOrani * 100.0).toStringAsFixed(1));

  // 2. Uyku & Sirkadiyen Göstergeleri
  double ortUyku = 7.5; // Varsayılan sağlıklı değer
  int ortSapma = 15;
  bool uykuDuzenli = true;

  if (uykular.isNotEmpty) {
    final sonYedi = uykular.take(7).toList();
    final toplamSaat = sonYedi.fold<double>(0.0, (t, u) => t + u.sureSaat);
    ortUyku = double.parse((toplamSaat / sonYedi.length).toStringAsFixed(1));

    final toplamSapma = sonYedi.fold<int>(
      0,
      (t, u) => t + u.yatisSapmasiDakika(depo.hedefYatisSaati),
    );
    ortSapma = (toplamSapma / sonYedi.length).round();
    uykuDuzenli = (ortUyku >= 7.0 && ortUyku <= 9.0 && ortSapma <= 30);
  }

  // 3. Tekrar Geçiş Oranları (R1 & R3)
  final tumTekrarlar = depo.tekrarlar(bugun);
  final r1ler = tumTekrarlar.where(
    (t) => t.no == 1 && (t.yapildi || !t.tarih.isAfter(bugun)),
  );
  final r1Orani = r1ler.isEmpty
      ? 100.0
      : double.parse(
          ((r1ler.where((t) => t.yapildi).length / r1ler.length) * 100.0)
              .toStringAsFixed(1),
        );

  final r3ler = tumTekrarlar.where(
    (t) => t.no == 3 && (t.yapildi || !t.tarih.isAfter(bugun)),
  );
  final r3Orani = r3ler.isEmpty
      ? 100.0
      : double.parse(
          ((r3ler.where((t) => t.yapildi).length / r3ler.length) * 100.0)
              .toStringAsFixed(1),
        );

  // 4. Bilişsel Odak & Tavan
  double ortOdak = 4.2; // Varsayılan sağlıklı referans
  if (odaklar.isNotEmpty) {
    final esik = gunEkle(bugun, -7);
    final sonHafta = odaklar.where((o) => !o.tarih.isBefore(esik)).toList();
    if (sonHafta.isNotEmpty) {
      final toplamOdak = sonHafta.fold<int>(0, (t, o) => t + o.odakPuani);
      ortOdak = double.parse((toplamOdak / sonHafta.length).toStringAsFixed(1));
    }
  }

  final zorDk = depo.zorBilisselDakikaBugun(bugun);
  final tavanAsildi = depo.zorBilisselTavanAsildi;
  final tavanYaklasti = depo.zorBilisselYaklasti;

  // 5. Kompozit Bilişsel Sağlık Skoru Hesabı (0 - 100 Puan)
  var skor = 0;

  // Kalibrasyon (15 Puan)
  if (kalibrasyon.abs() <= 5.0) {
    skor += 15;
  } else if (kalibrasyon.abs() <= 8.0) {
    skor += 10;
  } else {
    skor += 5;
  }

  // Uyku Düzeni & Süresi (20 Puan)
  if (ortUyku >= 7.0 && ortUyku <= 9.0 && ortSapma <= 30) {
    skor += 20;
  } else if (ortUyku >= 6.5 && ortSapma <= 45) {
    skor += 13;
  } else {
    skor += 6;
  }

  // PFC / C Tipi Okuma Hatası (20 Puan)
  if (cOrani <= 10.0) {
    skor += 20;
  } else if (cOrani <= 15.0) {
    skor += 13;
  } else {
    skor += 5;
  }

  // R1 Tekrar Tamamlama (20 Puan)
  if (r1Orani >= 75.0) {
    skor += 20;
  } else if (r1Orani >= 60.0) {
    skor += 12;
  } else {
    skor += 6;
  }

  // Odak Kalitesi (15 Puan)
  if (ortOdak >= 4.0 && !tavanAsildi) {
    skor += 15;
  } else if (ortOdak >= 3.0) {
    skor += 10;
  } else {
    skor += 5;
  }

  // Kaygı Düzeyi (10 Puan)
  if (kaygiPuani == null || kaygiPuani <= 6) {
    skor += 10;
  } else if (kaygiPuani <= 8) {
    skor += 6;
  } else {
    skor += 2;
  }

  // Sınırla
  skor = math.max(0, math.min(100, skor));

  final String etiket;
  final Color renk;
  if (skor >= 85) {
    etiket = 'Optimal Zirve (Türkiye 1.liği Hattı)';
    renk = Colors.green;
  } else if (skor >= 70) {
    etiket = 'Dengeli Bilişsel Performans';
    renk = Colors.teal;
  } else if (skor >= 50) {
    etiket = 'Dengeleme & Ayar Gerekli';
    renk = Colors.orange;
  } else {
    etiket = 'PFC Yorgunluğu / Kurtarma Modu Gerekli';
    renk = Colors.red;
  }

  return KokpitGostergeleri(
    kalibrasyonFarki: kalibrasyon,
    asiriGuvenVarMi: asiriGuven,
    uykuSuresiOrtalama: ortUyku,
    sirkadiyenSapmaDakika: ortSapma,
    uykuDuzenliMi: uykuDuzenli,
    sonKaygiPuani: kaygiPuani,
    r1GecisOrani: r1Orani,
    r3GecisOrani: r3Orani,
    cTipiOkumaHatasiOrani: cOrani,
    ortalamaOdakPuani: ortOdak,
    zorBilisselDakikaBugun: zorDk,
    zorBilisselTavanAsildi: tavanAsildi,
    zorBilisselTavanYaklasti: tavanYaklasti,
    hataDagilimi: hataHaritasi,
    enBuyukHataSinifi: enBuyukSinif,
    sonTemelNet: temelNet,
    sonKlinikNet: klinikNet,
    sonToplamNet: toplamNet,
    sonKlinikAgirlikliPuan: kPuani,
    tahminiEbapPuani: ebapPuani,
    denemeSayisi: denemeler.length,
    sonCeyrekHataOraniYuksek: sonCeyrekYuksek,
    genelSaglikSkoru: skor,
    saglikDurumEtiketi: etiket,
    saglikDurumRengi: renk,
  );
}
