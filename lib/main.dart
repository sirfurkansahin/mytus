import 'package:app/app/ana_iskelet.dart';
import 'package:app/core/renkler.dart';
import 'package:app/core/veri_kaydi.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/karsilama/karsilama_ekrani.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MyTusApp());
}

class MyTusApp extends StatefulWidget {
  /// [deposu] yalnızca testler içindir; verilmezse telefondaki dosya kullanılır.
  const MyTusApp({super.key, this.deposu});

  final PlanDeposu? deposu;

  @override
  State<MyTusApp> createState() => _MyTusAppState();
}

class _MyTusAppState extends State<MyTusApp> {
  late final PlanDeposu _deposu;

  @override
  void initState() {
    super.initState();
    _deposu = widget.deposu ?? PlanDeposu(kayit: const DosyaKaydi());
    if (_deposu.durum == YuklemeDurumu.yukleniyor) {
      _deposu.yukle();
    }
  }

  @override
  void dispose() {
    if (widget.deposu == null) {
      _deposu.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MY TUS',
      debugShowCheckedModeBanner: false,
      // Ana renk mor (onaylı tasarım). Tema telefonun ayarını izler.
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: morAna).copyWith(
          primary: morAna,
          onPrimary: Colors.white,
        ),
        scaffoldBackgroundColor: acikZemin,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: morAna,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => DepoKapsami(
        deposu: _deposu,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const _AcilisKapisi(),
    );
  }
}

/// Verinin durumuna göre doğru ekranı açar: yükleniyor, hata, karşılama veya ana ekran.
class _AcilisKapisi extends StatelessWidget {
  const _AcilisKapisi();

  @override
  Widget build(BuildContext context) {
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
            ? const AnaIskelet()
            : const KarsilamaEkrani();
    }
  }
}
