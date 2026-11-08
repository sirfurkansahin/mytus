import 'package:app/features/auth/kimlik_servisi.dart';
import 'package:app/features/auth/kvkk_dialogu.dart';
import 'package:app/features/dersler/dialoglar.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// Ayarlar ekranında gösterilen Hesap ve Bulut yönetimi kartı.
class HesapKarti extends StatefulWidget {
  const HesapKarti({super.key});

  @override
  State<HesapKarti> createState() => _HesapKartiState();
}

class _HesapKartiState extends State<HesapKarti> {
  bool _islemSuruyor = false;

  Future<void> _cikisYap(
    BuildContext context,
    KimlikServisi kimlik,
    PlanDeposu depo,
  ) async {
    final onay = await onayDialogu(
      context,
      baslik: 'Oturum kapatılsın mı?',
      metin:
          'Çalışma verilerin bulutta güvenle saklanıyor. Bu cihazdaki çalışma '
          'verileri temizlenecek, ancak eklediğin kitap fotoğrafları hesabına '
          'özel olarak bu cihazda korunacak ve tekrar giriş yaptığında geri gelecek.',
      eylem: 'Çıkış Yap',
    );
    if (!onay || !context.mounted) return;

    setState(() => _islemSuruyor = true);
    try {
      await depo.hemenKaydet();
      await kimlik.cikisYap();
      if (!context.mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } finally {
      if (mounted) setState(() => _islemSuruyor = false);
    }
  }

  Future<void> _hesabiSil(
    BuildContext context,
    KimlikServisi kimlik,
    PlanDeposu depo,
  ) async {
    final onay = await onayDialogu(
      context,
      baslik: 'Hesabın ve verilerin silinsin mi?',
      metin:
          'Bu işlem geri alınamaz! Hesabın, buluttaki tüm çalışma verilerin ve '
          'bu cihazdaki kayıtların kalıcı olarak silinecek (KVKK kapsamında tam silme).',
      eylem: 'Hesabımı Sil',
    );
    if (!onay || !context.mounted) return;

    setState(() => _islemSuruyor = true);
    try {
      await depo.tumVerileriSifirla();
      await kimlik.hesabiSil();
      if (!context.mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on KimlikHatasi catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.mesaj)));
    } finally {
      if (mounted) setState(() => _islemSuruyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kimlik = KimlikKapsami.belki(context);
    final kullanici = kimlik?.aktifKullanici;
    if (kimlik == null || kullanici == null) {
      return const SizedBox.shrink();
    }
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final baslikYazi = (kullanici.takmaAd != null &&
            kullanici.takmaAd!.trim().isNotEmpty)
        ? '${kullanici.takmaAd} (${kullanici.eposta})'
        : kullanici.eposta;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: tema.colorScheme.primaryContainer,
                foregroundColor: tema.colorScheme.onPrimaryContainer,
                child: const Icon(Icons.person_outline_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baslikYazi,
                      style: tema.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bulut eşitleme aktif · Oturum açık',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('hesap_cikis_butonu'),
                onPressed: _islemSuruyor
                    ? null
                    : () => _cikisYap(context, kimlik, depo),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Çıkış Yap'),
              ),
              TextButton.icon(
                onPressed: () => kvkkAydinlatmaDialoguGoster(context),
                icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                label: const Text('KVKK Aydınlatma'),
              ),
              TextButton.icon(
                key: const ValueKey('hesap_sil_butonu'),
                onPressed: _islemSuruyor
                    ? null
                    : () => _hesabiSil(context, kimlik, depo),
                style: TextButton.styleFrom(
                  foregroundColor: tema.colorScheme.error,
                ),
                icon: const Icon(Icons.delete_forever_outlined, size: 18),
                label: const Text('Hesabımı Sil'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
