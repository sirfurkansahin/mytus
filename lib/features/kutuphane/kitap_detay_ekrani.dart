import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/tarih.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/kutuphane/bolum_notlari_ekrani.dart';
import 'package:app/features/kutuphane/modeller.dart';
import 'package:app/features/takvim/gun_siniri.dart';
import 'package:app/features/takvim/takvim_eylemleri.dart';
import 'package:flutter/material.dart';

/// Kitap detay ve içindekiler/bölüm çalışma ekranı.
class KitapDetayEkrani extends StatefulWidget {
  const KitapDetayEkrani({super.key, required this.kitapId});

  final String kitapId;

  @override
  State<KitapDetayEkrani> createState() => _KitapDetayEkraniState();
}

class _KitapDetayEkraniState extends State<KitapDetayEkrani> {
  int _filtre = 0; // 0: Tümü, 1: Kalanlar, 2: Bitenler, 3: Notlular
  final _yeniBolumDenetci = TextEditingController();
  final _aramaDenetci = TextEditingController();
  String _aramaMetni = '';

  @override
  void dispose() {
    _yeniBolumDenetci.dispose();
    _aramaDenetci.dispose();
    super.dispose();
  }

  Future<void> _gunlukHedefBelirleDialogu(PlanDeposu depo, Kitap kitap) async {
    final denetci = TextEditingController(
      text: kitap.gunlukSayfaHedefi != null ? '${kitap.gunlukSayfaHedefi}' : '',
    );
    final sonuc = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Günlük Sayfa Hedefi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu kitaptan günde kaç sayfa okumayı hedefliyorsunuz? Bitiş tarihi buna göre hesaplanacaktır.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: denetci,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Günlük Sayfa',
                hintText: 'Örn: 25',
                border: OutlineInputBorder(),
                suffixText: 'sayfa/gün',
              ),
            ),
          ],
        ),
        actions: [
          if (kitap.gunlukSayfaHedefi != null)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(-1),
              child: const Text('Hedefi Kaldır'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              final sayi = int.tryParse(denetci.text.trim());
              Navigator.of(ctx).pop(sayi);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (!mounted || sonuc == null) return;
    if (sonuc == -1) {
      await depo.kitapGunlukSayfaHedefiBelirle(kitap.id, null);
    } else if (sonuc > 0) {
      await depo.kitapGunlukSayfaHedefiBelirle(kitap.id, sonuc);
    }
  }

  /// Kütüphane ⟷ Takvim Organik Bağı:
  /// Bölümü bir konuya bağlar; "hemenBugunCalistim" ise bugünden R0-R4 tekrar zincirini başlatır,
  /// değilse takvimde seçilen güne yerleştirir.
  Future<void> _bolumuTakvimeBagla(
    PlanDeposu depo,
    Kitap kitap,
    KitapBolumu bolum, {
    required bool hemenBugunCalistim,
  }) async {
    // 1) İlgili dersi bul
    Ders? ders;
    if (kitap.dersId != null) {
      ders = depo.dersBul(kitap.dersId!);
    }
    if (ders == null && kitap.dersAdi != null) {
      for (final d in depo.tumDersler) {
        if (d.ad.toLowerCase() == kitap.dersAdi!.toLowerCase()) {
          ders = d;
          break;
        }
      }
    }
    if (ders == null && depo.tumDersler.isNotEmpty) {
      ders = depo.tumDersler.first;
    }
    if (ders == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce Dersler sekmesinden en az 1 ders eklemelisiniz.')),
      );
      return;
    }

    // 2) Dersteki mevcut konuları getir
    final mevcutKonular = depo.konular(ders.id);

    // 3) Konu seçme diyaloğu (Kullanıcı Kararı A1: dersteki mevcut konulardan seç veya yeni oluştur)
    final secilenKonuId = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hemenBugunCalistim
                          ? 'Tekrar Zincirini Başlat'
                          : 'Takvime Planla',
                      style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${bolum.ad}" bölümü ${ders!.ad} dersinde hangi konuya bağlansın?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(sheetCtx).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Yeni konu olarak oluştur seçeneği
              ListTile(
                leading: const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.add, size: 18),
                ),
                title: Text(
                  '+ Yeni Konu Oluştur: "${bolum.ad}"',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${ders.ad} dersine yeni konu olarak eklenir'),
                onTap: () {
                  final yeni = depo.konuEkle(ders!.id, bolum.ad);
                  Navigator.of(sheetCtx).pop(yeni?.id);
                },
              ),
              if (mevcutKonular.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(
                    'VEYA MEVCUT KONULARDAN BİRİNİ SEÇ:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: mevcutKonular.length,
                    itemBuilder: (_, i) {
                      final k = mevcutKonular[i];
                      return ListTile(
                        leading: const Icon(Icons.menu_book_outlined, size: 20),
                        title: Text(k.ad),
                        onTap: () => Navigator.of(sheetCtx).pop(k.id),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (secilenKonuId == null || !mounted) return;

    final bugun = gunBasi(DateTime.now());

    if (hemenBugunCalistim) {
      // 1) Çalışma ekle ve hemen "Çalıştım" işaretle
      final calisma = depo.calismaEkle(secilenKonuId, bugun);
      if (calisma != null) {
        depo.calistim(calisma.id, bugun);
      }
      // 2) Kütüphanedeki bölümü de tamamlandı yap
      await depo.kitapBolumDurumuDegistir(kitap.id, bolum.id, true);

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Harika! "${bolum.ad}" tamamlandı ve aralıklı tekrar zinciri (R0–R4) bugünden planlandı.',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
      }
    } else {
      // Takvime ileri tarihli planlama
      final secilenGun = await yerlestirmeGunuSec(context, depo, baslangic: bugun);
      if (secilenGun == null || !mounted) return;

      if (!await yeniKonuSiniriOnayi(context, depo, secilenGun) || !mounted) {
        return;
      }

      depo.calismaEkle(secilenKonuId, secilenGun);

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                '"${bolum.ad}" ${tarihKisa(secilenGun)} gününe planlandı.',
              ),
            ),
          );
      }
    }
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

  void _bolumHizliNotPenceresi(PlanDeposu depo, Kitap kitap, KitapBolumu bolum) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final tema = Theme.of(ctx);
        final guncelKitap = depo.kitapBul(kitap.id) ?? kitap;
        final guncelBolum = guncelKitap.bolumler.firstWhere(
          (b) => b.id == bolum.id,
          orElse: () => bolum,
        );
        final notlar = guncelBolum.notlar;

        return DraggableScrollableSheet(
          initialChildSize: notlar.isEmpty ? 0.38 : 0.65,
          minChildSize: 0.28,
          maxChildSize: 0.92,
          expand: false,
          builder: (ctx, scrollController) => Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tema.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guncelBolum.ad,
                            style: tema.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            guncelBolum.sayfaAraligiMetni.isNotEmpty
                                ? '${guncelBolum.sayfaAraligiMetni} · ${notlar.length} Not'
                                : '${notlar.length} Not',
                            style: TextStyle(
                              fontSize: 12,
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Not Ekle'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        showDialog<void>(
                          context: context,
                          builder: (_) => NotDuzenleDialogu(
                            kitapId: kitap.id,
                            bolumId: bolum.id,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: notlar.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.note_alt_outlined,
                                size: 44,
                                color: tema.colorScheme.primary.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Bu bölüme henüz not eklenmedi',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Klinik ipucu, vaka özeti veya kitap fotoğrafı ekleyebilirsiniz.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tema.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: notlar.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final not = notlar[i];
                          return _HizliNotKarti(
                            not: not,
                            onSil: () {
                              depo.kitapBolumNotuSil(kitap.id, bolum.id, not.id);
                              Navigator.of(ctx).pop();
                            },
                            onTamSayfa: () {
                              Navigator.of(ctx).pop();
                              _bolumNotlariniAc(bolum.id);
                            },
                          );
                        },
                      ),
              ),
              if (notlar.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: TextButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Tüm Notları ve Fotoğrafları Yönet'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _bolumNotlariniAc(bolum.id);
                    },
                  ),
                ),
            ],
          ),
        );
      },
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
      if (_filtre == 1 && b.tamamlandi) return false;
      if (_filtre == 2 && !b.tamamlandi) return false;
      if (_filtre == 3 && !b.notVar) return false;

      if (_aramaMetni.isNotEmpty) {
        final adEslesir = b.ad.toLowerCase().contains(_aramaMetni);
        final sayfaEslesir = b.sayfaAraligiMetni.toLowerCase().contains(_aramaMetni);
        if (!adEslesir && !sayfaEslesir) return false;
      }
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
              if (val == 'hedef') _gunlukHedefBelirleDialogu(depo, kitap);
              if (val == 'klasor') _klasorDegistirDialogu(depo, kitap);
              if (val == 'sil') _kitapSilOnayi(depo, kitap);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'hedef',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Günlük Sayfa Hedefi Belirle'),
                  ],
                ),
              ),
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
                  Builder(
                    builder: (_) {
                      final kalanSayfa = kitap.kalanSayfaSayisi;
                      if (kalanSayfa == null || kitap.tamamlandi) {
                        return const SizedBox.shrink();
                      }
                      final otoHiz = depo.otomatikGunlukSayfaHizi;
                      final tahminiGun = kitap.tahminiKalanGun(otoHiz);
                      final tahminiTarih = tahminiGun != null
                          ? gunEkle(DateTime.now(), tahminiGun)
                          : null;

                      final bilgiMetni = tahminiGun != null
                          ? '$kalanSayfa sayfa kaldı · ${kitap.gunlukSayfaHedefi != null ? "Hedef: ${kitap.gunlukSayfaHedefi} s/gün" : "Hız: ${otoHiz.toStringAsFixed(0)} s/gün"} · Bitiş: $tahminiGun gün (${tarihKisa(tahminiTarih!)})'
                          : '$kalanSayfa sayfa kaldı · Tahmini bitiş için hedef belirleyin';

                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: tema.colorScheme.surface.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_graph_outlined,
                                size: 16,
                                color: tema.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  bilgiMetni,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: tema.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Günlük Sayfa Hedefi Belirle',
                                icon: const Icon(Icons.edit_outlined, size: 15),
                                onPressed: () => _gunlukHedefBelirleDialogu(depo, kitap),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Sıradaki Bölüm Kartı (arama yapılmıyorken ve tümü filtresindeyken)
          if (siradaki != null && _aramaMetni.isEmpty && _filtre == 0) ...[
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
                          onPressed: () => _bolumHizliNotPenceresi(depo, kitap, siradaki),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Takvim ve Tekrar Seçenekleri',
                          icon: const Icon(Icons.event_note, color: Colors.teal, size: 22),
                          onSelected: (val) {
                            if (val == 'planla') {
                              _bolumuTakvimeBagla(depo, kitap, siradaki, hemenBugunCalistim: false);
                            } else if (val == 'zincir') {
                              _bolumuTakvimeBagla(depo, kitap, siradaki, hemenBugunCalistim: true);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'zincir',
                              child: Row(
                                children: [
                                  Icon(Icons.replay_circle_filled, size: 18, color: Colors.teal),
                                  SizedBox(width: 8),
                                  Text('Bugün Çalıştım & Tekrar Başlat'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'planla',
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('İleri Tarihe Planla'),
                                ],
                              ),
                            ),
                          ],
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

          // Bölüm Arama Çubuğu
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: TextField(
              controller: _aramaDenetci,
              decoration: InputDecoration(
                hintText: 'Bölüm veya sayfa ara (örn: Kalp, 45)...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _aramaMetni.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _aramaDenetci.clear();
                          setState(() => _aramaMetni = '');
                        },
                      )
                    : null,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: tema.colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              onChanged: (val) => setState(() => _aramaMetni = val.trim().toLowerCase()),
            ),
          ),

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
                    label: Text(
                      'Tümü (${kitap.toplamBolumSayisi})',
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: _filtre == 0,
                    onSelected: (_) => setState(() => _filtre = 0),
                    visualDensity: VisualDensity.compact,
                  ),
                  ChoiceChip(
                    label: Text(
                      'Kalanlar (${kitap.kalanBolumSayisi})',
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: _filtre == 1,
                    onSelected: (_) => setState(() => _filtre = 1),
                    visualDensity: VisualDensity.compact,
                  ),
                  ChoiceChip(
                    label: Text(
                      'Bitenler (${kitap.tamamlananBolumSayisi})',
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: _filtre == 2,
                    onSelected: (_) => setState(() => _filtre = 2),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (kitap.notluBolumSayisi > 0)
                    ChoiceChip(
                      avatar: const Icon(Icons.note_alt_outlined, size: 14),
                      label: Text(
                        'Notlular (${kitap.notluBolumSayisi})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: _filtre == 3,
                      onSelected: (_) => setState(() => _filtre = 3),
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
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  _aramaMetni.isNotEmpty
                      ? '"$_aramaMetni" ile eşleşen bölüm bulunamadı.'
                      : 'Bu filtreye uygun bölüm bulunamadı.',
                  style: TextStyle(color: tema.colorScheme.onSurfaceVariant),
                ),
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
                onHizliNot: () => _bolumHizliNotPenceresi(depo, kitap, filtrelenmis[i]),
                onTakvimePlanla: () => _bolumuTakvimeBagla(
                  depo,
                  kitap,
                  filtrelenmis[i],
                  hemenBugunCalistim: false,
                ),
                onTekrarBaslat: () => _bolumuTakvimeBagla(
                  depo,
                  kitap,
                  filtrelenmis[i],
                  hemenBugunCalistim: true,
                ),
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
    required this.onHizliNot,
    required this.onTakvimePlanla,
    required this.onTekrarBaslat,
    required this.onSil,
  });

  final int sira;
  final KitapBolumu bolum;
  final ValueChanged<bool> onDegisti;
  final VoidCallback onNotlar;
  final VoidCallback onHizliNot;
  final VoidCallback onTakvimePlanla;
  final VoidCallback onTekrarBaslat;
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
        onTap: onHizliNot,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Checkbox(
              value: tamam,
              activeColor: Colors.teal,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              onChanged: (val) => onDegisti(val ?? false),
            ),
          ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: tema.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            bolum.notlar.any((n) => n.resimVar)
                                ? Icons.photo_camera_outlined
                                : Icons.edit_note,
                            size: 13,
                            color: tema.colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            bolum.notlar.any((n) => n.resimVar)
                                ? '${bolum.notSayisi} not 📷'
                                : '${bolum.notSayisi} not',
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
            PopupMenuButton<String>(
              tooltip: 'Takvim ve Tekrar Seçenekleri',
              icon: const Icon(Icons.calendar_month_outlined, size: 20),
              color: tema.colorScheme.surface,
              onSelected: (val) {
                if (val == 'planla') {
                  onTakvimePlanla();
                } else if (val == 'zincir') {
                  onTekrarBaslat();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'zincir',
                  child: Row(
                    children: [
                      Icon(Icons.replay_circle_filled, size: 18, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('Bugün Çalıştım & Tekrar Başlat'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'planla',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('İleri Tarihe Planla'),
                    ],
                  ),
                ),
              ],
            ),
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

class _HizliNotKarti extends StatelessWidget {
  const _HizliNotKarti({
    required this.not,
    required this.onSil,
    required this.onTamSayfa,
  });

  final BolumNotu not;
  final VoidCallback onSil;
  final VoidCallback onTamSayfa;

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

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: tema.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resimBytes != null)
              GestureDetector(
                onTap: onTamSayfa,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 160),
                    width: double.infinity,
                    color: tema.colorScheme.surfaceContainerHighest,
                    child: Image.memory(
                      resimBytes,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            if (resimBytes != null && not.metinVar) const SizedBox(height: 8),
            if (not.metinVar) ...[
              Text(
                not.metin,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 6),
            ],
            if (not.etiketVar) ...[
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: [
                  for (final etiket in not.etiketler)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tema.colorScheme.secondaryContainer.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#$etiket',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tema.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${not.olusturmaTarihi.day}.${not.olusturmaTarihi.month}.${not.olusturmaTarihi.year}',
                  style: TextStyle(fontSize: 11, color: tema.colorScheme.outline),
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
      ),
    );
  }
}
