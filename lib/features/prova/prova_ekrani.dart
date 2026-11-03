import 'dart:async';
import 'package:app/features/denemeler/deneme_ekle_ekrani.dart';
import 'package:app/features/prova/ara_dinlenme_dialog.dart';
import 'package:app/features/prova/beklenen_deger_dialog.dart';
import 'package:app/features/prova/modeller.dart';
import 'package:app/features/prova/panik_protokolu_dialog.dart';
import 'package:flutter/material.dart';

/// Gerçek Saat 135 Dakikalık TUS Sınav Provası Ekranı.
/// (Master Araştırma Raporu Bölüm 5.1, 5.2, 5.3)
class ProvaEkrani extends StatefulWidget {
  const ProvaEkrani({super.key});

  @override
  State<ProvaEkrani> createState() => _ProvaEkraniState();
}

class _ProvaEkraniState extends State<ProvaEkrani> {
  bool _basladi = false;
  bool _duraklatildi = false;
  bool _bitti = false;

  bool _temelMi = true; // true: TTBT (10:15), false: KTBT (14:45)
  int _kaygiPuani = 3; // 0-10 sınav öncesi kaygı düzeyi

  static const int _toplamSureSaniye = 135 * 60; // 8100 saniye
  int _kalanSaniye = _toplamSureSaniye;
  int _guncelSoruNo = 1;

  Timer? _sayac;

  @override
  void dispose() {
    _sayac?.cancel();
    super.dispose();
  }

  void _baslat() {
    setState(() {
      _basladi = true;
      _duraklatildi = false;
      _bitti = false;
      _kalanSaniye = _toplamSureSaniye;
      _guncelSoruNo = 1;
    });
    _sayacKur();
  }

