import 'package:app/app/ana_iskelet.dart';
import 'package:app/core/firebase_ayarlari.dart';
import 'package:app/core/renkler.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/auth/giris_ekrani.dart';
import 'package:app/features/auth/kimlik_servisi.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/ft_time/ft_native.dart';
import 'package:app/features/karsilama/karsilama_ekrani.dart';
import 'package:app/features/senkronizasyon/bulut_kaynagi.dart';
import 'package:app/features/senkronizasyon/bulut_senkron_servisi.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KimlikServisi? kimlikServisi;
  BulutSenkronServisi? senkronServisi;
  if (FirebaseAyarlari.yapilandirildiMi) {
    try {
      await Firebase.initializeApp(options: FirebaseAyarlari.webSecenekleri);
      kimlikServisi = FirebaseKimlikServisi();
      senkronServisi = BulutSenkronServisi(
        yerelKayit: const DosyaKaydi(),
        bulutKaynagi: FirestoreBulutKaynagi(),
      );
    } catch (_) {
      kimlikServisi = null;
      senkronServisi = null;
    }
  }
  runApp(
    MyTusApp(
      kimlikServisi: kimlikServisi,
      senkronServisi: senkronServisi,
    ),
  );
}

class MyTusApp extends StatefulWidget {
  /// [deposu], [ftNative], [kimlikServisi] ve [senkronServisi] testlerde dışarıdan verilebilir.
  const MyTusApp({
    super.key,
    this.deposu,
    this.ftNative = const FtNative(),
    this.kimlikServisi,
    this.senkronServisi,
  });

  final PlanDeposu? deposu;
  final FtNative ftNative;
  final KimlikServisi? kimlikServisi;
  final BulutSenkronServisi? senkronServisi;

  @override
  State<MyTusApp> createState() => _MyTusAppState();
}

class _MyTusAppState extends State<MyTusApp> {
  late final PlanDeposu _deposu;
  String? _sonOturumUid;

  @override
  void initState() {
    super.initState();
    final senkron = widget.senkronServisi;
    _deposu = widget.deposu ??
        PlanDeposu(kayit: senkron ?? const DosyaKaydi());
    senkron?.depoBagla(_deposu);
    if (_deposu.durum == YuklemeDurumu.yukleniyor) {
      _deposu.yukle();
    }
    widget.kimlikServisi?.addListener(_oturumDegisti);
    _oturumDegisti();
  }

  void _oturumDegisti() {
    final kimlik = widget.kimlikServisi;
    final senkron = widget.senkronServisi;
    if (kimlik == null || senkron == null || !kimlik.hazirMi) return;
    final aktif = kimlik.aktifKullanici;
    if (aktif != null && aktif.uid != _sonOturumUid) {
      _sonOturumUid = aktif.uid;
      senkron.oturumAcildi(aktif);
    } else if (aktif == null && _sonOturumUid != null) {
      _sonOturumUid = null;
    }
  }

  @override
  void dispose() {
    widget.kimlikServisi?.removeListener(_oturumDegisti);
    if (widget.deposu == null) {
      _deposu.dispose();
    }
    super.dispose();
  }

  ThemeMode _temaModu(TemaSecimi secim) {
    switch (secim) {
      case TemaSecimi.sistem:
        return ThemeMode.system;
      case TemaSecimi.acik:
        return ThemeMode.light;
      case TemaSecimi.koyu:
        return ThemeMode.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _deposu,
      builder: (context, _) {
        return MaterialApp(
          title: 'MY TUS',
          debugShowCheckedModeBanner: false,
          // Ana renk mor (onaylı tasarım). Tema kullanıcı tercihini veya telefonun ayarını izler.
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: morAna,
              surface: acikZemin,
            ).copyWith(
              primary: morAna,
              onPrimary: Colors.white,
            ),
            scaffoldBackgroundColor: acikZemin,
            cardTheme: CardTheme(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
              ),
              color: Colors.white,
            ),
            navigationBarTheme: NavigationBarThemeData(
              height: 64,
              elevation: 0,
              indicatorColor: morAna.withValues(alpha: 0.12),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            ),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: morAna,
              brightness: Brightness.dark,
              surface: koyuZemin,
            ).copyWith(
              primary: const Color(0xFF9D8DF1),
              onPrimary: Colors.white,
            ),
            scaffoldBackgroundColor: koyuZemin,
            cardTheme: CardTheme(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              color: koyuKartYuzeyi,
            ),
            navigationBarTheme: NavigationBarThemeData(
              height: 64,
              elevation: 0,
              backgroundColor: koyuZemin,
              indicatorColor: morAna.withValues(alpha: 0.3),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            ),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
          themeMode: _temaModu(_deposu.temaSecimi),
          locale: const Locale('tr', 'TR'),
          supportedLocales: const [Locale('tr', 'TR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) {
            Widget icerik = DepoKapsami(
              deposu: _deposu,
              child: child ?? const SizedBox.shrink(),
            );
            final senkron = widget.senkronServisi;
            if (senkron != null) {
              icerik = SenkronKapsami(servis: senkron, child: icerik);
            }
            final kimlik = widget.kimlikServisi;
            if (kimlik != null) {
              icerik = KimlikKapsami(servis: kimlik, child: icerik);
            }
            return icerik;
          },
          home: _AcilisKapisi(ftNative: widget.ftNative),
        );
      },
    );
  }
}

/// Verinin ve oturumun durumuna göre doğru ekranı açar:
/// yükleniyor, giriş ekranı (oturum yoksa), hata, karşılama veya ana ekran.
class _AcilisKapisi extends StatelessWidget {
  const _AcilisKapisi({required this.ftNative});

  final FtNative ftNative;

  @override
  Widget build(BuildContext context) {
    final kimlik = KimlikKapsami.belki(context);
    if (kimlik != null) {
      if (!kimlik.hazirMi) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (kimlik.aktifKullanici == null) {
        return const GirisEkrani();
      }
    }

    final depo = DepoKapsami.of(context);
    switch (depo.durum) {
      case YuklemeDurumu.yukleniyor:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case YuklemeDurumu.hata:
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    depo.hataMesaji ?? 'Veriler okunamadı.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verilerine dokunmadım. Tekrar deneyebilirsin.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: depo.yukle,
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          ),
        );
      case YuklemeDurumu.hazir:
        return depo.karsilamaTamam
            ? AnaIskelet(ftNative: ftNative)
            : const KarsilamaEkrani();
    }
  }
}
