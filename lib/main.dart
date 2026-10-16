import 'package:app/features/ft_time/ft_test_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyTusApp());
}

class MyTusApp extends StatelessWidget {
  const MyTusApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ana renk mor (onaylı tasarım): #5B3EC8. Tema telefonun ayarını izler.
    const mor = Color(0xFF5B3EC8);
    return MaterialApp(
      title: 'MY TUS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: mor),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: mor,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const FtTestScreen(),
    );
  }
}
