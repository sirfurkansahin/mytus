import 'package:flutter/material.dart';

/// Veriler cihaza kaydedilemediğinde (ör. tarayıcı deposu dolu) tüm ekranların
/// üstünde görünen uyarı şeridi. Kullanıcı kaydın yapılmadığını bilmeli.
class KayitHatasiSeridi extends StatelessWidget {
  const KayitHatasiSeridi({super.key, required this.yenidenDene});

  final VoidCallback yenidenDene;

  @override
  Widget build(BuildContext context) {
    final renkler = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('kayit_hatasi_seridi'),
      color: renkler.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: renkler.onErrorContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Son değişiklikler bu cihaza kaydedilemedi. Tarayıcı deposu '
                  'dolmuş olabilir: fotoğraflı notları azaltıp tekrar dene. '
                  'Uygulamayı kapatırsan bu değişiklikler kaybolabilir.',
                  style: TextStyle(
                    color: renkler.onErrorContainer,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('kayit_hatasi_tekrar_dene'),
                onPressed: yenidenDene,
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
