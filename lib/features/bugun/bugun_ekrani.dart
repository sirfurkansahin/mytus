import 'package:app/core/tarih.dart';
import 'package:app/features/ayarlar/ayarlar_ekrani.dart';
import 'package:app/features/bilissel/bilissel_ekrani.dart';
import 'package:app/features/defterler/defterler_ekrani.dart';
import 'package:app/features/denemeler/denemeler_ekrani.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/ilerleme/ilerleme_ekrani.dart';
import 'package:app/features/kokpit/kokpit_ekrani.dart';
import 'package:app/features/rehber/rehber_ekrani.dart';
import 'package:app/features/takvim/konu_sec_ekrani.dart';
import 'package:app/features/takvim/takvim_ogeleri.dart';
import 'package:flutter/material.dart';

/// "Bugün" ekranı: sınav sayacı, günlük görev ilerlemesi, geciken işler,
/// bugünün planı, R0 akşam beyaz sayfa tekrarı, bugünkü tekrarlar ve yarının özeti.
class BugunEkrani extends StatelessWidget {
  const BugunEkrani({super.key});

  Future<void> _buguneKonuYerlestir(
    BuildContext context,
    PlanDeposu depo,
    DateTime bugun,
  ) async {
    final konuId = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(builder: (_) => const KonuSecEkrani()),
    );
    if (konuId == null || !context.mounted) return;
    depo.calismaEkle(konuId, bugun);
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final soluk = tema.colorScheme.onSurfaceVariant;
    final bugun = gunBasi(DateTime.now());
    final yarin = gunEkle(bugun, 1);
    final sinav = depo.sinavTarihi ?? resmiSinavTarihi;
    final kalan = gunFarki(sinav, bugun);

    final tumCalismalar = depo.tumCalismalar();
    final tumTekrarlar = depo.tekrarlar(bugun);

    final gecikenCalismalar = [
      for (final c in tumCalismalar)
        if (!c.tamam && c.tarih.isBefore(bugun)) c,
    ];
    final gecikenTekrarlar = [
      for (final t in tumTekrarlar)
        if (t.eylemYapilabilir && t.tarih.isBefore(bugun)) t,
    ];
    final bugunCalismalari = [
      for (final c in tumCalismalar)
        if (ayniGun(c.tarih, bugun)) c,
    ];
    final bugunTamamKonular = [
      for (final c in bugunCalismalari)
        if (c.tamam)
          if (depo.konuBul(c.konuId) case final k?) k.ad,
    ];
    final bugunTekrarlari = [
      for (final t in tumTekrarlar)
        if (ayniGun(t.tarih, bugun)) t,
    ];
    final yarinCalismaSayisi = [
      for (final c in tumCalismalar)
        if (!c.tamam && ayniGun(c.tarih, yarin)) c,
    ].length;
    final yarinTekrarSayisi = [
      for (final t in tumTekrarlar)
        if (!t.yapildi && ayniGun(t.tarih, yarin)) t,
    ].length;

    final haftaSonu = gunEkle(bugun, 6);
    final haftaKonuSayisi = {
      for (final c in tumCalismalar)
        if (!c.tamam && !c.tarih.isBefore(bugun) && !c.tarih.isAfter(haftaSonu))
          c.konuId,
    }.length;

