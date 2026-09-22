import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const QrCodeCreatorApp());
}

class QrCodeCreatorApp extends StatelessWidget {
  const QrCodeCreatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Creator',
      debugShowCheckedModeBanner: false,
      // Cohesive M3 theme; light + dark via ColorScheme (no hardcoded
      // surface colors in panels — see DesignPanel / preview).
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
