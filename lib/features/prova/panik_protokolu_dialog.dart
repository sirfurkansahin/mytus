import 'dart:async';
import 'package:flutter/material.dart';

/// 90 Saniyelik Panik & Döngüsel İç Çekme (Cyclic Sighing) Aracı.
/// (Master Araştırma Raporu Bölüm 5.2 - Huberman Lab & Jamieson Bilişsel Yeniden Değerlendirme)
class PanikProtokoluDialog extends StatefulWidget {
  const PanikProtokoluDialog({super.key});

  @override
  State<PanikProtokoluDialog> createState() => _PanikProtokoluDialogState();
}

class _PanikProtokoluDialogState extends State<PanikProtokoluDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  Timer? _zamanlayici;

  int _kalanSaniye = 84; // 7 döngü x 12 sn = 84 saniye
  int _dongu = 1;
  static const int _toplamDongu = 7;

  // 1 döngü: 12 saniye
  // 0.0 - 3.5 sn (faz 1): Derin burun nefesi
  // 3.5 - 5.0 sn (faz 2): İkinci kısa burun nefesi (alveol açma)
  // 5.0 - 12.0 sn (faz 3): Yavaş ağız verişi (vagal tonus)
  int _faz = 1; // 1: Derin Al, 2: İkinci Kısa Al, 3: Yavaşça Ver

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );
    _anim.addListener(_animDinleyici);
    _baslat();
  }

  void _animDinleyici() {
    final v = _anim.value; // 0.0 to 1.0
    // 3.5 / 12 = 0.2917, 5.0 / 12 = 0.4167
    final yeniFaz = v < 0.2917 ? 1 : (v < 0.4167 ? 2 : 3);
    if (yeniFaz != _faz && mounted) {
      setState(() => _faz = yeniFaz);
    }
  }

  void _baslat() {
    _anim.repeat();
    _zamanlayici?.cancel();
    _zamanlayici = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_kalanSaniye > 0) {
          _kalanSaniye--;
          _dongu = ((84 - _kalanSaniye) ~/ 12) + 1;
          if (_dongu > _toplamDongu) _dongu = _toplamDongu;
        } else {
          _zamanlayici?.cancel();
          _anim.stop();
        }
      });
    });
  }

  @override
  void dispose() {
    _anim.removeListener(_animDinleyici);
    _anim.dispose();
    _zamanlayici?.cancel();
    super.dispose();
  }

  String get _fazBasligi {
    switch (_faz) {
      case 1:
        return '1. Burundan Derin Nefes Alın';
      case 2:
        return '2. Kısa Bir Nefes Daha Ekleyin!';
      default:
        return '3. Ağızdan Yavaşça ve Tamamen Verin';
    }
  }

  String get _fazAciklamasi {
    switch (_faz) {
      case 1:
        return 'Diyaframınızı şişirerek 3-4 saniye burundan derin nefes çekin.';
      case 2:
        return 'Nefesi bırakmadan alveolleri yeniden açmak için kısa bir ek nefes alın.';
      default:
        return 'Dudaklarınızı hafif aralayarak 6-7 saniye boyunca tüm havayı boşaltın.';
    }
  }

  Color get _halkaRengi {
    switch (_faz) {
      case 1:
        return Colors.blueAccent;
      case 2:
        return Colors.indigoAccent;
      default:
        return Colors.tealAccent.shade700;
    }
  }

  double get _olcek {
    final v = _anim.value;
    if (v < 0.2917) {
      // 0.0 -> 0.85
      return 0.5 + (0.35 * (v / 0.2917));
    } else if (v < 0.4167) {
      // 0.85 -> 1.0 (ikinci nefesle tepe nokta)
      final p = (v - 0.2917) / (0.4167 - 0.2917);
      return 0.85 + (0.15 * p);
    } else {
      // 1.0 -> 0.5 (yavaşça sönme)
      final p = (v - 0.4167) / (1.0 - 0.4167);
      return 1.0 - (0.5 * p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tamamlandi = _kalanSaniye <= 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.air_rounded, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '90 sn Döngüsel İç Çekme',
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!tamamlandi) ...[
                // Animasyonlu Nefes Halkası
                SizedBox(
                  height: 180,
                  width: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: _olcek,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _halkaRengi.withValues(alpha: 0.18),
                            border: Border.all(color: _halkaRengi, width: 3),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_kalanSaniye sn',
                            style: tema.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: _halkaRengi,
                            ),
                          ),
                          Text(
                            'Döngü $_dongu / $_toplamDongu',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _fazBasligi,
                  textAlign: TextAlign.center,
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _halkaRengi,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _fazAciklamasi,
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodySmall,
                ),
              ] else ...[
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
                const SizedBox(height: 12),
                Text(
                  'Vagal Tonus Aktifleştirildi',
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Alveoller açıldı, sempatik aşırı uyarım dengelendi. Beyniniz şimdi odaklanmış ve sakin bir frekansta çalışmaya hazır.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              // Jamieson Bilişsel Yeniden Çerçeveleme Kartı (Rapor 5.2)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.psychology, size: 18, color: Colors.indigo),
                        SizedBox(width: 6),
                        Text(
                          'Bilişsel Yeniden Değerlendirme',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '“Vücudum tehlikede değil. Kalp çarpıntısı ve sempatik uyarılma, '
                      'beynime glikoz ve oksijen pompalandığını, sınav görevine odaklanmamı '
                      'artıracağını gösterir.”',
                      style: tema.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tamamlandi ? 'Soruya Dön' : 'Protokolü Bitir & Devam Et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
