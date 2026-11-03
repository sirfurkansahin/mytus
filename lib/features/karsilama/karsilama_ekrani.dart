import 'package:app/core/renkler.dart';
import 'package:app/core/tarih.dart';
import 'package:app/features/dersler/dialoglar.dart';
import 'package:app/features/dersler/hazir_dersler.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// İlk açılış: resmi sınav tarihi (22 Ağustos 2027) ve çalışılacak dersler (onaylı tasarım: Karşılama).
class KarsilamaEkrani extends StatefulWidget {
  const KarsilamaEkrani({super.key});

  @override
  State<KarsilamaEkrani> createState() => _KarsilamaEkraniState();
}

class _KarsilamaEkraniState extends State<KarsilamaEkrani> {
  final DateTime _tarih = resmiSinavTarihi;
  MufredatTuru _seciliMufredat = MufredatTuru.speetus;
  late List<HazirDers> _liste = [...mufredatDersleri(_seciliMufredat)];
  late Set<HazirDers> _secili = {...mufredatDersleri(_seciliMufredat)};
  bool _kaydediliyor = false;

  void _mufredatSec(MufredatTuru yeni) {
    if (_seciliMufredat == yeni) return;
    setState(() {
      _seciliMufredat = yeni;
      final kaynak = mufredatDersleri(yeni);
      _liste = [...kaynak];
      _secili = {...kaynak};
    });
  }

  void _tumunuSecKaldir() {
    setState(() {
      if (_secili.length == _liste.length) {
        _secili.clear();
      } else {
        _secili.addAll(_liste);
      }
    });
  }

  Future<void> _kendiDersimiEkle() async {
    final sonuc = await dersEkleDialogu(
      context,
      grupSecimiGoster: _seciliMufredat == MufredatTuru.klasik,
    );
    if (!mounted || sonuc == null) return;
    final ad = PlanDeposu.adTemizle(sonuc.ad);
    if (ad == null) return;
    final varMi = _liste.any(
      (h) => h.ad.toLowerCase() == ad.toLowerCase(),
    );
    if (varMi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu ders zaten listede.')),
      );
      return;
    }
    final yeni = HazirDers(ad, sonuc.grup);
    setState(() {
      _liste.add(yeni);
      _secili.add(yeni);
    });
  }

  Future<void> _basla(PlanDeposu depo) async {
    if (_secili.isEmpty || _kaydediliyor) return;
    setState(() => _kaydediliyor = true);
    await depo.karsilamayiTamamla(
      sinavTarihi: _tarih,
      secilenDersler: [
        for (final h in _liste)
          if (_secili.contains(h)) h,
      ],
      mufredatTuru: _seciliMufredat,
    );
    // Kayıt bitince depo "karşılama tamam" olur ve ana iskelet kendiliğinden açılır.
  }

  Widget _cip(HazirDers h) {
    final klinik = h.grup == DersGrubu.klinik && _seciliMufredat == MufredatTuru.klasik;
    return FilterChip(
      label: Text(h.ad),
      selected: _secili.contains(h),
      showCheckmark: true,
      selectedColor: klinik
          ? klinikZemin(context)
          : Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: klinik
            ? klinikYazi(context)
            : Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      onSelected: (acik) => setState(() {
        if (acik) {
          _secili.add(h);
        } else {
          _secili.remove(h);
        }
      }),
    );
  }

  Widget _tumDersCipleri() {
    if (_seciliMufredat == MufredatTuru.speetus) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final h in _liste) _cip(h)],
      );
    }
    final temel = _liste.where((h) => h.grup == DersGrubu.temel);
    final klinik = _liste.where((h) => h.grup == DersGrubu.klinik);
    final tema = Theme.of(context);
    final soluk = tema.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (temel.isNotEmpty) ...[
          Text(
            'TEMEL',
            style: tema.textTheme.labelSmall?.copyWith(
              color: soluk,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final h in temel) _cip(h)]),
          const SizedBox(height: 12),
        ],
        if (klinik.isNotEmpty) ...[
          Text(
            'KLİNİK',
            style: tema.textTheme.labelSmall?.copyWith(
              color: soluk,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final h in klinik) _cip(h)]),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final soluk = tema.colorScheme.onSurfaceVariant;
    final kalanGun = gunFarki(_tarih, gunBasi(DateTime.now()));
    final hepsiSecili = _secili.length == _liste.length;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: morAna,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'MY TUS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Çalışma planını kuralım',
                      style: tema.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sınav tarihin hazır. Çalışacağın dersleri seç, '
                      'hepsini sonra değiştirebilirsin.',
                      style: tema.textTheme.bodyMedium?.copyWith(color: soluk),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sınav tarihi',
                      style: tema.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: tema.colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        tarihYaz(_tarih),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      kalanGun > 0
                          ? 'Sınava $kalanGun gün var · Tekrar günleri bu tarihe göre hesaplanır.'
                          : 'Tekrar günleri bu tarihe göre hesaplanır.',
                      style: tema.textTheme.bodySmall?.copyWith(color: soluk),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Çalışma tarzı / Müfredat',
                      style: tema.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<MufredatTuru>(
                      segments: const [
                        ButtonSegment(
                          value: MufredatTuru.klasik,
                          label: Text('Klasik Branşlar'),
                          icon: Icon(Icons.menu_book_outlined),
                        ),
                        ButtonSegment(
                          value: MufredatTuru.speetus,
                          label: Text('SpeeTUS Sarmal'),
                          icon: Icon(Icons.view_timeline_outlined),
                        ),
                      ],
                      selected: {_seciliMufredat},
                      onSelectionChanged: (yeni) => _mufredatSec(yeni.first),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _seciliMufredat.kisaAciklama,
                      style: tema.textTheme.bodySmall?.copyWith(color: soluk),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          'Dersler (${_secili.length} seçili)',
                          style: tema.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: _tumunuSecKaldir,
                          child: Text(
                            hepsiSecili ? 'Tümünü kaldır' : 'Tümünü seç',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _tumDersCipleri(),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _kendiDersimiEkle,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        foregroundColor: tema.colorScheme.primary,
                      ),
                      child: const Text('+ Kendi dersimi ekle'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_secili.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Başlamak için en az bir ders seç.',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.bodySmall?.copyWith(color: soluk),
                      ),
                    ),
                  FilledButton(
                    onPressed: _secili.isEmpty || _kaydediliyor
                        ? null
                        : () => _basla(depo),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Başla'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
