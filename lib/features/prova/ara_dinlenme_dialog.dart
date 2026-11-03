import 'package:flutter/material.dart';

/// İki Oturum Arası 135 Dakikalık Sıfırlama (Reset) Protokolü.
/// (Master Araştırma Raporu Bölüm 5.1 - 10:15 TTBT ile 14:45 KTBT Arası)
class AraDinlenmeDialog extends StatelessWidget {
  const AraDinlenmeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.restore_rounded, color: Colors.indigo),
          SizedBox(width: 8),
          Expanded(child: Text('İki Oturum Arası Sıfırlama')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '10:15 TTBT bitişi (12:30) ile 14:45 KTBT başlangıcı arasındaki 135 dakikalık altın dinlenme protokolü.',
              style: tema.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _madde(
              icon: Icons.cancel_outlined,
              renk: Colors.red,
              baslik: '1. Kesinlikle Cevap Tartışmayın',
              icerik:
                  'Diğer adaylarla şıkları karşılaştırmak sempatik sistemi ve kortizolü fırlatır; Klinik testi öncesi karar merkezini tüketir.',
            ),
            const SizedBox(height: 10),
            _madde(
              icon: Icons.restaurant_outlined,
              renk: Colors.orange,
              baslik: '2. Sindirimi Kolay Beslenme',
              icerik:
                  'Ağır karbonhidrat kan şekerini dalgalandırır ve reaktif hipoglisemi yaratır. Hafif protein, kuruyemiş ve su tercih edin.',
            ),
            const SizedBox(height: 10),
            _madde(
              icon: Icons.directions_walk_outlined,
              renk: Colors.green,
              baslik: '3. 15 Dk Düşük Tempolu Yürüyüş',
              icerik:
                  'Açık havada hafif yürüyüş beyne kan akımını canlandırır ve göz kaslarının uzağa odaklanarak dinlenmesini sağlar.',
            ),
            const SizedBox(height: 10),
            _madde(
              icon: Icons.air_outlined,
              renk: Colors.teal,
              baslik: '4. Döngüsel İç Çekme Uygulayın',
              icerik:
                  'Klinik oturumuna girmeden 15 dakika önce 90 saniyelik döngüsel iç çekme yaparak kalp hızınızı ve vagal tonusunuzu sabitleyin.',
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

  Widget _madde({
    required IconData icon,
    required Color renk,
    required String baslik,
    required String icerik,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: renk, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: renk)),
                const SizedBox(height: 2),
                Text(icerik, style: const TextStyle(fontSize: 11, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
