import 'package:app/core/renkler.dart';
import 'package:app/core/tarih.dart';
import 'package:app/features/denemeler/deneme_detay_ekrani.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// Yeni 200 soruluk TUS deneme sınavı kaydetme ekranı.
class DenemeEkleEkrani extends StatefulWidget {
  const DenemeEkleEkrani({super.key, this.duzenlenecek});

  final DenemeSinavi? duzenlenecek;

  @override
  State<DenemeEkleEkrani> createState() => _DenemeEkleEkraniState();
}

class _DenemeEkleEkraniState extends State<DenemeEkleEkrani> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _adKontrol;
  late final TextEditingController _notlarKontrol;
  late DateTime _tarih;

  int _temelDogru = 0;
  int _temelYanlis = 0;
  int _temelBos = 0;

  int _klinikDogru = 0;
  int _klinikYanlis = 0;
  int _klinikBos = 0;

  double _kaygiPuani = 3.0; // 0-10 skalası

  @override
  void initState() {
    super.initState();
    final d = widget.duzenlenecek;
    _adKontrol = TextEditingController(text: d?.ad ?? '');
    _notlarKontrol = TextEditingController(text: d?.notlar ?? '');
    _tarih = d?.tarih ?? DateTime.now();

    if (d != null) {
      _temelDogru = d.temel.dogru;
      _temelYanlis = d.temel.yanlis;
      _temelBos = d.temel.bos;

      _klinikDogru = d.klinik.dogru;
      _klinikYanlis = d.klinik.yanlis;
      _klinikBos = d.klinik.bos;

      _kaygiPuani = (d.kaygiPuani ?? 3).toDouble();
    }
  }

  @override
  void dispose() {
    _adKontrol.dispose();
    _notlarKontrol.dispose();
    super.dispose();
  }

  double get _temelNet => (_temelDogru - (_temelYanlis / 4.0)).clamp(0.0, 100.0);
  double get _klinikNet => (_klinikDogru - (_klinikYanlis / 4.0)).clamp(0.0, 100.0);
  double get _toplamNet => _temelNet + _klinikNet;
  double get _kPuan => (0.4 * _temelNet) + (0.6 * _klinikNet);

  double get _tahminiEbap {
    const double xOrtalama = 38.5;
    const double sSapma = 17.0;
    const double ebap = 85.0;

    final pay = (7 * (_kPuan - xOrtalama)) - sSapma;
    final payda = (7 * (ebap - xOrtalama)) - sSapma;

    if (payda == 0) return 45.0;
    final ham = 55.0 + 30.0 * (pay / payda);
    return ham.clamp(45.0, 85.0);
  }

  Future<void> _tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('tr', 'TR'),
    );
    if (secilen != null) {
      setState(() => _tarih = secilen);
    }
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    final depo = DepoKapsami.oku(context);

    final deneme = DenemeSinavi(
      id: widget.duzenlenecek?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      ad: _adKontrol.text.trim().isEmpty ? 'TUS Denemesi' : _adKontrol.text.trim(),
      tarih: _tarih,
      temel: DenemeOturumu(
        dogru: _temelDogru,
        yanlis: _temelYanlis,
        bos: _temelBos,
      ),
      klinik: DenemeOturumu(
        dogru: _klinikDogru,
        yanlis: _klinikYanlis,
        bos: _klinikBos,
      ),
      soruHatalari: widget.duzenlenecek?.soruHatalari ?? const [],
      kaygiPuani: _kaygiPuani.round(),
      notlar: _notlarKontrol.text.trim(),
    );

    if (widget.duzenlenecek != null) {
      await depo.denemeGuncelle(deneme);
    } else {
      await depo.denemeEkle(deneme);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    if (widget.duzenlenecek == null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DenemeDetayEkrani(denemeId: deneme.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.duzenlenecek != null ? 'Denemeyi Düzenle' : 'Yeni Deneme Ekle',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _kaydet,
            child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _adKontrol,
              decoration: const InputDecoration(
                labelText: 'Deneme Adı veya Yayın',
                hintText: 'Örn: TUSDATA 1. Deneme, Klinisyen vb.',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Lütfen bir ad girin' : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _tarihSec,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Sınav Tarihi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(tarihFormatla(_tarih)),
              ),
            ),
            const SizedBox(height: 20),
            _CanliPuanKarti(
              temelNet: _temelNet,
              klinikNet: _klinikNet,
              toplamNet: _toplamNet,
              kPuan: _kPuan,
              ebapPuan: _tahminiEbap,
            ),
            const SizedBox(height: 20),
            _OturumGirisKarti(
              baslik: 'Temel Tıp Bilimleri Testi (TTBT - 100 Soru)',
              dogru: _temelDogru,
              yanlis: _temelYanlis,
              bos: _temelBos,
              net: _temelNet,
              onDogruDegisti: (v) => setState(() {
                _temelDogru = v;
                _temelBos = (100 - _temelDogru - _temelYanlis).clamp(0, 100);
              }),
              onYanlisDegisti: (v) => setState(() {
                _temelYanlis = v;
                _temelBos = (100 - _temelDogru - _temelYanlis).clamp(0, 100);
              }),
              onBosDegisti: (v) => setState(() => _temelBos = v),
            ),
            const SizedBox(height: 16),
            _OturumGirisKarti(
              baslik: 'Klinik Tıp Bilimleri Testi (KTBT - 100 Soru)',
              dogru: _klinikDogru,
              yanlis: _klinikYanlis,
              bos: _klinikBos,
              net: _klinikNet,
              onDogruDegisti: (v) => setState(() {
                _klinikDogru = v;
                _klinikBos = (100 - _klinikDogru - _klinikYanlis).clamp(0, 100);
              }),
              onYanlisDegisti: (v) => setState(() {
                _klinikYanlis = v;
                _klinikBos = (100 - _klinikDogru - _klinikYanlis).clamp(0, 100);
              }),
              onBosDegisti: (v) => setState(() => _klinikBos = v),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: tema.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: tema.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sentiment_neutral_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Sınav Öncesi Test Kaygısı (0–10)',
                          style: tema.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_kaygiPuani.round()} / 10',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _kaygiPuani >= 7 ? Colors.red : morAna,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rapor Bölüm 5.2: Test kaygısı kurul başarısının bağımsız negatif belirleyicisidir. Düzenli izlenmelidir.',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    Slider(
                      value: _kaygiPuani,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      label: '${_kaygiPuani.round()}',
                      activeColor: _kaygiPuani >= 7 ? Colors.red : morAna,
                      onChanged: (v) => setState(() => _kaygiPuani = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notlarKontrol,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Deneme Notları / Gözlemler',
                hintText: 'Hangi dersler zordu, dikkat dağıtıcı oldu mu vb.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _kaydet,
              icon: const Icon(Icons.check),
              label: const Text('Denemeyi ve Netleri Kaydet'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _CanliPuanKarti extends StatelessWidget {
  const _CanliPuanKarti({
    required this.temelNet,
    required this.klinikNet,
    required this.toplamNet,
    required this.kPuan,
    required this.ebapPuan,
  });

  final double temelNet;
  final double klinikNet;
  final double toplamNet;
  final double kPuan;
  final double ebapPuan;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      elevation: 0,
      color: morAna.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: morAna.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOPLAM NET',
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: morAna,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${toplamNet.toStringAsFixed(2)} / 200',
                      style: tema.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: morAna,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: morAna,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'TAHMİNİ TUS PUANI',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${ebapPuan.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Temel: ${temelNet.toStringAsFixed(2)} net',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Klinik: ${klinikNet.toStringAsFixed(2)} net',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  'K-Puanı: ${kPuan.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OturumGirisKarti extends StatelessWidget {
  const _OturumGirisKarti({
    required this.baslik,
    required this.dogru,
    required this.yanlis,
    required this.bos,
    required this.net,
    required this.onDogruDegisti,
    required this.onYanlisDegisti,
    required this.onBosDegisti,
  });

  final String baslik;
  final int dogru;
  final int yanlis;
  final int bos;
  final double net;
  final ValueChanged<int> onDogruDegisti;
  final ValueChanged<int> onYanlisDegisti;
  final ValueChanged<int> onBosDegisti;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final toplam = dogru + yanlis + bos;

    return Card(
      elevation: 0,
      color: tema.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tema.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    baslik,
                    style: tema.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${net.toStringAsFixed(2)} Net',
                    style: TextStyle(
                      color: tema.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SayiKutusu(
                    etiket: 'Doğru',
                    deger: dogru,
                    renk: Colors.green,
                    onDegisti: onDogruDegisti,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SayiKutusu(
                    etiket: 'Yanlış',
                    deger: yanlis,
                    renk: Colors.red,
                    onDegisti: onYanlisDegisti,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SayiKutusu(
                    etiket: 'Boş',
                    deger: bos,
                    renk: Colors.grey,
                    onDegisti: onBosDegisti,
                  ),
                ),
              ],
            ),
            if (toplam != 100) ...[
              const SizedBox(height: 8),
              Text(
                'Toplam soru: $toplam / 100 (ÖSYM formatı 100 sorudur)',
                style: TextStyle(
                  fontSize: 11,
                  color: toplam > 100 ? Colors.red : tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SayiKutusu extends StatelessWidget {
  const _SayiKutusu({
    required this.etiket,
    required this.deger,
    required this.renk,
    required this.onDegisti,
  });

  final String etiket;
  final int deger;
  final Color renk;
  final ValueChanged<int> onDegisti;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: deger == 0 ? '' : deger.toString(),
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: etiket,
        labelStyle: TextStyle(color: renk, fontWeight: FontWeight.w600),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
      onChanged: (v) {
        final sayi = int.tryParse(v.trim()) ?? 0;
        onDegisti(sayi.clamp(0, 100));
      },
    );
  }
}
