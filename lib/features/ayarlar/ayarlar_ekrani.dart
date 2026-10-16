import 'package:app/core/tarih.dart';
import 'package:app/features/ayarlar/ayar_ogeleri.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/ft_time/ft_native.dart';
import 'package:app/features/ft_time/ft_test_screen.dart';
import 'package:app/features/ft_time/pil_rehberi.dart';
import 'package:flutter/material.dart';

/// Sınav tarihini seçtirir ve kaydeder. Bugün ve Ayarlar ekranları kullanır.
Future<void> sinavTarihiSec(BuildContext context, PlanDeposu depo) async {
  final ilk = gunBasi(DateTime.now());
  final mevcut = depo.sinavTarihi;
  final secilen = await showDatePicker(
    context: context,
    initialDate: mevcut != null && !mevcut.isBefore(ilk)
        ? mevcut
        : ilk.add(const Duration(days: 90)),
    firstDate: ilk,
    lastDate: DateTime(ilk.year + 3, ilk.month, ilk.day),
    helpText: 'Sınav tarihi',
  );
  if (secilen != null) depo.sinavTarihiBelirle(secilen);
}

/// Ayarlar: plan, F.T. time süreleri, arka plan ve görünüm (onaylı tasarım: Ayarlar).
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

  @override
  Widget build(BuildContext context) {
    final depo = DepoKapsami.of(context);
    final sinav = depo.sinavTarihi;
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _baslik(context, 'PLAN'),
          AyarSatiri(
            baslik: 'Sınav tarihi',
            deger: sinav == null ? 'Seç' : tarihYaz(sinav),
            onTap: () => sinavTarihiSec(context, depo),
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
          _baslik(context, 'F.T. TIME'),
          const FtSureAyarlari(),
          _baslik(context, 'ARKA PLAN'),
          const ArkaPlanKarti(),
          _baslik(context, 'GÖRÜNÜM'),
          const AyarSatiri(baslik: 'Tema', deger: 'Telefonun ayarı'),
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
