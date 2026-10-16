import 'package:app/features/dersler/dialoglar.dart';
import 'package:app/features/dersler/konu_ekrani.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:flutter/material.dart';

/// Bir dersin konu listesi ve hızlı konu ekleme kutusu.
/// (Onaylı tasarımda ayrı bir ders detayı ekranı yoktu; aynı görsel dille eklendi.)
class DersDetayEkrani extends StatefulWidget {
  const DersDetayEkrani({super.key, required this.dersId});

  final int dersId;

  @override
  State<DersDetayEkrani> createState() => _DersDetayEkraniState();
}

class _DersDetayEkraniState extends State<DersDetayEkrani> {
  final TextEditingController _yeniKonu = TextEditingController();
  final FocusNode _odak = FocusNode();

  @override
  void dispose() {
    _yeniKonu.dispose();
    _odak.dispose();
    super.dispose();
  }

  void _konuEkle(PlanDeposu depo) {
    final metin = _yeniKonu.text;
    if (metin.trim().isEmpty) return;
    final konu = depo.konuEkle(widget.dersId, metin);
    if (konu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu konu bu derste zaten var.')),
      );
      return;
    }
    _yeniKonu.clear();
    // Klavye açık kalsın: konuları arka arkaya girebilmek için.
    _odak.requestFocus();
  }

  Future<void> _menu(String secim, PlanDeposu depo, String ad) async {
    if (secim == 'ad') {
      final yeni = await MetinDialogu.goster(
        context,
        baslik: 'Dersin adı',
        ilkDeger: ad,
      );
      if (!mounted || yeni == null) return;
      if (!depo.dersAdiDegistir(widget.dersId, yeni)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad boş olamaz ve aynı grupta tekrar edemez.'),
          ),
        );
      }
    } else if (secim == 'sil') {
      final sayi = depo.konuSayisi(widget.dersId);
      final onay = await onayDialogu(
        context,
        baslik: 'Dersi sil?',
        metin: sayi == 0
            ? '"$ad" silinecek.'
            : '"$ad" ve içindeki $sayi konu, notlarıyla birlikte silinecek. '
                'Bu geri alınamaz.',
        eylem: 'Sil',
      );
      if (!mounted || !onay) return;
      Navigator.of(context).pop();
      depo.dersSil(widget.dersId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final tema = Theme.of(context);
    final ders = depo.dersBul(widget.dersId);
    if (ders == null) {
      // Ders silindi (sayfa kapanırken kısa süre görünür).
      return Scaffold(appBar: AppBar());
    }
    final konular = depo.konular(ders.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(ders.ad),
        actions: [
          PopupMenuButton<String>(
            onSelected: (s) => _menu(s, depo, ders.ad),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'ad', child: Text('Adını değiştir')),
              PopupMenuItem(value: 'sil', child: Text('Dersi sil')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _yeniKonu,
                    focusNode: _odak,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _konuEkle(depo),
                    decoration: InputDecoration(
                      hintText: 'Yeni konu adı',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Konu ekle',
                  onPressed: () => _konuEkle(depo),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: konular.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Henüz konu yok. Yukarıdaki kutuya konu adını yazıp ekle.',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: konular.length,
                    separatorBuilder: (context, sira) => const SizedBox(height: 8),
                    itemBuilder: (_, sira) {
                      final konu = konular[sira];
                      return Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: tema.colorScheme.outlineVariant,
                          ),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            konu.ad,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: konu.not.isEmpty ? null : const Text('Notu var'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => KonuEkrani(konuId: konu.id),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
