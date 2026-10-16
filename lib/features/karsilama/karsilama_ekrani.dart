import 'package:app/core/renkler.dart';
import 'package:app/core/tarih.dart';
import 'package:app/features/dersler/dialoglar.dart';
import 'package:app/features/dersler/hazir_dersler.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// İlk açılış: sınav tarihi ve çalışılacak dersler (onaylı tasarım: Karşılama).
class KarsilamaEkrani extends StatefulWidget {
  const KarsilamaEkrani({super.key});

  @override
  State<KarsilamaEkrani> createState() => _KarsilamaEkraniState();
}

class _KarsilamaEkraniState extends State<KarsilamaEkrani> {
  DateTime? _tarih;
  late final List<HazirDers> _liste = [...hazirDersler];
  late final Set<HazirDers> _secili = {...hazirDersler};
  bool _kaydediliyor = false;

  Future<void> _tarihSec() async {
    final bugun = DateTime.now();
    final ilk = DateTime(bugun.year, bugun.month, bugun.day);
    final secilen = await showDatePicker(
      context: context,
      initialDate: _tarih ?? ilk.add(const Duration(days: 90)),
      firstDate: ilk,
      lastDate: DateTime(ilk.year + 3, ilk.month, ilk.day),
      helpText: 'Sınav tarihi',
    );
    if (!mounted || secilen == null) return;
    setState(() => _tarih = secilen);
  }

  Future<void> _kendiDersimiEkle() async {
    final sonuc = await dersEkleDialogu(context);
    if (!mounted || sonuc == null) return;
    final ad = PlanDeposu.adTemizle(sonuc.ad);
    if (ad == null) return;
    final varMi = _liste.any(
      (h) => h.grup == sonuc.grup && h.ad.toLowerCase() == ad.toLowerCase(),
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
    final tarih = _tarih;
    if (tarih == null || _kaydediliyor) return;
    setState(() => _kaydediliyor = true);
    await depo.karsilamayiTamamla(
      sinavTarihi: tarih,
      secilenDersler: [
        for (final h in _liste)
          if (_secili.contains(h)) h,
      ],
    );
    // Kayıt bitince depo "karşılama tamam" olur ve ana iskelet kendiliğinden açılır.
  }

  Widget _dersCipleri(DersGrubu grup) {
    final temel = grup == DersGrubu.temel;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final h in _liste)
          if (h.grup == grup)
            FilterChip(
              label: Text(h.ad),
              selected: _secili.contains(h),
              showCheckmark: true,
              selectedColor: temel
                  ? Theme.of(context).colorScheme.primaryContainer
                  : klinikZemin(context),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: temel
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : klinikYazi(context),
              ),
              onSelected: (acik) => setState(() {
                if (acik) {
                  _secili.add(h);
                } else {
                  _secili.remove(h);
                }
              }),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final soluk = tema.colorScheme.onSurfaceVariant;
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
                      'İki şey yeterli: sınav tarihin ve çalışacağın dersler. '
                      'Hepsini sonra değiştirebilirsin.',
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
                    OutlinedButton(
                      onPressed: _tarihSec,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        alignment: Alignment.centerLeft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _tarih == null ? 'Tarih seç' : tarihYaz(_tarih!),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tekrar günleri bu tarihe göre hesaplanır.',
                      style: tema.textTheme.bodySmall?.copyWith(color: soluk),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Dersler',
                      style: tema.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'TEMEL',
                      style: tema.textTheme.labelMedium?.copyWith(
                        color: soluk,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _dersCipleri(DersGrubu.temel),
                    const SizedBox(height: 16),
                    Text(
                      'KLİNİK',
                      style: tema.textTheme.labelMedium?.copyWith(
                        color: soluk,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _dersCipleri(DersGrubu.klinik),
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
                  if (_tarih == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Başlamak için önce sınav tarihini seç.',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.bodySmall?.copyWith(color: soluk),
                      ),
                    ),
                  FilledButton(
                    onPressed: _tarih == null || _kaydediliyor
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
