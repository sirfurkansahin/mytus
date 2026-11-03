import 'package:app/core/renkler.dart';
import 'package:app/core/tarih.dart';
import 'package:app/features/denemeler/deneme_detay_ekrani.dart';
import 'package:app/features/denemeler/deneme_ekle_ekrani.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// Deneme sınavları listesi, net/puan göstergesi ve analiz kokpiti.
class DenemelerEkrani extends StatelessWidget {
  const DenemelerEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final denemeler = depo.denemeler;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Deneme Sınavları & Analiz',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Yeni Deneme'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const DenemeEkleEkrani()),
        ),
      ),
      body: denemeler.isEmpty
          ? _BosDurum(onEkle: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const DenemeEkleEkrani()),
              ))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                _OzetKokpitKarti(denemeler: denemeler),
                const SizedBox(height: 20),
                Text(
                  'DENEME GEÇMİŞİ (${denemeler.length})',
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                for (final d in denemeler) ...[
                  _DenemeKarti(deneme: d),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _OzetKokpitKarti extends StatelessWidget {
  const _OzetKokpitKarti({required this.denemeler});

  final List<DenemeSinavi> denemeler;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final sonDeneme = denemeler.first;
    final toplamNet = sonDeneme.toplamNet;
    final ebap = sonDeneme.tahminiEbapPuani;
    final kPuan = sonDeneme.klinikAgirlikliPuan;

    return Card(
      elevation: 0,
      color: tema.colorScheme.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: tema.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, color: tema.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Son Deneme Özeti',
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${ebap.toStringAsFixed(1)} Puan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniMetrik(
                    baslik: 'Toplam Net',
                    deger: '${toplamNet.toStringAsFixed(2)} / 200',
                    altYazi: 'Hedef: 180+ Net',
                  ),
                ),
                Expanded(
                  child: _MiniMetrik(
                    baslik: 'K Puanı',
                    deger: kPuan.toStringAsFixed(2),
                    altYazi: '0.4 Temel + 0.6 Klinik',
                  ),
                ),
                Expanded(
                  child: _MiniMetrik(
                    baslik: 'Son Deneme',
                    deger: sonDeneme.ad,
                    altYazi: tarihFormatla(sonDeneme.tarih),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetrik extends StatelessWidget {
  const _MiniMetrik({
    required this.baslik,
    required this.deger,
    required this.altYazi,
  });

  final String baslik;
  final String deger;
  final String altYazi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          baslik,
          style: tema.textTheme.labelSmall?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          deger,
          style: tema.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          altYazi,
          style: tema.textTheme.bodySmall?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _DenemeKarti extends StatelessWidget {
  const _DenemeKarti({required this.deneme});

  final DenemeSinavi deneme;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final temelNet = deneme.temel.net;
    final klinikNet = deneme.klinik.net;
    final toplamNet = deneme.toplamNet;
    final ebap = deneme.tahminiEbapPuani;
    final hiperSayisi = deneme.hiperDuzeltmeSayisi;

    return Card(
      elevation: 0,
      color: tema.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tema.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DenemeDetayEkrani(denemeId: deneme.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deneme.ad,
                          style: tema.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tarihFormatla(deneme.tarih),
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${toplamNet.toStringAsFixed(2)} Net',
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: morAna,
                        ),
                      ),
                      Text(
                        '~${ebap.toStringAsFixed(1)} Puan (EBAP)',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  _OturumChip(
                    etiket: 'Temel',
                    net: temelNet,
                    dogru: deneme.temel.dogru,
                    yanlis: deneme.temel.yanlis,
                  ),
                  const SizedBox(width: 8),
                  _OturumChip(
                    etiket: 'Klinik',
                    net: klinikNet,
                    dogru: deneme.klinik.dogru,
                    yanlis: deneme.klinik.yanlis,
                  ),
                  const Spacer(),
                  if (hiperSayisi > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$hiperSayisi Hiperdüzeltme',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OturumChip extends StatelessWidget {
  const _OturumChip({
    required this.etiket,
    required this.net,
    required this.dogru,
    required this.yanlis,
  });

  final String etiket;
  final double net;
  final int dogru;
  final int yanlis;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$etiket: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '${net.toStringAsFixed(2)} net ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          Text(
            '($dogru D / $yanlis Y)',
            style: TextStyle(
              fontSize: 10,
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BosDurum extends StatelessWidget {
  const _BosDurum({required this.onEkle});

  final VoidCallback onEkle;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: tema.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Henüz deneme kaydı yok',
              style: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Girdiğin deneme sınavlarının netlerini ve A–F hata sınıflarını buraya kaydederek bilişsel performansını ölçebilirsin.',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onEkle,
              icon: const Icon(Icons.add),
              label: const Text('İlk Denemeni Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
