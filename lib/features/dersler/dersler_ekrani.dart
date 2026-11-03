import 'package:app/features/dersler/ders_detay_ekrani.dart';
import 'package:app/features/dersler/dialoglar.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// Dersler sekmesi: SpeeTUS sarmal eğitim paketleri ve ders kartları (tek liste).
class DerslerEkrani extends StatelessWidget {
  const DerslerEkrani({super.key});

  Future<void> _dersEkle(BuildContext context, PlanDeposu depo) async {
    final sonuc = await dersEkleDialogu(context);
    if (sonuc == null) return;
    final ders = depo.dersEkle(sonuc.ad);
    if (ders == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ders adı boş olamaz ve listede tekrar edemez.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final liste = depo.tumDersler;
    final toplamKonu = liste.fold<int>(
      0,
      (toplam, d) => toplam + depo.konuSayisi(d.id),
    );
    final calisilanKonu = liste.fold<int>(
      0,
      (toplam, d) => toplam + depo.calisilanSayisi(d.id),
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dersler',
                    style: tema.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Toplam $toplamKonu konu · $calisilanKonu çalışıldı',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              FilledButton(
                onPressed: () => _dersEkle(context, depo),
                child: const Text('+ Ders ekle'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (liste.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Henüz ders yok. Sağ üstten "+ Ders ekle" ile ekleyebilirsin.',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (var sira = 0; sira < liste.length; sira++) ...[
              if (sira > 0) const SizedBox(height: 8),
              _DersKarti(ders: liste[sira]),
            ],
        ],
      ),
    );
  }
}

class _DersKarti extends StatelessWidget {
  const _DersKarti({required this.ders});

  final Ders ders;

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final toplam = depo.konuSayisi(ders.id);
    final calisilan = depo.calisilanSayisi(ders.id);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tema.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DersDetayEkrani(dersId: ders.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 8,
                runSpacing: 2,
                children: [
                  Text(
                    ders.ad,
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$toplam konu · $calisilan çalışıldı',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: toplam == 0 ? 0 : calisilan / toplam,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
                color: tema.colorScheme.primary,
                backgroundColor: tema.colorScheme.primaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
