import 'package:app/features/bugun/bugun_ekrani.dart';
import 'package:app/features/dersler/dersler_ekrani.dart';
import 'package:app/features/ft_time/ft_test_screen.dart';
import 'package:app/features/takvim/takvim_ekrani.dart';
import 'package:flutter/material.dart';

/// Alt menülü ana çerçeve: Bugün · Dersler · Takvim · F.T. time.
class AnaIskelet extends StatefulWidget {
  const AnaIskelet({super.key});

  @override
  State<AnaIskelet> createState() => _AnaIskeletState();
}

class _AnaIskeletState extends State<AnaIskelet> {
  int _sekme = 0;

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
        return const FtTestScreen();
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
