import 'package:app/core/renkler.dart';
import 'package:app/features/dersler/ders_detay_ekrani.dart';
import 'package:app/features/dersler/dialoglar.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/defterler/defterler_ekrani.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// Dersler sekmesi: Müfredat türüne göre (Klasik'te Temel/Klinik sekmeli, SpeeTUS'ta tek liste).
class DerslerEkrani extends StatefulWidget {
  const DerslerEkrani({super.key});

  @override
  State<DerslerEkrani> createState() => _DerslerEkraniState();
}

class _DerslerEkraniState extends State<DerslerEkrani> {
  DersGrubu _grup = DersGrubu.temel;

  Future<void> _dersEkle(BuildContext context, PlanDeposu depo) async {
    final klasikMi = depo.mufredatTuru == MufredatTuru.klasik;
    final sonuc = await dersEkleDialogu(
      context,
      baslangicGrubu: _grup,
      grupSecimiGoster: klasikMi,
    );
    if (sonuc == null) return;
    final ders = depo.dersEkle(sonuc.ad, sonuc.grup);
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
    final klasikMi = depo.mufredatTuru == MufredatTuru.klasik;
    final liste = klasikMi ? depo.dersler(_grup) : depo.tumDersler;
    final toplamKonu = liste.fold<int>(
      0,
      (toplam, d) => toplam + depo.konuSayisi(d.id),
    );
    final calisilanKonu = liste.fold<int>(
      0,
      (toplam, d) => toplam + depo.calisilanSayisi(d.id),
    );

    final durumMetni = klasikMi
        ? 'Bu grupta $toplamKonu konu · $calisilanKonu çalışıldı'
        : 'Toplam $toplamKonu konu · $calisilanKonu çalışıldı';

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
                    durumMetni,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.rule_folder_outlined, size: 16),
                    label: const Text('Özel Defterler'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DefterlerEkrani(),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => _dersEkle(context, depo),
                    child: const Text('+ Ders ekle'),
                  ),
                ],
              ),
            ],
          ),
          if (klasikMi) ...[
            const SizedBox(height: 16),
            _GrupSecici(
              secili: _grup,
              onSecildi: (g) => setState(() => _grup = g),
            ),
          ],
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
              _DersKarti(
                ders: liste[sira],
                klasikMi: klasikMi,
              ),
            ],
        ],
      ),
    );
  }
}

class _GrupSecici extends StatelessWidget {
  const _GrupSecici({required this.secili, required this.onSecildi});

  final DersGrubu secili;
  final ValueChanged<DersGrubu> onSecildi;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<DersGrubu>(
      segments: const [
        ButtonSegment(value: DersGrubu.temel, label: Text('Temel')),
        ButtonSegment(value: DersGrubu.klinik, label: Text('Klinik')),
      ],
      selected: {secili},
      onSelectionChanged: (yeni) => onSecildi(yeni.first),
    );
  }
}

class _DersKarti extends StatelessWidget {
  const _DersKarti({required this.ders, required this.klasikMi});

  final Ders ders;
  final bool klasikMi;

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final klinik = klasikMi && ders.grup == DersGrubu.klinik;
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
                color: klinik ? klinikYazi(context) : tema.colorScheme.primary,
                backgroundColor: klinik
                    ? klinikZemin(context)
                    : tema.colorScheme.primaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
