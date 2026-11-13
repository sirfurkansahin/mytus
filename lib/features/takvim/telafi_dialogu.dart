import 'package:app/core/tarih.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// Nöbet sonrası "Telafi Planı" penceresi: biriken işleri önizler, onaylanırsa uygular.
/// Geciken tekrarlar "yapıldı" sayılmaz; günlük sınırı aşmadan sonraki günlere yayılır.
Future<void> telafiPlaniDialogu(BuildContext context, DateTime bugun) async {
  final depo = DepoKapsami.oku(context);
  final plan = depo.telafiPlani(bugun);
  if (plan.bos) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Geciken iş yok. Her şey yolunda!')),
      );
    return;
  }
  final son = plan.sonGun;
  final onay = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final tema = Theme.of(ctx);
      return AlertDialog(
        icon: const Icon(Icons.healing_outlined),
        title: const Text('Telafi Planı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.calismaSayisi > 0)
              _Satir(
                ikon: Icons.menu_book_outlined,
                metin: '${plan.calismaSayisi} geciken konu',
              ),
            if (plan.tekrarSayisi > 0)
              _Satir(
                ikon: Icons.replay,
                metin: '${plan.tekrarSayisi} geciken tekrar',
              ),
            const SizedBox(height: 8),
            Text(
              son == null || ayniGun(son, bugun)
                  ? 'Hepsi bugüne sığıyor.'
                  : 'Bugünden ${tarihKisa(son)} tarihine kadar '
                      '${plan.gunSayisi} güne yayılacak.',
              style: tema.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Günde en fazla ${depo.gunlukYeniKonuSiniri} yeni konu ve '
              '${depo.etkinTekrarSiniri(bugun)} tekrar. Tekrarlar "yapıldı" '
              'sayılmaz; ertelenen tekrarın sonraki tekrarları da aynı gün kadar kayar.',
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Planı uygula'),
          ),
        ],
      );
    },
  );
  if (onay != true || !context.mounted) return;
  final n = depo.telafiPlaniUygula(bugun);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text('$n iş önümüzdeki günlere dengeli dağıtıldı.')),
    );
}

class _Satir extends StatelessWidget {
  const _Satir({required this.ikon, required this.metin});

  final IconData ikon;
  final String metin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(ikon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(metin)),
        ],
      ),
    );
  }
}
