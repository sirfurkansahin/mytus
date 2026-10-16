import 'package:app/features/bugun/bugun_ekrani.dart';
import 'package:app/features/dersler/dersler_ekrani.dart';
import 'package:app/features/dersler/plan_deposu.dart';
import 'package:app/features/ft_time/ft_ekrani.dart';
import 'package:app/features/ft_time/ft_kontrol.dart';
import 'package:app/features/ft_time/ft_native.dart';
import 'package:app/features/takvim/takvim_ekrani.dart';
import 'package:flutter/material.dart';

/// Alt menülü ana çerçeve: Bugün · Dersler · Takvim · F.T. time.
class AnaIskelet extends StatefulWidget {
  const AnaIskelet({super.key, this.ftNative = const FtNative()});

  final FtNative ftNative;

  @override
  State<AnaIskelet> createState() => _AnaIskeletState();
}

class _AnaIskeletState extends State<AnaIskelet> with WidgetsBindingObserver {
  int _sekme = 0;
  FtKontrol? _kontrol;

  FtKontrol get _ftKontrol =>
      _kontrol ??= FtKontrol(DepoKapsami.oku(context), widget.ftNative);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Uygulama kapalıyken biten bir odak bölümü varsa açılışta işle (puan kaybolmasın).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ftKontrol.tazele();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState durum) {
    if (durum == AppLifecycleState.resumed) _ftKontrol.tazele();
  }

  // Sekmeler ilk açıldığında oluşturulur (örneğin sayaç ekranı gereksiz yere erken açılmasın).
  final Set<int> _acilanlar = {0};

  Widget _sekmeIcerigi(int sira) {
    if (!_acilanlar.contains(sira)) return const SizedBox.shrink();
    switch (sira) {
      case 0:
        return const BugunEkrani();
      case 1:
        return const DerslerEkrani();
      case 2:
        return const TakvimEkrani();
      default:
        return FtEkrani(kontrol: _ftKontrol);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _sekme,
        children: [for (var i = 0; i < 4; i++) _sekmeIcerigi(i)],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _sekme,
        onDestinationSelected: (sira) => setState(() {
          _sekme = sira;
          _acilanlar.add(sira);
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Bugün',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Dersler',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Takvim',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'F.T. time',
          ),
        ],
      ),
    );
  }
}
