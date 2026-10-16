import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/ft_time/ft_oturum.dart';
import 'package:flutter/material.dart';

/// Bir sayı soran pencere (dakika, adet). İptalde null döner.
Future<int?> sayiDialogu(
  BuildContext context, {
  required String baslik,
  required int ilkDeger,
  required int enAz,
  required int enCok,
  required String birim,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _SayiDialogu(
      baslik: baslik,
      ilkDeger: ilkDeger,
      enAz: enAz,
      enCok: enCok,
      birim: birim,
    ),
  );
}

class _SayiDialogu extends StatefulWidget {
  const _SayiDialogu({
    required this.baslik,
    required this.ilkDeger,
    required this.enAz,
    required this.enCok,
    required this.birim,
  });

  final String baslik;
  final int ilkDeger;
  final int enAz;
  final int enCok;
  final String birim;

  @override
  State<_SayiDialogu> createState() => _SayiDialoguState();
}

class _SayiDialoguState extends State<_SayiDialogu> {
  late final TextEditingController _denetci =
      TextEditingController(text: '${widget.ilkDeger}');
  String? _hata;

  @override
  void dispose() {
    _denetci.dispose();
    super.dispose();
  }

  void _tamam() {
    final sayi = int.tryParse(_denetci.text.trim());
    if (sayi == null || sayi < widget.enAz || sayi > widget.enCok) {
      setState(() => _hata = '${widget.enAz} ile ${widget.enCok} arasında bir sayı yaz.');
      return;
    }
    Navigator.of(context).pop(sayi);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.baslik),
      content: TextField(
        controller: _denetci,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(suffixText: widget.birim, errorText: _hata),
        onSubmitted: (_) => _tamam(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(onPressed: _tamam, child: const Text('Kaydet')),
      ],
    );
  }
}

/// Başlık solda, değer sağda; dokununca düzenlenen satır.
class AyarSatiri extends StatelessWidget {
  const AyarSatiri({
    super.key,
    required this.baslik,
    required this.deger,
    this.onTap,
    this.altYazi,
  });

  final String baslik;
  final String deger;
  final String? altYazi;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(baslik),
      subtitle: altYazi == null ? null : Text(altYazi!),
      trailing: Text(
        deger,
        style: tema.textTheme.titleSmall?.copyWith(
          color: onTap == null ? tema.colorScheme.onSurfaceVariant : tema.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// Eksi / artı düğmeli sayı seçici.
class SayiSecici extends StatelessWidget {
  const SayiSecici({
    super.key,
    required this.deger,
    required this.enAz,
    required this.enCok,
    required this.onChanged,
    this.etiket = '',
  });

  final int deger;
  final int enAz;
  final int enCok;
  final ValueChanged<int> onChanged;

  /// Ekran okuyucu için ("Döngü sayısı" gibi).
  final String etiket;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: '$etiket azalt',
          onPressed: deger > enAz ? () => onChanged(deger - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$deger',
            textAlign: TextAlign.center,
            style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton.filledTonal(
          tooltip: '$etiket artır',
          onPressed: deger < enCok ? () => onChanged(deger + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// F.T. time süre satırları (çalışma, kısa mola, uzun mola, uzun mola sıklığı).
/// Hem F.T. time hazırlık ekranında hem Ayarlar'da kullanılır.
class FtSureAyarlari extends StatelessWidget {
  const FtSureAyarlari({super.key});

  Future<void> _dakikaSor(
    BuildContext context,
    PlanDeposu depo, {
    required String baslik,
    required int ilk,
    required int enAz,
    required int enCok,
    required FtAyarlari Function(FtAyarlari, int) uygula,
  }) async {
    final sonuc = await sayiDialogu(
      context,
      baslik: baslik,
      ilkDeger: ilk,
      enAz: enAz,
      enCok: enCok,
      birim: 'dk',
    );
    if (sonuc != null) depo.ftAyarBelirle(uygula(depo.ftAyar, sonuc));
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final a = depo.ftAyar;
    return Column(
      children: [
        AyarSatiri(
          baslik: 'Çalışma süresi',
          deger: '${a.calismaDk} dk',
          onTap: () => _dakikaSor(
            context,
            depo,
            baslik: 'Çalışma süresi',
            ilk: a.calismaDk,
            enAz: FtAyarlari.calismaEnAz,
            enCok: FtAyarlari.calismaEnCok,
            uygula: (x, v) => x.kopya(calismaDk: v),
          ),
        ),
        AyarSatiri(
          baslik: 'Kısa mola',
          deger: '${a.kisaMolaDk} dk',
          onTap: () => _dakikaSor(
            context,
            depo,
            baslik: 'Kısa mola',
            ilk: a.kisaMolaDk,
            enAz: FtAyarlari.molaEnAz,
            enCok: FtAyarlari.molaEnCok,
            uygula: (x, v) => x.kopya(kisaMolaDk: v),
          ),
        ),
        AyarSatiri(
          baslik: 'Uzun mola',
          deger: '${a.uzunMolaDk} dk',
          onTap: () => _dakikaSor(
            context,
            depo,
            baslik: 'Uzun mola',
            ilk: a.uzunMolaDk,
            enAz: FtAyarlari.molaEnAz,
            enCok: FtAyarlari.uzunMolaEnCok,
            uygula: (x, v) => x.kopya(uzunMolaDk: v),
          ),
        ),
        AyarSatiri(
          baslik: 'Uzun mola her',
          deger: '${a.uzunMolaAraligi} döngüde',
          onTap: () async {
            final sonuc = await sayiDialogu(
              context,
              baslik: 'Uzun mola kaç döngüde bir?',
              ilkDeger: a.uzunMolaAraligi,
              enAz: FtAyarlari.araligiEnAz,
              enCok: FtAyarlari.araligiEnCok,
              birim: 'döngü',
            );
            if (sonuc != null) {
              depo.ftAyarBelirle(depo.ftAyar.kopya(uzunMolaAraligi: sonuc));
            }
          },
        ),
      ],
    );
  }
}
