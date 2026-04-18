import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../services/score_service.dart';
import 'lingo_screen.dart';
import '../widgets/shop_sheet.dart';

class LingoMapScreen extends StatefulWidget {
  const LingoMapScreen({super.key});

  @override
  State<LingoMapScreen> createState() => _LingoMapScreenState();
}

class _LingoMapScreenState extends State<LingoMapScreen> {
  final ScoreService _scoreService = ScoreService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel();
    });
  }

  void _scrollToCurrentLevel() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    int currentLevel = _scoreService.currentLevel;
    // Sécurité au cas où currentLevel serait mal initialisé
    if (currentLevel < 1) currentLevel = 1;
    
    int totalLevels = 50;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Fond Nébuleuse
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Color(0xFF1A0535),
                    Color(0xFF0F021A),
                    Color(0xFF05010D),
                  ],
                ),
              ),
            ),
          ),
          
          // Chemin et Niveaux
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Le chemin (Ligne pointillée colorée)
                        CustomPaint(
                          size: Size(MediaQuery.of(context).size.width, totalLevels * 120.0),
                          painter: PathPainter(totalLevels: totalLevels),
                        ),
                        // Les Noeuds
                        Column(
                          children: List.generate(totalLevels, (index) {
                            int level = index + 1; // 1 en bas, 50 en haut
                            // On inverse l'affichage pour que 1 soit en bas
                            return _buildLevelNode(totalLevels - index, currentLevel);
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: const Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVENTURE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'SAGA DES MOTS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const ShopSheet(),
                  ).then((_) => setState(() {}));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('${_scoreService.coins}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(width: 4),
                      const Icon(Icons.add_circle, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelNode(int level, int currentLevel) {
    bool isCompleted = level < currentLevel;
    bool isActive = level == currentLevel;
    bool isLocked = level > currentLevel;

    String difficulty = 'FACILE';
    String emoji = '🌱';
    Color diffColor = Colors.green;
    int wordLen = 5;
    int maxAtt = 6;

    if (level > 35) {
      difficulty = 'HELL';
      emoji = '💀';
      diffColor = AppColors.red;
      wordLen = 8;
      maxAtt = 4;
    } else if (level > 25) {
      difficulty = 'TRÈS DIFFICILE';
      emoji = '🔥';
      diffColor = Colors.deepOrange;
      wordLen = 8;
      maxAtt = 5;
    } else if (level > 15) {
      difficulty = 'DIFFICILE';
      emoji = '⚡';
      diffColor = Colors.orange;
      wordLen = 7;
      maxAtt = 5;
    } else if (level > 5) {
      difficulty = 'MOYEN';
      emoji = '🌟';
      diffColor = AppColors.cyan;
      wordLen = 6;
      maxAtt = 6;
    }

    // Calcul de la position horizontale sinueuse
    double xOffset = 0;
    if (level % 4 == 1) xOffset = -80;
    if (level % 4 == 3) xOffset = 80;

    return Container(
      height: 120,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(xOffset, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Le Noeud
                GestureDetector(
                  onTap: isLocked ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LingoScreen(
                          level: level,
                          wordLength: wordLen,
                          maxAttempts: maxAtt,
                          difficulty: difficulty,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isActive)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.8, end: 1.2),
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Container(
                              width: 80 * value,
                              height: 80 * value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: diffColor.withOpacity(0.2 * (2 - value)),
                              ),
                            );
                          },
                          onEnd: () {}, // Restart is handled by repeat in real animation, but this works for a simple loop
                        ),
                      Container(
                        width: isActive ? 70 : 55,
                        height: isActive ? 70 : 55,
                        decoration: BoxDecoration(
                          color: isLocked ? Colors.white.withOpacity(0.05) : (isActive ? diffColor : Colors.white.withOpacity(0.1)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isLocked ? Colors.white12 : (isActive ? Colors.white : diffColor.withOpacity(0.5)),
                            width: isActive ? 3 : 2,
                          ),
                          boxShadow: [
                            if (!isLocked) BoxShadow(color: diffColor.withOpacity(0.3), blurRadius: 10),
                          ],
                        ),
                        child: Center(
                          child: isLocked 
                            ? const Icon(Icons.lock_outline, color: Colors.white24, size: 20)
                            : (isCompleted 
                              ? const Icon(Icons.check, color: Colors.white, size: 28)
                              : Text(
                                  '$level',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                                )
                            ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                // Texte de difficulté
                if (!isLocked)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$emoji $difficulty',
                        style: TextStyle(
                          color: diffColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '$wordLen LETTRES',
                        style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  final int totalLevels;
  PathPainter({required this.totalLevels});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    double startY = size.height - 60;
    path.moveTo(size.width / 2, startY);

    for (int i = 1; i < totalLevels; i++) {
      double nextY = startY - 120;
      double xOffset = 0;
      int level = i + 1;
      if (level % 4 == 1) xOffset = -80;
      if (level % 4 == 3) xOffset = 80;
      
      // On crée une courbe de Bézier pour le chemin sinueux
      double prevXOffset = 0;
      if (i % 4 == 1) prevXOffset = -80;
      if (i % 4 == 3) prevXOffset = 80;

      path.quadraticBezierTo(
        size.width / 2 + (prevXOffset + xOffset) / 2, 
        startY - 60, 
        size.width / 2 + xOffset, 
        nextY
      );
      
      startY = nextY;
    }

    // Dessin en pointillé avec dégradé
    final gradient = const LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [AppColors.cyan, AppColors.purple, AppColors.pink, AppColors.red],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    paint.shader = gradient;

    // Simuler des pointillés
    Path dashPath = Path();
    double dashWidth = 8.0;
    double dashSpace = 8.0;
    double distance = 0.0;
    
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
