library;

import 'package:app/features/rehber/tanitim_turu_ekrani.dart';
import 'package:flutter/material.dart';

/// MY TUS Kullanım Rehberi ve Sıkça Sorulan Sorular (SSS) Ekranı.
/// Adayın tüm modülleri, kuralları ve bilimsel arka planı sade dille öğrenmesini sağlar.
class RehberEkrani extends StatelessWidget {
  const RehberEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanım Rehberi & SSS'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // 1. Üst Kart: Görsel Tanıtım Turu Kısayolu
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: tema.colorScheme.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            color: tema.colorScheme.primary.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.slideshow_rounded, color: tema.colorScheme.primary, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '1 Dakikalık Görsel Tanıtım Turu',
                          style: tema.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: tema.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Uygulamanın mantığını, tekrar motorunu ve sınav araçlarını 5 tematik slayt ile adım adım keşfedin.',
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const TanitimTuruEkrani()),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'Tanıtım Turunu Başlat (5 Slayt)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'SIKÇA SORULAN SORULAR & MODÜL REHBERİ',
            style: tema.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: tema.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),

          // Bölüm 1: Hızlı Başlangıç & Günlük Kullanım
          _KategoriBasligi(
            ikon: Icons.home_outlined,
            baslik: '1. Hızlı Başlangıç & Günlük Kullanım',
            renk: Colors.purple,
          ),
          _SoruCevapKart(
            soru: 'İlk gün nereden başlamalıyım?',
            cevap: '1. "Dersler" sekmesine gidin, çalışmak istediğiniz konuyu bulun.\n'
                '2. Konunun içine girip "Takvime ekle" diyerek istediğiniz güne planlayın.\n'
                '3. "F.T. time" sekmesine geçip 25 dk veya 50 dk sürenizi başlatarak odaklanın.\n'
                '4. Çalışmanız bitince "Bugün" ekranında o konunun yanındaki "Çalıştım" butonuna dokunun.',
          ),
          _SoruCevapKart(
            soru: 'R0 Akşam Tekrarı (Beyaz Sayfa) nedir?',
            cevap: 'Günün en son çalışma bloğudur (15-20 dk). O gün çalıştığınız konuları '
                'kitaba bakmadan, boş bir beyaz kağıda zihninizden ana hatlarıyla dökme ritüelidir. '
                'Bilimsel kanıtlar, uykudan hemen önce yapılan bu kısa geri çağırmanın '
                'gece yavaş dalga uykusunda kalıcı bellek aktarımını (sistem konsolidasyonu) '
                'en üst düzeye çıkardığını gösterir.',
          ),
          _SoruCevapKart(
            soru: 'Geciken görevleri nasıl düzenlerim?',
            cevap: 'Geçmiş günlerde tamamlanmayan çalışmalar ve vadesi gelen tekrarlar '
                'Bugün ekranında "Geciken" başlığı altında toplanır. "Tümünü bugüne al" butonuna '
                'dokunarak tüm bekleyen işlerinizi bugünün planına taşıyabilirsiniz.',
          ),
          const SizedBox(height: 14),

          // Bölüm 2: Akıllı Tekrar Sistemi (R0–R4)
          _KategoriBasligi(
            ikon: Icons.event_repeat,
            baslik: '2. Akıllı Tekrar Motoru (R1–R4)',
            renk: Colors.indigo,
          ),
          _SoruCevapKart(
            soru: 'R1, R2, R3, R4 kodları ne anlama gelir?',
            cevap: 'Aralıklı tekrar aşamalarıdır:\n'
                '• R1 (G+1): İlk çalışmanın ertesi günü (erken LTP konsolidasyonu).\n'
                '• R2 (G+7): 1 hafta sonra yapılan pekiştirme.\n'
                '• R3 (G+30): 1 ay sonra yapılan kalıcı bellek aktarımı.\n'
                '• R4 (G+60/90): Faz sonu büyük entegrasyon tekrarı.\n'
                'Sınava az gün kaldığında sistem aralıkları otomatik olarak daraltır (Cepeda eğrisi).',
          ),
          _SoruCevapKart(
            soru: 'Tekrarı geciktirirsem zincir bozulur mu?',
            cevap: 'Hayır, asla bozulmaz! MY TUS "Gecikme Kayması" kuralıyla çalışır. '
                'Örneğin 1. tekrarı 2 gün geç yaparsanız, 2. ve 3. tekrarlar da otomatik olarak '
                '2 gün ileri kayar. Böylece tekrarlar birbirine yığılmaz ve aralık disiplini korunur.',
          ),
          _SoruCevapKart(
            soru: 'Günlük 10 tekrar sınırı nedir?',
            cevap: 'Beynin aşırı yüklenmesini önlemek için bir güne en fazla 10 tekrar atanır. '
                'O güne düşen 11. ve sonraki tekrarlar otomatik olarak ertesi güne ötelenir. '
                'Bu sınırı Ayarlar ekranından 3 ila 30 arasında değiştirebilirsiniz.',
          ),
          const SizedBox(height: 14),

          // Bölüm 3: F.T. Time & Nörobiyoloji
          _KategoriBasligi(
            ikon: Icons.psychology_outlined,
            baslik: '3. F.T. Time & Nörobiyolojik Performans',
            renk: Colors.teal,
          ),
          _SoruCevapKart(
            soru: 'Klasik (25 dk) mi yoksa Derin Blok (50 dk) mu seçmeliyim?',
            cevap: '• Derin Blok (50 dk çalışma, 10 dk mola): Mekanizma zincirleri, ağır '
                'patofizyoloji veya yeni klinik konular için tavsiye edilir.\n'
                '• Klasik (25 dk çalışma, 5 dk mola): Hızlı soru çözümü, tablo turu veya '
                'kart tekrarları için idealdir.\n'
                'Her iki hazır ayarı da F.T. time ekranından tek dokunuşla seçebilirsiniz.',
          ),
          _SoruCevapKart(
            soru: 'Ağır Analitik Bilişsel Tavan (3–4 Saat) kuralı nedir?',
            cevap: 'Bilişsel psikoloji araştırmaları (Ericsson ve Newport kanıtları), '
                'insan beyninin günde en fazla 3–4 saat (180–240 dk) yüksek odaklı "zor bilişsel iş" '
                '(yeni konu, hata analizi, deneme) yapabildiğini doğrular. 4 saatten sonra zor iş '
                'yapmak net kazandırmaz, yorar. Kalan çalışma sürenizi hafif işlere '
                '(kart kuyruğu, tablo tekrarı, video izleme) ayırmalısınız.',
          ),
          _SoruCevapKart(
            soru: 'Kafein kesilme saati neden yatıştan 8 saat önce?',
            cevap: 'Kafeinin vücuttaki yarılanma ömrü ortalama 5–8 saattir. Yatmadan önce '
                'alınan kafein uykuya dalsanız bile hipokampal bellek pekiştirmesi için '
                'hayati olan "yavaş dalga uykusu (SWS)" mimarisini bozar. Sistem hedef yatış '
                'saatinizden 8 saat önce otomatik kafein kesilme uyarısı üretir.',
          ),
          _SoruCevapKart(
            soru: '%70 Kurtarma Modu ne işe yarar?',
            cevap: 'Son denemelerinizde C tipi (okuma/dikkat) hataları %15\'i aştığında '
                'prefrontal korteks aşırı yorgun demektir. %70 Kurtarma Modu açıldığında '
                'o gün yeni konu eklenmez, çalışma yükü %70\'e çekilir ve yalnızca R1–R2 '
                'tekrarları yapılır.',
          ),
          const SizedBox(height: 14),

          // Bölüm 4: Denemeler & Özel Defterler
          _KategoriBasligi(
            ikon: Icons.rule_folder_outlined,
            baslik: '4. Deneme Analizi & Özel Defterler',
            renk: Colors.deepOrange,
          ),
          _SoruCevapKart(
            soru: 'A–F Hata Sınıfları neyi ifade eder?',
            cevap: '• A: Bilgi Kusuru (Bilmiyordum)\n'
                '• B: Yanlış İnanç (Emin işaretleyip yanlış çıkan - en tehlikeli, aynı gün düzeltilmeli)\n'
                '• C: Okuma / Kurgu Hatası (Kökü, sıfatı veya soruyu yanlış okuma)\n'
                '• D: Mantık / Halka Hatası (İki şık arasında kalıp yanlış halkayı seçme)\n'
                '• E: Süre / Yorgunluk Hatası (Son sorularda dikkatin dağılması)\n'
                '• F: Form / Dikkat Hatası (Kaydırma veya işaretleme hatası)',
          ),
          _SoruCevapKart(
            soru: 'Hata Defteri & Çeldirici Bankası nasıl doldurulmalı?',
            cevap: 'Her hata için 3 zorunlu altın alan doldurulur:\n'
                '1. Karışan Çeldirici (Hangi şıkla karıştı?)\n'
                '2. Ayıran Tek Kriter (İki şıkkı birbirinden ayıran somut fark nedir?)\n'
                '3. Kendi Kuralım (Gelecekte benzer soruda neye dikkat edeceğim?)',
          ),
          _SoruCevapKart(
            soru: 'Skor Defteri ve Mekanizma Zincirleri nedir?',
            cevap: '• Skor Defteri: Hinchey, Wells, CURB-65, Ranson gibi ezberlenmesi gereken '
                '10+ hazır TUS skoru ve sizin ekleyeceğiniz özel skorlardır.\n'
                '• Mekanizma Zincirleri (Illness Script): 6 branş için 5 halkalı nedensellik '
                'şablonudur (Etiyoloji ➔ Patofizyoloji ➔ Klinik ➔ Tanı ➔ Tedavi).',
          ),
          const SizedBox(height: 14),

          // Bölüm 5: Sınav Anı, Panik & Taktikler
          _KategoriBasligi(
            ikon: Icons.speed,
            baslik: '5. Sınav Anı, Panik ve Stratejiler',
            renk: Colors.blue,
          ),
          _SoruCevapKart(
            soru: '90 sn Panik / Nefes Protokolü nasıl çalışır?',
            cevap: 'Huberman Lab protokolüdür (7 döngü x 12 sn = 84 sn). '
                'Burundan 1 derin nefes + hemen ardından 1 kısa nefes daha alınır (alveolleri açar), '
                'ağızdan yavaşça uzun verilir (vagal tonusu uyarır ve kalp atışını yavaşlatır). '
                'Ekranda "Bu heyecan tehlike değil, odaklanmamı artıran bir hazırlıktır" '
                'bilişsel yeniden değerlendirme mesajı eşlik eder.',
          ),
          _SoruCevapKart(
            soru: 'Beklenen Değer (EV) Kuralı: İki şık arasında kalınca ne yapmalıyım?',
            cevap: 'ÖSYM sisteminde (+1 doğru / -0.25 yanlış):\n'
                '• 2 şık elediğinizde kalan 3 şıktan birini işaretlemek istatistiksel olarak '
                '+0.167 net kazandırır. Bu sebeple 2 şık elenen sorular ASLA boş bırakılmamalıdır!\n'
                '• Hiçbir şık elenmediğinde ise kör tahmin 0.00 net getirir; boş bırakılmalıdır.',
          ),
          _SoruCevapKart(
            soru: 'Cevap değiştirmek doğru mu, yanlış mı?',
            cevap: 'Psikometri araştırmaları kararsız soruların %57.8 oranında yanlışa '
                'döndüğünü doğrular. Bu nedenle kural şudur: "Yalnızca ilk işaretlemeniz '
                'Kararsız olup soruda yeni somut bir öncül/bulgu fark ettiyseniz değiştirin; '
                'kaygıyla asla değiştirmeyin."',
          ),
          const SizedBox(height: 14),

          // Bölüm 6: Master Yönetim Kokpiti
          _KategoriBasligi(
            ikon: Icons.dashboard_customize_outlined,
            baslik: '6. Master Yönetim Kokpiti & Karar Asistanı',
            renk: Colors.amber.shade900,
          ),
          _SoruCevapKart(
            soru: 'Bilişsel Sağlık Skoru (0–100) neye göre hesaplanır?',
            cevap: 'Kalibrasyon farkınız (±%5 hedefi), uyku düzenliliğiniz (7–9 sa, ±30 dk sapma), '
                'prefrontal korteks okuma hatası payı (< %10), R1 tekrar geçiş oranınız (>= %75) '
                've odak kalitenizin ağırlıklı bileşimidir. 85 üstü "Optimal Zirve" hattıdır.',
          ),
          _SoruCevapKart(
            soru: 'Otomatik "Eğer–O Zaman" Kararları nasıl yardımcı olur?',
            cevap: 'Sistem deneme, uyku ve tekrar verilerinizi sürekli analiz eder. '
                'Örneğin aşırı güven tespit ederse "Çeldiriciye tersini düşün", '
                'okuma hatası tespit ederse "Kurtarma Modunu Aç", tempo düşüşü tespit ederse '
                '"135 Dk Sınav Provası Başlat" gibi anında tıklanabilir çözümler sunar.',
          ),
          const SizedBox(height: 24),

          // Künye & Rapor Bilgisi
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: tema.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_outlined, size: 20, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        'Master Araştırma Raporu Bilgi Notu',
                        style: tema.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'MY TUS uygulamasındaki tüm bilişsel algoritmalar, uyku protokolleri, '
                    'R0–R4 aralıklı tekrar formülleri ve sınav anı stratejileri; Dr. Furkan tarafından '
                    'hazırlanan 32 sayfalık "TUS Türkiye 1.liği ve Maksimum Bilişsel Performans '
                    'Master Araştırma Raporu" (30 Eylül 2026) verilerine dayanarak geliştirilmiştir.',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KategoriBasligi extends StatelessWidget {
  const _KategoriBasligi({
    required this.ikon,
    required this.baslik,
    required this.renk,
  });

  final IconData ikon;
  final String baslik;
  final Color renk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(ikon, size: 20, color: renk),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              baslik,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: renk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoruCevapKart extends StatelessWidget {
  const _SoruCevapKart({required this.soru, required this.cevap});

  final String soru;
  final String cevap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: tema.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          soru,
          style: tema.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        children: [
          Text(
            cevap,
            style: tema.textTheme.bodyMedium?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
