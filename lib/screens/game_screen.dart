import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/sound_service.dart';
import '../services/word_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';

enum GameLevel { debutant, intermediaire, expert }

class GameScreen extends StatefulWidget {
  final GameLevel level;
  final List<String>? fixedLetters;

  const GameScreen({
    super.key, 
    this.level = GameLevel.debutant,
    this.fixedLetters,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late List<String> letters;
  late List<bool> selected;
  String currentWord = '';
  int score = 0;
  late int timeLeft;
  late int totalTime;
  late int letterCount;
  late double pointsMultiplier;
  late String levelLabel;
  final List<String> foundWords = [];
  late Timer _timer;

  // Feedback states
  bool _wordInvalid = false;
  bool _wordValid = false;
  bool _showScorePop = false;
  int _lastAddedScore = 0;
  String _feedbackMessage = '';

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;
  late AnimationController _scorePopController;
  late Animation<double> _scorePopAnim;

  final WordService _wordService = WordService();

  final List<String> frenchLetters = [
    'E',
    'E',
    'E',
    'E',
    'E',
    'A',
    'A',
    'A',
    'I',
    'I',
    'I',
    'S',
    'S',
    'S',
    'N',
    'N',
    'T',
    'T',
    'R',
    'R',
    'O',
    'O',
    'U',
    'U',
    'L',
    'L',
    'C',
    'D',
    'M',
    'P',
    'G',
    'B',
    'F',
    'H',
    'V',
    'X',
    'Y',
    'Z',
    'J',
    'K',
    'Q',
    'W',
  ];

  @override
  void initState() {
    super.initState();
    _setupLevel();
    _generateLetters();
    _initAnimations();
    _startTimer();
  }

  void _initAnimations() {
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _scorePopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scorePopAnim = CurvedAnimation(
      parent: _scorePopController,
      curve: Curves.easeOut,
    );
    _scorePopController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() => _showScorePop = false);
          _scorePopController.reset();
        }
      }
    });
  }

  void _setupLevel() {
    switch (widget.level) {
      case GameLevel.debutant:
        letterCount = 7;
        timeLeft = 90;
        totalTime = 90;
        pointsMultiplier = 1.0;
        levelLabel = 'DEBUTANT';
        break;
      case GameLevel.intermediaire:
        letterCount = 8;
        timeLeft = 75;
        totalTime = 75;
        pointsMultiplier = 1.5;
        levelLabel = 'INTERMEDIAIRE';
        break;
      case GameLevel.expert:
        letterCount = 9;
        timeLeft = 60;
        totalTime = 60;
        pointsMultiplier = 2.0;
        levelLabel = 'EXPERT';
        break;
    }
  }

  void _generateLetters() {
    if (widget.fixedLetters != null && widget.fixedLetters!.isNotEmpty) {
      letters = List.from(widget.fixedLetters!);
      letterCount = letters.length;
      selected = List.generate(letterCount, (_) => false);
      return;
    }

    final random = Random();
    letters = List.generate(
      letterCount,
      (_) => frenchLetters[random.nextInt(frenchLetters.length)],
    );
    selected = List.generate(letterCount, (_) => false);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (timeLeft == 0) {
        timer.cancel();
        HapticFeedback.heavyImpact();
        _goToResults();
      } else {
        setState(() => timeLeft--);
        if (timeLeft <= 10) HapticFeedback.lightImpact();
      }
    });
  }

  void _goToResults() {
    if (!mounted) return;

    // On arrête le timer pour éviter tout trigger résiduel
    _timer.cancel();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => ResultsScreen(
          score: score, // Ton score actuel [cite: 4, 25]
          foundWords: foundWords, // La liste List<String> de tes mots trouvés
          level: widget
              .level, // Le niveau (débutant, intermédiaire ou expert) [cite: 2, 25]
          totalTime: totalTime, // Le temps total alloué au niveau [cite: 4, 25]
          letters: letters,
        ),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _shakeController.dispose();
    _scorePopController.dispose();
    super.dispose();
  }

  void _onTileTap(int index) {
    HapticFeedback.selectionClick();
    SoundService().playPop(); // 🔊 AJOUT DU SON ICI

    setState(() {
      if (selected[index]) {
        final lastIndex = _getLastSelectedIndex();
        if (lastIndex == index) {
          selected[index] = false;
          if (currentWord.isNotEmpty) {
            currentWord = currentWord.substring(0, currentWord.length - 1);
          }
        }
      } else {
        selected[index] = true;
        currentWord += letters[index];
      }
    });
  }

  int _getLastSelectedIndex() {
    for (int i = selected.length - 1; i >= 0; i--) {
      if (selected[i]) return i;
    }
    return -1;
  }

  void _clearWord() {
    HapticFeedback.lightImpact();
    setState(() {
      currentWord = '';
      for (int i = 0; i < selected.length; i++) {
        selected[i] = false;
      }
    });
  }

  void _submitWord() {
    if (currentWord.length < 2) return;

    // Mot déjà trouvé
    if (foundWords.contains(currentWord)) {
      HapticFeedback.heavyImpact();
      _showInvalidFeedback('Déjà trouvé !');
      return;
    }

    // Validation dictionnaire
    if (!_wordService.isValidWord(currentWord, LanguageService().currentLanguage)) {
      HapticFeedback.heavyImpact();
      _showInvalidFeedback('Mot invalide');
      return;
    }

    // Mot valide ✅
    HapticFeedback.mediumImpact();
    SoundService().playDing(); // 🔊 AJOUT DU SON ICI

    final pts = (currentWord.length * 20 * pointsMultiplier).round();
    setState(() {
      foundWords.add(currentWord);
      _lastAddedScore = pts;
      score += pts;
      _showScorePop = true;
      _wordValid = true;
      currentWord = '';
      for (int i = 0; i < selected.length; i++) {
        selected[i] = false;
      }
    });

    _scorePopController.forward(from: 0);

    // Reset valid state
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _wordValid = false);
    });
  }

  void _showInvalidFeedback(String message) {
    setState(() {
      _wordInvalid = true;
      _feedbackMessage = message;
    });
    _shakeController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() => _wordInvalid = false);
        _clearWord();
      }
    });
  }

  Color _getLevelColor() {
    switch (widget.level) {
      case GameLevel.debutant:
        return AppColors.green;
      case GameLevel.intermediaire:
        return AppColors.cyan;
      case GameLevel.expert:
        return AppColors.pink;
    }
  }

  Color get _inputBorderColor {
    if (_wordInvalid) return const Color(0x60F43F5E);
    if (_wordValid) return const Color(0x604ADE80);
    return const Color(0x60A855F7);
  }

  Color get _inputBgColor {
    if (_wordInvalid) return const Color(0x1AF43F5E);
    if (_wordValid) return const Color(0x1A4ADE80);
    return const Color(0x1AA855F7);
  }

  Color get _inputTextColor {
    if (_wordInvalid) return AppColors.red;
    if (_wordValid) return AppColors.green;
    return AppColors.purple;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0525), AppColors.bg],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildTimer(),
              _buildWordInput(),
              const Spacer(),
              _buildTiles(),
              const SizedBox(height: 8),
              _buildFoundWords(),
              _buildButtons(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              SoundService().playPop();
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.purple,
                size: 16,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _getLevelColor().withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getLevelColor().withOpacity(0.4)),
            ),
            child: Text(
              levelLabel,
              style: TextStyle(
                fontSize: 10,
                color: _getLevelColor(),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.pink, AppColors.cyan],
                  ).createShader(bounds),
                  child: Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_showScorePop)
                  Positioned(
                    top: -28,
                    child: AnimatedBuilder(
                      animation: _scorePopAnim,
                      builder: (_, _) => Opacity(
                        opacity: (1 - _scorePopAnim.value).clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, -20 * _scorePopAnim.value),
                          child: Text(
                            '+$_lastAddedScore',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.green,
                            ),
                          ),
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

  Widget _buildTimer() {
    final ratio = (timeLeft / totalTime).clamp(0.0, 1.0);
    final timerColor = ratio > 0.5
        ? AppColors.cyan
        : ratio > 0.25
        ? AppColors.yellow
        : AppColors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: timeLeft <= 10 ? 48 : 40,
              fontWeight: FontWeight.w800,
              color: timerColor,
            ),
            child: Text('$timeLeft'),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 4,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    height: 4,
                    width: constraints.maxWidth * ratio,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.purple, timerColor],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWordInput() {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(sin(_shakeAnim.value * pi * 4) * 8, 0),
        child: child,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _inputBgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _inputBorderColor, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _wordInvalid
                    ? _feedbackMessage
                    : (currentWord.isEmpty ? '...' : currentWord),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _inputTextColor,
                  letterSpacing: currentWord.isEmpty ? 0 : 4,
                ),
              ),
            ),
            Text(
              '${letters.length} lettres',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTiles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: List.generate(letters.length, (i) {
          return GestureDetector(
            onTap: () => _onTileTap(i),
            child: AnimatedScale(
              scale: selected[i] ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutBack,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selected[i]
                      ? const LinearGradient(
                          colors: [AppColors.purple, AppColors.cyan],
                        )
                      : null,
                  color: selected[i] ? null : AppColors.surface2,
                  border: Border.all(
                    color: selected[i] ? Colors.transparent : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    letters[i],
                    style: TextStyle(
                      fontSize: selected[i] ? 20 : 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFoundWords() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${foundWords.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.purple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: foundWords.reversed.map((w) {
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x1A22D3EE),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x3022D3EE)),
                  ),
                  child: Text(
                    w,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _clearWord,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'Effacer',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _submitWord,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: currentWord.length >= 2
                        ? [AppColors.purple, AppColors.pink]
                        : [AppColors.surface2, AppColors.surface2],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: currentWord.length >= 2
                        ? Colors.transparent
                        : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Valider',
                    style: TextStyle(
                      fontSize: 13,
                      color: currentWord.length >= 2
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
