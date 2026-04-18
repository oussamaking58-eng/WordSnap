import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  // 1. S'assurer que les bindings Flutter sont prêts
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialiser Firebase très rapidement pour que l'app se lance
  try {
     await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
     print("Erreur Firebase: $e");
  }

  // 3. LANCER L'APPLICATION IMMÉDIATEMENT SUR LE SPLASH SCREEN
  // Le reste du chargement (Services, Dictionnaires, Auth) se fera dans le SplashScreen.
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
