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
        LanguageService().load(),
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
      backgroundColor: const Color(0xFF05010D),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.purple.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LogoCube(letter: 'L', color: AppColors.purple, size: 55),
                            LogoCube(letter: 'I', color: AppColors.purple, size: 55),
                            LogoCube(letter: 'N', color: AppColors.purple, size: 55),
                            LogoCube(letter: 'G', color: AppColors.purple, size: 55),
                            LogoCube(letter: 'O', color: AppColors.purple, size: 55),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LogoCube(letter: 'S', color: AppColors.cyan, size: 55),
                            LogoCube(letter: 'N', color: AppColors.cyan, size: 55),
                            LogoCube(letter: 'A', color: AppColors.cyan, size: 55),
                            LogoCube(letter: 'P', color: AppColors.cyan, size: 55),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 100),
                
                // Progress Section
                SizedBox(
                  width: 240,
                  child: Column(
                    children: [
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 14,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 236 * _progress,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.purple,
                                      AppColors.purple,
                                      AppColors.cyan,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.purple.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _statusText.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
