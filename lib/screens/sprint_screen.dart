import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

// Vérifie que ces imports correspondent à ton projet
import '../theme/app_theme.dart';
import '../services/letter_generator.dart';
import '../services/word_service.dart';
import '../services/firebase_storage_service.dart';
import '../widgets/combo_text.dart';

class SprintScreen extends StatefulWidget {
  const SprintScreen({super.key});

  @override
  State<SprintScreen> createState() => _SprintScreenState();
}

class _SprintScreenState extends State<SprintScreen> with TickerProviderStateMixin {
  // --- Variables du Sprint ---
  int _timeLeft = 60;
  final int _totalTime = 60;
  Timer? _timer;
  
  List<String> _currentHand = [];
  List<bool> _selected = [];
  String _currentWord = "";
  
  int _score = 0;
  int _comboCount = 0;
  
  // Feedback visuel
  bool _wordInvalid = false;
  bool _wordValid = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  final WordService _wordService = WordService();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startNewGame();
  }

  void _initAnimations() {
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void _startNewGame() {
    setState(() {
      _score = 0;
      _comboCount = 0;
      _timeLeft = _totalTime;
      _generateNewHand();
    });
    _startTimer();
  }

  void _generateNewHand() {
    _currentWord = "";
    // On génère 10 lettres pour le Sprint
    _currentHand = LetterGenerator.generateHand(10);
    _selected = List.generate(10, (_) => false);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeLeft == 0) {
        timer.cancel();
        HapticFeedback.heavyImpact();
        _showGameOverDialog();
      } else {
        setState(() => _timeLeft--);
        if (_timeLeft <= 10) HapticFeedback.lightImpact();
      }
    });
  }

  // --- LOGIQUE DE SÉLECTION (Calquée sur GameScreen) ---
  void _onTileTap(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected[index]) {
        final lastIndex = _getLastSelectedIndex();
        if (lastIndex == index) {
          _selected[index] = false;
          if (_currentWord.isNotEmpty) {
            _currentWord = _currentWord.substring(0, _currentWord.length - 1);
          }
        }
      } else {
        _selected[index] = true;
        _currentWord += _currentHand[index];
      }
    });
  }

  int _getLastSelectedIndex() {
    for (int i = _selected.length - 1; i >= 0; i--) {
      if (_selected[i]) return i;
    }
    return -1;
  }

  void _clearWord() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentWord = '';
      for (int i = 0; i < _selected.length; i++) _selected[i] = false;
    });
  }

  void _validateWord() {
    if (_currentWord.length < 2) return;

    if (!_wordService.isValidWord(_currentWord)) {
      HapticFeedback.heavyImpact();
      _showInvalidFeedback();
      return;
    }

    // Mot valide !
    HapticFeedback.mediumImpact();
    int wordScore = _currentWord.length * 10;
    
    setState(() {
      _wordValid = true;
      _score += wordScore + (_comboCount * 5);
      _timeLeft += 2; // Bonus de temps !
      _comboCount++;
      _generateNewHand(); // On donne de nouvelles lettres directement
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _wordValid = false);
    });
  }

  void _showInvalidFeedback() {
    setState(() {
      _wordInvalid = true;
      _comboCount = 0; // On casse le combo !
    });
    _shakeController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() => _wordInvalid = false);
        _clearWord();
      }
    });
  }

  void _showGameOverDialog() {
    if (_score > 0) {
      FirebaseStorageService().updateHighScore(_score);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("⏰ Temps écoulé !", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Score final : $_score points\nJoli sprint !",
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Quitter", style: TextStyle(color: AppColors.textSecondary)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.purple, AppColors.pink]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              onPressed: () {
                Navigator.pop(context);
                _startNewGame();
              },
              child: const Text("Rejouer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  // --- COULEURS DYNAMIQUES DU CHAMP TEXTE ---
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
              
              // Le Combo !
              SizedBox(height: 30, child: ComboText(comboCount: _comboCount)),
              
              _buildWordInput(),
              const Spacer(),
              _buildTiles(),
              const SizedBox(height: 16),
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
          // Bouton Retour
          GestureDetector(
            onTap: () {
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
              child: const Icon(Icons.arrow_back_ios_new, color: AppColors.purple, size: 16),
            ),
          ),
          // Badge Sprint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.yellow.withOpacity(0.4)),
            ),
            child: const Text(
              'SPRINT ⚡',
              style: TextStyle(fontSize: 10, color: AppColors.yellow, letterSpacing: 1.5, fontWeight: FontWeight.w600),
            ),
          ),
          // Score
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.pink, AppColors.cyan],
            ).createShader(bounds),
            child: Text(
              '$_score',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final ratio = (_timeLeft / _totalTime).clamp(0.0, 1.0);
    final timerColor = _timeLeft > 10 ? AppColors.cyan : AppColors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: _timeLeft <= 10 ? 48 : 40,
              fontWeight: FontWeight.w800,
              color: timerColor,
            ),
            child: Text('$_timeLeft'),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 4,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(4)),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    height: 4,
                    width: constraints.maxWidth * ratio,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.purple, timerColor]),
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                _currentWord.isEmpty ? '...' : _currentWord,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _inputTextColor,
                  letterSpacing: _currentWord.isEmpty ? 0 : 4,
                ),
              ),
            ),
            Text(
              '+2 sec',
              style: TextStyle(fontSize: 12, color: AppColors.green.withOpacity(0.8), fontWeight: FontWeight.bold),
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
        children: List.generate(_currentHand.length, (i) {
          return GestureDetector(
            onTap: () => _onTileTap(i),
            child: AnimatedScale(
              scale: _selected[i] ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutBack,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _selected[i] ? const LinearGradient(colors: [AppColors.purple, AppColors.cyan]) : null,
                  color: _selected[i] ? null : AppColors.surface2,
                  border: Border.all(
                    color: _selected[i] ? Colors.transparent : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _currentHand[i],
                    style: TextStyle(
                      fontSize: _selected[i] ? 20 : 18,
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
                  child: Text('Effacer', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _validateWord,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _currentWord.length >= 2
                        ? [AppColors.purple, AppColors.pink]
                        : [AppColors.surface2, AppColors.surface2],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _currentWord.length >= 2 ? Colors.transparent : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Valider',
                    style: TextStyle(
                      fontSize: 13,
                      color: _currentWord.length >= 2 ? Colors.white : AppColors.textSecondary,
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