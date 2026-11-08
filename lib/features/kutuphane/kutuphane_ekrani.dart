import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/kutuphane/hazir_klasorler.dart';
import 'package:app/features/kutuphane/kitap_detay_ekrani.dart';
import 'package:app/features/kutuphane/kitap_ekle_dialogu.dart';
import 'package:app/features/kutuphane/modeller.dart';
import 'package:flutter/material.dart';

/// Kütüphane Modülü Ana Ekranı:
/// Klasörleme / gruplandırma, klasör filtre çipleri, genel tamamlama oranı ve içindekiler takibi.
class KutuphaneEkrani extends StatefulWidget {
  const KutuphaneEkrani({super.key});

  @override
  State<KutuphaneEkrani> createState() => _KutuphaneEkraniState();
}

class _KutuphaneEkraniState extends State<KutuphaneEkrani> {
  static const String _tumuEtiketi = '__TUMU__';
  static const String _digerEtiketi = 'Diğer Kitaplar';

  String _seciliKlasor = _tumuEtiketi;
  final Set<String> _kapaliKlasorler = {};
  final _kitapAramaDenetci = TextEditingController();
  String _kitapAramaMetni = '';

  @override
  void dispose() {
    _kitapAramaDenetci.dispose();
    super.dispose();
  }

  Future<void> _hazirKlasorIndir(PlanDeposu depo, HazirKlasor klasor) async {
    final eklenen = await depo.hazirKlasorYukle(klasor.id);
    if (!mounted) return;
    setState(() => _seciliKlasor = klasor.ad);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          eklenen > 0
              ? '${klasor.ad} ($eklenen kitap) hesabınıza indirildi.'
              : '${klasor.ad} zaten kütüphanenizde mevcut.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _hazirKlasorlerDialogu(PlanDeposu depo) {
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final tema = Theme.of(ctx);
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.cloud_download_outlined),
                SizedBox(width: 8),
                Expanded(child: Text('Hazır Kitap Klasörleri')),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'İstediğiniz hazır klasörü seçip tek dokunuşla tüm kitapları ve içindekiler bölümlerini hesabınıza indirebilirsiniz:',
                    style: TextStyle(
                      fontSize: 13,
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < hazirKutuphaneKlasorleri.length; i++) ...[
                    Builder(
                      builder: (_) {
                        final kl = hazirKutuphaneKlasorleri[i];
                        final yuklu = depo.hazirKlasorYukluMu(kl.id);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tema.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: yuklu
                                  ? Colors.teal.withValues(alpha: 0.4)
                                  : tema.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    yuklu
                                        ? Icons.folder_special_rounded
                                        : Icons.folder_copy_outlined,
                                    color: yuklu
                                        ? Colors.teal
                                        : tema.colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${i + 1} - ${kl.ad}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${kl.kitapSayisi} Kitap · ${kl.toplamBolumSayisi} Bölüm — ${kl.aciklama}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tema.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: yuklu
                                    ? const Chip(
                                        avatar: Icon(
                                          Icons.check_circle,
                                          color: Colors.teal,
                                          size: 16,
                                        ),
                                        label: Text(
                                          'Hesapta Mevcut',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      )
                                    : FilledButton.tonalIcon(
                                        onPressed: () async {
                                          await _hazirKlasorIndir(depo, kl);
                                          if (ctx.mounted) {
                                            setDialogState(() {});
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.download_rounded,
                                          size: 18,
                                        ),
                                        label: const Text('Hesabıma İndir'),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Kapat'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _yeniKlasorOlusturDialogu(PlanDeposu depo) {
    final adDenetci = TextEditingController();
    final seciliKitapIdleri = <String>{};

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final tumKitaplar = depo.kitaplar;
          return AlertDialog(
            title: const Text('Klasör Oluştur / Kitapları Grupla'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460, maxHeight: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: adDenetci,
                    decoration: const InputDecoration(
                      labelText: 'Klasör Adı *',
                      hintText: 'Örn: SpeeTUS (5. Baskı), Soru Bankaları',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.create_new_folder_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bu klasöre eklenecek kitapları seç:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  if (tumKitaplar.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Henüz kitap yok. Klasör adını yazıp yeni kitap ekleyebilirsin.',
                        style: TextStyle(fontSize: 12),
                      ),
                    )
                  else
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(ctx).colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: tumKitaplar.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final k = tumKitaplar[i];
                            final secili = seciliKitapIdleri.contains(k.id);
                            return CheckboxListTile(
                              dense: true,
                              value: secili,
                              title: Text(
                                k.ad,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: k.klasoruVar
                                  ? Text(
                                      'Mevcut klasör: ${k.klasorAdi}',
                                      style: const TextStyle(fontSize: 11),
                                    )
                                  : null,
                              onChanged: (v) {
                                setDialogState(() {
                                  if (v == true) {
                                    seciliKitapIdleri.add(k.id);
                                  } else {
                                    seciliKitapIdleri.remove(k.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () async {
                  final klasorAdi = adDenetci.text.trim();
                  if (klasorAdi.isEmpty) return;
                  if (seciliKitapIdleri.isEmpty && tumKitaplar.isEmpty) {
                    Navigator.of(ctx).pop();
                    showDialog<void>(
                      context: context,
                      builder: (_) =>
                          KitapEkleDialogu(varsayilanKlasor: klasorAdi),
                    );
                    return;
                  }
                  for (final id in seciliKitapIdleri) {
                    await depo.kitapKlasoruDegistir(id, klasorAdi);
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  setState(() => _seciliKlasor = klasorAdi);
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _klasorYonetimDialogu(PlanDeposu depo, String klasorAdi) {
    final denetci = TextEditingController(text: klasorAdi);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Klasörü Düzenle'),
        content: TextField(
          controller: denetci,
          decoration: const InputDecoration(
            labelText: 'Klasör Adı',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.folder_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await depo.klasorYenidenAdlandir(klasorAdi, null);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (_seciliKlasor == klasorAdi) {
                setState(() => _seciliKlasor = _tumuEtiketi);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Klasörü Dağıt (Kitaplar Silinmez)'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () async {
              final yeni = denetci.text.trim();
              if (yeni.isNotEmpty && yeni != klasorAdi) {
                await depo.klasorYenidenAdlandir(klasorAdi, yeni);
                if (_seciliKlasor == klasorAdi) {
                  setState(() => _seciliKlasor = yeni);
                }
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final kitaplar = depo.kitaplar;
    final klasorler = depo.kitapKlasorleri;
    final digerKitaplar = kitaplar.where((k) => !k.klasoruVar).toList();
    final klasorlemeAktif = klasorler.isNotEmpty;

    // Seçili klasör artık mevcut değilse 'Tümü'ne dön.
    final gecerliSecim = (_seciliKlasor == _tumuEtiketi ||
            klasorler.contains(_seciliKlasor) ||
            (_seciliKlasor == _digerEtiketi && digerKitaplar.isNotEmpty))
        ? _seciliKlasor
        : _tumuEtiketi;

    // Üst özet kartı seçili klasöre (veya tümüne) göre hesaplanır.
    final ozetKitaplar = gecerliSecim == _tumuEtiketi
        ? kitaplar
        : (gecerliSecim == _digerEtiketi
            ? digerKitaplar
            : kitaplar.where((k) => k.klasorAdi?.trim() == gecerliSecim).toList());

    final toplamKitap = ozetKitaplar.length;
    final toplamBolum =
        ozetKitaplar.fold<int>(0, (top, k) => top + k.toplamBolumSayisi);
    final bitenBolum =
        ozetKitaplar.fold<int>(0, (top, k) => top + k.tamamlananBolumSayisi);
    final genelOran = toplamBolum > 0 ? (bitenBolum / toplamBolum) : 0.0;
    final genelYuzde = (genelOran * 100).round();

    final arananKitaplar = _kitapAramaMetni.isNotEmpty
        ? kitaplar.where((k) {
            final adUyusur = k.ad.toLowerCase().contains(_kitapAramaMetni);
            final dersUyusur =
                k.dersAdi?.toLowerCase().contains(_kitapAramaMetni) == true;
            final klasorUyusur =
                k.klasorAdi?.toLowerCase().contains(_kitapAramaMetni) == true;
            return adUyusur || dersUyusur || klasorUyusur;
          }).toList()
        : const <Kitap>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kütüphane',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Hazır Klasörler',
            icon: const Icon(Icons.cloud_download_outlined),
            onPressed: () => _hazirKlasorlerDialogu(depo),
          ),
          IconButton(
            tooltip: 'Klasör Oluştur / Grupla',
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => _yeniKlasorOlusturDialogu(depo),
          ),
          IconButton(
            tooltip: 'Yeni Kitap Ekle',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => KitapEkleDialogu(
                  varsayilanKlasor: gecerliSecim != _tumuEtiketi &&
                          gecerliSecim != _digerEtiketi
                      ? gecerliSecim
                      : null,
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'hazir') {
                _hazirKlasorlerDialogu(depo);
              } else if (val == 'klasor') {
                _yeniKlasorOlusturDialogu(depo);
              } else if (val == 'ornek') {
                depo.ornekKitapYukle();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Örnek Patoloji kitabı kütüphaneye yüklendi.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'hazir',
                child: Row(
                  children: [
                    Icon(Icons.cloud_download_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Hazır Kitap Klasörleri'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'klasor',
                child: Row(
                  children: [
                    Icon(Icons.create_new_folder_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Klasör Oluştur / Kitapları Grupla'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'ornek',
                child: Row(
                  children: [
                    Icon(Icons.auto_stories_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Örnek Kitap Yükle'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (_) => KitapEkleDialogu(
              varsayilanKlasor:
                  gecerliSecim != _tumuEtiketi && gecerliSecim != _digerEtiketi
                      ? gecerliSecim
                      : null,
            ),
          );
        },
        icon: const Icon(Icons.menu_book_outlined),
        label: const Text('Kitap Ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          // Genel Kütüphane Özeti Kartı
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: tema.colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            color: tema.colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        gecerliSecim == _tumuEtiketi
                            ? Icons.local_library_outlined
                            : Icons.folder_special_outlined,
                        color: tema.colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          gecerliSecim == _tumuEtiketi
                              ? 'Kütüphane İlerlemesi'
                              : gecerliSecim,
                          style: tema.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '%$genelYuzde',
                        style: TextStyle(
                          fontSize: 22,
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
                      value: genelOran,
                      minHeight: 8,
                      backgroundColor:
                          tema.colorScheme.primary.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        genelYuzde == 100
                            ? Colors.teal
                            : tema.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '$toplamKitap Kitap · $toplamBolum Bölüm',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '$bitenBolum bölüm bitti',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tema.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Kitap Arama Çubuğu
          if (kitaplar.length >= 2)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: TextField(
                controller: _kitapAramaDenetci,
                decoration: InputDecoration(
                  hintText: 'Kitap veya ders ara (örn: Patoloji, SpeeTUS)...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _kitapAramaMetni.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _kitapAramaDenetci.clear();
                            setState(() => _kitapAramaMetni = '');
                          },
                        )
                      : null,
                  filled: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: tema.colorScheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: tema.colorScheme.outlineVariant
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ),
                onChanged: (val) =>
                    setState(() => _kitapAramaMetni = val.trim().toLowerCase()),
              ),
            ),

          // Klasör Filtre Çipleri
          if (kitaplar.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.apps, size: 16),
                  label: Text(
                    'Tümü (${kitaplar.length})',
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: gecerliSecim == _tumuEtiketi,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) =>
                      setState(() => _seciliKlasor = _tumuEtiketi),
                ),
                for (final kl in klasorler)
                  ChoiceChip(
                    avatar: const Icon(Icons.folder_outlined, size: 16),
                    label: Text(
                      '$kl (${kitaplar.where((k) => k.klasorAdi?.trim() == kl).length})',
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: gecerliSecim == kl,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _seciliKlasor = kl),
                  ),
                if (klasorlemeAktif && digerKitaplar.isNotEmpty)
                  ChoiceChip(
                    avatar: const Icon(Icons.library_books_outlined, size: 16),
                    label: Text(
                      '$_digerEtiketi (${digerKitaplar.length})',
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: gecerliSecim == _digerEtiketi,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) =>
                        setState(() => _seciliKlasor = _digerEtiketi),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.create_new_folder_outlined, size: 16),
                  label: const Text(
                    '+ Klasör',
                    style: TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _yeniKlasorOlusturDialogu(depo),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Yeni veya eksik klasörü olan kullanıcılara hazır klasör öneri kartı
          if (hazirKutuphaneKlasorleri
              .any((kl) => !depo.hazirKlasorYukluMu(kl.id))) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: tema.colorScheme.secondary.withValues(alpha: 0.35),
                ),
              ),
              color: tema.colorScheme.secondaryContainer.withValues(alpha: 0.25),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_download_outlined,
                          size: 18,
                          color: tema.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hazır Klasörler — İstediğini Seç, Hesabına İndir',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: tema.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0;
                            i < hazirKutuphaneKlasorleri.length;
                            i++)
                          Builder(
                            builder: (_) {
                              final kl = hazirKutuphaneKlasorleri[i];
                              final yuklu = depo.hazirKlasorYukluMu(kl.id);
                              return ActionChip(
                                avatar: Icon(
                                  yuklu
                                      ? Icons.check_circle
                                      : Icons.download_rounded,
                                  size: 16,
                                  color: yuklu
                                      ? Colors.teal
                                      : tema.colorScheme.primary,
                                ),
                                label: Text(
                                  yuklu
                                      ? '${i + 1} - ${kl.ad} (İndirildi)'
                                      : '${i + 1} - ${kl.ad} (${kl.kitapSayisi} Kitap)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                visualDensity: VisualDensity.compact,
                                onPressed: yuklu
                                    ? () => setState(() => _seciliKlasor = kl.ad)
                                    : () => _hazirKlasorIndir(depo, kl),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (kitaplar.isEmpty) ...[
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
                        Icons.auto_stories_outlined,
                        size: 48,
                        color: tema.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Kütüphaneniz Henüz Boş',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'TUS konu kitaplarınızı, soru fasiküllerinizi veya spot notlarınızı '
                        'ekleyerek içindekiler takibini başlatabilirsiniz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              depo.ornekKitapYukle();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Örnek Patoloji kitabı kütüphaneye yüklendi.',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.auto_stories_outlined),
                            label: const Text('Örnek Kitap Yükle'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              showDialog<void>(
                                context: context,
                                builder: (_) => const KitapEkleDialogu(),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('İlk Kitabını Ekle'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else if (_kitapAramaMetni.isNotEmpty) ...[
            // Arama sonuçları
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ARAMA SONUÇLARI (${arananKitaplar.length})',
                    style: tema.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: tema.colorScheme.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _kitapAramaDenetci.clear();
                    setState(() => _kitapAramaMetni = '');
                  },
                  child: const Text('Aramayı Temizle'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (arananKitaplar.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 40,
                        color: tema.colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"$_kitapAramaMetni" ile eşleşen kitap bulunamadı.',
                        style: TextStyle(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final k in arananKitaplar) ...[
                _KitapKarti(kitap: k),
                const SizedBox(height: 10),
              ],
          ] else if (gecerliSecim == _tumuEtiketi && klasorlemeAktif) ...[
            // Klasörler halinde açılır/kapanır görünüm
            for (final kl in klasorler) ...[
              _KlasorBolumu(
                klasorAdi: kl,
                kitaplar: kitaplar
                    .where((k) => k.klasorAdi?.trim() == kl)
                    .toList(),
                acikMi: !_kapaliKlasorler.contains(kl),
                onBaslikTikla: () {
                  setState(() {
                    if (_kapaliKlasorler.contains(kl)) {
                      _kapaliKlasorler.remove(kl);
                    } else {
                      _kapaliKlasorler.add(kl);
                    }
                  });
                },
                onDuzenle: () => _klasorYonetimDialogu(depo, kl),
              ),
              const SizedBox(height: 12),
            ],
            if (digerKitaplar.isNotEmpty)
              _KlasorBolumu(
                klasorAdi: _digerEtiketi,
                kitaplar: digerKitaplar,
                acikMi: !_kapaliKlasorler.contains(_digerEtiketi),
                onBaslikTikla: () {
                  setState(() {
                    if (_kapaliKlasorler.contains(_digerEtiketi)) {
                      _kapaliKlasorler.remove(_digerEtiketi);
                    } else {
                      _kapaliKlasorler.add(_digerEtiketi);
                    }
                  });
                },
              ),
          ] else ...[
            // Tekil klasör seçiliyse veya hiç klasör yoksa düz liste
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    gecerliSecim == _tumuEtiketi
                        ? 'KİTAPLARIM (${ozetKitaplar.length})'
                        : '${gecerliSecim.toUpperCase()} (${ozetKitaplar.length})',
                    style: tema.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: tema.colorScheme.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (gecerliSecim != _tumuEtiketi &&
                    gecerliSecim != _digerEtiketi)
                  TextButton.icon(
                    onPressed: () => _klasorYonetimDialogu(depo, gecerliSecim),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Klasörü Düzenle'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (final k in ozetKitaplar) ...[
              _KitapKarti(kitap: k),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _KlasorBolumu extends StatelessWidget {
  const _KlasorBolumu({
    required this.klasorAdi,
    required this.kitaplar,
    required this.acikMi,
    required this.onBaslikTikla,
    this.onDuzenle,
  });

  final String klasorAdi;
  final List<Kitap> kitaplar;
  final bool acikMi;
  final VoidCallback onBaslikTikla;
  final VoidCallback? onDuzenle;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final toplamBolum =
        kitaplar.fold<int>(0, (top, k) => top + k.toplamBolumSayisi);
    final bitenBolum =
        kitaplar.fold<int>(0, (top, k) => top + k.tamamlananBolumSayisi);
    final yuzde =
        toplamBolum > 0 ? ((bitenBolum / toplamBolum) * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onBaslikTikla,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: tema.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  acikMi ? Icons.folder_open_rounded : Icons.folder_rounded,
                  color: tema.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        klasorAdi,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${kitaplar.length} kitap · $bitenBolum/$toplamBolum bölüm (%$yuzde)',
                        style: TextStyle(
                          fontSize: 11,
                          color: tema.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDuzenle != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Klasörü Düzenle',
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onDuzenle,
                  ),
                Icon(
                  acikMi ? Icons.expand_less : Icons.expand_more,
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (acikMi) ...[
          const SizedBox(height: 8),
          for (final k in kitaplar) ...[
            _KitapKarti(kitap: k),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _KitapKarti extends StatelessWidget {
  const _KitapKarti({required this.kitap});

  final Kitap kitap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final siradaki = kitap.siradakiBolum;
    final bitti = kitap.tamamlandi;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: bitti
              ? Colors.teal.withValues(alpha: 0.3)
              : tema.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      color: bitti ? Colors.teal.withValues(alpha: 0.03) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => KitapDetayEkrani(kitapId: kitap.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 52,
                    decoration: BoxDecoration(
                      color: bitti
                          ? Colors.teal.withValues(alpha: 0.15)
                          : tema.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: bitti
                            ? Colors.teal.withValues(alpha: 0.4)
                            : tema.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      bitti ? Icons.task_alt : Icons.menu_book,
                      color: bitti ? Colors.teal : tema.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kitap.ad,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tema.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                kitap.dersAdi ?? 'Genel',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: tema.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            if (kitap.klasoruVar)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: tema.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '📁 ${kitap.klasorAdi}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: tema.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            if (kitap.toplamSayfa != null)
                              Text(
                                '${kitap.toplamSayfa} sayfa',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tema.colorScheme.outline,
                                ),
                              ),
                            if (kitap.toplamNotSayisi > 0)
                              Text(
                                '· ${kitap.toplamNotSayisi} not',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: tema.colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '%${kitap.yuzde}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: bitti ? Colors.teal : tema.colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${kitap.tamamlananBolumSayisi}/${kitap.toplamBolumSayisi}',
                        style: TextStyle(
                          fontSize: 11,
                          color: tema.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: kitap.ilerlemeOrani,
                  minHeight: 5,
                  backgroundColor:
                      tema.colorScheme.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    bitti ? Colors.teal : tema.colorScheme.primary,
                  ),
                ),
              ),
              if (siradaki != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.arrow_right, size: 16, color: Colors.teal),
                    Expanded(
                      child: Text(
                        'Sırada: ${siradaki.ad}${siradaki.sayfaAraligiMetni.isNotEmpty ? ' (${siradaki.sayfaAraligiMetni})' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
