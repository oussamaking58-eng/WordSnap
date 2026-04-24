import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  // 1. S'assurer que les bindings Flutter sont prêts
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation des données locales pour intl (évite l'écran gris sur iOS en mode FR)
  await initializeDateFormatting();

  // 3. LANCER L'APPLICATION IMMÉDIATEMENT SUR LE SPLASH SCREEN
  // Le chargement de Firebase se fera dans le SplashScreen pour qu'il soit visible tout de suite.
  runApp(const LingoSnapApp());
}

class LingoSnapApp extends StatelessWidget {
  const LingoSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LingoSnap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A051A), // Fond très sombre
        colorScheme: const ColorScheme.dark(
           primary: Color(0xFFA855F7), // Purple
           secondary: Color(0xFFF472B6), // Pink
           tertiary: Color(0xFF22D3EE), // Cyan
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
