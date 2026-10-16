import 'package:app/features/dersler/modeller.dart';
import 'package:flutter/material.dart';

/// Tek satırlık metin soran pencere (ad değiştirme vb.). İptalde null döner.
class MetinDialogu extends StatefulWidget {
  const MetinDialogu({
    super.key,
    required this.baslik,
    this.ilkDeger = '',
    this.ipucu = '',
    this.eylem = 'Kaydet',
  });

  final String baslik;
  final String ilkDeger;
  final String ipucu;
  final String eylem;

  static Future<String?> goster(
    BuildContext context, {
    required String baslik,
    String ilkDeger = '',
    String ipucu = '',
    String eylem = 'Kaydet',
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => MetinDialogu(
        baslik: baslik,
        ilkDeger: ilkDeger,
        ipucu: ipucu,
        eylem: eylem,
      ),
    );
  }

  @override
  State<MetinDialogu> createState() => _MetinDialoguState();
}

class _MetinDialoguState extends State<MetinDialogu> {
  late final TextEditingController _denetci =
      TextEditingController(text: widget.ilkDeger);

  @override
  void dispose() {
    _denetci.dispose();
    super.dispose();
  }

  void _tamam() => Navigator.of(context).pop(_denetci.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.baslik),
      content: TextField(
        controller: _denetci,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: widget.ipucu),
        onSubmitted: (_) => _tamam(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(onPressed: _tamam, child: Text(widget.eylem)),
      ],
    );
  }
}

/// "Emin misin?" penceresi. Onaylanırsa true döner.
Future<bool> onayDialogu(
  BuildContext context, {
  required String baslik,
  required String metin,
  required String eylem,
}) async {
  final sonuc = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(baslik),
      content: Text(metin),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(eylem),
        ),
      ],
    ),
  );
  return sonuc ?? false;
}

typedef DersTaslagi = ({String ad, DersGrubu grup});

/// Ders adı ve grubu (Temel/Klinik) soran pencere. İptalde null döner.
Future<DersTaslagi?> dersEkleDialogu(
  BuildContext context, {
  DersGrubu baslangicGrubu = DersGrubu.temel,
}) {
  return showDialog<DersTaslagi>(
    context: context,
    builder: (_) => _DersEkleDialogu(baslangicGrubu: baslangicGrubu),
  );
}

class _DersEkleDialogu extends StatefulWidget {
  const _DersEkleDialogu({required this.baslangicGrubu});

  final DersGrubu baslangicGrubu;

  @override
  State<_DersEkleDialogu> createState() => _DersEkleDialoguState();
}

class _DersEkleDialoguState extends State<_DersEkleDialogu> {
  final TextEditingController _denetci = TextEditingController();
  late DersGrubu _grup = widget.baslangicGrubu;

  @override
  void dispose() {
    _denetci.dispose();
    super.dispose();
  }

  void _tamam() => Navigator.of(context).pop((ad: _denetci.text, grup: _grup));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ders ekle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _denetci,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Ders adı'),
            onSubmitted: (_) => _tamam(),
          ),
          const SizedBox(height: 16),
          SegmentedButton<DersGrubu>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: DersGrubu.temel, label: Text('Temel')),
              ButtonSegment(value: DersGrubu.klinik, label: Text('Klinik')),
            ],
            selected: {_grup},
            onSelectionChanged: (secim) => setState(() => _grup = secim.first),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(onPressed: _tamam, child: const Text('Ekle')),
      ],
    );
  }
}
