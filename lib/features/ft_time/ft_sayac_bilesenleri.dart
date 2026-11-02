import 'package:app/core/renkler.dart';
import 'package:flutter/material.dart';

// Sayaç ekranında kullanılan ortak parçalar (ft_sayac_ekrani.dart içinden ayrıldı).

class FtDugme extends StatelessWidget {
  const FtDugme({super.key, required this.yazi, required this.onPressed});

  final String yazi;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: ftVurgu,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
      ),
      child: Text(yazi),
    );
  }
}

/// Onaylı tasarımdaki görsel döngü noktaları (● ○ ○ ○).
class FtDonguNoktalari extends StatelessWidget {
  const FtDonguNoktalari({
    super.key,
    required this.toplamDongu,
    required this.tamamlananDongu,
    required this.aktifDongu,
  });

  final int toplamDongu;
  final int tamamlananDongu;
  final int aktifDongu;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        for (var i = 1; i <= toplamDongu; i++)
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= tamamlananDongu
                  ? ftIyi
                  : (i == aktifDongu ? Colors.white : Colors.transparent),
              border: Border.all(
                color: i <= tamamlananDongu
                    ? ftIyi
                    : (i == aktifDongu ? Colors.white : ftCizgi),
                width: 1.8,
              ),
            ),
          ),
      ],
    );
  }
}

/// Pil tasarrufu uygulamayı kısıtlıyorsa süre bitince uyarının gecikebileceğini söyler.
class FtPilUyarisi extends StatelessWidget {
  const FtPilUyarisi({super.key, required this.onAyar, required this.onKapat});

  final VoidCallback onAyar;
  final VoidCallback onKapat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 6),
      decoration: BoxDecoration(
        color: ftUyariZemin,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Telefonun pil tasarrufu MY TUS\'u kısıtlıyor olabilir; süre '
                  'bitince uyarı gecikebilir.',
                  style: TextStyle(fontSize: 13, color: ftUyari),
                ),
              ),
              IconButton(
                tooltip: 'Uyarıyı kapat',
                onPressed: onKapat,
                icon: const Icon(Icons.close, size: 18, color: ftUyari),
              ),
            ],
          ),
          TextButton(
            onPressed: onAyar,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Pil ayarlarını aç'),
          ),
        ],
      ),
    );
  }
}
