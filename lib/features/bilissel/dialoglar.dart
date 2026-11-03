import 'package:app/features/bilissel/modeller.dart';
import 'package:flutter/material.dart';

/// Dün geceki uykuyu hızlıca kaydetme dialogu.
class UykuKaydetDialog extends StatefulWidget {
  const UykuKaydetDialog({
    super.key,
    required this.hedefYatis,
    required this.hedefKalkis,
    this.mevcutKayit,
  });

  final String hedefYatis;
  final String hedefKalkis;
  final UykuKaydi? mevcutKayit;

  @override
  State<UykuKaydetDialog> createState() => _UykuKaydetDialogState();
}

class _UykuKaydetDialogState extends State<UykuKaydetDialog> {
  late TimeOfDay _yatis;
  late TimeOfDay _kalkis;
  TimeOfDay? _sonKafein;
  int _kalite = 4;

  @override
  void initState() {
    super.initState();
    final m = widget.mevcutKayit;
    if (m != null) {
      _yatis = _saatCoz(m.yatisSaati);
      _kalkis = _saatCoz(m.kalkisSaati);
      if (m.sonKafeinSaati != null) {
        _sonKafein = _saatCoz(m.sonKafeinSaati!);
      }
      _kalite = m.kalite;
    } else {
      _yatis = _saatCoz(widget.hedefYatis);
      _kalkis = _saatCoz(widget.hedefKalkis);
    }
  }

  TimeOfDay _saatCoz(String s) {
    final p = s.split(':');
    final saat = int.tryParse(p[0]) ?? 23;
    final dk = int.tryParse(p.length > 1 ? p[1] : '0') ?? 0;
    return TimeOfDay(hour: saat, minute: dk);
  }

