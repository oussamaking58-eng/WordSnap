import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../services/score_service.dart';
import 'lingo_screen.dart';
import '../services/language_service.dart';
import '../widgets/shop_sheet.dart';

class LingoMapScreen extends StatefulWidget {
  const LingoMapScreen({super.key});

  @override
  State<LingoMapScreen> createState() => _LingoMapScreenState();
}

class _LingoMapScreenState extends State<LingoMapScreen> {
  final ScoreService _scoreService = ScoreService();
  final LanguageService _langService = LanguageService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _langService.addListener(_rebuild);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel();
    });
  }

  @override
  void dispose() {
    _langService.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
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
          // Fond Nébuleuse Dynamique
          Positioned.fill(
            child: Stack(
              children: [
                Container(
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
                // Blue Glow
                Positioned(
                  top: 100,
                  left: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cyan.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                // Purple Glow
                Positioned(
                  bottom: 200,
                  right: -100,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.purple.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              ],
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
                    child: Center(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: SagaPathPainter(
                                totalLevels: totalLevels,
                                currentLevel: currentLevel,
                              ),
                            ),
                          ),
                          Column(
                            children: List.generate(totalLevels, (index) {
                              int level = totalLevels - index;
                              return _buildLevelNode(level, currentLevel);
                            }),
                          ),
                        ],
                      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _langService.translate('adventure_mode').toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                _langService.translate('saga_subtitle').toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => ShopSheet(),
              ).then((_) => setState(() {}));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text('${_scoreService.coins}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 4),
                  const Icon(Icons.add_circle, size: 16, color: Colors.amber),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelNode(int level, int currentLevel) {
    bool isCompleted = level < currentLevel;
    bool isActive = level == currentLevel;
    bool isLocked = level > currentLevel;

    String difficulty = _langService.translate('difficulty_easy');
    String emoji = '🌱';
    Color diffColor = Colors.green;
    int wordLen = 5;
    int maxAtt = 6;

    if (level > 35) {
      difficulty = _langService.translate('difficulty_hard');
      emoji = '💀';
      diffColor = AppColors.red;
      wordLen = 8;
      maxAtt = 4;
    } else if (level > 25) {
      difficulty = _langService.translate('difficulty_hard');
      emoji = '🔥';
      diffColor = Colors.deepOrange;
      wordLen = 8;
      maxAtt = 5;
    } else if (level > 15) {
      difficulty = _langService.translate('difficulty_hard');
      emoji = '⚡';
      diffColor = Colors.orange;
      wordLen = 7;
      maxAtt = 5;
    } else if (level > 5) {
      difficulty = _langService.translate('difficulty_medium');
      emoji = '🌟';
      diffColor = AppColors.cyan;
      wordLen = 6;
      maxAtt = 6;
    }

    // Positions sinusoids: level 1 is bottom, level 50 is top
    // We want a logic that matches the painter
    double xOffset = 0;
    int posIndex = (level - 1) % 4;
    if (posIndex == 1) xOffset = 80;
    if (posIndex == 3) xOffset = -80;

    return SizedBox(
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
                                color: diffColor.withValues(alpha: 0.2 * (2 - value)),
                              ),
                            );
                          },
                          onEnd: () {}, // Restart is handled by repeat in real animation, but this works for a simple loop
                        ),
                      if (isActive)
                        Positioned(
                          top: -20,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              final clampedValue = value.clamp(0.0, 1.0);
                              return Transform.translate(
                                offset: Offset(0, -10 * (1 - clampedValue)),
                                child: Opacity(
                                  opacity: clampedValue,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.cyan,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.cyan.withValues(alpha: 0.5),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _langService.translate('you_indicator'),
                                      style: const TextStyle(
                                        color: Color(0xFF000000),
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      Container(
                        width: isActive ? 75 : 60,
                        height: isActive ? 75 : 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (!isLocked) 
                              BoxShadow(
                                color: diffColor.withValues(alpha: 0.4), 
                                blurRadius: isActive ? 20 : 10,
                                spreadRadius: isActive ? 2 : 0,
                              ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isLocked 
                                  ? Colors.white.withValues(alpha: 0.05) 
                                  : (isActive ? diffColor.withValues(alpha: 0.3) : diffColor.withValues(alpha: 0.15)),
                                border: Border.all(
                                  color: isLocked 
                                    ? Colors.white12 
                                    : (isActive ? Colors.white : diffColor.withValues(alpha: 0.6)),
                                  width: isActive ? 3 : 2,
                                ),
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: isActive ? 0.3 : 0.1),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 1.0],
                                ),
                              ),
                              child: Center(
                                child: isLocked 
                                  ? const Icon(Icons.lock_outline, color: Colors.white24, size: 22)
                                  : (isCompleted 
                                    ? const Icon(Icons.check, color: Colors.white, size: 32)
                                    : Text(
                                        '$level',
                                        style: TextStyle(
                                          color: Colors.white, 
                                          fontSize: isActive ? 24 : 20, 
                                          fontWeight: FontWeight.w900,
                                          shadows: [
                                            Shadow(color: diffColor, blurRadius: 10),
                                          ],
                                        ),
                                      )
                                  ),
                              ),
                            ),
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
                        _langService.translate('n_letters').replaceAll('{n}', '$wordLen').toUpperCase(),
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

class SagaPathPainter extends CustomPainter {
  final int totalLevels;
  final int currentLevel;

  SagaPathPainter({required this.totalLevels, required this.currentLevel});

  @override
  void paint(Canvas canvas, Size size) {
    const double nodeHeight = 120.0;
    
    for (int i = 1; i < totalLevels; i++) {
      int fromLevel = i;
      int toLevel = i + 1;

      Offset p1 = _getNodeOffset(fromLevel, size, nodeHeight);
      Offset p2 = _getNodeOffset(toLevel, size, nodeHeight);

      bool isPassed = toLevel <= currentLevel;
      Color pathColor = isPassed ? AppColors.cyan : Colors.white.withValues(alpha: 0.1);

      final path = Path();
      path.moveTo(p1.dx, p1.dy);
      
      // Curve between nodes
      path.quadraticBezierTo(
        size.width / 2 + (p1.dx + p2.dx - size.width) / 2, 
        (p1.dy + p2.dy) / 2, 
        p2.dx, 
        p2.dy
      );

      final paint = Paint()
        ..color = pathColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (isPassed) {
        final glowPaint = Paint()
          ..color = pathColor.withValues(alpha: 0.3)
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, paint);
      } else {
        // Draw dashed for locked path
        _drawDashedPath(canvas, path, paint);
      }
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    double distance = 0.0;
    double dashWidth = 5.0;
    double dashSpace = 5.0;
    
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  Offset _getNodeOffset(int level, Size size, double nodeHeight) {
    double xOffset = 0;
    int posIndex = (level - 1) % 4;
    if (posIndex == 1) xOffset = 80;
    if (posIndex == 3) xOffset = -80;
    double y = size.height - ((level - 0.5) * nodeHeight);
    return Offset(size.width / 2 + xOffset, y);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
