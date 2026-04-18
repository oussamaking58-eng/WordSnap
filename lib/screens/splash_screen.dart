import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/lives_service.dart';
import '../services/score_service.dart';
import '../services/word_service.dart';
import '../services/language_service.dart';
import '../services/daily_reward_service.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_cube.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  double _progress = 0.0;
  String _statusText = 'Initialisation...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(_controller);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Auth Anonyme
      setState(() { _statusText = 'Connexion au serveur...'; _progress = 0.2; });
      await FirebaseAuth.instance.signInAnonymously().timeout(const Duration(seconds: 5));

      // 2. Chargement des services légers
      setState(() { _statusText = 'Chargement du profil...'; _progress = 0.5; });
      await Future.wait([
        LivesService().load(),
        ScoreService().load(),
        DailyRewardService().load(),
      ]);

      // 3. Chargement du gros dictionnaire
      setState(() { _statusText = LanguageService().translate('loading'); _progress = 0.8; });
      await WordService().loadAllDictionaries();

      setState(() { _progress = 1.0; });
      
      // Petit délai pour laisser l'animation finir de se remplir
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const HomeScreen(),
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    } catch (e) {
      print("Erreur globale Init: $e");
      // En cas d'erreur, on force quand même le passage à l'accueil pour ne pas bloquer l'utilisateur
      if (mounted) {
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_glowAnimation.value * 5),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LogoCube(letter: 'L', color: AppColors.purple, size: 45),
                          LogoCube(letter: 'I', color: AppColors.purple, size: 45),
                          LogoCube(letter: 'N', color: AppColors.purple, size: 45),
                          LogoCube(letter: 'G', color: AppColors.purple, size: 45),
                          LogoCube(letter: 'O', color: AppColors.purple, size: 45),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LogoCube(letter: 'S', color: AppColors.cyan, size: 45),
                          LogoCube(letter: 'N', color: AppColors.cyan, size: 45),
                          LogoCube(letter: 'A', color: AppColors.cyan, size: 45),
                          LogoCube(letter: 'P', color: AppColors.cyan, size: 45),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: 200,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusText,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
