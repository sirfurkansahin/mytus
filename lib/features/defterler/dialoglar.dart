import 'package:app/features/defterler/modeller.dart';
import 'package:app/features/denemeler/modeller.dart';
import 'package:flutter/material.dart';

/// Hata Defteri'ne yeni madde ekleme dialogu.
Future<HataKaydi?> hataEkleDialogu(BuildContext context) {
  return showDialog<HataKaydi>(
    context: context,
    builder: (ctx) => const _HataEkleDialogu(),
  );
}

class _HataEkleDialogu extends StatefulWidget {
  const _HataEkleDialogu();

  @override
  State<_HataEkleDialogu> createState() => _HataEkleDialoguState();
}

class _HataEkleDialoguState extends State<_HataEkleDialogu> {
  final _baslikKontrol = TextEditingController();
  final _dersKontrol = TextEditingController();
  final _celdiriciKontrol = TextEditingController();
  final _ayiranKriterKontrol = TextEditingController();
  final _kuralKontrol = TextEditingController();

  HataSinifi _hataSinifi = HataSinifi.b;
  GuvenSeviyesi _guven = GuvenSeviyesi.emin;

  @override
  void dispose() {
    _baslikKontrol.dispose();
    _dersKontrol.dispose();
    _celdiriciKontrol.dispose();
    _ayiranKriterKontrol.dispose();
    _kuralKontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hata Defterine Ekle', style: TextStyle(fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _baslikKontrol,
                decoration: const InputDecoration(
                  labelText: 'Soru Konusu / Yanlış Kavram',
                  hintText: 'Örn: Primer Sklerozan Kolanjit Tanısı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _dersKontrol,
                decoration: const InputDecoration(
                  labelText: 'Ders / Branş',
                  hintText: 'Örn: Dahiliye, Genel Cerrahi vb.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<HataSinifi>(
                      value: _hataSinifi,
                      decoration: const InputDecoration(
                        labelText: 'Hata Sınıfı',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final s in HataSinifi.values)
                          DropdownMenuItem(value: s, child: Text('${s.kod} · ${s.ad}')),
                      ],
                      onChanged: (v) => setState(() => _hataSinifi = v ?? HataSinifi.b),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<GuvenSeviyesi>(
                      value: _guven,
                      decoration: const InputDecoration(
                        labelText: 'Güven',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final g in GuvenSeviyesi.values)
                          DropdownMenuItem(value: g, child: Text(g.ad)),
                      ],
                      onChanged: (v) => setState(() => _guven = v ?? GuvenSeviyesi.emin),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _celdiriciKontrol,
                decoration: const InputDecoration(
                  labelText: 'Karışan Çeldirici Şık / Kavram',
                  hintText: 'Örn: Primer Biliyer Kolanjit',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _ayiranKriterKontrol,
                decoration: const InputDecoration(
                  labelText: 'İki Şıkkı Ayıran Tek Kriter (Zorunlu)',
                  hintText: 'Örn: AMA (+) ve kadın = PBC; p-ANCA ve ERCP = PSC',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _kuralKontrol,
                decoration: const InputDecoration(
                  labelText: 'Bir Daha Yapmamak İçin Kuralım',
                  hintText: 'Örn: Kolestaz sorusunda önce ERCP bulgusuna bak',
                  border: OutlineInputBorder(),
                ),
              ),
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
            if (_baslikKontrol.text.trim().isEmpty) return;
            final yeni = HataKaydi(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              baslik: _baslikKontrol.text.trim(),
              dersAdi: _dersKontrol.text.trim(),
              hataSinifi: _hataSinifi,
              guven: _guven,
              celdirici: _celdiriciKontrol.text.trim(),
              ayiranKriter: _ayiranKriterKontrol.text.trim(),
              kural: _kuralKontrol.text.trim(),
              tarih: DateTime.now(),
            );
            Navigator.of(context).pop(yeni);
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

/// Yeni Skor Kartı ekleme dialogu.
Future<SkorKarti?> skorEkleDialogu(BuildContext context) {
  return showDialog<SkorKarti>(
    context: context,
    builder: (ctx) => const _SkorEkleDialogu(),
  );
}

class _SkorEkleDialogu extends StatefulWidget {
  const _SkorEkleDialogu();

  @override
  State<_SkorEkleDialogu> createState() => _SkorEkleDialoguState();
}

class _SkorEkleDialoguState extends State<_SkorEkleDialogu> {
  final _adKontrol = TextEditingController();
  final _bransKontrol = TextEditingController();
  final _parametrelerKontrol = TextEditingController();
  final _kararKontrol = TextEditingController();
  final _tuzakKontrol = TextEditingController();

  @override
  void dispose() {
    _adKontrol.dispose();
    _bransKontrol.dispose();
    _parametrelerKontrol.dispose();
    _kararKontrol.dispose();
    _tuzakKontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Skor Kartı Ekle', style: TextStyle(fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _adKontrol,
                decoration: const InputDecoration(
                  labelText: 'Skor / Sınıflama Adı',
                  hintText: 'Örn: Wells DVT Skoru',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bransKontrol,
                decoration: const InputDecoration(
                  labelText: 'İlgili Branş / Ders',
                  hintText: 'Örn: Dahiliye, Genel Cerrahi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _parametrelerKontrol,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Parametreler (Her satıra bir kriter)',
                  hintText: '1. Yaş > 50\n2. İmmobilizasyon\n3. Aktif kanser',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _kararKontrol,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Klinik Karar / Puan Anlamı',
                  hintText: 'Puan ≥ 2: Yüksek risk, USG yap. Puan < 2: D-Dimer.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _tuzakKontrol,
                decoration: const InputDecoration(
                  labelText: 'ÖSYM Çeldirici Tuzağı',
                  hintText: 'Çeldiriciye sedimantasyonu koyarlar, skorda yoktur.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Vazgeç')),
        FilledButton(
          onPressed: () {
            if (_adKontrol.text.trim().isEmpty) return;
            final satirlar = _parametrelerKontrol.text
                .split('\n')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();

            final skor = SkorKarti(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              ad: _adKontrol.text.trim(),
              brans: _bransKontrol.text.trim(),
              parametreler: satirlar,
              klinikKarar: _kararKontrol.text.trim(),
              osymTuzagi: _tuzakKontrol.text.trim(),
              ozelMi: true,
            );
            Navigator.of(context).pop(skor);
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

/// Yeni Mekanizma Zinciri (Illness Script) ekleme dialogu.
Future<MekanizmaZinciri?> zincirEkleDialogu(BuildContext context) {
  return showDialog<MekanizmaZinciri>(
    context: context,
    builder: (ctx) => const _ZincirEkleDialogu(),
  );
}

class _ZincirEkleDialogu extends StatefulWidget {
  const _ZincirEkleDialogu();

  @override
  State<_ZincirEkleDialogu> createState() => _ZincirEkleDialoguState();
}

class _ZincirEkleDialoguState extends State<_ZincirEkleDialogu> {
  final _baslikKontrol = TextEditingController();
  final List<TextEditingController> _halkaKontrolleri = [
    for (int i = 0; i < 5; i++) TextEditingController(),
  ];
  final _ayiranKontrol = TextEditingController();
  final _nedenKontrol = TextEditingController();

  ZincirTuru _tur = ZincirTuru.dahiliye;

  @override
  void dispose() {
    _baslikKontrol.dispose();
    for (final c in _halkaKontrolleri) {
      c.dispose();
    }
    _ayiranKontrol.dispose();
    _nedenKontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mekanizma Zinciri Oluştur', style: TextStyle(fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _baslikKontrol,
                decoration: const InputDecoration(
                  labelText: 'Hastalık, İlaç veya Kavram Adı',
                  hintText: 'Örn: Graves Hastalığı veya Digoksin',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<ZincirTuru>(
                value: _tur,
                decoration: const InputDecoration(
                  labelText: 'Branş Şablonu (Rapor Bölüm 4.1)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final t in ZincirTuru.values)
                    DropdownMenuItem(value: t, child: Text(t.ad)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _tur = v);
                },
              ),
              const SizedBox(height: 14),
              const Text('5 HALKALI MEKANİZMA:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 6),
              for (int i = 0; i < 5; i++) ...[
                TextField(
                  controller: _halkaKontrolleri[i],
                  decoration: InputDecoration(
                    labelText: _tur.halkaAdlari[i],
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _ayiranKontrol,
                decoration: const InputDecoration(
                  labelText: 'Komşusundan Ayıran Tek Özellik',
                  hintText: 'Örn: Tiroiditlerde RAI uptake düşüktür, Graves\'te yüksektir',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nedenKontrol,
                decoration: const InputDecoration(
                  labelText: '"Neden?" Açıklaması',
                  hintText: 'TSHR uyarıcı antikorlar T3/T4 üretimini sürekli tetikler',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Vazgeç')),
        FilledButton(
          onPressed: () {
            if (_baslikKontrol.text.trim().isEmpty) return;
            final zincir = MekanizmaZinciri(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              baslik: _baslikKontrol.text.trim(),
              tur: _tur,
              halkalar: [for (final c in _halkaKontrolleri) c.text.trim()],
              ayiranOzellik: _ayiranKontrol.text.trim(),
              nedenCevabi: _nedenKontrol.text.trim(),
            );
            Navigator.of(context).pop(zincir);
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

/// 3 Dakikalık Vaka Kartı ekleme dialogu (Rapor Bölüm 5.5).
Future<VakaKarti?> vakaEkleDialogu(BuildContext context) {
  return showDialog<VakaKarti>(
    context: context,
    builder: (ctx) => const _VakaEkleDialogu(),
  );
}

class _VakaEkleDialogu extends StatefulWidget {
  const _VakaEkleDialogu();

  @override
  State<_VakaEkleDialogu> createState() => _VakaEkleDialoguState();
}

class _VakaEkleDialoguState extends State<_VakaEkleDialogu> {
  final _hastaKontrol = TextEditingController();
  final _halkaKontrol = TextEditingController();
  final _celdiriciKontrol = TextEditingController();
  final _ayiranKontrol = TextEditingController();
  final _dersKontrol = TextEditingController();

  String _olasiSoruKoku = 'En olası tanı nedir?';

  final List<String> _soruKokleri = [
    'En olası tanı nedir?',
    'İlk yapılması gereken nedir?',
    'En sık görülen etken nedir?',
    'Aşağıdakilerden hangisi değildir?',
    'İlk tercih edilecek tedavi nedir?',
  ];

  @override
  void dispose() {
    _hastaKontrol.dispose();
    _halkaKontrol.dispose();
    _celdiriciKontrol.dispose();
    _ayiranKontrol.dispose();
    _dersKontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('3 Dakikalık Vaka Kartı', style: TextStyle(fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _hastaKontrol,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '1. Bugünkü Hasta (Tek Cümle)',
                  hintText: '45 yaşında erkek hasta, ani başlayan epigastrik ağrı ve amilaz yüksekliği...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _halkaKontrol,
                decoration: const InputDecoration(
                  labelText: '2. Belirleyici Halka',
                  hintText: 'Sırta vuran kuşak tarzı ağrı ve safra kesesinde taş',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _olasiSoruKoku,
                decoration: const InputDecoration(
                  labelText: '3. TUS\'ta Hangi Kökle Sorulurdu?',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final k in _soruKokleri)
                    DropdownMenuItem(value: k, child: Text(k, style: const TextStyle(fontSize: 13))),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _olasiSoruKoku = v);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _celdiriciKontrol,
                decoration: const InputDecoration(
                  labelText: '4. Çeldirici (Hangi hastalık/ilaçla karışırdı?)',
                  hintText: 'Akut kolesistit veya MI',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _ayiranKontrol,
                decoration: const InputDecoration(
                  labelText: '5. Ayıran Tek Kriter',
                  hintText: 'Lipazın 3 kat artması pankreatiti kesinleştirir',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _dersKontrol,
                decoration: const InputDecoration(
                  labelText: 'İlgili Ders / Branş',
                  hintText: 'Genel Cerrahi / Dahiliye',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Vazgeç')),
        FilledButton(
          onPressed: () {
            if (_hastaKontrol.text.trim().isEmpty) return;
            final vaka = VakaKarti(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              tarih: DateTime.now(),
              hastaOzeti: _hastaKontrol.text.trim(),
              belirleyiciHalka: _halkaKontrol.text.trim(),
              olasiSoruKoku: _olasiSoruKoku,
              celdirici: _celdiriciKontrol.text.trim(),
              ayiranKriter: _ayiranKontrol.text.trim(),
              dersAdi: _dersKontrol.text.trim(),
            );
            Navigator.of(context).pop(vaka);
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
