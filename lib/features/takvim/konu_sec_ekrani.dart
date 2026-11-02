import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// Takvime yerleştirilecek konuyu seçtirir. Üstteki arama kutusuyla konular
/// doğrudan filtrelenebilir; arama boşken ders grupları altında listelenir.
class KonuSecEkrani extends StatefulWidget {
  const KonuSecEkrani({super.key});

  @override
  State<KonuSecEkrani> createState() => _KonuSecEkraniState();
}

class _KonuSecEkraniState extends State<KonuSecEkrani> {
  String _arama = '';

  Widget? _durumYazisi(BuildContext context, PlanDeposu depo, int konuId) {
    final sayi = depo.calismalarKonu(konuId).length;
    if (sayi == 0) return null;
    final tema = Theme.of(context);
    return Text(
      depo.konuCalisildi(konuId) ? 'çalışıldı · $sayi tur' : 'planlı · $sayi tur',
      style: tema.textTheme.bodySmall?.copyWith(
        color: tema.colorScheme.onSurfaceVariant,
      ),
    );
  }

  List<Widget> _aramaSonuclari(
    BuildContext context,
    PlanDeposu depo,
    String sorgu,
  ) {
    final kucuk = sorgu.toLowerCase();
    final sonuclar = <Widget>[];
    for (final grup in DersGrubu.values) {
      for (final ders in depo.dersler(grup)) {
        final dersEslesir = ders.ad.toLowerCase().contains(kucuk);
        for (final konu in depo.konular(ders.id)) {
          if (dersEslesir || konu.ad.toLowerCase().contains(kucuk)) {
            sonuclar.add(
              ListTile(
                title: Text(
                  konu.ad,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${ders.ad} · ${grup.ad}'),
                trailing: _durumYazisi(context, depo, konu.id),
                onTap: () => Navigator.of(context).pop(konu.id),
              ),
            );
          }
        }
      }
    }
    return sonuclar;
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final grupOgeleri = <Widget>[];
    var konuVar = false;
    for (final grup in DersGrubu.values) {
      final dersler = depo.dersler(grup);
      if (dersler.isEmpty) continue;
      grupOgeleri.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            grup.ad.toUpperCase(),
            style: tema.textTheme.labelMedium?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
      );
      for (final ders in dersler) {
        final konular = depo.konular(ders.id);
        if (konular.isNotEmpty) konuVar = true;
        grupOgeleri.add(
          ExpansionTile(
            title: Text(
              ders.ad,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${konular.length} konu'),
            children: [
              if (konular.isEmpty)
                const ListTile(
                  title: Text('Bu derste henüz konu yok. Dersler sekmesinden ekle.'),
                ),
              for (final konu in konular)
                ListTile(
                  title: Text(konu.ad),
                  trailing: _durumYazisi(context, depo, konu.id),
                  onTap: () => Navigator.of(context).pop(konu.id),
                ),
            ],
          ),
        );
      }
    }

    final sorgu = _arama.trim();
    final araniyor = sorgu.isNotEmpty;
    final bulunanlar =
        araniyor ? _aramaSonuclari(context, depo, sorgu) : const <Widget>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Konu seç')),
      body: !konuVar
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Henüz hiç konu yok. Önce Dersler sekmesinden bir derse konu ekle.',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: TextField(
                    onChanged: (deger) => setState(() => _arama = deger),
                    decoration: InputDecoration(
                      hintText: 'Konu veya ders ara...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: araniyor
                      ? (bulunanlar.isEmpty
                          ? Center(
                              child: Text(
                                'Eşleşen konu bulunamadı.',
                                style: tema.textTheme.bodyMedium?.copyWith(
                                  color: tema.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView(children: bulunanlar))
                      : ListView(children: grupOgeleri),
                ),
              ],
            ),
    );
  }
}
