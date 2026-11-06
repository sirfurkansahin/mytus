import 'dart:convert';
import 'dart:typed_data';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/kutuphane/modeller.dart';
import 'package:app/features/kutuphane/resim_secici.dart';
import 'package:flutter/material.dart';

/// Kitabın belirli bir bölümüne ait fotoğraflı ve metinli notların listelendiği ekran.
class BolumNotlariEkrani extends StatelessWidget {
  const BolumNotlariEkrani({
    super.key,
    required this.kitapId,
    required this.bolumId,
  });

  final String kitapId;
  final String bolumId;

  void _notEkleDuzenle(BuildContext context, PlanDeposu depo, {BolumNotu? mevcutNot}) {
    showDialog<void>(
      context: context,
      builder: (_) => NotDuzenleDialogu(
        kitapId: kitapId,
        bolumId: bolumId,
        mevcutNot: mevcutNot,
      ),
    );
  }

  void _notSilOnayi(BuildContext context, PlanDeposu depo, BolumNotu not) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Not Silinsin mi?'),
        content: const Text('Bu not ve ekli fotoğrafı kalıcı olarak silinecektir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              depo.kitapBolumNotuSil(kitapId, bolumId, not.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);

    final kitap = depo.kitapBul(kitapId);
    if (kitap == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bölüm Notları')),
        body: const Center(child: Text('Kitap bulunamadı.')),
      );
    }

    final bolum = kitap.bolumler.firstWhere(
      (b) => b.id == bolumId,
      orElse: () => KitapBolumu(id: '', ad: 'Bölüm'),
    );

