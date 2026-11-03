library;

import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/kokpit/modeller.dart';
import 'package:flutter/material.dart';

/// Kuralın aday üzerindeki aciliyet ve etki seviyesi.
enum OncelikSeviyesi {
  /// Acil müdahale gerektirir (Kırmızı). Örn: PFC tükenmesi veya Aşırı Güven alarmı.
  kritik('Kritik', Colors.red, Icons.error_outline),

  /// Dengeleme önerisi (Turuncu/Sarı). Örn: Uyku sapması veya R1 geçiş düşüşü.
  uyari('Uyarı', Colors.orange, Icons.warning_amber_rounded),

  /// Net artırıcı stratejik optimizasyon (Mavi). Örn: Beklenen Değer (EV) kuralı.
  optimizasyon('Strateji', Colors.blue, Icons.lightbulb_outline),

  /// Hedef referans aralığında başarı durumu (Yeşil).
  basarili('Başarılı', Colors.green, Icons.check_circle_outline);

  const OncelikSeviyesi(this.ad, this.renk, this.ikon);

  final String ad;
  final Color renk;
  final IconData ikon;
}

/// Kokpit eylem butonu basıldığında yürütülecek aksiyon türü.
enum KokpitEylemTuru {
  kurtarmaModu,
  celdiriciBankasi,
  panikProtokolu,
  sinavProvasi,
  tekrarPlani,
  uykuYonetimi,
  beklenenDeger,
  bilisselYonetim,
}

/// Otomatik "Eğer–O Zaman" Karar Kuralı (Master Araştırma Raporu Bölüm 6.4).
class KokpitKurali {
  const KokpitKurali({
    required this.id,
    required this.baslik,
    required this.oncelik,
    required this.eger,
    required this.oZaman,
    this.eylemEtiketi,
    this.eylemTuru,
    this.tetiklendi = true,
  });

  final String id;
  final String baslik;
  final OncelikSeviyesi oncelik;
  final String eger;
  final String oZaman;
  final String? eylemEtiketi;
  final KokpitEylemTuru? eylemTuru;
  final bool tetiklendi;
}

