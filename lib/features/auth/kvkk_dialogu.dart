import 'package:flutter/material.dart';

/// KVKK hafif uyum: aydınlatma metnini gösteren diyalog.
Future<void> kvkkAydinlatmaDialoguGoster(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('KVKK Aydınlatma Metni'),
      content: const SingleChildScrollView(
        child: Text(
          'MY TUS uygulaması olarak kişisel verilerinin gizliliğine önem veriyoruz:\n\n'
          '1. İşlenen Veriler:\n'
          '• E-posta adresin ve belirlediğin takma ad (kimlik doğrulama ve hesabına erişim için).\n'
          '• Çalışma planın, ders ilerlemen, deneme analizlerin, F.T. time kayıtların ve metin notların (cihazlar arası eşitleme için).\n\n'
          '2. Fotoğraflı Notlar:\n'
          '• Kitap bölümlerine eklediğin fotoğraflar buluta gönderilmez, yalnızca eklediğin cihazın hafızasında hesabına özel olarak saklanır.\n\n'
          '3. Veri Güvenliği ve Paylaşım:\n'
          '• Verilerin Google Firebase (Avrupa sunucuları) üzerinde yalnızca senin hesabının okuyabileceği güvenlik kurallarıyla saklanır. Üçüncü kişilerle paylaşılmaz.\n\n'
          '4. Hakların ve Veri Silme:\n'
          '• Dilediğin zaman Ayarlar > Hesap bölümünden hesabını ve buluttaki tüm verilerini kalıcı olarak silebilirsin.',
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Anladım'),
        ),
      ],
    ),
  );
}
