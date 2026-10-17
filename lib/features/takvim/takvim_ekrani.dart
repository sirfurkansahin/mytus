import 'package:app/core/renkler.dart';
import 'package:app/core/tarih.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/takvim/konu_sec_ekrani.dart';
import 'package:app/features/takvim/takvim_ogeleri.dart';
import 'package:flutter/material.dart';

/// Takvim sekmesi: ay görünümü, seçili günün listesi ve "+ Konu yerleştir"
/// (onaylı tasarım: Takvim).
class TakvimEkrani extends StatefulWidget {
  const TakvimEkrani({super.key});

  @override
  State<TakvimEkrani> createState() => _TakvimEkraniState();
}

class _TakvimEkraniState extends State<TakvimEkrani> {
  late DateTime _ay;
  late DateTime _secili;

  @override
  void initState() {
    super.initState();
    final simdi = DateTime.now();
    _ay = DateTime(simdi.year, simdi.month);
    _secili = gunBasi(simdi);
  }

  void _ayDegistir(int fark) {
    setState(() => _ay = DateTime(_ay.year, _ay.month + fark));
  }

  void _bugunuSec() {
    final simdi = DateTime.now();
    setState(() {
      _ay = DateTime(simdi.year, simdi.month);
      _secili = gunBasi(simdi);
    });
  }

  Future<void> _konuYerlestir(PlanDeposu depo) async {
    final konuId = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(builder: (_) => const KonuSecEkrani()),
    );
    if (!mounted || konuId == null) return;
    final c = depo.calismaEkle(konuId, _secili);
    if (c == null) return;
    final konu = depo.konuBul(konuId);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${konu?.ad ?? 'Konu'}" ${tarihKisa(_secili)} gününe yerleştirildi.'),
        ),
      );
  }

  Widget _ayIzgarasi(
    Set<int> calismaGunleri,
    Set<int> tekrarGunleri,
    DateTime bugun,
  ) {
    final ilk = DateTime(_ay.year, _ay.month);
    final bosluk = ilk.weekday - 1;
    final gunSayisi = DateTime(_ay.year, _ay.month + 1, 0).day;
    final satirSayisi = (bosluk + gunSayisi + 6) ~/ 7;
    return Column(
      children: [
        for (var satir = 0; satir < satirSayisi; satir++)
          Row(
            children: [
              for (var sutun = 0; sutun < 7; sutun++)
                Expanded(
                  child: _hucre(
                    satir * 7 + sutun - bosluk + 1,
                    gunSayisi,
                    calismaGunleri,
                    tekrarGunleri,
                    bugun,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _hucre(
    int gunNo,
    int gunSayisi,
    Set<int> calismaGunleri,
    Set<int> tekrarGunleri,
    DateTime bugun,
  ) {
    if (gunNo < 1 || gunNo > gunSayisi) return const SizedBox(height: 52);
    final tema = Theme.of(context);
    final gun = DateTime(_ay.year, _ay.month, gunNo);
    final anahtar = gunAnahtari(gun);
    final secili = ayniGun(gun, _secili);
    final bugunMu = ayniGun(gun, bugun);
    final calismaVar = calismaGunleri.contains(anahtar);
    final tekrarVar = tekrarGunleri.contains(anahtar);
    final aciklama = [
      tarihKisa(gun),
      if (bugunMu) 'bugün',
      if (calismaVar) 'planlı konu var',
      if (tekrarVar) 'tekrar var',
    ].join(', ');
    return Semantics(
      label: aciklama,
      button: true,
      selected: secili,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _secili = gun),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: secili ? tema.colorScheme.primaryContainer : null,
            borderRadius: BorderRadius.circular(12),
            border: bugunMu
                ? Border.all(color: tema.colorScheme.primary, width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$gunNo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: secili || bugunMu ? FontWeight.w800 : FontWeight.w500,
                  color: secili
                      ? tema.colorScheme.onPrimaryContainer
                      : tema.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (calismaVar) _nokta(tema.colorScheme.primary),
                    if (calismaVar && tekrarVar) const SizedBox(width: 3),
                    if (tekrarVar) _nokta(tekrarRengi(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nokta(Color renk) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: renk, shape: BoxShape.circle),
      );

  Widget _aciklama(Color renk, String yazi) {
    final tema = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _nokta(renk),
        const SizedBox(width: 6),
        Text(
          yazi,
          style: tema.textTheme.bodySmall?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final bugun = gunBasi(DateTime.now());
    final tekrarlar = depo.tekrarlar(bugun);
    final calismalar = depo.tumCalismalar();
    final calismaGunleri = {for (final c in calismalar) gunAnahtari(c.tarih)};
    final tekrarGunleri = {for (final t in tekrarlar) gunAnahtari(t.tarih)};

    final gunCalismalari = depo.calismalarGun(_secili);
    final gunTekrarlari = [
      for (final t in tekrarlar)
        if (ayniGun(t.tarih, _secili)) t,
    ];
    final sonGun = depo.sinavTarihi == null
        ? null
        : gunEkle(gunBasi(depo.sinavTarihi!), -1);
    final gecmisGun = _secili.isBefore(bugun);
    final sinavdanSonra = sonGun != null && _secili.isAfter(sonGun);
    final yerlestirilebilir = !gecmisGun && !sinavdanSonra;
    final bugunMu = ayniGun(_secili, bugun);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Önceki ay',
                onPressed: () => _ayDegistir(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${ayAdi(_ay.month)} ${_ay.year}',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Sonraki ay',
                onPressed: () => _ayDegistir(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              for (final ad in haftaGunleriKisa)
                Expanded(
                  child: Center(
                    child: Text(
                      ad,
                      style: tema.textTheme.labelMedium?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          _ayIzgarasi(calismaGunleri, tekrarGunleri, bugun),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 0,
            children: [
              _aciklama(tema.colorScheme.primary, 'Planlı konu'),
              _aciklama(tekrarRengi(context), 'Tekrar'),
              TextButton(onPressed: _bugunuSec, child: const Text('Bugüne git')),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  bugunMu
                      ? '${tarihKisa(_secili)} · Bugün'
                      : gunAdiIleTarih(_secili),
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FilledButton.tonal(
                onPressed: yerlestirilebilir ? () => _konuYerlestir(depo) : null,
                child: const Text('+ Konu yerleştir'),
              ),
            ],
          ),
          if (!yerlestirilebilir)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                gecmisGun
                    ? 'Geçmiş güne konu yerleştirilemez.'
                    : 'Sınav tarihinden sonraya konu yerleştirilemez.',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (gunCalismalari.isNotEmpty) const BolumBasligi(baslik: 'Konular'),
          for (final c in gunCalismalari) ...[
            CalismaSatiri(calisma: c, bugun: bugun),
            const SizedBox(height: 8),
          ],
          if (gunTekrarlari.isNotEmpty) const BolumBasligi(baslik: 'Tekrarlar'),
          for (final t in gunTekrarlari) ...[
            TekrarSatiri(tekrar: t, bugun: bugun),
            const SizedBox(height: 8),
          ],
          if (gunCalismalari.isEmpty && gunTekrarlari.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Bu güne planlanmış bir şey yok.',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
