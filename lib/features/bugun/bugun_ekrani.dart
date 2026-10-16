import 'package:app/core/tarih.dart';
import 'package:app/features/ayarlar/ayarlar_ekrani.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/takvim/takvim_ogeleri.dart';
import 'package:flutter/material.dart';

/// "Bugün" ekranı: geciken işler, bugünün planı, bugünkü tekrarlar ve sınav sayacı.
class BugunEkrani extends StatelessWidget {
  const BugunEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final soluk = tema.colorScheme.onSurfaceVariant;
    final bugun = gunBasi(DateTime.now());
    final sinav = depo.sinavTarihi;
    final kalan = sinav == null ? null : gunFarki(sinav, bugun);

    final tumCalismalar = depo.tumCalismalar();
    final tumTekrarlar = depo.tekrarlar(bugun);

    final gecikenCalismalar = [
      for (final c in tumCalismalar)
        if (!c.tamam && c.tarih.isBefore(bugun)) c,
    ];
    final gecikenTekrarlar = [
      for (final t in tumTekrarlar)
        if (t.eylemYapilabilir && t.tarih.isBefore(bugun)) t,
    ];
    final bugunCalismalari = [
      for (final c in tumCalismalar)
        if (ayniGun(c.tarih, bugun)) c,
    ];
    final bugunTekrarlari = [
      for (final t in tumTekrarlar)
        if (ayniGun(t.tarih, bugun)) t,
    ];
    final haftaSonu = gunEkle(bugun, 6);
    final haftaKonuSayisi = {
      for (final c in tumCalismalar)
        if (!c.tamam && !c.tarih.isBefore(bugun) && !c.tarih.isAfter(haftaSonu))
          c.konuId,
    }.length;

    final yapilanCalisma = bugunCalismalari.where((c) => c.tamam).length;
    final yapilanTekrar = bugunTekrarlari.where((t) => t.yapildi).length;
    final geciken = gecikenCalismalar.length + gecikenTekrarlar.length;
    final bosGun = geciken == 0 &&
        bugunCalismalari.isEmpty &&
        bugunTekrarlari.isEmpty;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bugün',
                  style: tema.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Ayarlar',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AyarlarEkrani()),
                ),
              ),
            ],
          ),
          Text(
            gunAdiIleTarih(bugun),
            style: tema.textTheme.bodyMedium?.copyWith(color: soluk),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
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
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => sinavTarihiSec(context, depo),
                    child: const Text('Sınav tarihini değiştir'),
                  ),
                ],
              ),
            ),
          ),
          if (haftaKonuSayisi > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Bu hafta $haftaKonuSayisi konu planlı',
              style: tema.textTheme.bodyMedium?.copyWith(color: soluk),
            ),
          ],
          if (geciken > 0) ...[
            BolumBasligi(baslik: 'Geciken', bilgi: '$geciken iş'),
            for (final c in gecikenCalismalar) ...[
              CalismaSatiri(calisma: c, bugun: bugun, planliGunuGoster: true),
              const SizedBox(height: 8),
            ],
            for (final t in gecikenTekrarlar) ...[
              TekrarSatiri(tekrar: t, bugun: bugun, tarihiGoster: true),
              const SizedBox(height: 8),
            ],
          ],
          if (bugunCalismalari.isNotEmpty) ...[
            BolumBasligi(
              baslik: 'Bugünün planı',
              bilgi: '$yapilanCalisma/${bugunCalismalari.length}',
            ),
            for (final c in bugunCalismalari) ...[
              CalismaSatiri(calisma: c, bugun: bugun),
              const SizedBox(height: 8),
            ],
          ],
          if (bugunTekrarlari.isNotEmpty) ...[
            BolumBasligi(
              baslik: 'Tekrarlar',
              bilgi: '$yapilanTekrar/${bugunTekrarlari.length}',
            ),
            for (final t in bugunTekrarlari) ...[
              TekrarSatiri(tekrar: t, bugun: bugun),
              const SizedBox(height: 8),
            ],
          ],
          if (bosGun)
            Padding(
              padding: const EdgeInsets.only(top: 28),
              child: Text(
                depo.tumCalismalar().isEmpty
                    ? 'Henüz plan yok. Takvim sekmesinden bir konuyu bir güne '
                        'yerleştir; tekrarlar otomatik oluşur.'
                    : 'Bugün için planlanmış bir iş yok.',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium?.copyWith(color: soluk),
              ),
            ),
        ],
      ),
    );
  }
}