  String _format(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  int _toplamUykuDakika() {
    final yatisDk = _yatis.hour * 60 + _yatis.minute;
    final kalkisDk = _kalkis.hour * 60 + _kalkis.minute;
    var fark = kalkisDk - yatisDk;
    if (fark <= 0) fark += 1440; // Gece yarısı devri
    return fark;
  }

  Future<void> _saatSec(bool yatisMi) async {
    final secilen = await showTimePicker(
      context: context,
      initialTime: yatisMi ? _yatis : _kalkis,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (secilen == null || !mounted) return;
    setState(() {
      if (yatisMi) {
        _yatis = secilen;
      } else {
        _kalkis = secilen;
      }
    });
  }

  Future<void> _kafeinSec() async {
    final secilen = await showTimePicker(
      context: context,
      initialTime: _sonKafein ?? const TimeOfDay(hour: 15, minute: 0),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (secilen == null || !mounted) return;
    setState(() => _sonKafein = secilen);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final toplamDk = _toplamUykuDakika();
    final saat = toplamDk ~/ 60;
    final dk = toplamDk % 60;

    final yatisStr = _format(_yatis);
    final kalkisStr = _format(_kalkis);
    final sapma = daireselDakikaFarki(yatisStr, widget.hedefYatis);
    final kafeinTavsiyesi = kafeinKesilmeSaatiHesapla(yatisStr);

    final sureUyumlu = toplamDk >= 420 && toplamDk <= 540;
    final sapmaUyumlu = sapma <= 30;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.bedtime_outlined, color: Colors.indigo),
          SizedBox(width: 8),
          Expanded(child: Text('Uyku & Ritim Kaydı')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bellek konsolidasyonu ve prefrontal korteks yenilenmesi için uyku takibi.',
              style: tema.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sureUyumlu && sapmaUyumlu
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sureUyumlu && sapmaUyumlu ? Colors.green : Colors.amber,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '$saat saat $dk dakika uyku',
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: sureUyumlu && sapmaUyumlu ? Colors.green[800] : Colors.amber[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sapmaUyumlu
                        ? '✅ Yatış sapması: $sapma dk (±30 dk hedefinde)'
                        : '⚠️ Yatış sapması: $sapma dk (Hedef: ±30 dk)',
                    style: tema.textTheme.bodySmall,
                  ),
                  Text(
                    sureUyumlu
                        ? '✅ Uyku süresi ideal (7 - 9 saat)'
                        : '⚠️ Hedef: 7 - 9 saat (Şu an: ${saat}s ${dk}dk)',
                    style: tema.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _saatSec(true),
                    icon: const Icon(Icons.nightlight_round, size: 18),
                    label: Text('Yatış: $yatisStr'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _saatSec(false),
                    icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                    label: Text('Kalkış: $kalkisStr'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _kafeinSec,
              icon: const Icon(Icons.coffee_outlined, size: 18),
              label: Text(
                _sonKafein == null
                    ? 'Son Kafein Saati Ekle (Tavsiye: $kafeinTavsiyesi)'
                    : 'Son Kafein: ${_format(_sonKafein!)}',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Uyku Dinlendiriciliği / Kalite:',
              style: tema.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () => setState(() => _kalite = i),
                    icon: Icon(
                      i <= _kalite ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber[700],
                      size: 30,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            final kayit = UykuKaydi(
              tarih: widget.mevcutKayit?.tarih ?? DateTime.now().toIso8601String().substring(0, 10),
              uykuSuresiDakika: toplamDk,
              yatisSaati: yatisStr,
              kalkisSaati: kalkisStr,
              hedefYatisSaati: widget.hedefYatis,
              sonKafeinSaati: _sonKafein != null ? _format(_sonKafein!) : null,
              kalite: _kalite,
            );
            Navigator.of(context).pop(kayit);
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

/// Hedef uyku penceresini düzenleme dialogu.
class HedefUykuDialog extends StatefulWidget {
  const HedefUykuDialog({
    super.key,
    required this.hedefYatis,
    required this.hedefKalkis,
  });

  final String hedefYatis;
  final String hedefKalkis;

  @override
  State<HedefUykuDialog> createState() => _HedefUykuDialogState();
}

class _HedefUykuDialogState extends State<HedefUykuDialog> {
  late TimeOfDay _yatis;
  late TimeOfDay _kalkis;

  @override
  void initState() {
    super.initState();
    _yatis = _coz(widget.hedefYatis);
    _kalkis = _coz(widget.hedefKalkis);
  }

  TimeOfDay _coz(String s) {
    final p = s.split(':');
    final saat = int.tryParse(p[0]) ?? 23;
    final dk = int.tryParse(p.length > 1 ? p[1] : '0') ?? 0;
    return TimeOfDay(hour: saat, minute: dk);
  }

  String _format(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _sec(bool yatisMi) async {
    final s = await showTimePicker(
      context: context,
      initialTime: yatisMi ? _yatis : _kalkis,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (s == null || !mounted) return;
    setState(() {
      if (yatisMi) {
        _yatis = s;
      } else {
        _kalkis = s;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final yatisStr = _format(_yatis);
    final kalkisStr = _format(_kalkis);
    final kafeinSaati = kafeinKesilmeSaatiHesapla(yatisStr);

    return AlertDialog(
      title: const Text('Hedef Sirkadiyen Pencere'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Her gün aynı saatte yatıp kalkmak (±30 dk), derin NREM ve REM evrelerini korur.',
            style: tema.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: tema.colorScheme.surfaceContainerHighest,
            title: const Text('Hedef Yatış Saati'),
            trailing: Text(yatisStr, style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            onTap: () => _sec(true),
          ),
          const SizedBox(height: 8),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: tema.colorScheme.surfaceContainerHighest,
            title: const Text('Hedef Kalkış Saati'),
            trailing: Text(kalkisStr, style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            onTap: () => _sec(false),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.brown.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.brown.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.coffee, color: Colors.brown),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '☕ Bu hedefe göre kafein her gün en geç $kafeinSaati\'da kesilmelidir (8 saat kuralı).',
                    style: tema.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop({
            'yatis': yatisStr,
            'kalkis': kalkisStr,
          }),
          child: const Text('Güncelle'),
        ),
      ],
    );
  }
}

/// F.T. Time blok bitiminde tek dokunuşla odak değerlendirmesi.
class OdakDegerlendirDialog extends StatefulWidget {
  const OdakDegerlendirDialog({
    super.key,
    required this.mevcutPuan,
    required this.mevcutZorBilissel,
  });

  final int mevcutPuan;
  final bool mevcutZorBilissel;

  @override
  State<OdakDegerlendirDialog> createState() => _OdakDegerlendirDialogState();
}

class _OdakDegerlendirDialogState extends State<OdakDegerlendirDialog> {
  late int _puan;
  late bool _zor;

  @override
  void initState() {
    super.initState();
    _puan = widget.mevcutPuan;
    _zor = widget.mevcutZorBilissel;
  }

  static const _seviyeler = [
    'Çok Dağınık (Düşük)',
    'Zorlandı (Düşük Odak)',
    'Orta (Standart)',
    'Yüksek (Çok İyi)',
    'Zirve Akış (Flow State)',
  ];

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.bolt_rounded, color: Colors.amber),
          SizedBox(width: 8),
          Expanded(child: Text('Blok Odak Değerlendirmesi')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bu bloktaki odaklanma seviyeniz nasıldı?',
            style: tema.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 1; i <= 5; i++)
                InkWell(
                  onTap: () => setState(() => _puan = i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _puan == i
                          ? tema.colorScheme.primaryContainer
                          : tema.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _puan == i ? tema.colorScheme.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: _puan >= i ? Colors.amber[700] : Colors.grey,
                          size: 24,
                        ),
                        Text('$i', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _seviyeler[_puan - 1],
              style: tema.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: tema.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _zor,
            onChanged: (v) => setState(() => _zor = v),
            title: const Text('Zor Bilişsel İş (Ağır Analitik)'),
            subtitle: const Text('Yeni konu, deneme, derin soru analizi (3-4 saat tavanına sayılır).'),
            dense: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop({
            'odak': _puan,
            'zor': _zor,
          }),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