  void _sayacKur() {
    _sayac?.cancel();
    _sayac = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (!_duraklatildi && _kalanSaniye > 0) {
        setState(() {
          _kalanSaniye--;
          if (_kalanSaniye <= 0) {
            _sayac?.cancel();
            _bitti = true;
          }
        });
      }
    });
  }

  void _duraklatDevam() {
    setState(() => _duraklatildi = !_duraklatildi);
  }

  void _bitirOnay() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Provayı Bitir?'),
        content: const Text('Bu sınav provasını tamamlamak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Bitir'),
          ),
        ],
      ),
    ).then((evet) {
      if (evet == true && mounted) {
        _sayac?.cancel();
        setState(() => _bitti = true);
      }
    });
  }

  String _sureFormati(int toplamSaniye) {
    final sa = toplamSaniye ~/ 3600;
    final dk = (toplamSaniye % 3600) ~/ 60;
    final sn = toplamSaniye % 60;
    if (sa > 0) {
      return '${sa.toString().padLeft(2, '0')}:${dk.toString().padLeft(2, '0')}:${sn.toString().padLeft(2, '0')}';
    }
    return '${dk.toString().padLeft(2, '0')}:${sn.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _basladi && !_bitti
              ? (_temelMi ? 'TTBT Provası (10:15)' : 'KTBT Provası (14:45)')
              : 'Gerçek Saat Sınav Provası',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: '90 sn Panik / Nefes',
            icon: const Icon(Icons.air_rounded, color: Colors.teal),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const PanikProtokoluDialog(),
            ),
          ),
          IconButton(
            tooltip: 'Beklenen Değer (EV) Kartı',
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const BeklenenDegerDialog(),
            ),
          ),
        ],
      ),
      body: !_basladi
          ? _hazirlikEkrani(tema)
          : _bitti
              ? _sonucEkrani(tema)
              : _canliSayacEkrani(tema),
    );
  }

  // ---------------------------------------------------- 1. Hazırlık Ekranı

  Widget _hazirlikEkrani(ThemeData tema) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: tema.colorScheme.primaryContainer.withValues(alpha: 0.4),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: Colors.indigo, size: 36),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '135 Dakika · 100 Soru',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Resmi ÖSYM saatleri, çeyrek dilim tempo bildirimleri ve panik protokolü ile birebir prova.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Sınav Oturumu Seçin:', style: tema.textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              label: Text('1. Oturum: TTBT (10:15)'),
              icon: Icon(Icons.science_outlined),
            ),
            ButtonSegment(
              value: false,
              label: Text('2. Oturum: KTBT (14:45)'),
              icon: Icon(Icons.local_hospital_outlined),
            ),
          ],
          selected: {_temelMi},
          onSelectionChanged: (set) => setState(() => _temelMi = set.first),
        ),
        const SizedBox(height: 24),
        Text(
          'Sınav Öncesi Kaygı Düzeyiniz (0 - 10):',
          style: tema.textTheme.labelLarge,
        ),
        Slider(
          value: _kaygiPuani.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          label: 'Kaygı: $_kaygiPuani',
          onChanged: (v) => setState(() => _kaygiPuani = v.round()),
        ),
        Center(
          child: Text(
            _kaygiPuani >= 7
                ? '⚠️ Yüksek Kaygı: Sınava başlamadan önce üstteki 🫁 nefes protokolünü uygulamanız önerilir.'
                : '✅ Dengeli uyarılma seviyesi.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kaygiPuani >= 7 ? Colors.orange[800] : Colors.green[800],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Çeyrek Dilim Tempo Hedefleri (Rapor 5.1):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                for (final c in resmiCeyrekDilimler)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(c.etiket, style: const TextStyle(fontSize: 12)),
                        Text(
                          '${c.hedefDakika}. Dakika',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _baslat,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Provayı Başlat (135 Dakika)'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        ),
      ],
    );
  }

  // ---------------------------------------------------- 2. Canlı Sayaç Ekranı

  Widget _canliSayacEkrani(ThemeData tema) {
    final gecenSaniye = _toplamSureSaniye - _kalanSaniye;
    final tempo = tempoAnalizi(soruNo: _guncelSoruNo, gecenSaniye: gecenSaniye);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        // Büyük Saat Sayacı
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: tema.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _duraklatildi ? Colors.amber : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                _duraklatildi ? 'DURAKLATILDI' : 'KALAN SÜRE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: _duraklatildi ? Colors.amber[800] : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _sureFormati(_kalanSaniye),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'Geçen Süre: ${_sureFormati(gecenSaniye)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Soru İlerlemesi ve Tempo Kartı
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Soru: $_guncelSoruNo / 100',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: tempo.durum.renk.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tempo.durum.renk),
                      ),
                      child: Text(
                        tempo.durum.etiket,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: tempo.durum.renk,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(tempo.aciklama, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.remove),
                      onPressed: _guncelSoruNo > 1
                          ? () => setState(() => _guncelSoruNo--)
                          : null,
                    ),
                    Expanded(
                      child: Slider(
                        value: _guncelSoruNo.toDouble(),
                        min: 1,
                        max: 100,
                        divisions: 99,
                        label: '$_guncelSoruNo',
                        onChanged: (v) => setState(() => _guncelSoruNo = v.round()),
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add),
                      onPressed: _guncelSoruNo < 100
                          ? () => setState(() => _guncelSoruNo++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Çeyrek Dilim Kontrol Çubukları
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Çeyrek Dilim Tempo Göstergesi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),
                for (final c in resmiCeyrekDilimler) ...[
                  _ceyrekDilimSatiri(c, gecenSaniye),
                  if (c != resmiCeyrekDilimler.last) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Kontrol Düğmeleri
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _duraklatDevam,
                icon: Icon(_duraklatildi ? Icons.play_arrow : Icons.pause),
                label: Text(_duraklatildi ? 'Devam Et' : 'Duraklat'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _bitirOnay,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Provayı Bitir'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ceyrekDilimSatiri(CeyrekDilimHedefi hedef, int gecenSaniye) {
    final hedefSaniye = hedef.hedefDakika * 60;
    final gecildi = _guncelSoruNo >= hedef.soruNo;
    final sureGecti = gecenSaniye >= hedefSaniye;

    return Row(
      children: [
        Icon(
          gecildi ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: gecildi ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hedef.etiket,
            style: TextStyle(
              fontSize: 12,
              fontWeight: gecildi ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          '${hedef.hedefDakika}. dk',
          style: TextStyle(
            fontSize: 12,
            color: sureGecti && !gecildi ? Colors.orange : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------- 3. Sonuç Ekranı

  Widget _sonucEkrani(ThemeData tema) {
    final gecenSaniye = _toplamSureSaniye - _kalanSaniye;
    final gecenDk = gecenSaniye ~/ 60;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.verified_rounded, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          Text(
            'Sınav Provası Tamamlandı',
            textAlign: TextAlign.center,
            style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Toplam süre: $gecenDk dakika · Son işaretlenen soru: $_guncelSoruNo',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const DenemeEkleEkrani()),
              );
            },
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: const Text('Doğru/Yanlışları Gir & Analiz Et'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AraDinlenmeDialog(),
            ),
            icon: const Icon(Icons.restore_rounded),
            label: const Text('135 Dk Sıfırlama Rehberi'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}
