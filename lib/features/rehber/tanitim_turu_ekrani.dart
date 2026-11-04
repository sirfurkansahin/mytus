library;

import 'package:flutter/material.dart';

/// Tek bir tanıtım slaytının içeriği.
class TanitimSlayti {
  const TanitimSlayti({
    required this.baslik,
    required this.altBaslik,
    required this.ikon,
    required this.renk,
    required this.maddeler,
    required this.ozet,
  });

  final String baslik;
  final String altBaslik;
  final IconData ikon;
  final Color renk;
  final List<String> maddeler;
  final String ozet;
}

/// MY TUS Görsel Tanıtım Turu: 5 Tematik Slayt ile Uygulama Mantığı.
/// (Master Araştırma Raporu Nörobiyolojik ve Psikometrik Temelleri)
class TanitimTuruEkrani extends StatefulWidget {
  const TanitimTuruEkrani({super.key});

  @override
  State<TanitimTuruEkrani> createState() => _TanitimTuruEkraniState();
}

class _TanitimTuruEkraniState extends State<TanitimTuruEkrani> {
  final PageController _controller = PageController();
  int _mevcutSayfa = 0;

  static const List<TanitimSlayti> _slaytlar = [
    TanitimSlayti(
      baslik: '1. Akıllı Planlama & Tekrar Sistemi (R0–R4)',
      altBaslik: 'Soru Merkezli Döngü & Sistem Konsolidasyonu',
      ikon: Icons.event_repeat,
      renk: Colors.purple,
      maddeler: [
        '📅 Konunu Ekle: Dersler ekranından konunu seç ve takvimde istediğin güne yerleştir.',
        '🌙 R0 Akşam Tekrarı: Bir konuyu çalıştığında, uyku öncesi 15-20 dakikalık R0 beyaz sayfa hatırlatması Bugün ekranına düşer.',
        '🔁 R1–R4 Aralıklı Tekrarlar: Sınava kalan gün sayısına göre (G+1, G+7, G+30 vb.) tekrarlar otomatik hesaplanır ve takvime dizilir.',
        '⏩ Gecikme Kayması: Bir tekrar gecikirse sonraki adımlar silinmez; aralıklar korunarak ileri kayar.',
      ],
      ozet: 'Beyin bilgiyi uykuda pekiştirir. Tekrar aralıklarını ezberlemenize gerek yok, sistem sizin yerinize yönetir.',
    ),
    TanitimSlayti(
      baslik: '2. F.T. Time & Bilişsel Kapasite (3–4 Saat Kuralı)',
      altBaslik: 'Derin Odaklanma & Tükenmeyi Önleme',
      ikon: Icons.timer_outlined,
      renk: Colors.indigo,
      maddeler: [
        '⏱️ Blok Presetleri: Klasik Pomodoro (25/5 dk) veya derin çalışma (50/10 dk) bloklarını tek dokunuşla başlat.',
        '⭐ Blok Sonu Puanı: Her çalışma bitiminde 1-5 arası odak puanı vererek kendi verim eğrini gör.',
        '🧠 3–4 Saat Kuralı: Nitelikli "zor analitik iş" (yeni konu, ağır soru) için günlük kanıtlı tavan 180-240 dakikadır.',
        '☕ Kafein Disiplini: Yatış saatinden 8 saat önce otomatik kafein kesilme uyarısıyla derin yavaş dalga uykunu koru.',
      ],
      ozet: 'TUS günde 12 saat oturmakla değil; 3-4 saat yüksek odaklı zor iş ve kaliteli uykuyla kazanılır.',
    ),
    TanitimSlayti(
      baslik: '3. Deneme Analizi & Özel Defterler',
      altBaslik: 'A–F Hata Sınıfları, Çeldirici Bankası & Skorlar',
      ikon: Icons.assignment_outlined,
      renk: Colors.teal,
      maddeler: [
        '📊 ÖSYM 85 EBAP Puanı: 200 soruluk (TTBT + KTBT) denemelerini kaydet; net ve tahmini TUS puanını anında gör.',
        '🏷️ A–F Hata Kodlaması: Hatalarını bilgi, yanlış inanç, okuma, mantık, süre ve dikkat sınıflarına ayır.',
        '🎯 Çeldirici Bankası: Karışan şıkkı, ayıran tek kriteri ve kendi altın kuralını yazarak tuzakları kalıcı olarak çöz.',
        '📋 Skor Defteri & Mekanizma: 10+ hazır TUS skoru (Wells, CURB-65 vb.) ve 5 halkalı mekanizma zincirleriyle çalış.',
      ],
      ozet: '"Emin işaretleyip yanlış yaptığın" sorular en tehlikeli kör noktalardır; aynı gün Çeldirici Bankası\'na işlenir.',
    ),
    TanitimSlayti(
      baslik: '4. Sınav Anı, Panik Protokolü & Provalar',
      altBaslik: '135 Dk Gerçek Saat Provası & Vagal Tonus',
      ikon: Icons.air,
      renk: Colors.deepOrange,
      maddeler: [
        '🫁 90 sn Panik / Nefes Protokolü: Çarpıntı veya kilitlenme anında 84 saniyelik görsel Döngüsel İç Çekme (Cyclic Sighing) rehberiyle sempatik uyarılmayı sakinleştir.',
        '⏱️ 135 Dk Sınav Provası: Resmi süreyle deneme provası yap; 25, 50, 75 ve 100. sorularda çeyrek dilim tempo durumunu kontrol et.',
        '🥪 135 Dk Ara Protokolü: TTBT ile KTBT oturumları arasında cevap tartışmadan sıfırlanma rehberi.',
        '🎲 Beklenen Değer (EV) Kartı: 2 şık elediğinde işaretlemek istatistiksel olarak +0.167 net kazandırır; asla boş bırakma!',
      ],
      ozet: 'Stres vücudun göreve hazırlandığını gösterir. Doğru nefes ve önceden kararlaştırılmış kurallarla avantajına çevir.',
    ),
    TanitimSlayti(
      baslik: '5. Master Yönetim Kokpiti & Karar Asistanı',
      altBaslik: 'Haftalık 8 Bilişsel Gösterge & "Eğer–O Zaman" Motoru',
      ikon: Icons.dashboard_customize_outlined,
      renk: Colors.blue,
      maddeler: [
        '🧭 8 Bilişsel Gösterge: Kalibrasyon farkı, aşırı güven, uyku düzeni, okuma hatası payı, kaygı ve tekrar tamamlama oranlarını izle.',
        '🛡️ %70 Kurtarma Modu: Okuma hatası > %15 olduğunda tek tıkla prefrontal korteksi dinlendirme moduna geç.',
        '⚡ Otomatik Strateji Motoru: Teşhis edilen risklere göre anında butonlu eylem önerileri (Örn: "Yeni konuyu kıs", "Çeldiriciye tersini düşün").',
        '🏆 0–100 Bilişsel Sağlık Skoru: Hedef referans aralığına ve Türkiye 1.liği performans hattına göre genel durumunu gör.',
      ],
      ozet: 'Tüm çalışmaların, uykun ve denemelerin tek bir akıllı karar merkezine bağlanır; sana en doğru rotayı gösterir.',
    ),
  ];

