import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/kutuphane/modeller.dart';
import 'package:flutter/material.dart';

/// Yeni kitap ekleme diyaloğu (tek tek veya toplu içindekiler yapıştırma).
class KitapEkleDialogu extends StatefulWidget {
  const KitapEkleDialogu({super.key});

  @override
  State<KitapEkleDialogu> createState() => _KitapEkleDialoguState();
}

class _KitapEkleDialoguState extends State<KitapEkleDialogu> {
  final _adDenetci = TextEditingController();
  final _sayfaDenetci = TextEditingController();
  final _topluMetinDenetci = TextEditingController();

  // Tek tek ekleme için
  final _tekBolumAdDenetci = TextEditingController();
  final _tekBasSayfaDenetci = TextEditingController();
  final _tekBitSayfaDenetci = TextEditingController();
  final List<KitapBolumu> _tekEklenenBolumler = [];

  int? _seciliDersId;
  String? _seciliDersAdi;
  int _girisTuru = 0; // 0: Toplu Yapıştır, 1: Tek Tek Ekle

  @override
  void dispose() {
    _adDenetci.dispose();
    _sayfaDenetci.dispose();
    _topluMetinDenetci.dispose();
    _tekBolumAdDenetci.dispose();
    _tekBasSayfaDenetci.dispose();
    _tekBitSayfaDenetci.dispose();
    super.dispose();
  }

  void _tekBolumEkle() {
    final ad = _tekBolumAdDenetci.text.trim();
    if (ad.isEmpty) return;

    final bas = int.tryParse(_tekBasSayfaDenetci.text.trim());
    final bit = int.tryParse(_tekBitSayfaDenetci.text.trim());

    setState(() {
      _tekEklenenBolumler.add(
        KitapBolumu(
          id: 'b_${DateTime.now().microsecondsSinceEpoch}_${_tekEklenenBolumler.length + 1}',
          ad: ad,
          baslangicSayfa: bas,
          bitisSayfa: bit,
        ),
      );
      _tekBolumAdDenetci.clear();
      _tekBasSayfaDenetci.clear();
      _tekBitSayfaDenetci.clear();
    });
  }

  void _kaydet(PlanDeposu depo) {
    final ad = _adDenetci.text.trim();
    if (ad.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kitap adını girin.')),
      );
      return;
    }

    List<KitapBolumu> bolumler;
    if (_girisTuru == 0) {
      // Toplu yapıştırma
      bolumler = topluBolumleriAyristir(_topluMetinDenetci.text);
    } else {
      bolumler = List.from(_tekEklenenBolumler);
    }

    final toplamSayfa = int.tryParse(_sayfaDenetci.text.trim());

    final yeniKitap = Kitap(
      id: 'k_${DateTime.now().microsecondsSinceEpoch}',
      ad: ad,
      dersId: _seciliDersId,
      dersAdi: _seciliDersAdi ?? 'Genel',
      toplamSayfa: toplamSayfa,
      eklenmeTarihi: DateTime.now(),
      bolumler: bolumler,
    );

    depo.kitapEkle(yeniKitap);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final dersler = depo.tumDersler;

    final algilananBolumSayisi = _girisTuru == 0
        ? _topluMetinDenetci.text
            .split('\n')
            .where((s) => s.trim().isNotEmpty)
            .length
        : _tekEklenenBolumler.length;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Kütüphaneye Kitap Ekle',
                      style: tema.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    TextField(
                      controller: _adDenetci,
                      decoration: const InputDecoration(
                        labelText: 'Kitap Adı *',
                        hintText: 'Örn: TUSDATA Patoloji Konu Kitabı',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<int?>(
                            isExpanded: true,
                            initialValue: _seciliDersId,
                            decoration: const InputDecoration(
                              labelText: 'Ders / Branş',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.school_outlined),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Genel / Diğer'),
                              ),
                              for (final d in dersler)
                                DropdownMenuItem<int?>(
                                  value: d.id,
                                  child: Text(d.ad),
                                ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _seciliDersId = val;
                                if (val != null) {
                                  _seciliDersAdi = depo.dersBul(val)?.ad;
                                } else {
                                  _seciliDersAdi = 'Genel';
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _sayfaDenetci,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Toplam Sayfa',
                              hintText: 'İsteğe bağlı',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.numbers_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'İÇİNDEKİLER / BÖLÜMLER',
                      style: tema.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: tema.colorScheme.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          icon: Icon(Icons.content_paste_outlined),
                          label: Text('Toplu Yapıştır (Hızlı)'),
                        ),
                        ButtonSegment(
                          value: 1,
                          icon: Icon(Icons.playlist_add),
                          label: Text('Tek Tek Ekle'),
                        ),
                      ],
                      selected: {_girisTuru},
                      onSelectionChanged: (val) {
                        setState(() => _girisTuru = val.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_girisTuru == 0) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tema.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tema.colorScheme.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 20,
                              color: tema.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Kamerayı içindekiler sayfasına tutup telefonunuzun '
                                '"Metni Kopyala / Tara" butonuyla metni alabilir ve buraya yapıştırabilirsiniz. '
                                'Her satır otomatik ayrı bir bölüm olur.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tema.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _topluMetinDenetci,
                        maxLines: 8,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'İçindekiler listesini buraya alt alta yapıştırın:\n\n'
                              '1. Hücre Hasarı ve Ölümü (s. 1-35)\n'
                              '2. İltihap ve Onarım (s. 36-65)\n'
                              '3. Hemodinamik Bozukluklar (s. 66-95)\n'
                              '4. İmmün Sistem Hastalıkları...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _tekBolumAdDenetci,
                              decoration: const InputDecoration(
                                labelText: 'Bölüm Adı',
                                hintText: 'Örn: Hücre Zedelenmesi',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _tekBasSayfaDenetci,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'İlk S.',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _tekBitSayfaDenetci,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Son S.',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filled(
                            onPressed: _tekBolumEkle,
                            icon: const Icon(Icons.add),
                            tooltip: 'Bölümü Ekle',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_tekEklenenBolumler.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Henüz bölüm eklenmedi. Yukarıdaki alanlardan tek tek bölüm ekleyebilirsiniz.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          decoration: BoxDecoration(
                            border: Border.all(color: tema.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _tekEklenenBolumler.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final b = _tekEklenenBolumler[i];
                              return ListTile(
                                dense: true,
                                title: Text(b.ad, style: const TextStyle(fontSize: 13)),
                                subtitle: b.sayfaAraligiMetni.isNotEmpty
                                    ? Text(b.sayfaAraligiMetni, style: const TextStyle(fontSize: 11))
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  onPressed: () {
                                    setState(() => _tekEklenenBolumler.removeAt(i));
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Vazgeç'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => _kaydet(depo),
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        algilananBolumSayisi > 0
                            ? 'Kaydet ($algilananBolumSayisi Bölüm)'
                            : 'Kitabı Kaydet',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
