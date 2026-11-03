import 'package:app/core/tarih.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/denemeler/denemeler_ekrani.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:app/features/ilerleme/ilerleme_hesabi.dart';
import 'package:app/features/kokpit/kokpit_ekrani.dart';
import 'package:flutter/material.dart';

/// İlerleme: haftalık özet, günlük odak grafiği ve en çok çalışılan dersler
/// (onaylı tasarım: İlerleme). Sürüm 1'de yalnızca kendi verin gösterilir.
class IlerlemeEkrani extends StatefulWidget {
  const IlerlemeEkrani({super.key});

  @override
  State<IlerlemeEkrani> createState() => _IlerlemeEkraniState();
}

class _IlerlemeEkraniState extends State<IlerlemeEkrani> {
  late DateTime _hafta = haftaBasi(DateTime.now());

  void _git(int hafta) => setState(() => _hafta = gunEkle(_hafta, 7 * hafta));

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final soluk = tema.colorScheme.onSurfaceVariant;
    final bugun = gunBasi(DateTime.now());
    final buHafta = haftaBasi(bugun);
    final ozet = haftaOzetiHesapla(depo, _hafta);
    final genel = genelIlerlemeHesapla(depo, bugun);
    final suAnki = ayniGun(_hafta, buHafta);
    final enCok = ozet.gunlukDakika.fold<int>(0, (a, b) => a > b ? a : b);
    final enUstDers = ozet.dersler.isEmpty ? 0 : ozet.dersler.first.dakika;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlerleme'),
        actions: [
          if (!suAnki)
            TextButton(
              onPressed: () => setState(() => _hafta = buHafta),
              child: const Text('Bu haftaya dön'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: tema.colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
            color: tema.colorScheme.primary.withValues(alpha: 0.08),
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const KokpitEkrani()),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.dashboard_customize_outlined,
                      color: tema.colorScheme.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Master Yönetim Kokpiti',
                            style: tema.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: tema.colorScheme.primary,
                            ),
                          ),
                          Text(
                            '8 Bilişsel Gösterge & "Eğer–O Zaman" Kararları',
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: soluk,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: tema.colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: tema.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Genel konu ilerlemesi',
                        style: tema.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (genel.seriGun > 0)
                        Text(
                          '${genel.seriGun} gün seri',
                          style: tema.textTheme.labelMedium?.copyWith(
                            color: tema.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${genel.calisilanKonu} / ${genel.toplamKonu} konu (%${genel.yuzde})'
                    ' · ${genel.toplamTekrar} tekrar tamamlandı',
                    style: tema.textTheme.bodySmall?.copyWith(color: soluk),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: genel.oran,
                      minHeight: 7,
                      backgroundColor: tema.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DenemelerIlerlemeKarti(
            denemeSayisi: depo.denemeler.length,
            sonDeneme: depo.denemeler.isNotEmpty ? depo.denemeler.first : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                tooltip: 'Önceki hafta',
                onPressed: () => _git(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      suAnki ? 'Bu hafta' : haftaAraligiYaz(_hafta),
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (suAnki)
                      Text(
                        haftaAraligiYaz(_hafta),
                        style: tema.textTheme.bodySmall?.copyWith(color: soluk),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Sonraki hafta',
                onPressed: suAnki ? null : () => _git(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Kutu(deger: '${ozet.calisilanKonu}', etiket: 'Çalışılan konu'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Kutu(deger: '${ozet.bitenDongu}', etiket: 'Biten döngü'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Kutu(
                  deger: odakSuresiYaz(ozet.odakDakika),
                  etiket: 'Odak süresi',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${ozet.puan} puan kazandın (1 dakika = 1 puan)',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodyMedium?.copyWith(
              color: tema.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bu hafta ${ozet.bitenTekrar} tekrar bitti · ${ozet.aktifGun} aktif gün',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodySmall?.copyWith(color: soluk),
          ),
          const SizedBox(height: 24),
          Text(
            'Günlük odak süresi (dk)',
            style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: _Cubuk(
                      gun: haftaGunleriKisa[i],
                      dakika: ozet.gunlukDakika[i],
                      enCok: enCok,
                      bugunMu: ayniGun(gunEkle(_hafta, i), bugun),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'En çok çalışılan dersler',
            style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (ozet.dersler.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                ozet.bos
                    ? 'Bu hafta henüz kayıt yok. F.T. time ile bir konu seçip odaklan; dersler burada görünür.'
                    : 'Bu hafta konu seçerek yapılmış odak yok. F.T. time\'da konu seçersen dersler burada görünür.',
                style: tema.textTheme.bodyMedium?.copyWith(color: soluk),
              ),
            ),
          for (final d in ozet.dersler.take(5)) ...[
            _DersSatiri(ders: d, enUst: enUstDers),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _Kutu extends StatelessWidget {
  const _Kutu({required this.deger, required this.etiket});

  final String deger;
  final String etiket;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final renk = tema.colorScheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: tema.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              deger,
              style: tema.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: renk,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiket,
            textAlign: TextAlign.center,
            style: tema.textTheme.labelSmall?.copyWith(color: renk),
          ),
        ],
      ),
    );
  }
}

class _Cubuk extends StatelessWidget {
  const _Cubuk({
    required this.gun,
    required this.dakika,
    required this.enCok,
    required this.bugunMu,
  });

  final String gun;
  final int dakika;
  final int enCok;
  final bool bugunMu;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    // Çubuk alanı 160 - yazı alanları (üst 18, alt 22) kadar yüksekliğe ölçeklenir.
    const alan = 110.0;
    final yukseklik = enCok == 0 || dakika == 0 ? 3.0 : (dakika / enCok) * alan;
    return Semantics(
      label: '$gun: $dakika dakika',
      excludeSemantics: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 18,
            child: Text(
              dakika == 0 ? '' : '$dakika',
              style: tema.textTheme.labelSmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            width: 22,
            height: yukseklik,
            decoration: BoxDecoration(
              color: dakika == 0
                  ? tema.colorScheme.outlineVariant
                  : tema.colorScheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 16,
            child: Text(
              gun,
              style: tema.textTheme.labelMedium?.copyWith(
                fontWeight: bugunMu ? FontWeight.w800 : FontWeight.w500,
                color: bugunMu
                    ? tema.colorScheme.primary
                    : tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DersSatiri extends StatelessWidget {
  const _DersSatiri({required this.ders, required this.enUst});

  final DersOzeti ders;
  final int enUst;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final oran = enUst == 0 ? 0.0 : ders.dakika / enUst;
    return Semantics(
      label: '${ders.ad}: ${odakSuresiYaz(ders.dakika)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ders.ad,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                odakSuresiYaz(ders.dakika),
                style: tema.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: oran,
              minHeight: 8,
              backgroundColor: tema.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}


class _DenemelerIlerlemeKarti extends StatelessWidget {
  const _DenemelerIlerlemeKarti({
    required this.denemeSayisi,
    this.sonDeneme,
  });

  final int denemeSayisi;
  final DenemeSinavi? sonDeneme;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final soluk = tema.colorScheme.onSurfaceVariant;

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
          MaterialPageRoute<void>(builder: (_) => const DenemelerEkrani()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tema.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.assignment_outlined, color: tema.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deneme Sınavları & Net Analizi',
                      style: tema.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sonDeneme != null
                          ? 'Son:  ( net · ~ Puan)'
                          : 'Henüz deneme girilmedi. Eklemek için dokun.',
                      style: tema.textTheme.bodySmall?.copyWith(color: soluk),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