  void _sayfayaGit(int sayfa) {
    _controller.animateToPage(
      sayfa,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final sonSayfaMi = _mevcutSayfa == _slaytlar.length - 1;
    final aktifSlayt = _slaytlar[_mevcutSayfa];

    return Scaffold(
      appBar: AppBar(
        title: const Text('MY TUS Kullanım Turu'),
        actions: [
          if (!sonSayfaMi)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Atla'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slaytlar.length,
                onPageChanged: (idx) => setState(() => _mevcutSayfa = idx),
                itemBuilder: (context, index) {
                  final slayt = _slaytlar[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // İkon Kutusu
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: slayt.renk.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: slayt.renk.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: Icon(slayt.ikon, size: 40, color: slayt.renk),
                        ),
                        const SizedBox(height: 16),

                        // Başlık ve Alt Başlık
                        Text(
                          slayt.baslik,
                          textAlign: TextAlign.center,
                          style: tema.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: slayt.renk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          slayt.altBaslik,
                          textAlign: TextAlign.center,
                          style: tema.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Maddeler
                        for (final madde in slayt.maddeler) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: tema.colorScheme.outlineVariant.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    madde,
                                    style: tema.textTheme.bodyMedium?.copyWith(
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Alt Özet Kartı
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: slayt.renk.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: slayt.renk.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lightbulb_outline, size: 20, color: slayt.renk),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  slayt.ozet,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: slayt.renk,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Alt Gezinme ve Gösterge Bölümü
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              decoration: BoxDecoration(
                color: tema.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: tema.colorScheme.outlineVariant),
                ),
              ),
              child: Column(
                children: [
                  // Sayfa Noktaları (Dots)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _slaytlar.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _mevcutSayfa == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _mevcutSayfa == i
                                ? aktifSlayt.renk
                                : tema.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Butonlar
                  Row(
                    children: [
                      if (_mevcutSayfa > 0)
                        OutlinedButton(
                          onPressed: () => _sayfayaGit(_mevcutSayfa - 1),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Geri'),
                        )
                      else
                        const SizedBox.shrink(),
                      const Spacer(),
                      if (!sonSayfaMi)
                        FilledButton.icon(
                          onPressed: () => _sayfayaGit(_mevcutSayfa + 1),
                          style: FilledButton.styleFrom(
                            backgroundColor: aktifSlayt.renk,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('İlerle'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: aktifSlayt.renk,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 20),
                          label: const Text(
                            'Anladım, Başla!',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
