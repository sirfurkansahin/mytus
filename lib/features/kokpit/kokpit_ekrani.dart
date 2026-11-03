library;

import 'package:app/features/bilissel/bilissel_ekrani.dart';
import 'package:app/features/defterler/defterler_ekrani.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/kokpit/modeller.dart';
import 'package:app/features/kokpit/strateji_motoru.dart';
import 'package:app/features/prova/beklenen_deger_dialog.dart';
import 'package:app/features/prova/panik_protokolu_dialog.dart';
import 'package:app/features/prova/prova_ekrani.dart';
import 'package:flutter/material.dart';

/// Master Yönetim Kokpiti: Haftalık 8 Bilişsel + 4 Sınav Göstergesi ve
/// Otomatik "Eğer–O Zaman" Karar Motoru (Master Araştırma Raporu Bölüm 6.3 & 6.4).
class KokpitEkrani extends StatelessWidget {
  const KokpitEkrani({super.key});

  void _bilgiGoster(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Master Yönetim Kokpiti'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Master Araştırma Raporu (Bölüm 6.3 & 6.4) çerçevesinde '
                'tüm bilişsel, nörobiyolojik, uyku ve deneme sınavı verilerini '
                'tek bir akıllı karar merkezinde birleştirir.\n',
              ),
              Text(
                '🧠 8 Bilişsel Gösterge:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '• Kalibrasyon Farkı (Hedef: ≤ %5)\n'
                '• Aşırı Güven Alarmı (Eşik: > +%8)\n'
                '• Uyku Süresi & Sirkadiyen Sapma (7–9 sa, ±30 dk)\n'
                '• Prefrontal Korteks & C Tipi Okuma Hatası (< %10–15)\n'
                '• Test Kaygı Puanı (0–10, Hedef: ≤ 6)\n'
                '• R1 & R3 Tekrar Geçiş Oranları (≥ %75 / ≥ %70)\n'
                '• Ortalama Odak Puanı & Ağır Analitik Tavan (3–4 saat)\n'
                '• A–F Kayıp Net ve Hata Dağılımı\n',
              ),
              Text(
                '🎯 4 Sınav & Net Göstergesi:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '• Temel Bilimler (TTBT) Neti\n'
                '• Klinik Bilimler (KTBT) Neti\n'
                '• Klinik Ağırlıklı K Puanı (0.4 TTBT + 0.6 KTBT)\n'
                '• Tahmini ÖSYM 85 EBAP Puanı\n',
              ),
              Text(
                '⚡ Otomatik "Eğer–O Zaman" Asistanı:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Bilişsel yorgunluk, aşırı güven, tempo düşüşü veya sirkadiyen sapma '
                'tespit edildiğinde anında bilimsel eylem yönlendirmesi yapar.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  void _eylemCalistir(
    BuildContext context,
    PlanDeposu depo,
    KokpitEylemTuru eylem,
  ) {
    switch (eylem) {
      case KokpitEylemTuru.kurtarmaModu:
        final yeniDurum = !depo.kurtarmaModuAktif;
        depo.kurtarmaModuAyarla(yeniDurum);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              yeniDurum
                  ? '%70 Kurtarma Modu açıldı. Yeni konular ertelendi, R1–R2 tekrarları korunuyor.'
                  : '%70 Kurtarma Modu kapatıldı.',
            ),
          ),
        );
      case KokpitEylemTuru.celdiriciBankasi:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const DefterlerEkrani()),
        );
      case KokpitEylemTuru.panikProtokolu:
        showDialog<void>(
          context: context,
          builder: (_) => const PanikProtokoluDialog(),
        );
      case KokpitEylemTuru.sinavProvasi:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ProvaEkrani()),
        );
      case KokpitEylemTuru.tekrarPlani:
        Navigator.of(context).pop();
      case KokpitEylemTuru.uykuYonetimi:
      case KokpitEylemTuru.bilisselYonetim:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const BilisselEkrani()),
        );
      case KokpitEylemTuru.beklenenDeger:
        showDialog<void>(
          context: context,
          builder: (_) => const BeklenenDegerDialog(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final gostergeler = kokpitGostergeleriHesapla(depo);
    final kurallar = stratejiAnaliziYap(gostergeler, depo);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Yönetim Kokpiti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Kokpit Hakkında',
            onPressed: () => _bilgiGoster(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // 1. Tepe Kartı: Kompozit Bilişsel Sağlık Skoru
          _SaglikOzetiKarti(gostergeler: gostergeler),
          const SizedBox(height: 16),

          // 2. Bölüm: Otomatik "Eğer–O Zaman" Karar ve Strateji Motoru
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 20, color: tema.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Otomatik "Eğer–O Zaman" Kararları',
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final kural in kurallar) ...[
            _KuralKarti(
              kural: kural,
              onEylem: kural.eylemTuru != null
                  ? () => _eylemCalistir(context, depo, kural.eylemTuru!)
                  : null,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),

          // 3. Bölüm: 8 Bilişsel Performans Göstergesi
          Row(
            children: [
              Icon(Icons.psychology, size: 20, color: tema.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '8 Bilişsel Gösterge (Haftalık Teşhis)',
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SekizBilisselGostergeGrid(gostergeler: gostergeler),
          const SizedBox(height: 20),

          // 4. Bölüm: 4 Sınav ve Net Göstergesi
          Row(
            children: [
              Icon(Icons.military_tech_outlined, size: 20, color: tema.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '4 Sınav & Net Göstergesi',
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DortSinavGostergesiKarti(gostergeler: gostergeler),
          const SizedBox(height: 20),

          // 5. Bölüm: Hızlı Sınav & Bilişsel Araçlar
          Text(
            'Hızlı Sınav ve Bilişsel Araçlar',
            style: tema.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _HizliAraclarSatiri(
            depo: depo,
            onEylem: (eylem) => _eylemCalistir(context, depo, eylem),
          ),
        ],
      ),
    );
  }
}

/// Tepe Kartı: Kompozit Bilişsel Sağlık Skoru ve Hızlı Sınav Özeti
class _SaglikOzetiKarti extends StatelessWidget {
  const _SaglikOzetiKarti({required this.gostergeler});

  final KokpitGostergeleri gostergeler;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: gostergeler.saglikDurumRengi.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      color: gostergeler.saglikDurumRengi.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
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
                      'BİLİŞSEL SAĞLIK & KOKPİT SKORU',
                      style: tema.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gostergeler.saglikDurumEtiketi,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: gostergeler.saglikDurumRengi,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: gostergeler.saglikDurumRengi,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${gostergeler.genelSaglikSkoru} / 100',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: gostergeler.genelSaglikSkoru / 100.0,
                minHeight: 8,
                backgroundColor: Colors.black12,
                color: gostergeler.saglikDurumRengi,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 16,
              runSpacing: 8,
              children: [
                _MiniMetrik(
                  etiket: 'Tahmini EBAP',
                  deger: gostergeler.tahminiEbapPuani > 0
                      ? gostergeler.tahminiEbapPuani.toStringAsFixed(1)
                      : '–',
                ),
                _MiniMetrik(
                  etiket: 'Klinik K Puanı',
                  deger: gostergeler.sonKlinikAgirlikliPuan > 0
                      ? gostergeler.sonKlinikAgirlikliPuan.toStringAsFixed(1)
                      : '–',
                ),
                _MiniMetrik(
                  etiket: 'Toplam Net',
                  deger: gostergeler.sonToplamNet > 0
                      ? gostergeler.sonToplamNet.toStringAsFixed(1)
                      : '–',
                ),
                _MiniMetrik(
                  etiket: 'Kalibrasyon',
                  deger: '${gostergeler.kalibrasyonFarki > 0 ? '+' : ''}${gostergeler.kalibrasyonFarki}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetrik extends StatelessWidget {
  const _MiniMetrik({required this.etiket, required this.deger});

  final String etiket;
  final String deger;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      children: [
        Text(
          deger,
          style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          etiket,
          style: tema.textTheme.bodySmall?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Otomatik "Eğer–O Zaman" Karar Kartı
class _KuralKarti extends StatelessWidget {
  const _KuralKarti({required this.kural, this.onEylem});

  final KokpitKurali kural;
  final VoidCallback? onEylem;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final renk = kural.oncelik.renk;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: renk.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(kural.oncelik.ikon, size: 18, color: renk),
                    const SizedBox(width: 6),
                    Text(
                      kural.baslik,
                      style: tema.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: renk,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: renk.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    kural.oncelik.ad,
                    style: TextStyle(
                      color: renk,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: tema.textTheme.bodySmall?.copyWith(height: 1.35),
                      children: [
                        const TextSpan(
                          text: '🔍 EĞER (Teşhis): ',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: kural.eger),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: tema.textTheme.bodySmall?.copyWith(height: 1.35),
                      children: [
                        TextSpan(
                          text: '💡 O ZAMAN (Bilimsel Eylem): ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: tema.colorScheme.primary,
                          ),
                        ),
                        TextSpan(text: kural.oZaman),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (kural.eylemEtiketi != null && onEylem != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: renk.withValues(alpha: 0.15),
                    foregroundColor: renk,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onEylem,
                  child: Text(
                    kural.eylemEtiketi!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 8 Bilişsel Göstergenin Kart Dizilimi
class _SekizBilisselGostergeGrid extends StatelessWidget {
  const _SekizBilisselGostergeGrid({required this.gostergeler});

  final KokpitGostergeleri gostergeler;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _GostergeKarti(
                baslik: 'Kalibrasyon Farkı',
                deger: '${gostergeler.kalibrasyonFarki > 0 ? '+' : ''}${gostergeler.kalibrasyonFarki}%',
                hedef: 'Hedef: ≤ %5',
                durumRenk: gostergeler.kalibrasyonFarki.abs() <= 5.0
                    ? Colors.green
                    : (gostergeler.asiriGuvenVarMi ? Colors.red : Colors.orange),
                altMetin: gostergeler.asiriGuvenVarMi
                    ? 'Aşırı Güven Alarmı (Tersini Düşün)'
                    : 'Güven-Doğruluk Uyumu',
                ikon: Icons.balance,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GostergeKarti(
                baslik: 'Uyku Düzeni & Sapma',
                deger: '${gostergeler.uykuSuresiOrtalama} sa',
                hedef: 'Sapma: ±${gostergeler.sirkadiyenSapmaDakika} dk',
                durumRenk: gostergeler.uykuDuzenliMi ? Colors.green : Colors.orange,
                altMetin: gostergeler.uykuDuzenliMi
                    ? 'Sirkadiyen Sabit (7–9 sa)'
                    : 'Yatış Saatini Sabitle',
                ikon: Icons.nightlight_round,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _GostergeKarti(
                baslik: 'Prefrontal Korteks (PFC)',
                deger: '%${gostergeler.cTipiOkumaHatasiOrani.toStringAsFixed(1)}',
                hedef: 'C Tipi Hata: < %15',
                durumRenk: gostergeler.cTipiOkumaHatasiOrani > 15.0
                    ? Colors.red
                    : (gostergeler.cTipiOkumaHatasiOrani > 10.0
                        ? Colors.orange
                        : Colors.green),
                altMetin: gostergeler.cTipiOkumaHatasiOrani > 15.0
                    ? 'PFC Yorgunluğu (Kurtarma Modu)'
                    : 'Okuma & Dikkat Dengeli',
                ikon: Icons.psychology_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GostergeKarti(
                baslik: 'Test Kaygısı',
                deger: gostergeler.sonKaygiPuani != null
                    ? '${gostergeler.sonKaygiPuani} / 10'
                    : '–',
                hedef: 'Hedef: ≤ 6',
                durumRenk: (gostergeler.sonKaygiPuani ?? 0) >= 7
                    ? Colors.orange
                    : Colors.green,
                altMetin: (gostergeler.sonKaygiPuani ?? 0) >= 7
                    ? '90 sn Nefes Provası Yap'
                    : 'Sempatik Düzey Kontrollü',
                ikon: Icons.favorite_border,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _GostergeKarti(
                baslik: 'R1 Tekrar Geçişi',
                deger: '%${gostergeler.r1GecisOrani.toStringAsFixed(0)}',
                hedef: 'Hedef: ≥ %75',
                durumRenk: gostergeler.r1GecisOrani >= 75.0
                    ? Colors.green
                    : Colors.orange,
                altMetin: gostergeler.r1GecisOrani >= 75.0
                    ? 'G+1 LTP Konsolidasyonu Tam'
                    : 'Yeni Konuyu %20 Kıs',
                ikon: Icons.history,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GostergeKarti(
                baslik: 'R3 Tekrar Geçişi',
                deger: '%${gostergeler.r3GecisOrani.toStringAsFixed(0)}',
                hedef: 'Hedef: ≥ %70',
                durumRenk: gostergeler.r3GecisOrani >= 70.0
                    ? Colors.green
                    : Colors.orange,
                altMetin: gostergeler.r3GecisOrani >= 70.0
                    ? 'G+30 Kalıcı Bellek Aktarımı'
                    : 'Aralıklı Tekrarı Sıkılaştır',
                ikon: Icons.update,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _GostergeKarti(
                baslik: 'Odak & Bilişsel Tavan',
                deger: '${gostergeler.ortalamaOdakPuani.toStringAsFixed(1)} / 5',
                hedef: 'Bugün Zor: ${gostergeler.zorBilisselDakikaBugun} dk',
                durumRenk: gostergeler.zorBilisselTavanAsildi
                    ? Colors.orange
                    : Colors.green,
                altMetin: gostergeler.zorBilisselTavanAsildi
                    ? '4 Saatlik Kanıtlı Tavan Doldu'
                    : 'Verimli Odak Skalası',
                ikon: Icons.timer_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GostergeKarti(
                baslik: 'Kayıp Net (Hata Dağılımı)',
                deger: gostergeler.enBuyukHataSinifi != null
                    ? '${gostergeler.enBuyukHataSinifi!.kod} Sınıfı'
                    : '–',
                hedef: gostergeler.enBuyukHataSinifi != null
                    ? gostergeler.enBuyukHataSinifi!.ad
                    : 'Hata Yok',
                durumRenk: gostergeler.enBuyukHataSinifi?.renk ?? Colors.blue,
                altMetin: 'En çok kayıp nete yol açan',
                ikon: Icons.pie_chart_outline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GostergeKarti extends StatelessWidget {
  const _GostergeKarti({
    required this.baslik,
    required this.deger,
    required this.hedef,
    required this.durumRenk,
    required this.altMetin,
    required this.ikon,
  });

  final String baslik;
  final String deger;
  final String hedef;
  final Color durumRenk;
  final String altMetin;
  final IconData ikon;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tema.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  baslik,
                  style: tema.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
                Icon(ikon, size: 16, color: durumRenk),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              deger,
              style: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: durumRenk,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              hedef,
              style: tema.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              altMetin,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tema.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: durumRenk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 4 Sınav ve Net Göstergesi Kartı
class _DortSinavGostergesiKarti extends StatelessWidget {
  const _DortSinavGostergesiKarti({required this.gostergeler});

  final KokpitGostergeleri gostergeler;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tema.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _NetHucre(
                    baslik: 'Temel (TTBT)',
                    deger: gostergeler.sonTemelNet > 0
                        ? gostergeler.sonTemelNet.toStringAsFixed(2)
                        : '–',
                    altBilgi: '100 Soru',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NetHucre(
                    baslik: 'Klinik (KTBT)',
                    deger: gostergeler.sonKlinikNet > 0
                        ? gostergeler.sonKlinikNet.toStringAsFixed(2)
                        : '–',
                    altBilgi: '100 Soru',
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _NetHucre(
                    baslik: 'Klinik K Puanı',
                    deger: gostergeler.sonKlinikAgirlikliPuan > 0
                        ? gostergeler.sonKlinikAgirlikliPuan.toStringAsFixed(2)
                        : '–',
                    altBilgi: '0.4 TTBT + 0.6 KTBT',
                    vurgulu: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NetHucre(
                    baslik: 'Tahmini ÖSYM EBAP',
                    deger: gostergeler.tahminiEbapPuani > 0
                        ? gostergeler.tahminiEbapPuani.toStringAsFixed(2)
                        : '–',
                    altBilgi: '85 Tavan Skalası',
                    vurgulu: true,
                  ),
                ),
              ],
            ),
            if (gostergeler.sonCeyrekHataOraniYuksek) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Son çeyrek hata oranı ilk çeyreğin 1.5 katı (Karar Yorgunluğu)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NetHucre extends StatelessWidget {
  const _NetHucre({
    required this.baslik,
    required this.deger,
    required this.altBilgi,
    this.vurgulu = false,
  });

  final String baslik;
  final String deger;
  final String altBilgi;
  final bool vurgulu;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          baslik,
          style: tema.textTheme.labelMedium?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          deger,
          style: tema.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: vurgulu ? tema.colorScheme.primary : null,
          ),
        ),
        Text(
          altBilgi,
          style: tema.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Hızlı Aksiyon Araçları Butonları
class _HizliAraclarSatiri extends StatelessWidget {
  const _HizliAraclarSatiri({required this.depo, required this.onEylem});

  final PlanDeposu depo;
  final void Function(KokpitEylemTuru eylem) onEylem;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.timer_outlined, size: 18),
          label: const Text('135 Dk Sınav Provası'),
          onPressed: () => onEylem(KokpitEylemTuru.sinavProvasi),
        ),
        ActionChip(
          avatar: const Icon(Icons.air, size: 18),
          label: const Text('90 sn Panik / Nefes'),
          onPressed: () => onEylem(KokpitEylemTuru.panikProtokolu),
        ),
        ActionChip(
          avatar: const Icon(Icons.calculate_outlined, size: 18),
          label: const Text('Beklenen Değer (EV)'),
          onPressed: () => onEylem(KokpitEylemTuru.beklenenDeger),
        ),
        ActionChip(
          avatar: const Icon(Icons.nightlight_round, size: 18),
          label: const Text('Bilişsel & Uyku'),
          onPressed: () => onEylem(KokpitEylemTuru.uykuYonetimi),
        ),
        ActionChip(
          avatar: const Icon(Icons.rule_folder_outlined, size: 18),
          label: const Text('Özel Defterler'),
          onPressed: () => onEylem(KokpitEylemTuru.celdiriciBankasi),
        ),
      ],
    );
  }
}
