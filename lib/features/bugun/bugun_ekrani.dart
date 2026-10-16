import 'package:app/core/tarih.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// Geçici "Bugün" ekranı: sınava kalan gün ve sınav tarihini değiştirme.
/// Günün planı ve tekrarlar takvim parçasında gelecek.
class BugunEkrani extends StatelessWidget {
  const BugunEkrani({super.key});

  Future<void> _tarihDegistir(BuildContext context, PlanDeposu depo) async {
    final bugun = DateTime.now();
    final ilk = DateTime(bugun.year, bugun.month, bugun.day);
    final mevcut = depo.sinavTarihi;
    final secilen = await showDatePicker(
      context: context,
      initialDate: mevcut != null && !mevcut.isBefore(ilk)
          ? mevcut
          : ilk.add(const Duration(days: 90)),
      firstDate: ilk,
      lastDate: DateTime(ilk.year + 3, ilk.month, ilk.day),
      helpText: 'Sınav tarihi',
    );
    if (secilen != null) depo.sinavTarihiBelirle(secilen);
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final sinav = depo.sinavTarihi;
    final kalan = sinav == null ? null : gunFarki(sinav, DateTime.now());
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bugün',
              style: tema.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: tema.colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kalan == null
                          ? 'Sınav tarihi seçilmedi'
                          : kalan > 0
                              ? 'Sınava $kalan gün kaldı'
                              : kalan == 0
                                  ? 'Sınav bugün'
                                  : 'Sınav tarihi geçti',
                      style: tema.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: tema.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    if (sinav != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        tarihYaz(sinav),
                        style: tema.textTheme.bodyMedium?.copyWith(
                          color: tema.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _tarihDegistir(context, depo),
                      child: const Text('Sınav tarihini değiştir'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bugünün planı ve tekrarlar, takvim hazır olunca burada görünecek.',
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
