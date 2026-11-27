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
/// (Uygulamanın temel akışları)
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
      altBaslik: 'Soru Merkezli Döngü & Aralıklı Tekrar',
      ikon: Icons.event_repeat,
      renk: Colors.purple,
      maddeler: [
        '📅 Konunu Ekle: Dersler ekranından konunu seç ve takvimde istediğin güne yerleştir.',
        '🌙 R0 Akşam Tekrarı: Bir konuyu çalıştığında, günün sonunda 15-20 dakikalık R0 beyaz sayfa hatırlatması Bugün ekranına düşer.',
        '🔁 R1–R4 Aralıklı Tekrarlar: Sınava kalan gün sayısına göre (G+1, G+7, G+30 vb.) tekrarlar otomatik hesaplanır ve takvime dizilir.',
        '⏩ Gecikme Kayması: Bir tekrar gecikirse sonraki adımlar silinmez; aralıklar korunarak ileri kayar.',
      ],
      ozet: 'Tekrar aralıklarını ezberlemenize gerek yok, sistem sizin yerinize yönetir.',
    ),
    TanitimSlayti(
      baslik: '2. F.T. Time (Odak Sayacı)',
      altBaslik: 'Bloklarla Odaklı Çalışma',
      ikon: Icons.timer_outlined,
      renk: Colors.indigo,
      maddeler: [
        '⏱️ Blok Presetleri: Klasik Pomodoro (25/5 dk) veya derin çalışma (50/10 dk) bloklarını tek dokunuşla başlat.',
        '⏸️ Molalar: Kısa ve uzun molalar sayaçta sırayla gelir.',
      ],
      ozet: 'Süreyi sayaç tutar; sen konuya odaklan.',
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
      baslik: '4. Sınav Provası & Stratejiler',
      altBaslik: '135 Dk Gerçek Saat Provası',
      ikon: Icons.timer,
      renk: Colors.deepOrange,
      maddeler: [
        '⏱️ 135 Dk Sınav Provası: Resmi süreyle deneme provası yap; 25, 50, 75 ve 100. sorularda çeyrek dilim tempo durumunu kontrol et.',
        '🎲 Beklenen Değer (EV) Kartı: 2 şık elediğinde işaretlemek istatistiksel olarak +0.167 net kazandırır; asla boş bırakma!',
      ],
      ozet: 'Sınav gününü önceden aynı süre ve düzenle prova et.',
    ),
    TanitimSlayti(
      baslik: '5. İlerleme, Çalışma Grubu & Bulut',
      altBaslik: 'Haftalık Özet, Grup Puanı & Eşitleme',
      ikon: Icons.groups_outlined,
      renk: Colors.blue,
      maddeler: [
        '📈 İlerleme: Haftalık özetini, konu ilerlemeni ve son denemeni tek ekranda gör.',
        '👥 Çalışma Grubu: 2-10 kişilik grubunla haftalık puan tablosu ve ortak hedef (1 soru = 1 puan, 1 konu = 10 puan).',
        '☁️ Bulut Hesabı: İstersen hesap açıp verilerini telefon ve tabletinde eşitle; misafir modunda veriler yalnız bu cihazda kalır.',
      ],
      ozet: 'Notların ve kişisel çalışma içeriğin grupta asla paylaşılmaz.',
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
