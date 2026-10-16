import 'package:app/features/ayarlar/ayar_ogeleri.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/ft_time/ft_kontrol.dart';
import 'package:app/features/ft_time/ft_oturum.dart';
import 'package:app/features/ft_time/ft_sayac_ekrani.dart';
import 'package:app/features/ft_time/ft_timer.dart';
import 'package:app/features/takvim/konu_sec_ekrani.dart';
import 'package:flutter/material.dart';

/// F.T. time sekmesi: oturum yoksa hazırlık, varsa sayaç ekranı.
class FtEkrani extends StatelessWidget {
  const FtEkrani({super.key, required this.kontrol});

  final FtKontrol kontrol;

  @override
  Widget build(BuildContext context) {
    final oturum = DepoKapsami.of(context).oturum;
    if (oturum == null) return FtHazirlik(kontrol: kontrol);
    return FtSayacEkrani(key: ValueKey(oturum.id), kontrol: kontrol);
  }
}

/// Oturum başlamadan önce: konu (isteğe bağlı), döngü sayısı ve süreler.
class FtHazirlik extends StatefulWidget {
  const FtHazirlik({super.key, required this.kontrol});

  final FtKontrol kontrol;

  @override
  State<FtHazirlik> createState() => _FtHazirlikState();
}

class _FtHazirlikState extends State<FtHazirlik> {
  int? _konuId;

  Future<void> _konuSec() async {
    final id = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(builder: (_) => const KonuSecEkrani()),
    );
    if (!mounted || id == null) return;
    setState(() => _konuId = id);
  }

  void _baslat(PlanDeposu depo) {
    widget.kontrol.baslat(
      toplamDongu: depo.ftAyar.donguSayisi,
      konuId: _konuId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final soluk = tema.colorScheme.onSurfaceVariant;
    final ayar = depo.ftAyar;
    final bugun = DateTime.now();
    final konu = _konuId == null ? null : depo.konuBul(_konuId!);
    final ders = konu == null ? null : depo.dersBul(konu.dersId);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        children: [
          Text(
            'F.T. time',
            style: tema.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Ne çalışacağını ve süreleri seç',
            style: tema.textTheme.bodyMedium?.copyWith(color: soluk),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: tema.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _PuanKutusu(
                      etiket: 'Bugün',
                      puan: depo.puanGun(bugun),
                    ),
                  ),
                  Expanded(
                    child: _PuanKutusu(
                      etiket: 'Bu hafta',
                      puan: depo.puanHafta(bugun),
                    ),
                  ),
                  Expanded(
                    child: _PuanKutusu(
                      etiket: 'Toplam',
                      puan: depo.toplamPuan,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Konu (isteğe bağlı)',
            style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: tema.colorScheme.outlineVariant),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(konu?.ad ?? 'Konusuz çalış'),
              subtitle: Text(ders?.ad ?? 'İstersen bir konu seç'),
              trailing: konu == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      tooltip: 'Konuyu kaldır',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _konuId = null),
                    ),
              onTap: _konuSec,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Döngü sayısı',
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SayiSecici(
                etiket: 'Döngü sayısı',
                deger: ayar.donguSayisi,
                enAz: FtAyarlari.donguEnAz,
                enCok: FtAyarlari.donguEnCok,
                onChanged: (v) => depo.ftAyarBelirle(ayar.kopya(donguSayisi: v)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const FtSureAyarlari(),
          const Divider(height: 24),
          Row(
            children: [
              const Expanded(child: Text('Toplam yaklaşık süre')),
              Text(
                dakikaYaz(ayar.toplamDakika(ayar.donguSayisi)),
                style: tema.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Her tamamlanan döngü, çalışma süresi kadar puan kazandırır '
            '(1 dakika = 1 puan). Yarım bırakılan döngü puan getirmez.',
            style: tema.textTheme.bodySmall?.copyWith(color: soluk),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _baslat(depo),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Başlat'),
          ),
        ],
      ),
    );
  }
}

class _PuanKutusu extends StatelessWidget {
  const _PuanKutusu({required this.etiket, required this.puan});

  final String etiket;
  final int puan;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final renk = tema.colorScheme.onPrimaryContainer;
    return Column(
      children: [
        Text(
          '$puan',
          style: tema.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: renk,
          ),
        ),
        Text(
          '$etiket puan',
          style: tema.textTheme.labelMedium?.copyWith(color: renk),
        ),
      ],
    );
  }
}
