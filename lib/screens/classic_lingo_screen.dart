import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import 'lingo_screen.dart';
import '../services/language_service.dart';
import '../services/sound_service.dart';

class ClassicLingoScreen extends StatelessWidget {
  const ClassicLingoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langService = LanguageService();
    return ListenableBuilder(
      listenable: langService,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Stack(
            children: [
              // Fond Nébuleuse
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0F021A), Color(0xFF1A0535)],
                    ),
                  ),
                ),
              ),
              
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, langService),
                    const Spacer(),
                    Text(
                      langService.translate('choose_challenge').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      langService.translate('find_word_subtitle'),
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const Spacer(),
                    
                    _buildModeOption(
                      context,
                      title: langService.translate('easy_word'),
                      subtitle: langService.translate('letters_attempts').replaceAll('{n}', '4').replaceAll('{a}', '6'),
                      icon: '🎈',
                      color: AppColors.green,
                      wordLength: 4,
                      maxAttempts: 6,
                    ),
                    const SizedBox(height: 20),
                    _buildModeOption(
                      context,
                      title: langService.translate('normal_word'),
                      subtitle: langService.translate('letters_attempts').replaceAll('{n}', '5').replaceAll('{a}', '6'),
                      icon: '🅰️',
                      color: AppColors.cyan,
                      wordLength: 5,
                      maxAttempts: 6,
                    ),
                    const SizedBox(height: 20),
                    _buildModeOption(
                      context,
                      title: langService.translate('hard_word'),
                      subtitle: langService.translate('letters_attempts').replaceAll('{n}', '6').replaceAll('{a}', '6'),
                      icon: '🧠',
                      color: AppColors.purple,
                      wordLength: 6,
                      maxAttempts: 6,
                    ),
                    
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, LanguageService langService) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Text(
            langService.translate('classic_mode').toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
    required int wordLength,
    required int maxAttempts,
  }) {
    return GestureDetector(
      onTap: () {
        SoundService().playPop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LingoScreen(
              level: 0, // 0 = Mode Classique (pas d'aventure)
              wordLength: wordLength,
              maxAttempts: maxAttempts,
              difficulty: title,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white.withValues(alpha: 0.05),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Text(icon, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.5), size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
