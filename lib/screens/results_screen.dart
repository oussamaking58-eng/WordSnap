import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../services/firebase_storage_service.dart';
import '../services/score_service.dart';
import '../theme/app_theme.dart';
import '../widgets/leaderboard_sheet.dart';
import 'game_screen.dart';
import '../services/sound_service.dart';

class ResultsScreen extends StatefulWidget {
  final int score;
  final List<String> foundWords;
  final GameLevel level;
  final int totalTime;
  final List<String> letters;

  const ResultsScreen({
    super.key,
    required this.score,
    required this.foundWords,
    required this.level,
    required this.totalTime,
    required this.letters,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _wordsController;
  late Animation<double> _trophyScale;
  late Animation<double> _scoreFade;
  late Animation<double> _statsSlide;
  late Animation<double> _buttonsFade;
  late ConfettiController _confettiController;

  final ScoreService _scoreService = ScoreService();
  final FirebaseStorageService _firebaseService = FirebaseStorageService();
  bool _isNewBest = false;
  String _userName = "Joueur";

 @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    
    _loadUserName();
    
    _saveScore().then((_) {
      if (_isNewBest) {
        SoundService().playTada(); // 🔊 LE SON EST DÉCLENCHÉ ICI !
        _confettiController.play();
      }
    });
    
    _initAnimations();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? "Joueur";
      });
    }
  }

  Future<void> _saveScore() async {
    final oldBest = _scoreService.bestScore;
    await _scoreService.saveGame(widget.score);
    await _firebaseService.updateHighScore(widget.score);
    if (widget.score > oldBest && mounted) {
      setState(() => _isNewBest = true);
      HapticFeedback.heavyImpact();
    }
  }

  void _initAnimations() {
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _wordsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _trophyScale = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
    );
    _scoreFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
    );
    _statsSlide = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.5, 0.8, curve: Curves.easeOutCubic),
    );
    _buttonsFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );
    _mainController.forward().then((_) => _wordsController.forward());
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _mainController.dispose();
    _wordsController.dispose();
    super.dispose();
  }

  String get _resultEmoji => widget.foundWords.length >= 8
      ? '🏆'
      : widget.foundWords.length >= 5
      ? '🌟'
      : widget.foundWords.length >= 3
      ? '👍'
      : '💪';
  String get _resultMessage => _isNewBest
      ? '🎉 Nouveau record !'
      : widget.foundWords.length >= 8
      ? 'Incroyable !'
      : widget.foundWords.length >= 5
      ? 'Excellent !'
      : 'Bien joué !';
  Color get _levelColor {
    switch (widget.level) {
      case GameLevel.debutant:
        return AppColors.green;
      case GameLevel.intermediaire:
        return AppColors.cyan;
      case GameLevel.expert:
        return AppColors.pink;
    }
  }

  String get _levelLabel {
    switch (widget.level) {
      case GameLevel.debutant:
        return 'DEBUTANT';
      case GameLevel.intermediaire:
        return 'INTERMEDIAIRE';
      case GameLevel.expert:
        return 'EXPERT';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A0535), AppColors.bg],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      _userName.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.cyan,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTrophy(),
                    const SizedBox(height: 20),
                    _buildScore(),
                    const SizedBox(height: 20),
                    _buildStats(),
                    const SizedBox(height: 16),
                    _buildBestScore(),
                    const SizedBox(height: 16),
                    _buildFoundWords(),
                    const SizedBox(height: 24),
                    _buildButtons(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              AppColors.cyan,
              AppColors.pink,
              AppColors.purple,
              Colors.yellow,
            ],
            numberOfParticles: 25,
            gravity: 0.1,
          ),
        ],
      ),
    );
  }

  Widget _buildTrophy() {
    return ScaleTransition(
      scale: _trophyScale,
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [_levelColor, AppColors.purple]),
              boxShadow: [
                BoxShadow(
                  color: _levelColor.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Text(_resultEmoji, style: const TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: _levelColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _levelColor.withOpacity(0.4)),
            ),
            child: Text(
              _levelLabel,
              style: TextStyle(
                fontSize: 10,
                color: _levelColor,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScore() {
    return FadeTransition(
      opacity: _scoreFade,
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: _isNewBest
                  ? [AppColors.yellow, AppColors.pink]
                  : [AppColors.pink, AppColors.cyan],
            ).createShader(bounds),
            child: Text(
              '${widget.score}',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _resultMessage,
            style: TextStyle(
              fontSize: 15,
              color: _isNewBest ? AppColors.yellow : AppColors.textSecondary,
              fontWeight: _isNewBest ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(_statsSlide),
      child: FadeTransition(
        opacity: _statsSlide,
        child: Row(
          children: [
            _buildStatBox('${widget.foundWords.length}', 'MOTS'),
            const SizedBox(width: 10),
            _buildStatBox(
              widget.foundWords.isNotEmpty
                  ? widget.foundWords.reduce(
                      (a, b) => a.length >= b.length ? a : b,
                    )
                  : '-',
              'MEILLEUR MOT',
            ),
            const SizedBox(width: 10),
            _buildStatBox('${_scoreService.streak}🔥', 'STREAK'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.purple, AppColors.cyan],
              ).createShader(bounds),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestScore() {
    return FadeTransition(
      opacity: _statsSlide,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: _isNewBest ? const Color(0x1AFACC15) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isNewBest ? const Color(0x50FACC15) : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isNewBest ? '🏅 Nouveau record !' : '🏅 Meilleur score',
              style: TextStyle(
                fontSize: 13,
                color: _isNewBest ? AppColors.yellow : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: _isNewBest
                    ? [AppColors.yellow, AppColors.pink]
                    : [AppColors.purple, AppColors.cyan],
              ).createShader(bounds),
              child: Text(
                '${_scoreService.bestScore}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoundWords() {
    return FadeTransition(
      opacity: _wordsController,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'MOTS TROUVES',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.foundWords.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.purple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            widget.foundWords.isEmpty
                ? const Text(
                    'Aucun mot trouvé...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.foundWords
                        .map(
                          (word) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x1A22D3EE),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0x3022D3EE),
                              ),
                            ),
                            child: Text(
                              word,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.cyan,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  void _shareChallenge(BuildContext context) {
    // On transforme la liste ['B', 'O', 'N'] en "BON"
    final String code = widget.foundWords.isNotEmpty ? widget.letters.join("") : ""; 
    final String message = "🔥 Défi WordSnap !\n\nJ'ai fait ${widget.score} points avec ces lettres. Peux-tu faire mieux ?\n\nCode à copier : $code";

    // Utilise le package share_plus pour ouvrir le menu natif (WhatsApp, Messenger, etc.)
    Share.share(message);
  }

  Widget _buildButtons(BuildContext context) {
    return FadeTransition(
      opacity: _buttonsFade,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => GameScreen(level: widget.level),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.purple, AppColors.pink],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'Rejouer',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _shareChallenge(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.pink.withOpacity(0.5)),
              ),
              child: const Center(
                child: Text(
                  'Défier un ami 📤',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.pink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const LeaderboardSheet(),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cyan.withOpacity(0.5)),
              ),
              child: const Center(
                child: Text(
                  'Classement Mondial 🏆',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text(
              'Retour à l\'accueil',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
