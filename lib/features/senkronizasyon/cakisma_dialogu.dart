import 'package:app/features/senkronizasyon/bulut_senkron_servisi.dart';
import 'package:flutter/material.dart';

/// Girişte hem bu cihazda hem hesapta (bulutta) birbirinden farklı veri varsa
/// hangisiyle devam edileceğini sorar (DECISIONS: "İkisinde de varsa kullanıcıya
/// sorulur; seçilmeyen taraf cihazda yedek olarak saklanır").
/// true: bu cihazdaki veri kalır; false: hesaptaki (bulut) veri kalır.
Future<bool> cakismaDialoguGoster(
  BuildContext context,
  SenkronCakismasi cakisma,
) async {
  final sonuc = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        key: const ValueKey('cakisma_dialogu'),
        title: const Text('Hangi veriler kalsın?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bu cihazda da hesabında da çalışma verisi var ve birbirinden '
                'farklı. Hangisiyle devam edelim?',
              ),
              const SizedBox(height: 12),
              _SecenekOzeti(
                baslik: 'Hesabındaki (bulut)',
                ozet: cakisma.bulutOzet,
              ),
              const SizedBox(height: 8),
              _SecenekOzeti(baslik: 'Bu cihazdaki', ozet: cakisma.yerelOzet),
              const SizedBox(height: 12),
              const Text(
                'Seçmediğin veri silinmez: bu cihazda yedek olarak saklanır, '
                'Ayarlar\'daki hesap kartından geri getirebilirsin.',
                style: TextStyle(fontSize: 12.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const ValueKey('cakisma_cihazdaki'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Bu cihazdakini kullan'),
          ),
          FilledButton(
            key: const ValueKey('cakisma_buluttaki'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hesabımdakini kullan'),
          ),
        ],
      ),
    ),
  );
  return sonuc ?? false;
}

class _SecenekOzeti extends StatelessWidget {
  const _SecenekOzeti({required this.baslik, required this.ozet});

  final String baslik;
  final String ozet;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            baslik,
            style: tema.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(ozet, style: tema.textTheme.bodySmall),
        ],
      ),
    );
  }
}
