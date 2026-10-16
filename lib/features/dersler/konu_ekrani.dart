import 'package:app/core/renkler.dart';
import 'package:app/core/tarih.dart';
import 'package:app/features/dersler/dialoglar.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// Konu detayı: ad, durum ve özel not alanı (onaylı tasarım: Konu).
/// Tekrar planı ve "Takvime ekle" düğmeleri takvim parçasında eklenecek.
class KonuEkrani extends StatefulWidget {
  const KonuEkrani({super.key, required this.konuId});

  final int konuId;

  @override
  State<KonuEkrani> createState() => _KonuEkraniState();
}

class _KonuEkraniState extends State<KonuEkrani> with WidgetsBindingObserver {
  late final PlanDeposu _depo;
  late final TextEditingController _not;

  @override
  void initState() {
    super.initState();
    _depo = DepoKapsami.oku(context);
    _not = TextEditingController(text: _depo.konuBul(widget.konuId)?.not ?? '');
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Sayfa kapanırken bekleyen not kaydını hemen yaz.
    _depo.hemenKaydet();
    _not.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState durum) {
    // Uygulama arka plana giderken not kaybolmasın.
    if (durum != AppLifecycleState.resumed) {
      _depo.hemenKaydet();
    }
  }

  Future<void> _menu(String secim, Konu konu) async {
    if (secim == 'ad') {
      final yeni = await MetinDialogu.goster(
        context,
        baslik: 'Konunun adı',
        ilkDeger: konu.ad,
      );
      if (!mounted || yeni == null) return;
      if (!_depo.konuAdiDegistir(konu.id, yeni)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad boş olamaz ve aynı derste tekrar edemez.'),
          ),
        );
      }
    } else if (secim == 'sil') {
      final onay = await onayDialogu(
        context,
        baslik: 'Konuyu sil?',
        metin: '"${konu.ad}" notuyla birlikte silinecek. Bu geri alınamaz.',
        eylem: 'Sil',
      );
      if (!mounted || !onay) return;
      Navigator.of(context).pop();
      _depo.konuSil(konu.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final soluk = tema.colorScheme.onSurfaceVariant;
    final konu = depo.konuBul(widget.konuId);
    if (konu == null) {
      // Konu silindi (sayfa kapanırken kısa süre görünür).
      return Scaffold(appBar: AppBar());
    }
    final ders = depo.dersBul(konu.dersId);
    final klinik = ders?.grup == DersGrubu.klinik;
    final ilk = konu.ilkCalisma;
    final durumYazisi = '${ders?.grup.ad ?? ''} · '
        '${ilk == null ? 'Henüz çalışılmadı' : 'İlk çalışma ${tarihYaz(ilk)}'}';
    return Scaffold(
      appBar: AppBar(
        title: Text(ders?.ad ?? ''),
        actions: [
          PopupMenuButton<String>(
            onSelected: (s) => _menu(s, konu),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'ad', child: Text('Adını değiştir')),
              PopupMenuItem(value: 'sil', child: Text('Konuyu sil')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              konu.ad,
              style: tema.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: klinik
                      ? klinikZemin(context)
                      : tema.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  durumYazisi,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: klinik
                        ? klinikYazi(context)
                        : tema.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: tema.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tekrar planı',
                      style: tema.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Konuyu takvime yerleştirince tekrar günleri burada '
                      'görünecek. (Bir sonraki adımda geliyor.)',
                      style: tema.textTheme.bodySmall?.copyWith(color: soluk),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Notlarım',
                    style: tema.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.lock_outline, size: 14, color: soluk),
                const SizedBox(width: 4),
                Text(
                  'Sadece sen görürsün',
                  style: tema.textTheme.labelSmall?.copyWith(color: soluk),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _not,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (metin) => _depo.notYaz(widget.konuId, metin),
                decoration: InputDecoration(
                  hintText: 'Buraya kendi notlarını yazarsın. Örnek: önemli '
                      'başlıklar, karıştırdığın yerler.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
