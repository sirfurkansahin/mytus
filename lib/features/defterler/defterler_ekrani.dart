import 'package:app/core/renkler.dart';
import 'package:app/core/tarih.dart';
import 'package:app/features/defterler/dialoglar.dart';
import 'package:app/features/defterler/modeller.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// Rapor Bölüm 2.2, 3.3, 4.1 ve 5.5 kapsamındaki 4 özel defter merkezi:
/// 1. Hata Defteri & Çeldirici Bankası
/// 2. Sınıflama & Skor Defteri
/// 3. Mekanizma Zincirleri (Illness Script)
/// 4. 3 Dakikalık Vaka Kartları
class DefterlerEkrani extends StatelessWidget {
  const DefterlerEkrani({super.key, this.baslangicSekmesi = 0});

  final int baslangicSekmesi;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: baslangicSekmesi,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Özel Defterler & Akıllı Havuz',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.rule_folder_outlined), text: 'Hata & Çeldirici'),
              Tab(icon: Icon(Icons.format_list_numbered_rounded), text: 'Skor Defteri'),
              Tab(icon: Icon(Icons.hub_outlined), text: 'Mekanizma Zincirleri'),
              Tab(icon: Icon(Icons.medical_services_outlined), text: '3 Dk Vaka Kartı'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _HataDefteriSekmesi(),
            _SkorDefteriSekmesi(),
            _ZincirlerSekmesi(),
            _VakalarSekmesi(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 1. HATA DEFTERİ & ÇELDİRİCİ BANKASI
// ============================================================================
class _HataDefteriSekmesi extends StatefulWidget {
  const _HataDefteriSekmesi();

  @override
  State<_HataDefteriSekmesi> createState() => _HataDefteriSekmesiState();
}

class _HataDefteriSekmesiState extends State<_HataDefteriSekmesi> {
  bool _sadeceHiper = false;
  HataSinifi? _seciliSinif;

  Future<void> _hataEkle(BuildContext context, PlanDeposu depo) async {
    final yeni = await hataEkleDialogu(context);
    if (yeni != null) await depo.hataEkle(yeni);
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    var liste = depo.hataDefteri;

    if (_sadeceHiper) {
      liste = liste.where((h) => h.hiperDuzeltmeGerektirir).toList();
    }
    if (_seciliSinif != null) {
      liste = liste.where((h) => h.hataSinifi == _seciliSinif).toList();
    }

    final hiperSayisi = depo.hataDefteri.where((h) => h.hiperDuzeltmeGerektirir).length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Hata Ekle'),
        onPressed: () => _hataEkle(context, depo),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          // Hiperdüzeltme uyarı kartı
          if (hiperSayisi > 0)
            Card(
              elevation: 0,
              color: Colors.red.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.withValues(alpha: 0.35)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$hiperSayisi adet yanlış inanç (Emin + Yanlış) bekliyor. Hiperdüzeltme etkisiyle bugün kapatılmalıdır.',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _sadeceHiper = !_sadeceHiper),
                      child: Text(_sadeceHiper ? 'Tümünü Gör' : 'Filtrele'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),

          // Filtre Çipleri
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tümü'),
                  selected: !_sadeceHiper && _seciliSinif == null,
                  onSelected: (_) => setState(() {
                    _sadeceHiper = false;
                    _seciliSinif = null;
                  }),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('⚠️ Yalnız Hiperdüzeltme'),
                  selected: _sadeceHiper,
                  selectedColor: Colors.red.withValues(alpha: 0.2),
                  onSelected: (v) => setState(() {
                    _sadeceHiper = v;
                    if (v) _seciliSinif = null;
                  }),
                ),
                const SizedBox(width: 6),
                for (final s in HataSinifi.values) ...[
                  FilterChip(
                    label: Text('${s.kod} · ${s.ad}'),
                    selected: _seciliSinif == s,
                    onSelected: (v) => setState(() {
                      _seciliSinif = v ? s : null;
                      _sadeceHiper = false;
                    }),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (liste.isEmpty)
            Card(
              elevation: 0,
              color: tema.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: tema.colorScheme.outlineVariant),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Hata Defterinde gösterilecek kayıt yok.\nSoru çözerken veya denemelerde karşılaştığın zor çeldiricileri ekleyebilirsin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
              ),
            )
          else
            for (final h in liste) ...[
              _HataKarti(
                hata: h,
                onPekistir: (v) => depo.hataPekistir(h.id, v),
                onSil: () => depo.hataSil(h.id),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _HataKarti extends StatelessWidget {
  const _HataKarti({
    required this.hata,
    required this.onPekistir,
    required this.onSil,
  });

  final HataKaydi hata;
  final ValueChanged<bool> onPekistir;
  final VoidCallback onSil;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      elevation: 0,
      color: hata.pekiştirildi
          ? Colors.green.withValues(alpha: 0.05)
          : hata.hiperDuzeltmeGerektirir
              ? Colors.red.withValues(alpha: 0.08)
              : tema.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hata.pekiştirildi
              ? Colors.green.withValues(alpha: 0.3)
              : hata.hiperDuzeltmeGerektirir
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: hata.hataSinifi.renk,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    hata.hataSinifi.kod,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hata.baslik,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: hata.pekiştirildi ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Checkbox(
                  value: hata.pekiştirildi,
                  onChanged: (v) => onPekistir(v ?? false),
                  tooltip: 'Pekiştirildi olarak işaretle',
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: onSil,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (hata.dersAdi.isNotEmpty)
              Text(
                hata.dersAdi,
                style: TextStyle(fontSize: 11, color: tema.colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: 8),
            if (hata.celdirici.isNotEmpty)
              Text('Karışan Çeldirici: ${hata.celdirici}', style: const TextStyle(fontSize: 12)),
            if (hata.ayiranKriter.isNotEmpty)
              Text(
                'Ayıran Tek Kriter: ${hata.ayiranKriter}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            if (hata.kural.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Kuralım: "${hata.kural}"',
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

// ============================================================================
// 2. SINIFLAMA & SKOR DEFTERİ
// ============================================================================
class _SkorDefteriSekmesi extends StatefulWidget {
  const _SkorDefteriSekmesi();

  @override
  State<_SkorDefteriSekmesi> createState() => _SkorDefteriSekmesiState();
}

class _SkorDefteriSekmesiState extends State<_SkorDefteriSekmesi> {
  String _arama = '';

  Future<void> _skorEkle(BuildContext context, PlanDeposu depo) async {
    final yeni = await skorEkleDialogu(context);
    if (yeni != null) await depo.skorEkle(yeni);
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final tumSkorlar = depo.tumSkorlar;

    final filtreli = tumSkorlar.where((s) {
      if (_arama.isEmpty) return true;
      final query = _arama.toLowerCase();
      return s.ad.toLowerCase().contains(query) ||
          s.brans.toLowerCase().contains(query) ||
          s.parametreler.any((p) => p.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Skor Ekle'),
        onPressed: () => _skorEkle(context, depo),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Skor veya sınıflama ara (örn: Hinchey, Child, Wells)...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (v) => setState(() => _arama = v.trim()),
          ),
          const SizedBox(height: 12),
          Text(
            'TUS SKOR & SINIFLAMA KÜTÜPHANESİ (${filtreli.length})',
            style: tema.textTheme.labelSmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          for (final skor in filtreli) ...[
            _SkorKartiBileseni(
              skor: skor,
              onSil: skor.ozelMi ? () => depo.skorSil(skor.id) : null,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SkorKartiBileseni extends StatelessWidget {
  const _SkorKartiBileseni({required this.skor, this.onSil});

  final SkorKarti skor;
  final VoidCallback? onSil;

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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    skor.ad,
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: morAna,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    skor.brans,
                    style: TextStyle(
                      color: tema.colorScheme.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onSil != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: onSil,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (final p in skor.parametreler) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(p, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Klinik Karar: ${skor.klinikKarar}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            if (skor.osymTuzagi.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ÖSYM Tuzağı: ${skor.osymTuzagi}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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

// ============================================================================
// 3. MEKANİZMA ZİNCİRLERİ (ILLNESS SCRIPTS)
// ============================================================================
class _ZincirlerSekmesi extends StatelessWidget {
  const _ZincirlerSekmesi();

  Future<void> _zincirEkle(BuildContext context, PlanDeposu depo) async {
    final yeni = await zincirEkleDialogu(context);
    if (yeni != null) await depo.zincirEkle(yeni);
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final liste = depo.zincirler;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Zincir Ekle'),
        onPressed: () => _zincirEkle(context, depo),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          Card(
            elevation: 0,
            color: morAna.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: morAna.withValues(alpha: 0.2)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Rapor Bölüm 4.1: Tıp bilgisi ezber listesi değil, 5 halkalı hastalık betiğidir (Illness Script). Beyaz sayfada çizip "Neden?" sorusuyla pekiştirilmelidir.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (liste.isEmpty)
            Card(
              elevation: 0,
              color: tema.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: tema.colorScheme.outlineVariant),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Henüz mekanizma zinciri eklenmedi.\nDahiliye, Farmakoloji veya Anatomi için 5 halkalı illness script oluşturmak için "+ Zincir Ekle" düğmesini kullanabilirsin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
              ),
            )
          else
            for (final z in liste) ...[
              _ZincirKarti(zincir: z, onSil: () => depo.zincirSil(z.id)),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _ZincirKarti extends StatelessWidget {
  const _ZincirKarti({required this.zincir, required this.onSil});

  final MekanizmaZinciri zincir;
  final VoidCallback onSil;

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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    zincir.baslik,
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: morAna,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    zincir.tur.ad.split(' ')[0],
                    style: TextStyle(
                      color: tema.colorScheme.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, size: 16), onPressed: onSil),
              ],
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < zincir.halkalar.length; i++) ...[
              if (zincir.halkalar[i].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i + 1}➔ ',
                        style: TextStyle(
                          color: tema.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${zincir.tur.halkaAdlari[i]}: ${zincir.halkalar[i]}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (zincir.ayiranOzellik.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Ayıran Özellik: ${zincir.ayiranOzellik}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
            if (zincir.nedenCevabi.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Neden?: ${zincir.nedenCevabi}',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 4. 3 DAKİKALIK VAKA KARTLARI (İNTÖRN/KLİNİSYEN MODU)
// ============================================================================
class _VakalarSekmesi extends StatelessWidget {
  const _VakalarSekmesi();

  Future<void> _vakaEkle(BuildContext context, PlanDeposu depo) async {
    final yeni = await vakaEkleDialogu(context);
    if (yeni != null) await depo.vakaEkle(yeni);
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final liste = depo.vakaKartlari;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Vaka Ekle'),
        onPressed: () => _vakaEkle(context, depo),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          Card(
            elevation: 0,
            color: Colors.teal.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.teal.withValues(alpha: 0.2)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Rapor Bölüm 5.5: Nöbet ve klinikte karşılaşılan hastaları 3 dakikada TUS soru mantığına ve ayırıcı tanı çeldiricisine dönüştürün.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (liste.isEmpty)
            Card(
              elevation: 0,
              color: tema.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: tema.colorScheme.outlineVariant),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Henüz klinik vaka kartı eklenmedi.\nServiste, acilde veya poliklinikte gördüğün bir hastayı 3 dakikalık vaka kartıyla TUS bilgisine çevirebilirsin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
              ),
            )
          else
            for (final v in liste) ...[
              _VakaKartiBileseni(vaka: v, onSil: () => depo.vakaSil(v.id)),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _VakaKartiBileseni extends StatelessWidget {
  const _VakaKartiBileseni({required this.vaka, required this.onSil});

  final VakaKarti vaka;
  final VoidCallback onSil;

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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tarihYaz(vaka.tarih),
                    style: TextStyle(
                      fontSize: 11,
                      color: tema.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (vaka.dersAdi.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tema.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      vaka.dersAdi,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: tema.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                IconButton(icon: const Icon(Icons.close, size: 16), onPressed: onSil),
              ],
            ),
            Text(
              vaka.hastaOzeti,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('Belirleyici Halka: ${vaka.belirleyiciHalka}', style: const TextStyle(fontSize: 12)),
            Text(
              'Olası Soru Kökü: ${vaka.olasiSoruKoku}',
              style: TextStyle(fontSize: 12, color: tema.colorScheme.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text('Çeldirici: ${vaka.celdirici}', style: const TextStyle(fontSize: 12)),
            Text(
              'Ayıran Tek Kriter: ${vaka.ayiranKriter}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