    if (bolum.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bölüm Notları')),
        body: const Center(child: Text('Bölüm bulunamadı.')),
      );
    }

    final notlar = bolum.notlar;

    return Scaffold(
      appBar: AppBar(
        title: Text(bolum.ad),
        actions: [
          IconButton(
            tooltip: 'Yeni Not Ekle',
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: () => _notEkleDuzenle(context, depo),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _notEkleDuzenle(context, depo),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Not / Fotoğraf Ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          // Bölüm Bilgi Başlığı Kartı
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: tema.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            color: tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    color: tema.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${kitap.ad}${bolum.sayfaAraligiMetni.isNotEmpty ? ' · ${bolum.sayfaAraligiMetni}' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: tema.colorScheme.primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tema.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${bolum.notSayisi} Not',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: tema.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (notlar.isEmpty) ...[
            const SizedBox(height: 30),
            Center(
              child: Card(
                elevation: 0,
                color: tema.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: tema.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.note_alt_outlined,
                        size: 48,
                        color: tema.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Bu Bölüme Henüz Not Eklenmedi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kitabınızdaki önemli tabloları, spot sayfaları kamerayla çekip '
                        'yanına hoca vurgusu veya çeldirici uyarınızı ekleyebilirsiniz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _notEkleDuzenle(context, depo),
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('İlk Notunu Ekle'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            for (final not in notlar) ...[
              _NotKarti(
                not: not,
                onDuzenle: () => _notEkleDuzenle(context, depo, mevcutNot: not),
                onSil: () => _notSilOnayi(context, depo, not),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _NotKarti extends StatelessWidget {
  const _NotKarti({
    required this.not,
    required this.onDuzenle,
    required this.onSil,
  });

  final BolumNotu not;
  final VoidCallback onDuzenle;
  final VoidCallback onSil;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    Uint8List? resimBytes;
    if (not.resimVar) {
      try {
        resimBytes = base64Decode(not.resimBase64!);
      } catch (_) {
        resimBytes = null;
      }
    }

    final tarih = not.olusturmaTarihi;
    final tarihMetni = '${tarih.day}.${tarih.month}.${tarih.year}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: tema.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resimBytes != null) ...[
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TamEkranResimEkrani(
                        resimBytes: resimBytes!,
                        baslik: not.metinVar ? not.metin : 'Not Görseli',
                      ),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 260),
                        width: double.infinity,
                        color: tema.colorScheme.surfaceContainerHighest,
                        child: Image.memory(
                          resimBytes,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Padding(
                            padding: EdgeInsets.all(20),
                            child: Icon(Icons.broken_image, size: 40),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Büyüt',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (not.metinVar) ...[
              Text(
                not.metin,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tarihMetni,
                  style: TextStyle(
                    fontSize: 11,
                    color: tema.colorScheme.outline,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Notu Düzenle',
                      visualDensity: VisualDensity.compact,
                      onPressed: onDuzenle,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      tooltip: 'Notu Sil',
                      visualDensity: VisualDensity.compact,
                      onPressed: onSil,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Yeni not ekleme veya mevcut notu düzenleme diyaloğu.
class NotDuzenleDialogu extends StatefulWidget {
  const NotDuzenleDialogu({
    super.key,
    required this.kitapId,
    required this.bolumId,
    this.mevcutNot,
  });

  final String kitapId;
  final String bolumId;
  final BolumNotu? mevcutNot;

  @override
  State<NotDuzenleDialogu> createState() => _NotDuzenleDialoguState();
}

class _NotDuzenleDialoguState extends State<NotDuzenleDialogu> {
  late final TextEditingController _metinDenetci;
  Uint8List? _resimBytes;
  bool _yukleniyor = false;

  @override
  void initState() {
    super.initState();
    _metinDenetci = TextEditingController(text: widget.mevcutNot?.metin ?? '');
    if (widget.mevcutNot?.resimVar == true) {
      try {
        _resimBytes = base64Decode(widget.mevcutNot!.resimBase64!);
      } catch (_) {
        _resimBytes = null;
      }
    }
  }

  @override
  void dispose() {
    _metinDenetci.dispose();
    super.dispose();
  }

  Future<void> _kameraCek() async {
    setState(() => _yukleniyor = true);
    final bytes = await ResimSecici.ornek.kameradanCek();
    if (mounted) {
      setState(() {
        if (bytes != null) _resimBytes = bytes;
        _yukleniyor = false;
      });
    }
  }

  Future<void> _galeriSec() async {
    setState(() => _yukleniyor = true);
    final bytes = await ResimSecici.ornek.galeridenSec();
    if (mounted) {
      setState(() {
        if (bytes != null) _resimBytes = bytes;
        _yukleniyor = false;
      });
    }
  }

  void _kaydet(PlanDeposu depo) {
    final metin = _metinDenetci.text.trim();
    if (metin.isEmpty && _resimBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir not metni girin veya fotoğraf ekleyin.')),
      );
      return;
    }

    final resimBase64 = _resimBytes != null ? base64Encode(_resimBytes!) : null;

    if (widget.mevcutNot != null) {
      final guncel = widget.mevcutNot!.kopya(
        metin: metin,
        resimBase64: resimBase64,
      );
      depo.kitapBolumNotuGuncelle(widget.kitapId, widget.bolumId, guncel);
    } else {
      final yeni = BolumNotu(
        id: 'n_${DateTime.now().microsecondsSinceEpoch}',
        metin: metin,
        resimBase64: resimBase64,
        olusturmaTarihi: DateTime.now(),
      );
      depo.kitapBolumNotuEkle(widget.kitapId, widget.bolumId, yeni);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final duzenleme = widget.mevcutNot != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
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
                      duzenleme ? 'Notu Düzenle' : 'Bölüme Not Ekle',
                      style: tema.textTheme.titleMedium?.copyWith(
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
                    // Fotoğraf Seçim / Önizleme Alanı
                    if (_resimBytes != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 220),
                              width: double.infinity,
                              color: tema.colorScheme.surfaceContainerHighest,
                              child: Image.memory(_resimBytes!, fit: BoxFit.contain),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black.withValues(alpha: 0.65),
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                tooltip: 'Fotoğrafı Kaldır',
                                onPressed: () => setState(() => _resimBytes = null),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: _kameraCek,
                            icon: const Icon(Icons.photo_camera_outlined, size: 16),
                            label: const Text('Fotoğrafı Değiştir'),
                          ),
                          TextButton.icon(
                            onPressed: _galeriSec,
                            icon: const Icon(Icons.photo_library_outlined, size: 16),
                            label: const Text('Galeriden Değiştir'),
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: tema.colorScheme.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 36,
                              color: tema.colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Kitap Sayfası veya Tablo Fotoğrafı',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'İsteğe bağlı. Fotoğrafsız sadece metin notu da yazabilirsiniz.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: tema.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: _yukleniyor ? null : _kameraCek,
                                  icon: const Icon(Icons.camera_alt, size: 16),
                                  label: const Text('Kamerayla Çek'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _yukleniyor ? null : _galeriSec,
                                  icon: const Icon(Icons.photo_library, size: 16),
                                  label: const Text('Galeriden Seç'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Not / Bilgi Girişi Alanı
                    TextField(
                      controller: _metinDenetci,
                      maxLines: 5,
                      minLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Bölüm Notu / Bilgi Girişi',
                        hintText: 'Örn: Hoca Goodpasture ile Pevfigus ayrımını sordu. '
                            'Tip 2 aşırı duyarlılık antikor aracılıdır...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Vazgeç'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _kaydet(depo),
                    child: Text(duzenleme ? 'Güncelle' : 'Kaydet'),
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

/// Fotoğrafı tam ekranda açan ve iki parmakla yakınlaştırma (zoom) sağlayan görüntüleyici.
class TamEkranResimEkrani extends StatelessWidget {
  const TamEkranResimEkrani({
    super.key,
    required this.resimBytes,
    required this.baslik,
  });

  final Uint8List resimBytes;
  final String baslik;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          baslik,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 6.0,
          child: Image.memory(
            resimBytes,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
