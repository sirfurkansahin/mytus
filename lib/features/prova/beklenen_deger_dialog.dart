import 'package:app/features/prova/modeller.dart';
import 'package:flutter/material.dart';

/// Cevap Değiştirme ve Beklenen Değer (EV) Kartı.
/// (Master Araştırma Raporu Bölüm 5.3)
class BeklenenDegerDialog extends StatefulWidget {
  const BeklenenDegerDialog({super.key});

  @override
  State<BeklenenDegerDialog> createState() => _BeklenenDegerDialogState();
}

class _BeklenenDegerDialogState extends State<BeklenenDegerDialog> {
  int _elenenSik = 2; // Varsayılan: 2 şık elendi (3 şık kaldı)

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final kalanSik = 5 - _elenenSik;
    final ev = beklenenDegerHesapla(_elenenSik);

    final Color evRenk;
    final String tavsiye;
    if (_elenenSik >= 2) {
      evRenk = Colors.green;
      tavsiye = '✅ MATEMATİKSEL KAZANÇ: 2 veya daha fazla şıkkı güvenle elediyseniz '
          'soruyu ASLA boş bırakmayın. İşaretlemek uzun vadede her zaman net kazandırır (+${ev.toStringAsFixed(3)} net/soru).';
    } else if (_elenenSik == 1) {
      evRenk = Colors.blue;
      tavsiye = '⚡ HAFİF POZİTİF: 1 şık elendiğinde beklenen değer pozitiftir (+${ev.toStringAsFixed(3)} net), '
          'fakat sezgisel bir dayanağınız yoksa risk kontrollü yaklaşılabilir.';
    } else {
      evRenk = Colors.grey;
      tavsiye = '⛔ NÖTR GETİRİ: Hiçbir şık elenmediğinde beklenen değer sıfırdır (0.00 net). '
          'Kör tahmin yapmak gereksiz varyans ve moral bozukluğu yaratır; boş bırakın.';
    }

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.calculate_outlined, color: Colors.indigo),
          SizedBox(width: 8),
          Expanded(child: Text('Beklenen Değer (EV) & Cevap')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ÖSYM 5 şıklı sınav mimarisinde (+1 doğru / -0.25 yanlış) matematiksel getiri.',
              style: tema.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: evRenk.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: evRenk.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Elenen Şık: $_elenenSik / 5',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Kalan Şık: $kalanSik',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ev >= 0 ? '+${ev.toStringAsFixed(3)} Net' : '${ev.toStringAsFixed(3)} Net',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: evRenk,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tavsiye,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: evRenk, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Güvenle Elediğiniz Şık Sayısı:', style: tema.textTheme.labelMedium),
            Slider(
              value: _elenenSik.toDouble(),
              min: 0,
              max: 3,
              divisions: 3,
              label: '$_elenenSik şık elendi',
              onChanged: (v) => setState(() => _elenenSik = v.round()),
            ),
            const SizedBox(height: 12),
            // Altın Cevap Değiştirme Kuralları (Rapor 5.3)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tema.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.rule, size: 16, color: Colors.amber[800]),
                      const SizedBox(width: 6),
                      const Text(
                        'Cevap Değiştirme Altın Kuralı',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '⚠️ Adayların kaygıyla değiştirdiği cevapların %57.8\'i net kaybına yol açar.\n\n'
                    'Sadece 2 durumda cevap değiştirin:\n'
                    '1. Soruda kaçırdığınız somut bir klinik bulguyu/öncülü fark ettiyseniz.\n'
                    '2. İlk işaretleme "Kararsız" olup yeni şık net bir mekanizma zinciriyle doğrulanıyorsa.',
                    style: TextStyle(fontSize: 11, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anladım'),
        ),
      ],
    );
  }
}
