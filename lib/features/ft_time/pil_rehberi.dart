import 'package:app/features/ft_time/ft_native.dart';
import 'package:flutter/material.dart';

const String _rehberAnahtari = 'guide_seen';

/// Rehber daha önce gösterilmediyse gösterir (ilk odak başlatılınca).
Future<void> pilRehberiniBirKezGoster(
  BuildContext context,
  FtNative native,
) async {
  final goruldu = await native.kayitOku(_rehberAnahtari);
  if (goruldu != null || !context.mounted) return;
  await pilRehberiGoster(context, native);
}

/// "Sayacın arka planda çalışması için" rehberi (pil ve bildirim ayarları).
Future<void> pilRehberiGoster(BuildContext context, FtNative native) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final tema = Theme.of(sheetContext);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sayacın arka planda çalışması için',
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bazı telefonlarda sistem, kapalı görünen uygulamaları pil '
                'tasarrufu için durdurur. Süre bitince seni uyarabilmem için '
                'şunları yap:',
                style: tema.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                '1. Bildirim iznini ver.\n'
                '2. "Pil ayarlarını aç" düğmesine bas ve MY TUS için '
                'kısıtlama olmamasını (optimize etme) seç.\n'
                '3. "Uygulama ayarlarını aç" düğmesine bas; pil kullanımı '
                'bölümünde "arka planda çalışmaya izin ver" ve varsa '
                '"otomatik başlatma" seçeneğini aç.',
                style: tema.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Menü adları telefon markasına ve sürümüne göre biraz '
                'değişebilir. Bu ayarlar sonradan Ayarlar ekranından da açılabilir.',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: native.pilAyarlariniAc,
                child: const Text('Pil ayarlarını aç'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: native.uygulamaAyarlariniAc,
                child: const Text('Uygulama ayarlarını aç'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Anladım'),
              ),
            ],
          ),
        ),
      );
    },
  );
  await native.kayitYaz(_rehberAnahtari, '1');
}

/// Ayarlar'daki "Arka plan" kartı: bildirim ve pil durumunu gösterir.
class ArkaPlanKarti extends StatefulWidget {
  const ArkaPlanKarti({super.key, this.native = const FtNative()});

  final FtNative native;

  @override
  State<ArkaPlanKarti> createState() => _ArkaPlanKartiState();
}

class _ArkaPlanKartiState extends State<ArkaPlanKarti>
    with WidgetsBindingObserver {
  bool? _bildirim;
  bool? _pil;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _oku();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState durum) {
    if (durum == AppLifecycleState.resumed) _oku();
  }

  Future<void> _oku() async {
    final bildirim = await widget.native.bildirimAcik();
    final pil = await widget.native.pilKisitsiz();
    if (!mounted) return;
    setState(() {
      _bildirim = bildirim;
      _pil = pil;
    });
  }

  String _yazi(bool? deger, String acik, String kapali) =>
      deger == null ? 'Bilinmiyor' : (deger ? acik : kapali);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: const Text('Bildirim izni'),
          trailing: Text(_yazi(_bildirim, 'Açık', 'Kapalı')),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: const Text('Pil kısıtlaması'),
          subtitle: Text(
            'Kısıtlama varsa süre bitince uyarı gecikebilir.',
            style: tema.textTheme.bodySmall,
          ),
          trailing: Text(_yazi(_pil, 'Yok (iyi)', 'Olabilir')),
        ),
        Wrap(
          spacing: 4,
          children: [
            TextButton(
              onPressed: widget.native.pilAyarlariniAc,
              child: const Text('Pil ayarlarını aç'),
            ),
            TextButton(
              onPressed: widget.native.uygulamaAyarlariniAc,
              child: const Text('Uygulama ayarlarını aç'),
            ),
            TextButton(
              onPressed: () => pilRehberiGoster(context, widget.native),
              child: const Text('Rehberi göster'),
            ),
          ],
        ),
      ],
    );
  }
}
