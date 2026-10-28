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
