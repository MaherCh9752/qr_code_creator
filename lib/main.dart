import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const QrCodeCreatorApp());
}

class QrCodeCreatorApp extends StatefulWidget {
  const QrCodeCreatorApp({super.key});

  @override
  State<QrCodeCreatorApp> createState() => _QrCodeCreatorAppState();
}

class _QrCodeCreatorAppState extends State<QrCodeCreatorApp> {
  // System theme by default; user can override via the AppBar toggle.
  ThemeMode _themeMode = ThemeMode.system;

  void _setThemeMode(ThemeMode mode) => setState(() => _themeMode = mode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Creator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _themeMode,
      home: HomeScreen(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}
