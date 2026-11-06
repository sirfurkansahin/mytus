import 'package:app/core/gizli_ozellikler.dart';
import 'package:app/features/bilissel/dialoglar.dart';
import 'package:app/features/bilissel/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// Bilişsel performans, nörobiyoloji, uyku disiplini ve PFC koruma ekranı.
/// (Master Araştırma Raporu Bölüm 1.1, 1.3, 1.6 ve 6.4)
class BilisselEkrani extends StatelessWidget {
  const BilisselEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final zorDk = depo.zorBilisselDakikaBugun();
    final toplamDk = depo.toplamOdakDakikaBugun();
    final ortOdak = depo.ortalamaOdakPuani();
    final cOran = depo.sonOkumaHatasiOrani;
    final bugun = DateTime.now();
    final bugunkuUyku = depo.bugunkuUyku(bugun);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilişsel & Uyku Yönetimi'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // 0. Sınav Taper & PFC Erken Uyarı Bildirimleri
          if (depo.uykuTaperAktif) ...[
            _taperProtokolKarti(context),
            const SizedBox(height: 12),
          ],
          if (depo.pfcErkenUyariAktif) ...[
            _pfcUyariKarti(context, depo, cOran),
            const SizedBox(height: 12),
          ],
          if (depo.kurtarmaModuAktif) ...[
            _kurtarmaModuKarti(context, depo),
            const SizedBox(height: 12),
          ],

          // 1. Zor Bilişsel İş Tavanı Kartı (3-4 Saat Kuralı)
          _zorBilisselTavanKarti(context, depo, zorDk, toplamDk),
          const SizedBox(height: 16),

          // 2. Sirkadiyen Odak Dağılımı ve Eğrisi (K1: gizli, bkz. gizli_ozellikler.dart)
          if (sirkadiyenGrafikAcik) ...[
            _odakEgrisiKarti(context, depo, ortOdak),
            const SizedBox(height: 16),
          ],

          // 3. Uyku, Kafein ve Sirkadiyen Ritim Kartı
          _uykuKafeinKarti(context, depo, bugunkuUyku),
          const SizedBox(height: 16),

          // 4. Prefrontal Korteks & Kurtarma Modu Ayarı
          _pfcYonetimKarti(context, depo, cOran),
          const SizedBox(height: 16),

