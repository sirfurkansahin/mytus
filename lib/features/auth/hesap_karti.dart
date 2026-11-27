import 'package:app/features/auth/kimlik_servisi.dart';
import 'package:app/features/auth/kvkk_dialogu.dart';
import 'package:app/features/dersler/dialoglar.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/senkronizasyon/bulut_senkron_servisi.dart';
import 'package:flutter/material.dart';

/// Ayarlar ekranında gösterilen Hesap ve Bulut yönetimi kartı.
class HesapKarti extends StatefulWidget {
  const HesapKarti({super.key});

  @override
  State<HesapKarti> createState() => _HesapKartiState();
}

class _HesapKartiState extends State<HesapKarti> {
  bool _islemSuruyor = false;

  String _durumEtiketi(SenkronDurumu? durum) {
    switch (durum) {
      case SenkronDurumu.gonderiliyor:
        return 'Buluta eşitleniyor...';
      case SenkronDurumu.bekleyenDegisiklikVar:
        return 'Bekleyen değişiklikler var · Birkaç sn içinde eşitlenecek';
      case SenkronDurumu.cevrimdisi:
        return 'Çevrimdışı · İnternet gelince otomatik eşitlenecek';
      case SenkronDurumu.esitlendi:
      case null:
        return 'Bulut eşitleme aktif · Tüm veriler güncel';
    }
  }

  Future<void> _cikisYap(
    BuildContext context,
    KimlikServisi kimlik,
    PlanDeposu depo,
    BulutSenkronServisi? senkron,
  ) async {
    final bekleyenUyarisi = (senkron != null && senkron.bekleyenVarMi)
        ? '\n\n⚠️ Dikkat: Henüz buluta gönderilmemiş değişikliklerin var. İnternet bağlantın yoksa çıkış yapmadan önce bağlantını kontrol et.'
        : '';
    final onay = await onayDialogu(
      context,
      baslik: 'Oturum kapatılsın mı?',
      metin:
          'Çalışma verilerin bulutta güvenle saklanıyor. Bu cihazdaki çalışma '
          'verileri temizlenecek, ancak eklediğin kitap fotoğrafları hesabına '
          'özel olarak bu cihazda korunacak ve tekrar giriş yaptığında geri gelecek.$bekleyenUyarisi',
      eylem: 'Çıkış Yap',
    );
    if (!onay || !context.mounted) return;

    setState(() => _islemSuruyor = true);
    try {
      await depo.hemenKaydet();
      if (senkron != null) {
        await senkron.oturumKapatildi(hesabiTamamenSil: false);
      } else {
        await depo.tumVerileriSifirla();
      }
      await depo.misafirModunuAyarla(false);
      await kimlik.cikisYap();
      if (!context.mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } finally {
      if (mounted) setState(() => _islemSuruyor = false);
    }
  }

  /// Girişte seçilmeyen veri cihazda yedek olarak durur; kullanıcı isterse
  /// yer değiştirir (şu anki veri yedeğe geçer, hiçbir şey silinmez).
  Future<void> _yedegiGetir(
    BuildContext context,
    BulutSenkronServisi senkron,
  ) async {
    final onay = await onayDialogu(
      context,
      baslik: 'Cihazdaki yedek geri getirilsin mi?',
      metin:
          'Girişte seçmediğin veri bu cihazda yedek olarak duruyor. Geri '
          'getirirsen şu anki verin onun yerine yedeğe geçer (hiçbir şey '
          'silinmez) ve geri getirdiğin veri hesabına gönderilir.',
      eylem: 'Yedeği Getir',
    );
    if (!onay || !context.mounted) return;
    setState(() => _islemSuruyor = true);
    try {
      final oldu = await senkron.yedegiGeriYukle();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              oldu ? 'Yedek geri getirildi.' : 'Geri getirilecek yedek yok.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _islemSuruyor = false);
    }
  }

  Future<void> _hesabiSil(
    BuildContext context,
    KimlikServisi kimlik,
    PlanDeposu depo,
    BulutSenkronServisi? senkron,
  ) async {
    final sifre = await _silmeSifresiSor(context);
    if (sifre == null || !context.mounted) return;

    setState(() => _islemSuruyor = true);
    try {
      // Önce şifre doğrulanır; doğrulanamazsa hiçbir şey silinmez.
      await hesabiGuvenliSil(
        kimlik: kimlik,
        sifre: sifre,
        verileriSil: () async {
          if (senkron != null) {
            await senkron.oturumKapatildi(hesabiTamamenSil: true);
          } else {
            await depo.tumVerileriSifirla();
          }
          await depo.misafirModunuAyarla(false);
        },
      );
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

  /// Hesap silme onayı: geri alınamaz uyarısı ve şifre. Vazgeçilirse null.
  Future<String?> _silmeSifresiSor(BuildContext context) => showDialog<String>(
        context: context,
        builder: (context) => const _SilmeSifresiDialogu(),
      );

  @override
  Widget build(BuildContext context) {
    final kimlik = KimlikKapsami.belki(context);
    final kullanici = kimlik?.aktifKullanici;
    if (kimlik == null || kullanici == null) {
      return const SizedBox.shrink();
    }
    final depo = DepoKapsami.of(context);
    final senkron = SenkronKapsami.belki(context);
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
                child: const Icon(Icons.cloud_done_outlined),
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
                      _durumEtiketi(senkron?.durum),
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
                    : () => _cikisYap(context, kimlik, depo, senkron),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Çıkış Yap'),
              ),
              if (senkron != null && senkron.yedekVar)
                TextButton.icon(
                  key: const ValueKey('hesap_yedek_butonu'),
                  onPressed: _islemSuruyor
                      ? null
                      : () => _yedegiGetir(context, senkron),
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('Cihazdaki yedeği getir'),
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
                    : () => _hesabiSil(context, kimlik, depo, senkron),
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

/// Hesap silme onay penceresi (şifre alanıyla).
class _SilmeSifresiDialogu extends StatefulWidget {
  const _SilmeSifresiDialogu();

  @override
  State<_SilmeSifresiDialogu> createState() => _SilmeSifresiDialoguState();
}

class _SilmeSifresiDialoguState extends State<_SilmeSifresiDialogu> {
  final TextEditingController _sifre = TextEditingController();

  @override
  void dispose() {
    _sifre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hesabın ve verilerin silinsin mi?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bu işlem geri alınamaz! Hesabın, buluttaki tüm çalışma verilerin '
            've bu cihazdaki kayıtların kalıcı olarak silinecek (KVKK kapsamında '
            'tam silme). Onaylamak için şifreni gir.',
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('hesap_sil_sifre'),
            controller: _sifre,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Şifre'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          key: const ValueKey('hesap_sil_onay'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(_sifre.text),
          child: const Text('Hesabımı Sil'),
        ),
      ],
    );
  }
}
