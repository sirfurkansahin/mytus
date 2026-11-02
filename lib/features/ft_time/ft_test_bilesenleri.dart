import 'package:app/core/renkler.dart';
import 'package:flutter/material.dart';

// Sayaç testi ekranının kart, satır ve bağlantı düğmesi parçaları (ft_test_screen.dart içinden ayrıldı).

class FtKart extends StatelessWidget {
  const FtKart({super.key, required this.baslik, required this.children});

  final String baslik;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ftYuzeyHafif,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            baslik,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class FtSatir extends StatelessWidget {
  const FtSatir({super.key,
    required this.etiket,
    required this.deger,
    this.renk = ftAcikYazi,
  });

  final String etiket;
  final String deger;
  final Color renk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              etiket,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              deger,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: renk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FtLinkDugme extends StatelessWidget {
  const FtLinkDugme({super.key, required this.yazi, required this.onPressed});

  final String yazi;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: const Color(0xFFC9BDF7)),
      child: Text(yazi),
    );
  }
}
