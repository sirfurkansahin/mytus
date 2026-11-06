import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/kutuphane/kitap_detay_ekrani.dart';
import 'package:app/features/kutuphane/kitap_ekle_dialogu.dart';
import 'package:app/features/kutuphane/modeller.dart';
import 'package:flutter/material.dart';

/// Kütüphane Modülü Ana Ekranı (Sürüm 1).
/// Kitaplarım, genel tamamlama oranı ve içindekiler takibi.
class KutuphaneEkrani extends StatelessWidget {
  const KutuphaneEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final kitaplar = depo.kitaplar;

    final toplamKitap = kitaplar.length;
    final toplamBolum = kitaplar.fold<int>(0, (top, k) => top + k.toplamBolumSayisi);
    final bitenBolum = kitaplar.fold<int>(0, (top, k) => top + k.tamamlananBolumSayisi);
    final genelOran = toplamBolum > 0 ? (bitenBolum / toplamBolum) : 0.0;
    final genelYuzde = (genelOran * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kütüphane',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Yeni Kitap Ekle',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => const KitapEkleDialogu(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (_) => const KitapEkleDialogu(),
          );
        },
        icon: const Icon(Icons.menu_book_outlined),
        label: const Text('Kitap Ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          // Genel Kütüphane Özeti Kartı
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: tema.colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            color: tema.colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_library_outlined,
                            color: tema.colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kütüphane İlerlemesi',
                            style: tema.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '%$genelYuzde',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: tema.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: genelOran,
                      minHeight: 8,
                      backgroundColor: tema.colorScheme.primary.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        genelYuzde == 100 ? Colors.teal : tema.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '$toplamKitap Kitap · $toplamBolum Bölüm',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '$bitenBolum bölüm bitti',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tema.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Kitap Listesi Başlığı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KİTAPLARIM ($toplamKitap)',
                style: tema.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: tema.colorScheme.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (kitaplar.isEmpty) ...[
            const SizedBox(height: 30),
            Center(
              child: Card(
                elevation: 0,
                color: tema.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: tema.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        size: 48,
                        color: tema.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Kütüphaneniz Henüz Boş',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'TUS konu kitaplarınızı, soru fasiküllerinizi veya spot notlarınızı '
                        'ekleyerek içindekiler takibini başlatabilirsiniz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (_) => const KitapEkleDialogu(),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('İlk Kitabını Ekle'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            for (final k in kitaplar) ...[
              _KitapKarti(kitap: k),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _KitapKarti extends StatelessWidget {
  const _KitapKarti({required this.kitap});

  final Kitap kitap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final siradaki = kitap.siradakiBolum;
    final bitti = kitap.tamamlandi;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: bitti
              ? Colors.teal.withValues(alpha: 0.3)
              : tema.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      color: bitti ? Colors.teal.withValues(alpha: 0.03) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => KitapDetayEkrani(kitapId: kitap.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 52,
                    decoration: BoxDecoration(
                      color: bitti
                          ? Colors.teal.withValues(alpha: 0.15)
                          : tema.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: bitti
                            ? Colors.teal.withValues(alpha: 0.4)
                            : tema.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      bitti ? Icons.task_alt : Icons.menu_book,
                      color: bitti ? Colors.teal : tema.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kitap.ad,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: tema.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                kitap.dersAdi ?? 'Genel',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: tema.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (kitap.toplamSayfa != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '${kitap.toplamSayfa} sayfa',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tema.colorScheme.outline,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '%${kitap.yuzde}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: bitti ? Colors.teal : tema.colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${kitap.tamamlananBolumSayisi}/${kitap.toplamBolumSayisi}',
                        style: TextStyle(
                          fontSize: 11,
                          color: tema.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: kitap.ilerlemeOrani,
                  minHeight: 5,
                  backgroundColor: tema.colorScheme.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    bitti ? Colors.teal : tema.colorScheme.primary,
                  ),
                ),
              ),
              if (siradaki != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.arrow_right, size: 16, color: Colors.teal),
                    Expanded(
                      child: Text(
                        'Sırada: ${siradaki.ad}${siradaki.sayfaAraligiMetni.isNotEmpty ? ' (${siradaki.sayfaAraligiMetni})' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
