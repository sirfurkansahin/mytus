import 'package:app/core/renkler.dart';
import 'package:app/features/auth/kimlik_servisi.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/grup/grup_servisi.dart';
import 'package:app/features/grup/modeller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Çalışma Grubu ve Haftalık Puan Tablosu Ekranı (Sürüm 2).
/// Seçenek C (Konu ve Soru Modeli) ile puanlama: 1 Konu = 10 Puan, 1 Soru = 1 Puan.
class GrupEkrani extends StatefulWidget {
  const GrupEkrani({super.key, this.servis});

  final GrupServisi? servis;

  @override
  State<GrupEkrani> createState() => _GrupEkraniState();
}

class _GrupEkraniState extends State<GrupEkrani> {
  late final GrupServisi _servis;
  int _seciliSekme = 0; // 0: Sıralama, 1: Ortak Hedef
  bool _yukleniyor = false;

  final _kodDenetci = TextEditingController();
  final _grupAdiDenetci = TextEditingController();
  final _hedefKonuDenetci = TextEditingController(text: '40');
  final _hedefSoruDenetci = TextEditingController(text: '1000');

  @override
  void initState() {
    super.initState();
    _servis = widget.servis ?? FirestoreGrupServisi();
    WidgetsBinding.instance.addPostFrameCallback((_) => _puaniBulutaEsitele());
  }

  @override
  void dispose() {
    _kodDenetci.dispose();
    _grupAdiDenetci.dispose();
    _hedefKonuDenetci.dispose();
    _hedefSoruDenetci.dispose();
    super.dispose();
  }

  Future<void> _puaniBulutaEsitele() async {
    final depo = DepoKapsami.oku(context);
    final kimlik = KimlikKapsami.belki(context);
    final grupId = depo.aktifGrupId;
    final uid = kimlik?.aktifKullanici?.uid;
    if (grupId == null || uid == null) return;

    final bugun = DateTime.now();
    final konuSayisi = depo.haftalikTamamlananKonuSayisi(bugun);
    final soruSayisi = depo.haftalikCozulenSoruSayisi(bugun);
    final sonCalisma = depo.tumCalismalar().where((c) => c.tamam).lastOrNull;
    final sonKonu = sonCalisma != null ? depo.konuBul(sonCalisma.konuId) : null;
    final sonDers = sonKonu != null ? depo.dersBul(sonKonu.dersId)?.ad : null;
    final takmaAd = kimlik?.aktifKullanici?.takmaAd ?? 'Meslektaşımız';

    try {
      await _servis.puanGuncelle(
        grupId: grupId,
        uid: uid,
        takmaAd: takmaAd,
        konuSayisi: konuSayisi,
        soruSayisi: soruSayisi,
        sonDers: sonDers,
      );
    } catch (_) {
      // Çevrimdışıysa veya hata varsa sessizce geç
    }
  }

  Future<void> _grubaKatil(PlanDeposu depo, String uid, String takmaAd) async {
    final kod = _kodDenetci.text.trim().toUpperCase();
    if (kod.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen 6 haneli geçerli bir davet kodu girin.')),
      );
      return;
    }

    setState(() => _yukleniyor = true);
    try {
      final grup = await _servis.kodIleGrupBul(kod);
      if (grup == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu davet koduna ait bir grup bulunamadı.')),
        );
        return;
      }

      final bugun = DateTime.now();
      await _servis.grubaKatil(
        grupId: grup.id,
        uid: uid,
        takmaAd: takmaAd,
        konuSayisi: depo.haftalikTamamlananKonuSayisi(bugun),
        soruSayisi: depo.haftalikCozulenSoruSayisi(bugun),
      );