    final yapilanCalisma = bugunCalismalari.where((c) => c.tamam).length;
    final yapilanTekrar = bugunTekrarlari.where((t) => t.yapildi).length;
    final toplamGorev = bugunCalismalari.length + bugunTekrarlari.length;
    final yapilanGorev = yapilanCalisma + yapilanTekrar;
    final geciken = gecikenCalismalar.length + gecikenTekrarlar.length;
    final bosGun = geciken == 0 &&
        bugunCalismalari.isEmpty &&
        bugunTekrarlari.isEmpty;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Bugün',
                style: tema.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Master Kokpit',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.dashboard_customize_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const KokpitEkrani()),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Bilişsel & Uyku',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.psychology_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const BilisselEkrani()),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Özel Defterler',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.rule_folder_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const DefterlerEkrani()),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Denemeler & Analiz',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.assignment_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const DenemelerEkrani()),
                    ),
                  ),
                  IconButton(
                    tooltip: 'İlerleme',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.bar_chart_rounded),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const IlerlemeEkrani()),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kullanım Rehberi & SSS',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.help_outline),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const RehberEkrani()),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ayarlar',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AyarlarEkrani()),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            gunAdiIleTarih(bugun),
            style: tema.textTheme.bodyMedium?.copyWith(color: soluk),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const KokpitEkrani()),
            ),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: tema.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: tema.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.speed, color: tema.colorScheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Master Kokpit · 8 Bilişsel Gösterge & Strateji',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: tema.colorScheme.primary,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: tema.colorScheme.primary, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RehberEkrani()),
            ),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.indigo.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.menu_book_outlined, color: Colors.indigo, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kullanım Rehberi & 1 Dk Tanıtım Turu',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.indigo, size: 18),
                ],
              ),
            ),
          ),
          if (depo.kurtarmaModuAktif) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const BilisselEkrani()),
              ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: Colors.teal, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '🛡️ %70 Kurtarma Modu Aktif (PFC Dinlendirme)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.teal, size: 20),
                  ],
                ),
              ),
            ),
          ] else if (depo.zorBilisselTavanAsildi) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const BilisselEkrani()),
              ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.block_rounded, color: Colors.red, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '⛔ Günlük Zor Bilişsel Tavan (4 saat) Doldu!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.red, size: 20),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: tema.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kalan > 0
                        ? 'Sınava $kalan gün kaldı'
                        : kalan == 0
                            ? 'Sınav bugün'
                            : 'Sınav tarihi geçti',
                    style: tema.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: tema.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tarihYaz(sinav),
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: tema.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (toplamGorev > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Bugünkü ilerleme: $yapilanGorev / $toplamGorev görev',
                      style: tema.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tema.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: yapilanGorev / toplamGorev,
                        minHeight: 6,
                        backgroundColor: tema.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.18),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          tema.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              if (haftaKonuSayisi > 0)
                Text(
                  'Bu hafta $haftaKonuSayisi konu planlı',
                  style: tema.textTheme.bodyMedium?.copyWith(color: soluk),
                )
              else
                const SizedBox.shrink(),
              TextButton.icon(
                onPressed: () => _buguneKonuYerlestir(context, depo, bugun),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('+ Bugüne konu yerleştir'),
              ),
            ],
          ),
          if (geciken > 0) ...[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                BolumBasligi(baslik: 'Geciken', bilgi: '$geciken iş'),
                if (gecikenCalismalar.isNotEmpty)
                  TextButton(
                    onPressed: () => depo.gecikenleriBuguneAl(bugun),
                    child: const Text('Tümünü bugüne al'),
                  ),
              ],
            ),
            for (final c in gecikenCalismalar) ...[
              CalismaSatiri(calisma: c, bugun: bugun, planliGunuGoster: true),
              const SizedBox(height: 8),
            ],
            for (final t in gecikenTekrarlar) ...[
              TekrarSatiri(tekrar: t, bugun: bugun, tarihiGoster: true),
              const SizedBox(height: 8),
            ],
          ],
          if (bugunCalismalari.isNotEmpty) ...[
            BolumBasligi(
              baslik: 'Bugünün planı',
              bilgi: '$yapilanCalisma/${bugunCalismalari.length}',
            ),
            for (final c in bugunCalismalari) ...[
              CalismaSatiri(calisma: c, bugun: bugun),
              const SizedBox(height: 8),
            ],
          ],
          if (bugunTamamKonular.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tema.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'R0 · Akşam uyku öncesi beyaz sayfa tekrarı',
                    style: tema.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: tema.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Uyumadan önce bu konuları nota bakmadan boş kağıda '
                    'zincir olarak çiz (${bugunTamamKonular.join(', ')}). '
                    'Yavaş dalga uykusunda kalıcı belleğe geçişi güçlendirir.',
                    style: tema.textTheme.bodySmall?.copyWith(color: soluk),
                  ),
                ],
              ),
            ),
          ],
          if (bugunTekrarlari.isNotEmpty) ...[
            BolumBasligi(
              baslik: 'Tekrarlar',
              bilgi: '$yapilanTekrar/${bugunTekrarlari.length}',
            ),
            for (final t in bugunTekrarlari) ...[
              TekrarSatiri(tekrar: t, bugun: bugun),
              const SizedBox(height: 8),
            ],
          ],
          if (bosGun)
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 8),
              child: Text(
                depo.tumCalismalar().isEmpty
                    ? 'Henüz plan yok. "+ Bugüne konu yerleştir" düğmesiyle '
                        'veya Takvim sekmesinden bir konu ekle; tekrarlar otomatik oluşur.'
                    : 'Bugün için planlanmış bir iş yok.',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium?.copyWith(color: soluk),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: tema.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Yarının planı',
                  style: tema.textTheme.labelLarge?.copyWith(
                    color: soluk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  yarinCalismaSayisi == 0 && yarinTekrarSayisi == 0
                      ? 'Planlanmış iş yok'
                      : '$yarinCalismaSayisi konu · $yarinTekrarSayisi tekrar',
                  style: tema.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
