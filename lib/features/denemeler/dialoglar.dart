import 'package:app/core/gizli_ozellikler.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:flutter/material.dart';

/// Tek bir deneme sorusunun hata analizi giriş dialogu.
/// Sadeleştirme (S4/S5/K7): yalnızca YANLIŞ sorular için, 3 kategorili tek dokunuşluk etiket.
/// Güven seviyesi ve doğru/yanlış seçimi gizlidir (gizli_ozellikler.dart); "Yanlış biliyordum"
/// seçilirse güven otomatik "Emin" sayılır (Emin + Yanlış = yanlış inanç).
Future<DenemeSorusu?> soruAnalizDialogu(BuildContext context) {
  return showDialog<DenemeSorusu>(
    context: context,
    builder: (ctx) => const _SoruAnalizDialogu(),
  );
}

class _SoruAnalizDialogu extends StatefulWidget {
  const _SoruAnalizDialogu();

  @override
  State<_SoruAnalizDialogu> createState() => _SoruAnalizDialoguState();
}

class _SoruAnalizDialoguState extends State<_SoruAnalizDialogu> {
  final _soruNoKontrol = TextEditingController(text: '1');
  final _celdiriciKontrol = TextEditingController();
  final _ayiranKriterKontrol = TextEditingController();
  final _kuralKontrol = TextEditingController();

  bool _oturumTemelMi = true;
  GuvenSeviyesi _guven = GuvenSeviyesi.kararsiz;
  bool _dogruMu = false;
  HataSinifi _hataSinifi = HataSinifi.a; // Varsayılan: Bilgi

  @override
  void dispose() {
    _soruNoKontrol.dispose();
    _celdiriciKontrol.dispose();
    _ayiranKriterKontrol.dispose();
    _kuralKontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final soruNo = int.tryParse(_soruNoKontrol.text.trim()) ?? 1;

    return AlertDialog(
      title: const Text(
        'Yanlış Soru Ekle',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Temel')),
                        ButtonSegment(value: false, label: Text('Klinik')),
                      ],
                      selected: {_oturumTemelMi},
                      onSelectionChanged: (s) => setState(() => _oturumTemelMi = s.first),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _soruNoKontrol,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'Soru No',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              if (soruBazliGuvenAcik) ...[
                const SizedBox(height: 14),
                Text(
                  'GÜVEN SEVİYESİ (Çözerken ne kadar emindin?)',
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                SegmentedButton<GuvenSeviyesi>(
                  segments: const [
                    ButtonSegment(value: GuvenSeviyesi.emin, label: Text('Emin')),
                    ButtonSegment(value: GuvenSeviyesi.kararsiz, label: Text('Kararsız')),
                    ButtonSegment(value: GuvenSeviyesi.tahmin, label: Text('Tahmin')),
                  ],
                  selected: {_guven},
                  onSelectionChanged: (s) => setState(() {
                    _guven = s.first;
                    if (_guven == GuvenSeviyesi.emin && !_dogruMu) {
                      _hataSinifi = HataSinifi.b;
                    }
                  }),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      'Soru Sonucu: ',
                      style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    ChoiceChip(
                      label: const Text('Yanlış'),
                      selected: !_dogruMu,
                      selectedColor: Colors.red.withValues(alpha: 0.2),
                      onSelected: (s) => setState(() => _dogruMu = !s),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Doğru'),
                      selected: _dogruMu,
                      selectedColor: Colors.green.withValues(alpha: 0.2),
                      onSelected: (s) => setState(() => _dogruMu = s),
                    ),
                  ],
                ),
              ],
              if (!_dogruMu) ...[
                const SizedBox(height: 14),
                Text(
                  'NEDEN YANLIŞ? (tek dokunuş)',
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final s in HataSinifi.grupTemsilcileri)
                      ChoiceChip(
                        label: Text(s.grupAdi),
                        selected: _hataSinifi.grupAdi == s.grupAdi,
                        selectedColor: s.renk.withValues(alpha: 0.25),
                        onSelected: (_) => setState(() => _hataSinifi = s),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _kuralKontrol,
                  decoration: const InputDecoration(
                    labelText: 'Bir daha ne yapacağım? (isteğe bağlı)',
                    hintText: 'Örn: Kolestaz görünce hemen AMA ve ERCP ayrımına bak',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Ayrıntı (isteğe bağlı)', style: TextStyle(fontSize: 13)),
                  children: [
                    TextField(
                      controller: _celdiriciKontrol,
                      decoration: const InputDecoration(
                        labelText: 'Karışan Çeldirici Şık / Kavram',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _ayiranKriterKontrol,
                      decoration: const InputDecoration(
                        labelText: 'İki Şıkkı Ayıran Tek Kriter',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () {
            // "Yanlış biliyordum" = Emin + Yanlış (yanlış inanç); diğerleri kararsız.
            final guven = soruBazliGuvenAcik
                ? _guven
                : (_hataSinifi == HataSinifi.b ? GuvenSeviyesi.emin : GuvenSeviyesi.kararsiz);
            final sonuc = DenemeSorusu(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              soruNo: soruNo,
              oturumTemelMi: _oturumTemelMi,
              guven: guven,
              dogruMu: _dogruMu,
              hataSinifi: _dogruMu ? null : _hataSinifi,
              celdirici: _celdiriciKontrol.text.trim(),
              ayiranKriter: _ayiranKriterKontrol.text.trim(),
              kural: _kuralKontrol.text.trim(),
            );
            Navigator.of(context).pop(sonuc);
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}