/// Mevcut bilişsel göstergeleri ve depo durumunu tarayarak otomatik
/// "Eğer–O Zaman" strateji ve eylem kurallarını üretir.
List<KokpitKurali> stratejiAnaliziYap(KokpitGostergeleri g, PlanDeposu depo) {
  final kurallar = <KokpitKurali>[];

  // 1. KURAL: PFC Tükenmesi & C Tipi Okuma Hatası (Rapor Bölüm 1.6 & 6.4)
  if (depo.kurtarmaModuAktif) {
    kurallar.add(
      const KokpitKurali(
        id: 'pfc_kurtarma_aktif',
        baslik: '%70 Kurtarma Modu Devrede',
        oncelik: OncelikSeviyesi.uyari,
        eger: 'Prefrontal korteks aşırı yükünü hafifletmek için %70 Kurtarma Modu açık.',
        oZaman: 'Bugün yeni konu açılmaz; sadece R1–R2 tekrarları yapılır ve uyku penceresi korunur.',
        eylemEtiketi: 'Kurtarma Modunu Kapat',
        eylemTuru: KokpitEylemTuru.kurtarmaModu,
      ),
    );
  } else if (g.cTipiOkumaHatasiOrani > 15.0) {
    kurallar.add(
      KokpitKurali(
        id: 'pfc_c_hatasi_alarm',
        baslik: 'PFC Aşırı Yükü (Okuma Hatası > %15)',
        oncelik: OncelikSeviyesi.kritik,
        eger: 'Son denemelerde C tipi (okuma/kurgu/dikkat) hata oranı %${g.cTipiOkumaHatasiOrani.toStringAsFixed(1)} (Eşik: %15). Prefrontal korteks karar yorgunluğu altında.',
        oZaman: 'Günün çalışma yükünü hemen %70\'e indir; yeni konuyu ertele, yalnızca R1–R2 tekrarlarını koru; uyku ve mola sürelerini artır.',
        eylemEtiketi: '%70 Kurtarma Modunu Aç',
        eylemTuru: KokpitEylemTuru.kurtarmaModu,
      ),
    );
  }

  // 2. KURAL: Aşırı Güven Alarmı (Kalibrasyon Farkı > +%8) (Rapor Bölüm 4.2 & 6.4)
  if (g.asiriGuvenVarMi) {
    kurallar.add(
      KokpitKurali(
        id: 'asiri_guven_alarm',
        baslik: 'Aşırı Güven Uyarısı (Kalibrasyon > +%8)',
        oncelik: OncelikSeviyesi.kritik,
        eger: 'Kalibrasyon farkı +%${g.kalibrasyonFarki.toStringAsFixed(1)} (Hedef: ±%5). '
            'Tahmin edilen özgüven, gerçek doğruluk oranının belirgin şekilde üzerinde.',
        oZaman: 'Soruyu "Emin" işaretlemeden önce 10 saniye durup "tersini düşün". '
            '"Emin + Yanlış" (B sınıfı) soruları aynı gün Çeldirici Defteri\'ne işle; tanıdık sorularda kök kelimeleri iki kez çiz.',
        eylemEtiketi: 'Çeldirici Bankası\'nı Aç',
        eylemTuru: KokpitEylemTuru.celdiriciBankasi,
      ),
    );
  }

  // 3. KURAL: Zaman / Karar Yorgunluğu Kırılması (Son Çeyrek Hata Yığılması) (Rapor Bölüm 5.1 & 6.4)
  if (g.sonCeyrekHataOraniYuksek) {
    kurallar.add(
      const KokpitKurali(
        id: 'son_ceyrek_yorgunluk',
        baslik: 'Yorgunluk Eşiği Aşıldı (Son Çeyrek Hatası > 1.5x)',
        oncelik: OncelikSeviyesi.uyari,
        eger: 'Denemenin son 25 sorusundaki hata adedi ilk 25 sorunun 1.5 katını aştı. '
            'Sınavın son bölümünde bilişsel tükenme ve tempo kaybı yaşanıyor.',
        oZaman: '135 dakikalık sınav provası simülatörüyle tempo çalış; 25, 50 ve 75. sorularda '
            '30 saniyelik mikro-sıfırlama nefes molası ver ve iki oturum arası 135 dk protokolünü uygula.',
        eylemEtiketi: 'Sınav Provası Başlat',
        eylemTuru: KokpitEylemTuru.sinavProvasi,
      ),
    );
  }

  // 4. KURAL: Test Kaygısı ve Sempatik Aşırı Uyarılma (Kaygı ≥ 7) (Rapor Bölüm 5.2 & 6.4)
  if (g.sonKaygiPuani != null && g.sonKaygiPuani! >= 7) {
    kurallar.add(
      KokpitKurali(
        id: 'kaygi_uyarisi',
        baslik: 'Yüksek Test Kaygısı (${g.sonKaygiPuani}/10)',
        oncelik: OncelikSeviyesi.uyari,
        eger: 'Sınav öncesi kaygı düzeyi ${g.sonKaygiPuani}/10 olarak kaydedildi (Hedef: <= 6). '
            'Sempatik aşırı uyarılma prefrontal korteks fonksiyonunu baskılayabilir.',
        oZaman: '90 saniyelik Panik Protokolü & Döngüsel İç Çekme (Cyclic Sighing) ile Jamieson '
            'uyarılmayı yeniden değerlendirme kartını ("Bu uyarılma göreve hazırlandığımı gösteriyor") günde 5 dk prova yap.',
        eylemEtiketi: '90 sn Nefes Protokolü',
        eylemTuru: KokpitEylemTuru.panikProtokolu,
      ),
    );
  }

  // 5. KURAL: Aralıklı Tekrar Zinciri Zayıflaması (R1 < %75) (Rapor Bölüm 1.2 & 6.4)
  if (g.r1GecisOrani < 75.0) {
    kurallar.add(
      KokpitKurali(
        id: 'r1_gecis_dusuk',
        baslik: 'R1 Konsolidasyon Düşüşü (%${g.r1GecisOrani.toStringAsFixed(0)})',
        oncelik: OncelikSeviyesi.uyari,
        eger: 'R1 (G+1) tekrar tamamlama oranı %${g.r1GecisOrani.toStringAsFixed(0)} (Hedef: >= %75). '
            'Erken LTP basamağındaki izler kalıcı belleğe aktarılamadan siliniyor.',
        oZaman: 'Yeni konu hacmini %20 kıs; geciken tekrarları bugüne al ve zorlandığın konuları '
            'Hata Defteri\'nde Sıcak Liste\'ye ekle.',
        eylemEtiketi: 'Tekrar Planına Git',
        eylemTuru: KokpitEylemTuru.tekrarPlani,
      ),
    );
  }

  // 6. KURAL: Sirkadiyen Biyolojik Sapma (> 30 dk veya Uyku < 7 sa) (Rapor Bölüm 1.3 & 6.4)
  if (depo.uykular.isNotEmpty && !g.uykuDuzenliMi) {
    kurallar.add(
      KokpitKurali(
        id: 'uyku_sirkadiyen_sapma',
        baslik: 'Sirkadiyen Biyolojik Saat Sapması',
        oncelik: OncelikSeviyesi.uyari,
        eger: 'Ortalama uyku süresi ${g.uykuSuresiOrtalama.toStringAsFixed(1)} saat ve yatış sapması ±${g.sirkadiyenSapmaDakika} dk (Hedef: 7–9 sa, ±30 dk).',
        oZaman: 'Yavaş dalga uykusu (SWS) sinaptik budama için zorunludur. Hafta sonu dahil yatış saatini sabitle; '
            'kafeini yatıştan en az 8 saat önce kes ve gece ekran ışığını kapat.',
        eylemEtiketi: 'Bilişsel & Uyku Yönetimi',
        eylemTuru: KokpitEylemTuru.uykuYonetimi,
      ),
    );
  }

  // 7. KURAL: Ağır Analitik Bilişsel Tavan Aşıldı (> 240 dk) (Rapor Bölüm 1.1)
  if (g.zorBilisselTavanAsildi) {
    kurallar.add(
      KokpitKurali(
        id: 'zor_bilissel_tavan',
        baslik: 'Ağır Analitik Bilişsel Tavan Doldu (4 Saat)',
        oncelik: OncelikSeviyesi.uyari,
        eger: 'Bugünkü zor bilişsel iş süresi ${g.zorBilisselDakikaBugun} dk oldu (Günlük kanıtlı tavan: 240 dk).',
        oZaman: 'Prefrontal korteks kapasitesi doldu. Bu saatten sonra yeni konu veya ağır deneme analizi yapma; '
            'kalan çalışma süresini kart kuyruğu, tablo turu veya hafif soruya ayır.',
        eylemEtiketi: 'Bilişsel Takip',
        eylemTuru: KokpitEylemTuru.bilisselYonetim,
      ),
    );
  }

  // 8. KURAL: Beklenen Değer (EV) & İkilem Disiplini (Rapor Bölüm 5.3)
  kurallar.add(
    const KokpitKurali(
      id: 'beklenen_deger_disiplini',
      baslik: 'İkilem & Beklenen Değer (EV) Disiplini',
      oncelik: OncelikSeviyesi.optimizasyon,
      eger: '2 şıkkı elediğinde veya iki seçenek arasında kaldığında tereddüt edip boş bırakıyorsan.',
      oZaman: '2 şık güvenle elendiğinde kalan 3 seçenekten birini işaretlemek istatistiksel olarak '
          '+0.167 net kazandırır. Boş bırakmak net kaybıdır! "Kararsız" işaretli soruları ancak somut '
          'yeni gerekçe bulduysan değiştir, kaygıyla asla dokunma.',
      eylemEtiketi: 'Beklenen Değer Kartı',
      eylemTuru: KokpitEylemTuru.beklenenDeger,
    ),
  );

  // 9. KURAL: Optimal Zirve Durumu (Tüm Göstergeler Yeşil)
  final kritikVeyaUyariVarMi = kurallar.any(
    (k) =>
        k.oncelik == OncelikSeviyesi.kritik ||
        (k.oncelik == OncelikSeviyesi.uyari && k.id != 'pfc_kurtarma_aktif'),
  );

  if (!kritikVeyaUyariVarMi) {
    kurallar.insert(
      0,
      const KokpitKurali(
        id: 'optimal_zirve',
        baslik: 'Optimal Zirve (Türkiye 1.liği Hattı)',
        oncelik: OncelikSeviyesi.basarili,
        eger: 'Tüm nörobiyolojik, sirkadiyen uyku, tekrar ve kalibrasyon göstergelerin hedef referans bandında.',
        oZaman: 'Harika gidiyorsun! Bu bilişsel ritmi, R0 akşam tekrarlarını ve uyku saati penceresini tavizsiz sürdür.',
      ),
    );
  }

  return kurallar;
}