      depo.aktifGrupAyarla(grup.id);
      _kodDenetci.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${grup.ad}" grubuna başarıyla katıldınız! 🎉')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gruba katılırken hata oluştu: $e')),
      );
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _grupOlustur(PlanDeposu depo, String uid, String takmaAd) async {
    final ad = _grupAdiDenetci.text.trim();
    if (ad.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir grup adı belirleyin.')),
      );
      return;
    }

    final hedefKonu = int.tryParse(_hedefKonuDenetci.text.trim()) ?? 40;
    final hedefSoru = int.tryParse(_hedefSoruDenetci.text.trim()) ?? 1000;

    setState(() => _yukleniyor = true);
    try {
      final grup = await _servis.grupOlustur(
        grupAdi: ad,
        olusturanUid: uid,
        takmaAd: takmaAd,
        hedefKonu: hedefKonu,
        hedefSoru: hedefSoru,
      );

      depo.aktifGrupAyarla(grup.id);
      _grupAdiDenetci.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${grup.ad}" grubu kuruldu! Davet Kodu: ${grup.davetKodu}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Grup oluşturulurken hata oluştu: $e')),
      );
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _gruptanAyril(PlanDeposu depo, String uid, String grupId) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gruptan Ayrıl'),
        content: const Text(
          'Bu çalışma grubundan ayrılmak istediğinize emin misiniz? Puanlarınız gruptan silinecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ayrıl'),
          ),
        ],
      ),
    );

    if (onay != true || !mounted) return;

    setState(() => _yukleniyor = true);
    try {
      await _servis.gruptanAyril(grupId: grupId, uid: uid);
      depo.aktifGrupAyarla(null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gruptan ayrıldınız.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gruptan ayrılırken hata: $e')),
      );
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  void _davetKodunuKopyala(String kod) {
    Clipboard.setData(ClipboardData(text: kod));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Davet kodu ($kod) panoya kopyalandı!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final kimlik = KimlikKapsami.belki(context);
    final uid = kimlik?.aktifKullanici?.uid ?? 'yerel_kullanici';
    final takmaAd = kimlik?.aktifKullanici?.takmaAd ?? 'Meslektaşımız';
    final grupId = depo.aktifGrupId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Çalışma Grubu & Puan'),
        actions: [
          if (grupId != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Puanları Tazele',
              onPressed: _puaniBulutaEsitele,
            ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : grupId == null
              ? _GrupYokEkrani(
                  kodDenetci: _kodDenetci,
                  grupAdiDenetci: _grupAdiDenetci,
                  hedefKonuDenetci: _hedefKonuDenetci,
                  hedefSoruDenetci: _hedefSoruDenetci,
                  onKatil: () => _grubaKatil(depo, uid, takmaAd),
                  onOlustur: () => _grupOlustur(depo, uid, takmaAd),
                )
              : StreamBuilder<Grup?>(
                  stream: _servis.grupDinle(grupId),
                  builder: (context, grupSnap) {
                    final grup = grupSnap.data;
                    if (grup == null) {
                      return FutureBuilder<Grup?>(
                        future: _servis.grupGetir(grupId),
                        builder: (context, fSnap) {
                          if (fSnap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final g = fSnap.data;
                          if (g == null) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Grup bulunamadı veya silinmiş.'),
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    onPressed: () => depo.aktifGrupAyarla(null),
                                    child: const Text('Grup Seçimine Dön'),
                                  ),
                                ],
                              ),
                            );
                          }
                          return _GrupIcerigi(
                            grup: g,
                            servis: _servis,
                            uid: uid,
                            seciliSekme: _seciliSekme,
                            onSekmeDegisti: (s) => setState(() => _seciliSekme = s),
                            onKopyala: () => _davetKodunuKopyala(g.davetKodu),
                            onAyril: () => _gruptanAyril(depo, uid, g.id),
                          );
                        },
                      );
                    }
                    return _GrupIcerigi(
                      grup: grup,
                      servis: _servis,
                      uid: uid,
                      seciliSekme: _seciliSekme,
                      onSekmeDegisti: (s) => setState(() => _seciliSekme = s),
                      onKopyala: () => _davetKodunuKopyala(grup.davetKodu),
                      onAyril: () => _gruptanAyril(depo, uid, grup.id),
                    );
                  },
                ),
    );
  }
}

