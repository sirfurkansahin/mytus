import 'package:app/features/denemeler/modeller.dart';
import 'package:flutter/material.dart';

/// Tek bir deneme sorusunun A–F ve güven analizi giriş dialogu.
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
  HataSinifi _hataSinifi = HataSinifi.b; // Varsayılan B (Yanlış biliyordum)

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
        'Soru Hata & Güven Analizi',
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
                  ButtonSegment(
                    value: GuvenSeviyesi.emin,
                    label: Text('Emin'),
                  ),
                  ButtonSegment(
                    value: GuvenSeviyesi.kararsiz,
                    label: Text('Kararsız'),
                  ),
                  ButtonSegment(
                    value: GuvenSeviyesi.tahmin,
                    label: Text('Tahmin'),
                  ),
                ],
                selected: {_guven},
                onSelectionChanged: (s) => setState(() {
                  _guven = s.first;
                  // Eğer Emin ise ve Yanlış ise otomatik B sınıfı öner
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
              if (!_dogruMu) ...[
                const SizedBox(height: 14),
                Text(
                  'HATA SINIFI (Rapor Bölüm 3.3)',
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<HataSinifi>(
                  initialValue: _hataSinifi,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: [
                    for (final s in HataSinifi.values)
                      DropdownMenuItem(
                        value: s,
                        child: Text('${s.kod} · ${s.ad}'),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _hataSinifi = v);
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  _hataSinifi.aciklama,
                  style: TextStyle(fontSize: 11, color: _hataSinifi.renk),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _celdiriciKontrol,
                  decoration: const InputDecoration(
                    labelText: 'Karışan Çeldirici Şık / Kavram',
                    hintText: 'Örn: Primer Biliyer Kolanjit yerine PSC',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _ayiranKriterKontrol,
                  decoration: const InputDecoration(
                    labelText: 'İki Şıkkı Ayıran Tek Kriter',
                    hintText: 'Örn: AMA (+) ve kadın = PBC; p-ANCA ve ERCP = PSC',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _kuralKontrol,
                  decoration: const InputDecoration(
                    labelText: 'Bir Daha Yapmamak İçin Kuralım',
                    hintText: 'Örn: Kolestaz görünce hemen AMA ve ERCP ayrımına bak',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
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
            final sonuc = DenemeSorusu(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              soruNo: soruNo,
              oturumTemelMi: _oturumTemelMi,
              guven: _guven,
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
