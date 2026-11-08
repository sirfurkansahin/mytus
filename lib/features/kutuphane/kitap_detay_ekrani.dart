import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/kutuphane/bolum_notlari_ekrani.dart';
import 'package:app/features/kutuphane/modeller.dart';
import 'package:flutter/material.dart';

/// Kitap detay ve içindekiler/bölüm çalışma ekranı.
class KitapDetayEkrani extends StatefulWidget {
  const KitapDetayEkrani({super.key, required this.kitapId});

  final String kitapId;

  @override
  State<KitapDetayEkrani> createState() => _KitapDetayEkraniState();
}

class _KitapDetayEkraniState extends State<KitapDetayEkrani> {
  int _filtre = 0; // 0: Tümü, 1: Kalanlar, 2: Bitenler
  final _yeniBolumDenetci = TextEditingController();

  @override
  void dispose() {
    _yeniBolumDenetci.dispose();
    super.dispose();
  }

  void _yeniBolumEkle(PlanDeposu depo, Kitap kitap) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final adDenetci = TextEditingController();
        final basDenetci = TextEditingController();
        final bitDenetci = TextEditingController();

        return AlertDialog(
          title: const Text('Yeni Bölüm Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: adDenetci,
                decoration: const InputDecoration(
                  labelText: 'Bölüm Adı',
                  hintText: 'Örn: Tümör İmmünolojisi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: basDenetci,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'İlk Sayfa',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: bitDenetci,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Son Sayfa',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                final ad = adDenetci.text.trim();
                if (ad.isEmpty) return;
                final bas = int.tryParse(basDenetci.text.trim());
                final bit = int.tryParse(bitDenetci.text.trim());

                final yeni = KitapBolumu(
                  id: 'b_${DateTime.now().microsecondsSinceEpoch}',
                  ad: ad,
                  baslangicSayfa: bas,
                  bitisSayfa: bit,
                );

                final guncelList = List<KitapBolumu>.from(kitap.bolumler)..add(yeni);
                depo.kitapGuncelle(kitap.kopya(bolumler: guncelList));
                Navigator.of(ctx).pop();
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }

  void _klasorDegistirDialogu(PlanDeposu depo, Kitap kitap) {
    final denetci = TextEditingController(text: kitap.klasorAdi ?? '');
    final mevcutKlasorler = depo.kitapKlasorleri;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Klasöre Taşı / Değiştir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: denetci,
                decoration: const InputDecoration(
                  labelText: 'Klasör / Grup Adı',
                  hintText: 'Örn: SpeeTUS (5. Baskı), Soru Bankaları',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
              ),
              if (mevcutKlasorler.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Mevcut klasörlerden seç:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final kl in mevcutKlasorler)
                      ActionChip(
                        avatar: const Icon(Icons.folder_open, size: 15),
                        label: Text(kl, style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setDialogState(() => denetci.text = kl);
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            if (kitap.klasoruVar)
              TextButton(
                onPressed: () {
                  depo.kitapKlasoruDegistir(kitap.id, null);
                  Navigator.of(ctx).pop();
                },
                child: const Text('Klasörden Çıkar'),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                depo.kitapKlasoruDegistir(kitap.id, denetci.text);
                Navigator.of(ctx).pop();
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _kitapSilOnayi(PlanDeposu depo, Kitap kitap) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kitap Silinsin mi?'),
        content: Text(
          '"${kitap.ad}" kütüphanenizden ve çalışma takibinizden silinecek. '
          'Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              depo.kitapSil(kitap.id);
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _bolumNotlariniAc(String bolumId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BolumNotlariEkrani(
          kitapId: widget.kitapId,
          bolumId: bolumId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final kitap = depo.kitapBul(widget.kitapId);

    if (kitap == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kitap Bulunamadı')),
        body: const Center(child: Text('Bu kitap silinmiş veya bulunamıyor.')),
      );
    }

    final siradaki = kitap.siradakiBolum;

    final filtrelenmis = kitap.bolumler.where((b) {
      if (_filtre == 1) return !b.tamamlandi;
      if (_filtre == 2) return b.tamamlandi;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(kitap.ad),
        actions: [
          IconButton(
            tooltip: 'Yeni Bölüm Ekle',
            icon: const Icon(Icons.add_task),
            onPressed: () => _yeniBolumEkle(depo, kitap),
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'klasor') _klasorDegistirDialogu(depo, kitap);
              if (val == 'sil') _kitapSilOnayi(depo, kitap);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'klasor',
                child: Row(
                  children: [
                    Icon(Icons.create_new_folder_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Klasöre Taşı / Değiştir'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sil',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Kitabı Sil', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Kitap Bilgi & İlerleme Kartı
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: tema.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            color: tema.colorScheme.primaryContainer.withValues(alpha: 0.25),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tema.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          kitap.dersAdi ?? 'Genel',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (kitap.klasoruVar) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _klasorDegistirDialogu(depo, kitap),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: tema.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  size: 13,
                                  color: tema.colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  kitap.klasorAdi!,
                                  style: TextStyle(
                                    color: tema.colorScheme.onSecondaryContainer,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (kitap.toplamSayfa != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${kitap.toplamSayfa} sayfa',
                            style: TextStyle(
                              fontSize: 12,
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ] else
                        const Spacer(),
                      const SizedBox(width: 8),
                      Text(
                        '%${kitap.yuzde}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: tema.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: kitap.ilerlemeOrani,
                      minHeight: 8,
                      backgroundColor: tema.colorScheme.primary.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        kitap.tamamlandi ? Colors.teal : tema.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${kitap.tamamlananBolumSayisi} / ${kitap.toplamBolumSayisi} bölüm tamamlandı '
                    '(${kitap.kalanBolumSayisi} bölüm kaldı)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sıradaki Bölüm Kartı
          if (siradaki != null) ...[
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.teal.withValues(alpha: 0.4)),
              ),
              color: Colors.teal.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_fill, color: Colors.teal, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SIRADAKİ ÇALIŞILACAK BÖLÜM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.teal,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            siradaki.ad,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (siradaki.sayfaAraligiMetni.isNotEmpty)
                            Text(
                              siradaki.sayfaAraligiMetni,
                              style: TextStyle(
                                fontSize: 11,
                                color: tema.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            siradaki.notVar ? Icons.note_alt : Icons.note_alt_outlined,
                            color: Colors.teal,
                            size: 22,
                          ),
                          tooltip: 'Bölüm Notları (${siradaki.notSayisi})',
                          onPressed: () => _bolumNotlariniAc(siradaki.id),
                        ),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () {
                            depo.kitapBolumDurumuDegistir(kitap.id, siradaki.id, true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Tebrikler! "${siradaki.ad}" tamamlandı.'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text('Çalıştım ✓'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Filtreler
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'BÖLÜMLER (${kitap.toplamBolumSayisi})',
                style: tema.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: tema.colorScheme.primary,
                  letterSpacing: 0.8,
                ),
              ),
              Wrap(
                spacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('Tümü', style: TextStyle(fontSize: 12)),
                    selected: _filtre == 0,
                    onSelected: (_) => setState(() => _filtre = 0),
                    visualDensity: VisualDensity.compact,
                  ),
                  ChoiceChip(
                    label: const Text('Kalanlar', style: TextStyle(fontSize: 12)),
                    selected: _filtre == 1,
                    onSelected: (_) => setState(() => _filtre = 1),
                    visualDensity: VisualDensity.compact,
                  ),
                  ChoiceChip(
                    label: const Text('Bitenler', style: TextStyle(fontSize: 12)),
                    selected: _filtre == 2,
                    onSelected: (_) => setState(() => _filtre = 2),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (kitap.bolumler.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('Bu kitaba henüz bölüm eklenmedi.'),
              ),
            )
          else if (filtrelenmis.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Text('Bu filtreye uygun bölüm bulunamadı.'),
              ),
            )
          else
            for (var i = 0; i < filtrelenmis.length; i++) ...[
              _BolumKarti(
                sira: i + 1,
                bolum: filtrelenmis[i],
                onDegisti: (tamam) {
                  depo.kitapBolumDurumuDegistir(kitap.id, filtrelenmis[i].id, tamam);
                },
                onNotlar: () => _bolumNotlariniAc(filtrelenmis[i].id),
                onSil: () {
                  final guncel = List<KitapBolumu>.from(kitap.bolumler)
                    ..removeWhere((b) => b.id == filtrelenmis[i].id);
                  depo.kitapGuncelle(kitap.kopya(bolumler: guncel));
                },
              ),
              const SizedBox(height: 6),
            ],
        ],
      ),
    );
  }
}

class _BolumKarti extends StatelessWidget {
  const _BolumKarti({
    required this.sira,
    required this.bolum,
    required this.onDegisti,
    required this.onNotlar,
    required this.onSil,
  });

  final int sira;
  final KitapBolumu bolum;
  final ValueChanged<bool> onDegisti;
  final VoidCallback onNotlar;
  final VoidCallback onSil;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tamam = bolum.tamamlandi;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: tamam
              ? Colors.teal.withValues(alpha: 0.3)
              : tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: tamam ? Colors.teal.withValues(alpha: 0.04) : null,
      child: ListTile(
        onTap: onNotlar,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: Checkbox(
          value: tamam,
          activeColor: Colors.teal,
          onChanged: (val) => onDegisti(val ?? false),
        ),
        title: Text(
          bolum.ad,
          style: TextStyle(
            fontSize: 14,
            fontWeight: tamam ? FontWeight.w500 : FontWeight.w700,
            decoration: tamam ? TextDecoration.lineThrough : null,
            color: tamam ? tema.colorScheme.outline : null,
          ),
        ),
        subtitle: (bolum.sayfaAraligiMetni.isNotEmpty || bolum.notVar)
            ? Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 2,
                children: [
                  if (bolum.sayfaAraligiMetni.isNotEmpty)
                    Text(
                      bolum.sayfaAraligiMetni,
                      style: TextStyle(
                        fontSize: 11,
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (bolum.notVar)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: tema.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_note, size: 13, color: tema.colorScheme.primary),
                          const SizedBox(width: 2),
                          Text(
                            '${bolum.notSayisi} not',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: tema.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                bolum.notVar ? Icons.note_alt : Icons.note_alt_outlined,
                size: 20,
                color: bolum.notVar ? tema.colorScheme.primary : tema.colorScheme.outline,
              ),
              tooltip: 'Bölüm Notları',
              onPressed: onNotlar,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: tema.colorScheme.outline,
              tooltip: 'Bölümü Sil',
              onPressed: onSil,
            ),
          ],
        ),
      ),
    );
  }
}
