import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// Takvime yerleştirilecek ders veya konuları seçtirir.
/// İki sekme sunar:
/// 1. "Dersler (Toplu Ekle)": Birden çok dersi tek seferde seçip tüm konularıyla takvime ekleme.
/// 2. "Konular": Konu bazlı inceleme, filtreleme ve tekil/çoklu seçim.
class KonuSecEkrani extends StatefulWidget {
  const KonuSecEkrani({
    super.key,
    this.baslangicSekmesi = 0,
    this.cokluSecim = true,
  });

  final int baslangicSekmesi;
  final bool cokluSecim;

  @override
  State<KonuSecEkrani> createState() => _KonuSecEkraniState();
}

class _KonuSecEkraniState extends State<KonuSecEkrani>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<int> _seciliKonuIdleri = {};
  String _arama = '';
  final _aramaDenetci = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.baslangicSekmesi.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aramaDenetci.dispose();
    super.dispose();
  }

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

  void _konuSeciminiDegistir(int konuId) {
    setState(() {
      if (_seciliKonuIdleri.contains(konuId)) {
        _seciliKonuIdleri.remove(konuId);
      } else {
        _seciliKonuIdleri.add(konuId);
      }
    });
  }

  void _dersSeciminiDegistir(PlanDeposu depo, Ders ders) {
    final konular = depo.dersinKonulariniGetirVeyaOlustur(ders.id);
    final konuIdleri = konular.map((k) => k.id).toSet();
    final hepsiSecili = konuIdleri.isNotEmpty &&
        konuIdleri.every((id) => _seciliKonuIdleri.contains(id));

    setState(() {
      if (hepsiSecili) {
        _seciliKonuIdleri.removeAll(konuIdleri);
      } else {
        _seciliKonuIdleri.addAll(konuIdleri);
      }
    });
  }

  void _gruptakiTumDersleriSec(PlanDeposu depo, DersGrubu grup) {
    final dersler = depo.dersler(grup);
    final eklenecekler = <int>{};
    for (final d in dersler) {
      final konular = depo.dersinKonulariniGetirVeyaOlustur(d.id);
      eklenecekler.addAll(konular.map((k) => k.id));
    }
    setState(() => _seciliKonuIdleri.addAll(eklenecekler));
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
            final secili = _seciliKonuIdleri.contains(konu.id);
            sonuclar.add(
              ListTile(
                leading: SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: secili,
                    onChanged: (_) => _konuSeciminiDegistir(konu.id),
                  ),
                ),
                title: Text(
                  konu.ad,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${ders.ad} · ${grup.ad}'),
                trailing: _durumYazisi(context, depo, konu.id),
                onTap: () {
                  if (_seciliKonuIdleri.isNotEmpty) {
                    _konuSeciminiDegistir(konu.id);
                  } else {
                    Navigator.of(context).pop(konu.id);
                  }
                },
              ),
            );
          }
        }
      }
    }
    return sonuclar;
  }

  Widget _derslerSekmesi(BuildContext context, PlanDeposu depo) {
    final tema = Theme.of(context);
    final liste = <Widget>[];

    // Üst Hızlı Seçim Butonları
    liste.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ActionChip(
              avatar: const Icon(Icons.biotech_outlined, size: 16),
              label: const Text('Tüm Temel Bilimler'),
              visualDensity: VisualDensity.compact,
              onPressed: () => _gruptakiTumDersleriSec(depo, DersGrubu.temel),
            ),
            ActionChip(
              avatar: const Icon(Icons.local_hospital_outlined, size: 16),
              label: const Text('Tüm Klinik Bilimler'),
              visualDensity: VisualDensity.compact,
              onPressed: () => _gruptakiTumDersleriSec(depo, DersGrubu.klinik),
            ),
            if (_seciliKonuIdleri.isNotEmpty)
              ActionChip(
                avatar: const Icon(Icons.clear_all, size: 16),
                label: const Text('Seçimi Temizle'),
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _seciliKonuIdleri.clear()),
              ),
          ],
        ),
      ),
    );

    for (final grup in DersGrubu.values) {
      final dersler = depo.dersler(grup);
      if (dersler.isEmpty) continue;

      liste.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Icon(
                grup == DersGrubu.temel
                    ? Icons.biotech_outlined
                    : Icons.local_hospital_outlined,
                size: 18,
                color: tema.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${grup.ad.toUpperCase()} BİLİMLER',
                style: tema.textTheme.labelMedium?.copyWith(
                  color: tema.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      );

      for (final ders in dersler) {
        final konular = depo.konular(ders.id);
        final dersKonuIdleri = konular.map((k) => k.id).toSet();
        final seciliSayisi = dersKonuIdleri.intersection(_seciliKonuIdleri).length;
        final hepsiSecili =
            dersKonuIdleri.isNotEmpty && seciliSayisi == dersKonuIdleri.length;
        final bool? tristateDeger = dersKonuIdleri.isEmpty
            ? false
            : (hepsiSecili ? true : (seciliSayisi > 0 ? null : false));

        final tamamlananSayisi =
            konular.where((k) => depo.konuCalisildi(k.id)).length;
        final kalanSayisi = konular.length - tamamlananSayisi;

        liste.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: hepsiSecili
                      ? tema.colorScheme.primary
                      : (seciliSayisi > 0
                          ? tema.colorScheme.primary.withValues(alpha: 0.5)
                          : tema.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  width: hepsiSecili ? 1.5 : 1,
                ),
              ),
              color: hepsiSecili
                  ? tema.colorScheme.primaryContainer.withValues(alpha: 0.25)
                  : (seciliSayisi > 0
                      ? tema.colorScheme.primaryContainer.withValues(alpha: 0.1)
                      : null),
              child: ListTile(
                onTap: () => _dersSeciminiDegistir(depo, ders),
                leading: SizedBox(
                  width: 32,
                  height: 32,
                  child: Checkbox(
                    tristate: true,
                    value: tristateDeger,
                    onChanged: (_) => _dersSeciminiDegistir(depo, ders),
                  ),
                ),
                title: Text(
                  ders.ad,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                subtitle: Text(
                  konular.isEmpty
                      ? 'Genel çalışma konusu oluşturulacak'
                      : '${konular.length} konu · $kalanSayisi kalan (${tamamlananSayisi} çalışıldı)',
                  style: TextStyle(
                    fontSize: 12,
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: seciliSayisi > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tema.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$seciliSayisi konu seçili',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: tema.colorScheme.primary,
                          ),
                        ),
                      )
                    : const Icon(Icons.chevron_right, size: 20),
              ),
            ),
          ),
        );
      }
    }

    liste.add(const SizedBox(height: 80));
    return ListView(children: liste);
  }

  Widget _konularSekmesi(BuildContext context, PlanDeposu depo) {
    final tema = Theme.of(context);
    final grupOgeleri = <Widget>[];

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
        final dersKonuIdleri = konular.map((k) => k.id).toSet();
        final seciliSayisi =
            dersKonuIdleri.intersection(_seciliKonuIdleri).length;
        final hepsiSecili =
            dersKonuIdleri.isNotEmpty && seciliSayisi == dersKonuIdleri.length;

        grupOgeleri.add(
          ExpansionTile(
            title: Text(
              ders.ad,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              seciliSayisi > 0
                  ? '${konular.length} konu · $seciliSayisi seçili'
                  : '${konular.length} konu',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (konular.isNotEmpty)
                  TextButton(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () => _dersSeciminiDegistir(depo, ders),
                    child: Text(
                      hepsiSecili ? 'Kaldır' : 'Dersi Seç',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                const Icon(Icons.expand_more),
              ],
            ),
            children: [
              if (konular.isEmpty)
                ListTile(
                  title: const Text('Bu derste henüz konu yok. Genel konu eklenebilir.'),
                  trailing: TextButton(
                    onPressed: () => _dersSeciminiDegistir(depo, ders),
                    child: const Text('Konu Oluştur ve Ekle'),
                  ),
                ),
              for (final konu in konular) ...[
                ListTile(
                  dense: true,
                  leading: SizedBox(
                    width: 28,
                    height: 28,
                    child: Checkbox(
                      value: _seciliKonuIdleri.contains(konu.id),
                      onChanged: (_) => _konuSeciminiDegistir(konu.id),
                    ),
                  ),
                  title: Text(
                    konu.ad,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: _durumYazisi(context, depo, konu.id),
                  onTap: () {
                    if (_seciliKonuIdleri.isNotEmpty) {
                      _konuSeciminiDegistir(konu.id);
                    } else {
                      // Çoklu seçimde henüz eleman seçilmemişken doğrudan konuya dokunulursa:
                      // Eski davranışla tam uyumlu hızlı tekil yerleştirme
                      Navigator.of(context).pop(konu.id);
                    }
                  },
                ),
              ],
            ],
          ),
        );
      }
    }

    grupOgeleri.add(const SizedBox(height: 80));

    final sorgu = _arama.trim();
    final araniyor = sorgu.isNotEmpty;
    final bulunanlar =
        araniyor ? _aramaSonuclari(context, depo, sorgu) : const <Widget>[];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: TextField(
            controller: _aramaDenetci,
            onChanged: (deger) => setState(() => _arama = deger),
            decoration: InputDecoration(
              hintText: 'Konu veya ders ara...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _arama.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _aramaDenetci.clear();
                        setState(() => _arama = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget? _altSecimBari(BuildContext context, PlanDeposu depo) {
    if (!widget.cokluSecim || _seciliKonuIdleri.isEmpty) return null;
    final tema = Theme.of(context);
    final seciliDersIdleri = _seciliKonuIdleri
        .map((kId) => depo.konuBul(kId)?.dersId)
        .whereType<int>()
        .toSet();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${seciliDersIdleri.length} ders · ${_seciliKonuIdleri.length} konu seçildi',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  InkWell(
                    onTap: () => setState(() => _seciliKonuIdleri.clear()),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Seçimi Temizle',
                        style: TextStyle(
                          fontSize: 12,
                          color: tema.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.calendar_month, size: 18),
              label: const Text('Takvime Ekle'),
              onPressed: () =>
                  Navigator.of(context).pop(_seciliKonuIdleri.toList()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final tumDersler = depo.tumDersler;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Takvime Ders / Konu Ekle'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: tema.colorScheme.primary,
          unselectedLabelColor: tema.colorScheme.onSurfaceVariant,
          indicatorColor: tema.colorScheme.primary,
          tabs: const [
            Tab(
              icon: Icon(Icons.list_alt, size: 20),
              text: 'Konular',
            ),
            Tab(
              icon: Icon(Icons.library_add_check_outlined, size: 20),
              text: 'Dersler (Toplu Ekle)',
            ),
          ],
        ),
      ),
      body: tumDersler.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Henüz kayıtlı ders bulunamadı.',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _konularSekmesi(context, depo),
                _derslerSekmesi(context, depo),
              ],
            ),
      bottomNavigationBar: _altSecimBari(context, depo),
    );
  }
}
