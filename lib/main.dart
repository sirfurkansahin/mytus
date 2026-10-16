import 'package:flutter/material.dart';

void main() => runApp(const MyTusApp());

/// Uygulamanin kok widget'i.
class MyTusApp extends StatelessWidget {
  const MyTusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MY TUS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1E6F5C),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

/// Faz 2 icin gecici ana ekran: kurulumun calistigini gosterir.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MY TUS')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64),
            SizedBox(height: 16),
            Text('Kurulum başarılı'),
            SizedBox(height: 8),
            Text('Faz 2: boş uygulama'),
          ],
        ),
      ),
    );
  }
}