          // 5. Nörobiyoloji Rehberi (Rapor İlkeleri)
          _norobiyolojiRehberi(tema),
        ],
      ),
    );
  }

  Widget _taperProtokolKarti(BuildContext context) {
    return Card(
      color: Colors.purple.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.purple, width: 1.5),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.bed_rounded, color: Colors.purple, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔥 Sınava Son 7 Gün: Uyku Taper Protokolü',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Uykudan fedakarlık yapılamaz. Bellek konsolidasyonu için her gün sabit saatte en az 8 saat uyunmalıdır.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pfcUyariKarti(BuildContext context, PlanDeposu depo, double cOran) {
    final yuzde = (cOran * 100).toStringAsFixed(1);
    return Card(
      color: Colors.red.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ Prefrontal Korteks (PFC) Aşırı Yük Uyarısı',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[800]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Son denemelerinizdeki okuma/dikkat (C tipi) hata oranı: %$yuzde (Eşik: %15).\n'
              'Bu durum beynin karar merkezinin yorulduğunu gösterir.',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            if (!depo.kurtarmaModuAktif)
              FilledButton.tonalIcon(
                onPressed: () => depo.kurtarmaModuAyarla(true),
                icon: const Icon(Icons.shield_outlined),
                label: const Text('%70 Kurtarma Modunu Başlat'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _kurtarmaModuKarti(BuildContext context, PlanDeposu depo) {
    return Card(
      color: Colors.teal.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.teal, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.shield_rounded, color: Colors.teal, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🛡️ %70 Yük Kurtarma Modu Devrede',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ağır yeni konular ertelendi. Sadece R1-R2 aralıklı tekrarları ve hafif pekiştirme kartları çalışılmalıdır.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Kurtarma Modunu Kapat',
              icon: const Icon(Icons.close),
              onPressed: () => depo.kurtarmaModuAyarla(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zorBilisselTavanKarti(
    BuildContext context,
    PlanDeposu depo,
    int zorDk,
    int toplamDk,
  ) {
    final tema = Theme.of(context);
    final oran = (zorDk / 240.0).clamp(0.0, 1.0);
    final saat = zorDk ~/ 60;
    final dk = zorDk % 60;

    final Color renk;
    final String durumYazisi;
    if (zorDk >= 240) {
      renk = Colors.red;
      durumYazisi = '⛔ Ağır Analitik Tavan Doldu (4 saat)! Kalan sürede sadece hafif tekrar ve kart çalışın.';
    } else if (zorDk >= 180) {
      renk = Colors.orange;
      durumYazisi = '⚡ Zor Bilişsel Tavana Yaklaşıldı (3+ saat). PFC yorulmak üzere.';
    } else {
      renk = Colors.green;
      durumYazisi = '✅ Prefrontal korteks analitik kapasitesi dengeli.';
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_outlined, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zor Bilişsel İş Tavanı (3–4 Saat)',
                    style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '$saat sa $dk dk / 4 sa',
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: renk,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: oran,
                minHeight: 10,
                color: renk,
                backgroundColor: tema.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              durumYazisi,
              style: TextStyle(fontSize: 12, color: renk, fontWeight: FontWeight.w600),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bugünkü Toplam Odak: $toplamDk dk',
                  style: tema.textTheme.bodySmall,
                ),
                Text(
                  'Hafif / Tekrar: ${toplamDk - zorDk} dk',
                  style: tema.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _odakEgrisiKarti(BuildContext context, PlanDeposu depo, double ortOdak) {
    final tema = Theme.of(context);
    final dagilim = depo.saatlikOdakDagilimi(14);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_rounded, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sirkadiyen Odak Dağılımı',
                    style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (ortOdak > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '★ ${ortOdak.toStringAsFixed(1)} / 5.0',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[900],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'F.T. Time blok sonlarında verdiğiniz 1-5 puanlara göre gün içi analitik zirve ve çukur saatleriniz.',
              style: tema.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (dagilim.isEmpty)
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Henüz blok odak kaydı bulunmuyor.\nF.T. time çalışmalarınızı tamamladıkça saatlik verim grafiğiniz burada oluşur.',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                ),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var saat = 7; saat <= 23; saat++)
                    if (dagilim.containsKey(saat))
                      _saatRozeti(saat, dagilim[saat]!, tema),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _saatRozeti(int saat, double puan, ThemeData tema) {
    final Color zemin;
    final Color yazi;
    if (puan >= 4.0) {
      zemin = Colors.green.withValues(alpha: 0.15);
      yazi = Colors.green[800]!;
    } else if (puan >= 3.0) {
      zemin = Colors.blue.withValues(alpha: 0.15);
      yazi = Colors.blue[800]!;
    } else {
      zemin = Colors.orange.withValues(alpha: 0.15);
      yazi = Colors.orange[800]!;
    }

    final saatStr = '${saat.toString().padLeft(2, '0')}:00';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: zemin,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: yazi.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(saatStr, style: TextStyle(fontSize: 11, color: yazi, fontWeight: FontWeight.bold)),
          Text('★ ${puan.toStringAsFixed(1)}', style: TextStyle(fontSize: 10, color: yazi)),
        ],
      ),
    );
  }

  Widget _uykuKafeinKarti(
    BuildContext context,
    PlanDeposu depo,
    UykuKaydi? bugunkuUyku,
  ) {
    final tema = Theme.of(context);
    final kafeinSaati = kafeinKesilmeSaatiHesapla(depo.hedefYatisSaati);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bedtime_outlined, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Uyku & Kafein Disiplini',
                    style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final res = await showDialog<Map<String, String>>(
                      context: context,
                      builder: (_) => HedefUykuDialog(
                        hedefYatis: depo.hedefYatisSaati,
                        hedefKalkis: depo.hedefKalkisSaati,
                      ),
                    );
                    if (res != null) {
                      depo.hedefUykuAyarla(yatis: res['yatis']!, kalkis: res['kalkis']!);
                    }
                  },
                  child: const Text('Hedefi Düzenle'),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tema.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hedef Pencere', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          '${depo.hedefYatisSaati} – ${depo.hedefKalkisSaati}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.grey[400]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('☕ Kafein Kesilme (8 sa)', style: TextStyle(fontSize: 11, color: Colors.brown)),
                        Text(
                          'En geç $kafeinSaati',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.brown),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // K1: Günlük uyku girişi gizli (bkz. gizli_ozellikler.dart)
            if (gunlukUykuGirisiAcik) ...[
            const SizedBox(height: 12),
            if (bugunkuUyku != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bugunkuUyku.sirkadiyenUyumlu
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: bugunkuUyku.sirkadiyenUyumlu ? Colors.green : Colors.amber,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      bugunkuUyku.sirkadiyenUyumlu ? Icons.check_circle : Icons.info_outline,
                      color: bugunkuUyku.sirkadiyenUyumlu ? Colors.green : Colors.amber[800],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bugün: ${bugunkuUyku.uykuSuresiSaat.toStringAsFixed(1)} saat (${bugunkuUyku.yatisSaati} - ${bugunkuUyku.kalkisSaati})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            bugunkuUyku.sirkadiyenUyumlu
                                ? '🏆 Sirkadiyen Altın Uyum! (±${bugunkuUyku.yatisSapmasiDakika} dk sapma)'
                                : 'Sapma: ${bugunkuUyku.yatisSapmasiDakika} dk · Kalite: ${bugunkuUyku.kalite}/5',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _uykuDuzenle(context, depo, bugunkuUyku),
                    ),
                  ],
                ),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () => _uykuEkle(context, depo),
                icon: const Icon(Icons.add),
                label: const Text('Dün Geceki Uykuyu Kaydet'),
              ),
            ],
            if (depo.uykular.length > 1) ...[
              const SizedBox(height: 12),
              Text('Son Kayıtlar:', style: tema.textTheme.labelMedium),
              const SizedBox(height: 6),
              for (final u in depo.uykular.skip(bugunkuUyku != null ? 1 : 0).take(5))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(u.tarih, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 10),
                      Text(
                        '${u.uykuSuresiSaat.toStringAsFixed(1)} sa (${u.yatisSaati})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      if (u.sirkadiyenUyumlu)
                        const Text('✅ Uyumlu', style: TextStyle(fontSize: 11, color: Colors.green))
                      else
                        Text('Sapma: ${u.yatisSapmasiDakika} dk', style: const TextStyle(fontSize: 11, color: Colors.amber)),
                    ],
                  ),
                ),
            ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _uykuEkle(BuildContext context, PlanDeposu depo) async {
    final kayit = await showDialog<UykuKaydi>(
      context: context,
      builder: (_) => UykuKaydetDialog(
        hedefYatis: depo.hedefYatisSaati,
        hedefKalkis: depo.hedefKalkisSaati,
      ),
    );
    if (kayit != null) depo.uykuKaydet(kayit);
  }

  Future<void> _uykuDuzenle(BuildContext context, PlanDeposu depo, UykuKaydi mevcut) async {
    final kayit = await showDialog<UykuKaydi>(
      context: context,
      builder: (_) => UykuKaydetDialog(
        hedefYatis: depo.hedefYatisSaati,
        hedefKalkis: depo.hedefKalkisSaati,
        mevcutKayit: mevcut,
      ),
    );
    if (kayit != null) depo.uykuKaydet(kayit);
  }

  Widget _pfcYonetimKarti(BuildContext context, PlanDeposu depo, double cOran) {
    final tema = Theme.of(context);
    final yuzde = (cOran * 100).toStringAsFixed(1);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Prefrontal Korteks (PFC) & Kurtarma',
                    style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Son Deneme Okuma/Kurgu (C Tipi) Hata Oranı: %$yuzde',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cOran > 0.15 ? Colors.red : Colors.green[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rapor İlkesi: C tipi hata oranı > %15 ise dikkat tükenmiştir. Yeni konu yüklemek verimsizdir.',
              style: tema.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: depo.kurtarmaModuAktif,
              onChanged: (v) => depo.kurtarmaModuAyarla(v),
              title: const Text('🛡️ %70 Yük Kurtarma Modu', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text(
                'Etkinleştirildiğinde yeni konular askıya alınır, sadece R1-R2 tekrarları yapılır.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _norobiyolojiRehberi(ThemeData tema) {
    return Card(
      elevation: 0,
      color: tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Master Nörobiyoloji İlkeleri',
                  style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _rehberMaddesi(
              '1. Bilişsel Tavan (3-4 Saat):',
              'Prefrontal korteksin glikoz ve nörotransmitter depoları günde net 3-4 saat ağır analitik işten sonra tükenir. 4 saatin üzerindeki ağır çalışma öğrenme yanılsamasıdır.',
            ),
            _rehberMaddesi(
              '2. 8 Saat Kafein Kuralı:',
              'Kafeinin yarılanma ömrü 5-7 saattir. Yatmadan 8 saat önce kesilmezse uykuya dalsanız bile derin yavaş dalga (NREM) ve REM uyku mimarisi bozulur; bellek konsolidasyonu gerçekleşmez.',
            ),
            _rehberMaddesi(
              '3. ±30 Dk Sirkadiyen Tutarlılık:',
              'Hafta sonu dahil her gün aynı saatte yatıp kalkmak biyolojik saati kilitler, sabah kortizol uyanma yanıtını optimize eder.',
            ),
            _rehberMaddesi(
              '4. %70 Yük & Kurtarma:',
              'Ardı ardına gelen okuma hataları dikkatin tükendiğini gösterir. Bu günlerde zorlamak yerine yük %70\'e çekilir ve sadece aralıklı tekrar yapılır.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _rehberMaddesi(String baslik, String icerik) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 2),
          Text(icerik, style: const TextStyle(fontSize: 11, color: Colors.black87)),
        ],
      ),
    );
  }
}