/// Henüz bir gruba üye olmayan hekim için Karşılama ve Katıl/Oluştur Ekranı.
class _GrupYokEkrani extends StatelessWidget {
  const _GrupYokEkrani({
    required this.kodDenetci,
    required this.grupAdiDenetci,
    required this.hedefKonuDenetci,
    required this.hedefSoruDenetci,
    required this.onKatil,
    required this.onOlustur,
  });

  final TextEditingController kodDenetci;
  final TextEditingController grupAdiDenetci;
  final TextEditingController hedefKonuDenetci;
  final TextEditingController hedefSoruDenetci;
  final VoidCallback onKatil;
  final VoidCallback onOlustur;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // Bilgilendirme Kartı
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: morAna.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: morAna.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.groups_rounded, color: morAna, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'TUS Çalışma Grubu',
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: morAna,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Arkadaşlarınızla 2-10 kişilik küçük bir grup kurarak birbirinizi motive edin. '
                'Süre tutma zorunluluğu yoktur; bitirdiğiniz her konu 10 puan, çözdüğünüz her soru 1 puandır. '
                'Özel notlarınız asla paylaşılmaz.',
                style: tema.textTheme.bodySmall?.copyWith(height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 1. Davet Koduyla Katıl Kartı
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tema.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.vpn_key_outlined, color: tema.colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Davet Koduyla Katıl',
                      style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: kodDenetci,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: '6 Haneli Davet Kodu',
                    hintText: 'Örn: TUS84X',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onKatil,
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Gruba Katıl'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 2. Yeni Grup Kur Kartı
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tema.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: tema.colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Yeni Çalışma Grubu Kur',
                      style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: grupAdiDenetci,
                  decoration: const InputDecoration(
                    labelText: 'Grup Adı',
                    hintText: 'Örn: Dahiliye Tayfa, TUS 2027',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hedefKonuDenetci,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Haftalık Konu Hedefi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: hedefSoruDenetci,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Haftalık Soru Hedefi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: onOlustur,
                  icon: const Icon(Icons.group_add_rounded),
                  label: const Text('Grubu Oluştur ve Kod Al'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Grupta olan kullanıcı için Puan Tablosu ve Ortak Hedef Ekranı.
class _GrupIcerigi extends StatelessWidget {
  const _GrupIcerigi({
    required this.grup,
    required this.servis,
    required this.uid,
    required this.seciliSekme,
    required this.onSekmeDegisti,
    required this.onKopyala,
    required this.onAyril,
  });

  final Grup grup;
  final GrupServisi servis;
  final String uid;
  final int seciliSekme;
  final ValueChanged<int> onSekmeDegisti;
  final VoidCallback onKopyala;
  final VoidCallback onAyril;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // Grup Başlık ve Davet Kodu Kartı
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                morAna.withValues(alpha: 0.12),
                morAna.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: morAna.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          grup.ad,
                          style: tema.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Puan Kuralı: 1 Konu = 10 Puan • 1 Soru = 1 Puan',
                          style: TextStyle(
                            fontSize: 11,
                            color: tema.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'ayril') onAyril();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'ayril',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Gruptan Ayrıl', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: onKopyala,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tema.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.share_outlined, size: 18, color: morAna),
                      const SizedBox(width: 10),
                      Text(
                        'Davet Kodu: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        grup.davetKodu,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: morAna,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.copy_rounded, size: 18, color: morAna),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // İki Sekmeli Görünüm Seçici
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 0,
              icon: Icon(Icons.leaderboard_rounded),
              label: Text('Haftalık Sıralama'),
            ),
            ButtonSegment(
              value: 1,
              icon: Icon(Icons.track_changes_rounded),
              label: Text('Ortak Hedef'),
            ),
          ],
          selected: {seciliSekme},
          onSelectionChanged: (val) => onSekmeDegisti(val.first),
        ),

        const SizedBox(height: 16),

        // Üyeleri Canlı Dinle
        StreamBuilder<List<GrupUyesi>>(
          stream: servis.uyeleriDinle(grup.id),
          builder: (context, snap) {
            final uyeler = snap.data ?? [];
            if (snap.connectionState == ConnectionState.waiting && uyeler.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
            }

            if (uyeler.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Grupta henüz üye bulunmuyor.'),
                ),
              );
            }

            if (seciliSekme == 1) {
              final durum = GrupHedefDurumu.hesapla(uyeler: uyeler, grup: grup);
              return _OrtakHedefPaneli(durum: durum, uyeler: uyeler);
            }

            return _SiralamaListesi(uyeler: uyeler, aktifUid: uid);
          },
        ),
      ],
    );
  }
}

