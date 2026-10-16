import 'package:app/core/renkler.dart';
import 'package:app/features/dersler/dialoglar.dart';
import 'package:app/features/dersler/ders_detay_ekrani.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// Dersler sekmesi: Temel / Klinik grupları ve ders kartları (onaylı tasarım: Dersler).
class DerslerEkrani extends StatefulWidget {
  const DerslerEkrani({super.key});

  @override
  State<DerslerEkrani> createState() => _DerslerEkraniState();
}

class _DerslerEkraniState extends State<DerslerEkrani> {
  DersGrubu _grup = DersGrubu.temel;

  Future<void> _dersEkle(PlanDeposu depo) async {
    final sonuc = await dersEkleDialogu(context, baslangicGrubu: _grup);
    if (!mounted || sonuc == null) return;
    final ders = depo.dersEkle(sonuc.ad, sonuc.grup);
    if (ders == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ders adı boş olamaz ve aynı grupta tekrar edemez.'),
        ),
      );
      return;
    }
    setState(() => _grup = sonuc.grup);
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final liste = depo.dersler(_grup);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Dersler',
                    style: tema.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () => _dersEkle(depo),
                  child: const Text('+ Ders ekle'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _GrupSecici(
              secili: _grup,
              degisti: (g) => setState(() => _grup = g),
            ),
          ),
          Expanded(
            child: liste.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Bu grupta henüz ders yok. Sağ üstten "+ Ders ekle" ile '
                      'ekleyebilirsin.',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: liste.length,
                    separatorBuilder: (context, sira) => const SizedBox(height: 8),
                    itemBuilder: (_, sira) => _DersKarti(ders: liste[sira]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GrupSecici extends StatelessWidget {
  const _GrupSecici({required this.secili, required this.degisti});

  final DersGrubu secili;
  final ValueChanged<DersGrubu> degisti;

  @override
  Widget build(BuildContext context) {
    final renkler = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: renkler.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final grup in DersGrubu.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: secili == grup,
                child: Material(
                  color: secili == grup ? renkler.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => degisti(grup),
                    child: SizedBox(
                      height: 44,
                      child: Center(
                        child: Text(
                          grup.ad,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                secili == grup ? FontWeight.w700 : FontWeight.w600,
                            color: secili == grup
                                ? renkler.primary
                                : renkler.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
    final klinik = ders.grup == DersGrubu.klinik;
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      ders.ad,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                color: klinik ? klinikYazi(context) : tema.colorScheme.primary,
                backgroundColor:
                    klinik ? klinikZemin(context) : tema.colorScheme.primaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
