import 'package:app/core/renkler.dart';
import 'package:app/core/tarih.dart';
import 'package:app/features/dersler/dialoglar.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/takvim/calisma.dart';
import 'package:app/features/takvim/takvim_eylemleri.dart';
import 'package:app/features/takvim/tekrar_motoru.dart';
import 'package:flutter/material.dart';

/// Konu detayı: ad, durum ve özel not alanı (onaylı tasarım: Konu).
/// Her yerleştirme (tur) için kendi tekrar planı gösterilir.
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

  Future<void> _takvimeEkle() async {
    final bugun = gunBasi(DateTime.now());
    final gun = await yerlestirmeGunuSec(context, _depo, baslangic: bugun);
    if (!mounted || gun == null) return;
    _depo.calismaEkle(widget.konuId, gun);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${tarihKisa(gun)} gününe yerleştirildi.')),
      );
  }

  Widget _kart(BuildContext context, {required Widget child}) {
    final tema = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tema.colorScheme.outlineVariant),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  /// Tek bir tekrarın küçük göstergesi: yapıldı ✓ / sırada (kehribar halka) / bekliyor.
  Widget _tekrarKutusu(
    BuildContext context,
    TekrarOgesi t,
    DateTime bugun,
  ) {
    final tema = Theme.of(context);
    final vurgu = tekrarRengi(context);
    final gecikti = !t.yapildi && t.calismaTamam && t.tarih.isBefore(bugun);
    final Widget ikon;
    if (t.yapildi) {
      ikon = Icon(Icons.check_circle, color: vurgu, size: 28);
    } else if (t.eylemYapilabilir) {
      ikon = Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: vurgu, width: 3),
        ),
      );
    } else {
      ikon = Icon(
        Icons.radio_button_unchecked,
        color: tema.colorScheme.outline,
        size: 28,
      );
    }
    return Semantics(
      button: true,
      label: 'Tekrar ${t.no}, ${tarihKisa(t.tarih)}'
          '${t.yapildi ? ', yapıldı' : gecikti ? ', gecikti' : ''}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => tekrarEylemleri(context, t, bugun),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ikon,
              const SizedBox(height: 4),
              Text(
                tarihKisa(t.tarih),
                style: tema.textTheme.labelSmall?.copyWith(
                  color: gecikti ? vurgu : tema.colorScheme.onSurfaceVariant,
                  fontWeight: gecikti ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calismaKarti(
    BuildContext context,
    PlanDeposu depo,
    Calisma c,
    List<TekrarOgesi> tekrarlar,
    DateTime bugun,
  ) {
    final tema = Theme.of(context);
    final soluk = tema.colorScheme.onSurfaceVariant;
    final benimkiler = [
      for (final t in tekrarlar)
        if (t.calismaId == c.id) t,
    ]..sort((a, b) => a.no.compareTo(b.no));
    final isaretlenebilir = !c.tamam && !c.tarih.isAfter(bugun);
    final durum = c.tamam
        ? 'Çalışıldı · ${tarihKisa(c.tarih)}'
        : 'Planlı · ${tarihKisa(c.tarih)}';
    return _kart(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tur ${depo.turNo(c)}/${depo.turSayisi} · $durum',
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Bu çalışma için işlemler',
                icon: const Icon(Icons.more_horiz),
                onPressed: () => calismaEylemleri(context, c, bugun),
              ),
            ],
          ),
          if (benimkiler.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Tekrar planı',
              style: tema.textTheme.labelMedium?.copyWith(color: soluk),
            ),
            const SizedBox(height: 4),
            Wrap(
              children: [
                for (final t in benimkiler) _tekrarKutusu(context, t, bugun),
              ],
            ),
          ] else
            Text(
              depo.sinavTarihi == null
                  ? 'Tekrar günleri için sınav tarihi gerekli (Bugün sekmesi).'
                  : 'Bu çalışma için tekrar günü kalmadı.',
              style: tema.textTheme.bodySmall?.copyWith(color: soluk),
            ),
          if (!c.tamam) ...[
            const SizedBox(height: 8),
            if (isaretlenebilir)
              FilledButton.icon(
                onPressed: () => depo.calistim(c.id, bugun),
                icon: const Icon(Icons.check),
                label: const Text('Çalıştım'),
              )
            else
              Text(
                'Planlanan günde "Çalıştım" diyebilirsin; istersen "Bugüne al".',
                style: tema.textTheme.bodySmall?.copyWith(color: soluk),
              ),
          ],
        ],
      ),
    );
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
    final bugun = gunBasi(DateTime.now());
    final ders = depo.dersBul(konu.dersId);
    final klinik = ders?.grup == DersGrubu.klinik;
    final ilk = depo.ilkCalisma(konu.id);
    final durumYazisi = '${ders?.grup.ad ?? ''} · '
        '${ilk == null ? 'Henüz çalışılmadı' : 'İlk çalışma ${tarihYaz(ilk)}'}';
    final calismalar = depo.calismalarKonu(konu.id);
    final tekrarlar = depo.tekrarlar(bugun);
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
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
          if (calismalar.isEmpty)
            _kart(
              context,
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
                    'Konuyu takvime yerleştirince ve "Çalıştım" deyince '
                    'tekrar günleri burada görünür.',
                    style: tema.textTheme.bodySmall?.copyWith(color: soluk),
                  ),
                ],
              ),
            ),
          for (final c in calismalar) ...[
            _calismaKarti(context, depo, c, tekrarlar, bugun),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: _takvimeEkle,
            icon: const Icon(Icons.event_available_outlined),
            label: Text(
              calismalar.isEmpty ? 'Takvime ekle' : 'Başka bir güne daha ekle',
            ),
          ),
          const SizedBox(height: 20),
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
          TextField(
            controller: _not,
            minLines: 6,
            maxLines: null,
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
        ],
      ),
    );
  }
}
