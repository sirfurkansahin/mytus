import 'dart:convert';

import 'package:app/core/tarih.dart';
import 'package:app/features/ayarlar/ayar_ogeleri.dart';
import 'package:app/features/dersler/dialoglar.dart';
import 'package:app/features/dersler/hazir_dersler.dart';
import 'package:app/features/dersler/modeller.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/ft_time/ft_native.dart';
import 'package:app/features/ft_time/ft_test_screen.dart';
import 'package:app/features/ft_time/pil_rehberi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Ayarlar: plan, F.T. time süreleri, arka plan, görünüm ve veri yönetimi
/// (onaylı tasarım: Ayarlar).
class AyarlarEkrani extends StatelessWidget {
  const AyarlarEkrani({super.key});

  Widget _baslik(BuildContext context, String yazi) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 4),
      child: Text(
        yazi,
        style: tema.textTheme.labelMedium?.copyWith(
          color: tema.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  String _temaEtiketi(TemaSecimi secim) {
    switch (secim) {
      case TemaSecimi.sistem:
        return 'Telefonun ayarı';
      case TemaSecimi.acik:
        return 'Açık';
      case TemaSecimi.koyu:
        return 'Koyu';
    }
  }

  Future<void> _temaSec(BuildContext context, PlanDeposu depo) async {
    final secilen = await showModalBottomSheet<TemaSecimi>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in TemaSecimi.values)
              ListTile(
                title: Text(_temaEtiketi(s)),
                trailing: depo.temaSecimi == s ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(ctx).pop(s),
              ),
          ],
        ),
      ),
    );
    if (secilen != null) depo.temaBelirle(secilen);
  }

  Future<void> _yedekKopyala(BuildContext context, PlanDeposu depo) async {
    final metin = jsonEncode(depo.toJson());
    await Clipboard.setData(ClipboardData(text: metin));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Yedek panoya kopyalandı.')),
      );
  }

  Future<void> _yedektenYukle(BuildContext context, PlanDeposu depo) async {
    final denetci = TextEditingController();
    final metin = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yedekten geri yükle'),
        content: TextField(
          controller: denetci,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Kopyaladığın yedek metnini buraya yapıştır',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(denetci.text.trim()),
            child: const Text('Yükle'),
          ),
        ],
      ),
    );
    denetci.dispose();
    if (metin == null || metin.isEmpty || !context.mounted) return;
    final basarili = depo.yedektenYukle(metin);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            basarili
                ? 'Yedek başarıyla yüklendi.'
                : 'Yedek metni geçersiz, mevcut verilerine dokunulmadı.',
          ),
        ),
      );
  }

  Future<void> _mufredatDegistir(BuildContext context, PlanDeposu depo) async {
    final hedef = depo.mufredatTuru == MufredatTuru.klasik
        ? MufredatTuru.speetus
        : MufredatTuru.klasik;
    final onay = await onayDialogu(
      context,
      baslik: 'Müfredat tarzını değiştir?',
      metin: 'Mevcut tarzın "${depo.mufredatTuru.baslik}". "${hedef.baslik}" tarzına '
          'geçmek ders ve konu listeni yeni sisteme göre baştan kurar. '
          'Mevcut çalışma ve not kayıtların sıfırlanır. Devam edilsin mi?',
      eylem: 'Değiştir',
    );
    if (!onay || !context.mounted) return;
    final yeniDersler = mufredatDersleri(hedef);
    await depo.mufredatSifirlaVeDegistir(
      yeniTur: hedef,
      yeniDersler: yeniDersler,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Müfredat "${hedef.baslik}" olarak değiştirildi.'),
        ),
      );
    }
  }

  Future<void> _sifirla(BuildContext context, PlanDeposu depo) async {
    final onay = await onayDialogu(
      context,
      baslik: 'Tüm veriler silinsin mi?',
      metin: 'Dersler, konular, notlar, takvim planı ve F.T. time puanların '
          'bu telefondan kalıcı olarak silinecek.',
      eylem: 'Sıfırla',
    );
    if (!onay || !context.mounted) return;
    await depo.tumVerileriSifirla();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final sinav = depo.sinavTarihi ?? resmiSinavTarihi;
    final bugun = gunBasi(DateTime.now());
    final kalan = gunFarki(sinav, bugun);
    final kalanMetin = kalan > 0
        ? 'Sınava $kalan gün kaldı'
        : (kalan == 0 ? 'Sınav günü bugün' : 'Sınav tarihi geçti');

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _baslik(context, 'PLAN'),
          AyarSatiri(
            baslik: 'Sınav tarihi',
            altYazi: kalanMetin,
            deger: tarihYaz(sinav),
          ),
          AyarSatiri(
            baslik: 'Tur sayısı',
            altYazi: 'Her konuyu kaç tur çalışacaksın',
            deger: '${depo.turSayisi}',
            onTap: () async {
              final v = await sayiDialogu(
                context,
                baslik: 'Tur sayısı',
                ilkDeger: depo.turSayisi,
                enAz: 1,
                enCok: 5,
                birim: 'tur',
              );
              if (v != null) depo.turSayisiBelirle(v);
            },
          ),
          AyarSatiri(
            baslik: 'Günlük tekrar sınırı',
            altYazi: 'Bir güne bundan fazla tekrar düşmez, fazlası ertesi güne kayar',
            deger: '${depo.gunlukTekrarSiniri} tekrar',
            onTap: () async {
              final v = await sayiDialogu(
                context,
                baslik: 'Günlük tekrar sınırı',
                ilkDeger: depo.gunlukTekrarSiniri,
                enAz: 3,
                enCok: 30,
                birim: 'tekrar',
              );
              if (v != null) depo.gunlukSinirBelirle(v);
            },
          ),
          AyarSatiri(
            baslik: 'Müfredat tarzı',
            altYazi: depo.mufredatTuru.kisaAciklama,
            deger: depo.mufredatTuru.baslik,
            onTap: () => _mufredatDegistir(context, depo),
          ),
          _baslik(context, 'F.T. TIME'),
          const FtSureAyarlari(),
          _baslik(context, 'ARKA PLAN'),
          const ArkaPlanKarti(),
          _baslik(context, 'GÖRÜNÜM'),
          AyarSatiri(
            baslik: 'Tema',
            deger: _temaEtiketi(depo.temaSecimi),
            onTap: () => _temaSec(context, depo),
          ),
          _baslik(context, 'VERİ VE YEDEK'),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: const Text('Yedeği panoya kopyala'),
            subtitle: const Text('Planını ve notlarını metin olarak saklamak için'),
            trailing: const Icon(Icons.copy_outlined),
            onTap: () => _yedekKopyala(context, depo),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: const Text('Yedekten geri yükle'),
            subtitle: const Text('Daha önce kopyaladığın yedeği geri yükler'),
            trailing: const Icon(Icons.restore_outlined),
            onTap: () => _yedektenYukle(context, depo),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(
              'Tüm verileri sıfırla',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text('Planı, notları ve puanları silip baştan başlar'),
            trailing: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            onTap: () => _sifirla(context, depo),
          ),
          _baslik(context, 'GELİŞMİŞ'),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: const Text('Sayaç testi'),
            subtitle: const Text('Alarmın arka planda çalıştığını ölçmek için'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (depo.oturum != null) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Çalışan bir F.T. time oturumu var. Önce onu bitir.'),
                    ),
                  );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const FtTestScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          const _SurumYazisi(),
        ],
      ),
    );
  }
}

/// "MY TUS · Sürüm 0.4 · derleme N" ve gizlilik notu. Derleme numarası hangi
/// sürümün kurulu olduğunu anlamaya yarar.
class _SurumYazisi extends StatefulWidget {
  const _SurumYazisi();

  @override
  State<_SurumYazisi> createState() => _SurumYazisiState();
}

class _SurumYazisiState extends State<_SurumYazisi> {
  String? _derleme;

  @override
  void initState() {
    super.initState();
    _oku();
  }

  Future<void> _oku() async {
    final no = await const FtNative().derlemeNo();
    if (!mounted) return;
    setState(() => _derleme = no);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final derleme = _derleme == null ? '' : ' · derleme $_derleme';
    return Center(
      child: Text(
        'MY TUS · Sürüm 0.4$derleme\nVerilerin yalnızca bu telefonda tutulur.',
        textAlign: TextAlign.center,
        style: tema.textTheme.bodySmall?.copyWith(
          color: tema.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
