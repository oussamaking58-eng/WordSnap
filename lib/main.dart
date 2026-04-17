import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/lives_service.dart';
import 'services/score_service.dart';
import 'services/word_service.dart';

void main() async {
  // 1. S'assurer que les bindings Flutter sont prêts
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialiser Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Connexion anonyme immédiate
  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    print(
      "✅ Joueur connecté silencieusement avec l'ID : ${userCredential.user?.uid}",
    );
  } catch (e) {
    print("❌ Erreur lors de la connexion anonyme : $e");
  }

  // 4. Charger TOUS les services vitaux
  // 👈 On a mis le dictionnaire ici avec un "await" pour forcer
  // l'application à attendre qu'il soit prêt avant de s'afficher.
  await Future.wait([
    LivesService().load(),
    ScoreService().load(),
    WordService().loadDictionary(),
  ]);

  print("📚 Tous les services et le dictionnaire sont prêts !");

  // 5. LANCER L'APPLICATION
  runApp(const WordSnapApp());
}

class WordSnapApp extends StatelessWidget {
  const WordSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WordSnap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Tu pourras remettre ton AppTheme.dark() ici
      home: const HomeScreen(),
    );
  }
}