/// 1. Sekme: Haftalık Sıralama Listesi.
class _SiralamaListesi extends StatelessWidget {
  const _SiralamaListesi({
    required this.uyeler,
    required this.aktifUid,
  });

  final List<GrupUyesi> uyeler;
  final String aktifUid;

  Widget _madalya(int sira) {
    if (sira == 1) return const Text('🥇', style: TextStyle(fontSize: 20));
    if (sira == 2) return const Text('🥈', style: TextStyle(fontSize: 20));
    if (sira == 3) return const Text('🥉', style: TextStyle(fontSize: 20));
    return CircleAvatar(
      radius: 12,
      backgroundColor: Colors.grey.withValues(alpha: 0.18),
      child: Text(
        '$sira',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Column(
      children: [
        for (var i = 0; i < uyeler.length; i++) ...[
          Builder(
            builder: (_) {
              final u = uyeler[i];
              final benMiyim = u.uid == aktifUid;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: benMiyim
                        ? morAna.withValues(alpha: 0.5)
                        : tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: benMiyim ? 1.5 : 1,
                  ),
                ),
                color: benMiyim ? morAna.withValues(alpha: 0.05) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      _madalya(i + 1),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  u.takmaAd,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: benMiyim ? FontWeight.w800 : FontWeight.w700,
                                  ),
                                ),
                                if (benMiyim) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: morAna,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Sen',
                                      style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${u.konuSayisi} konu • ${u.soruSayisi} soru'
                              '${u.sonDers != null ? ' • ${u.sonDers}' : ''}',
                              style: TextStyle(
                                fontSize: 11,
                                color: tema.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${u.puan}',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: benMiyim ? morAna : tema.colorScheme.primary,
                            ),
                          ),
                          Text(
                            'puan',
                            style: TextStyle(fontSize: 10, color: tema.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

/// 2. Sekme: Ortak Hedef Paneli.
class _OrtakHedefPaneli extends StatelessWidget {
  const _OrtakHedefPaneli({
    required this.durum,
    required this.uyeler,
  });

  final GrupHedefDurumu durum;
  final List<GrupUyesi> uyeler;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.teal.withValues(alpha: 0.3)),
      ),
      color: Colors.teal.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_rounded, color: Colors.teal, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Bu Haftaki Ortak Hedefimiz',
                  style: tema.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.teal,
                  ),
                ),
                const Spacer(),
                Text(
                  '%${durum.genelYuzde}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Konu İlerlemesi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Haftalık Konu Hedefi:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text('${durum.toplamKonu} / ${durum.hedefKonu} konu', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: durum.konuOrani,
                minHeight: 8,
                color: Colors.teal,
                backgroundColor: Colors.teal.withValues(alpha: 0.15),
              ),
            ),

            const SizedBox(height: 14),

            // Soru İlerlemesi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Haftalık Soru Hedefi:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text('${durum.toplamSoru} / ${durum.hedefSoru} soru', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: durum.soruOrani,
                minHeight: 8,
                color: morAna,
                backgroundColor: morAna.withValues(alpha: 0.15),
              ),
            ),

            const SizedBox(height: 14),
            Text(
              'Gruptaki ${uyeler.length} arkadaş ortak hedefe birlikte ilerliyor. '
              'Tüm tamamlanan konular ve çözülen sorular ortak havuza katkı sağlar.',
              style: TextStyle(fontSize: 11, color: tema.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
