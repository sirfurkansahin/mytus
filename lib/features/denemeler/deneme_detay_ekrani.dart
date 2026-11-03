import 'package:app/core/renkler.dart';
import 'package:app/core/tarih.dart';
import 'package:app/features/denemeler/deneme_ekle_ekrani.dart';
import 'package:app/features/denemeler/dialoglar.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:app/features/dersler/dialoglar.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// Deneme sınavının kapsamlı bilişsel ve hata analizi ekranı.
class DenemeDetayEkrani extends StatelessWidget {
  const DenemeDetayEkrani({super.key, required this.denemeId});

  final String denemeId;

  Future<void> _denemeSil(BuildContext context, PlanDeposu depo) async {
    final onay = await onayDialogu(
      context,
      baslik: 'Denemeyi sil?',
      metin: 'Bu deneme ve kaydedilen tüm soru analizleri silinecek. Geri alınamaz.',
      eylem: 'Sil',
    );
    if (!onay || !context.mounted) return;
    await depo.denemeSil(denemeId);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _soruEkle(BuildContext context, PlanDeposu depo, DenemeSinavi deneme) async {
    final yeniSoru = await soruAnalizDialogu(context);
    if (yeniSoru == null) return;

    final guncelSorular = List<DenemeSorusu>.from(deneme.soruHatalari)..add(yeniSoru);
    final guncelDeneme = DenemeSinavi(
      id: deneme.id,
      ad: deneme.ad,
      tarih: deneme.tarih,
      temel: deneme.temel,
      klinik: deneme.klinik,
      soruHatalari: guncelSorular,
      kaygiPuani: deneme.kaygiPuani,
      notlar: deneme.notlar,
    );
    await depo.denemeGuncelle(guncelDeneme);
  }

  Future<void> _soruSil(
    BuildContext context,
    PlanDeposu depo,
    DenemeSinavi deneme,
    String soruId,
  ) async {
    final guncelSorular = deneme.soruHatalari.where((s) => s.id != soruId).toList();
    final guncelDeneme = DenemeSinavi(
      id: deneme.id,
      ad: deneme.ad,
      tarih: deneme.tarih,
      temel: deneme.temel,
      klinik: deneme.klinik,
      soruHatalari: guncelSorular,
      kaygiPuani: deneme.kaygiPuani,
      notlar: deneme.notlar,
    );
    await depo.denemeGuncelle(guncelDeneme);
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final deneme = depo.denemeBul(denemeId);

    if (deneme == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Deneme bulunamadı')),
      );
    }

    final tema = Theme.of(context);
    final ebap = deneme.tahminiEbapPuani;
    final kPuan = deneme.klinikAgirlikliPuan;
    final tPuan = deneme.temelAgirlikliPuan;
    final hataDagilimi = deneme.hataDagilimi;
    final kalibrasyon = deneme.kalibrasyonFarki;
    final hiperSayisi = deneme.hiperDuzeltmeSayisi;

    return Scaffold(
      appBar: AppBar(
        title: Text(deneme.ad, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Düzenle',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DenemeEkleEkrani(duzenlenecek: deneme),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sil',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _denemeSil(context, depo),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_task),
        label: const Text('Soru / Hata Ekle'),
        onPressed: () => _soruEkle(context, depo, deneme),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          // 1. Puan & Net Özeti
          _PuanNetKarti(
            deneme: deneme,
            ebap: ebap,
            kPuan: kPuan,
            tPuan: tPuan,
          ),
          const SizedBox(height: 16),

          // 2. "Emin + Yanlış" Hiperdüzeltme Uyarısı (Rapor Bölüm 3.3)
          if (hiperSayisi > 0) ...[
            _HiperDuzeltmeKarti(hiperSayisi: hiperSayisi),
            const SizedBox(height: 16),
          ],

          // 3. Güven Matrisi ve Kalibrasyon Farkı (Rapor Bölüm 4.2)
          _KalibrasyonKarti(
            deneme: deneme,
            kalibrasyon: kalibrasyon,
          ),
          const SizedBox(height: 16),

          // 4. A–F Hata Sınıfları Dağılımı (Rapor Bölüm 3.3)
          _HataSiniflariKarti(hataDagilimi: hataDagilimi),
          const SizedBox(height: 20),

          // 5. Analiz Edilen Sorular Listesi
          Row(
            children: [
              Text(
                'ANALİZ EDİLEN SORULAR (${deneme.soruHatalari.length})',
                style: tema.textTheme.labelSmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _soruEkle(context, depo, deneme),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Soru Ekle'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (deneme.soruHatalari.isEmpty)
            Card(
              elevation: 0,
              color: tema.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: tema.colorScheme.outlineVariant),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Bu denemede henüz soru bazlı hata analizi yapılmadı. Yanlış yaptığın veya kararsız kaldığın soruları ekleyerek A–F sınıflandırması yapabilirsin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
              ),
            )
          else
            for (final soru in deneme.soruHatalari) ...[
              _SoruAnalizKarti(
                soru: soru,
                onSil: () => _soruSil(context, depo, deneme, soru.id),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _PuanNetKarti extends StatelessWidget {
  const _PuanNetKarti({
    required this.deneme,
    required this.ebap,
    required this.kPuan,
    required this.tPuan,
  });

  final DenemeSinavi deneme;
  final double ebap;
  final double kPuan;
  final double tPuan;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      elevation: 0,
      color: morAna.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: morAna.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarihFormatla(deneme.tarih),
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${deneme.toplamNet.toStringAsFixed(2)} Net',
                      style: tema.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: morAna,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: morAna,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'TAHMİNİ TUS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ebap.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                      const Text(
                        'EBAP 85 Tavanı',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniNetSatiri(
                  baslik: 'Temel (TTBT)',
                  net: deneme.temel.net,
                  dogru: deneme.temel.dogru,
                  yanlis: deneme.temel.yanlis,
                ),
                _MiniNetSatiri(
                  baslik: 'Klinik (KTBT)',
                  net: deneme.klinik.net,
                  dogru: deneme.klinik.dogru,
                  yanlis: deneme.klinik.yanlis,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'K-Puanı: ${kPuan.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    Text(
                      'T-Puanı: ${tPuan.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniNetSatiri extends StatelessWidget {
  const _MiniNetSatiri({
    required this.baslik,
    required this.net,
    required this.dogru,
    required this.yanlis,
  });

  final String baslik;
  final double net;
  final int dogru;
  final int yanlis;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          baslik,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '${net.toStringAsFixed(2)} net',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        Text(
          '$dogru D · $yanlis Y',
          style: TextStyle(fontSize: 10, color: tema.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _HiperDuzeltmeKarti extends StatelessWidget {
  const _HiperDuzeltmeKarti({required this.hiperSayisi});

  final int hiperSayisi;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.red.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ HİPERDÜZELTME ALARMI ($hiperSayisi Soru)',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Rapor Bölüm 3.3: "Emin + Yanlış" hücresi bir bilgi eksiği değil YANLIŞ İNANÇTIR. Yüksek güvenle yapılan hatalar geri bildirimle en kolay düzelenlerdir ve AYNI GÜN düzeltilmelidir!',
                    style: TextStyle(fontSize: 11, height: 1.3),
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

class _KalibrasyonKarti extends StatelessWidget {
  const _KalibrasyonKarti({
    required this.deneme,
    required this.kalibrasyon,
  });

  final DenemeSinavi deneme;
  final double kalibrasyon;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final eminOran = deneme.eminDogrulukOrani;
    final kaygi = deneme.kaygiPuani ?? 3;

    String mesaj = 'Hedef dahilinde kalibrasyon (|Fark| ≤ %5)';
    Color durumRenk = Colors.green;

    if (kalibrasyon > 8.0) {
      mesaj = '⚠️ Aşırı güven tespit edildi! "Emin" işaretlemeden önce 10 sn tersini düşün.';
      durumRenk = Colors.orange;
    } else if (kalibrasyon < -8.0) {
      mesaj = 'Aşırı şüphecilik! Bilgine güvenmekte çekiniyorsun.';
      durumRenk = Colors.blue;
    }

    return Card(
      elevation: 0,
      color: tema.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tema.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, size: 18, color: tema.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Bilişsel Kalibrasyon & Güven Matrisi',
                  style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniKutu(
                    baslik: 'Kalibrasyon Farkı',
                    deger: '${kalibrasyon >= 0 ? '+' : ''}$kalibrasyon%',
                    renk: durumRenk,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniKutu(
                    baslik: 'Emin Doğruluk',
                    deger: '${eminOran.toStringAsFixed(0)}%',
                    renk: eminOran >= 90 ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniKutu(
                    baslik: 'Test Kaygısı',
                    deger: '$kaygi / 10',
                    renk: kaygi >= 7 ? Colors.red : morAna,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              mesaj,
              style: TextStyle(
                fontSize: 11,
                color: durumRenk,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniKutu extends StatelessWidget {
  const _MiniKutu({
    required this.baslik,
    required this.deger,
    required this.renk,
  });

  final String baslik;
  final String deger;
  final Color renk;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            baslik,
            style: TextStyle(fontSize: 10, color: tema.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            deger,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: renk,
            ),
          ),
        ],
      ),
    );
  }
}

class _HataSiniflariKarti extends StatelessWidget {
  const _HataSiniflariKarti({required this.hataDagilimi});

  final Map<HataSinifi, int> hataDagilimi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      elevation: 0,
      color: tema.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tema.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart_outline_rounded, size: 18, color: tema.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'A–F Hata Sınıfları Dağılımı',
                  style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Her yanlışın maliyeti 1.25 nettir (+1 doğru fırsatı + 0.25 yanlış cezası).',
              style: TextStyle(fontSize: 11, color: tema.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            for (final sinif in HataSinifi.values) ...[
              _HataSinifSatiri(
                sinif: sinif,
                adet: hataDagilimi[sinif] ?? 0,
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _HataSinifSatiri extends StatelessWidget {
  const _HataSinifSatiri({required this.sinif, required this.adet});

  final HataSinifi sinif;
  final int adet;

  @override
  Widget build(BuildContext context) {
    final kayipNet = adet * 1.25;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: adet > 0
            ? sinif.renk.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: adet > 0 ? sinif.renk.withValues(alpha: 0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sinif.renk,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              sinif.kod,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sinif.ad,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                Text(
                  sinif.aciklama,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$adet hata',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: adet > 0 ? sinif.renk : Colors.grey,
                ),
              ),
              if (adet > 0)
                Text(
                  '-${kayipNet.toStringAsFixed(2)} net',
                  style: const TextStyle(fontSize: 10, color: Colors.red),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SoruAnalizKarti extends StatelessWidget {
  const _SoruAnalizKarti({
    required this.soru,
    required this.onSil,
  });

  final DenemeSorusu soru;
  final VoidCallback onSil;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final oturumAd = soru.oturumTemelMi ? 'Temel' : 'Klinik';

    return Card(
      elevation: 0,
      color: soru.hiperDuzeltmeGerektirir
          ? Colors.red.withValues(alpha: 0.06)
          : tema.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: soru.hiperDuzeltmeGerektirir
              ? Colors.red.withValues(alpha: 0.4)
              : tema.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: soru.dogruMu ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$oturumAd Soru ${soru.soruNo}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (soru.hataSinifi != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: soru.hataSinifi!.renk.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Sınıf ${soru.hataSinifi!.kod}: ${soru.hataSinifi!.ad}',
                      style: TextStyle(
                        color: soru.hataSinifi!.renk,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  'Güven: ${soru.guven.ad}',
                  style: TextStyle(
                    fontSize: 11,
                    color: tema.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: onSil,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (soru.hiperDuzeltmeGerektirir) ...[
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 14),
                  SizedBox(width: 4),
                  Text(
                    '⚠️ Hiperdüzeltme: Yanlış inanç, aynı gün kapatılmalıdır!',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
            if (soru.celdirici.isNotEmpty || soru.ayiranKriter.isNotEmpty) ...[
              const SizedBox(height: 8),
              if (soru.celdirici.isNotEmpty)
                Text(
                  'Çeldirici: ${soru.celdirici}',
                  style: const TextStyle(fontSize: 12),
                ),
              if (soru.ayiranKriter.isNotEmpty)
                Text(
                  'Ayıran Tek Kriter: ${soru.ayiranKriter}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
            ],
            if (soru.kural.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Kuralım: ${soru.kural}',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: tema.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
