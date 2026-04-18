import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import '../services/language_service.dart';
import '../services/lives_service.dart';
import '../services/score_service.dart';
import '../services/word_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shop_sheet.dart';
import '../widgets/end_game_dialog.dart';

enum LetterState { initial, notInWord, inWordWrongSpot, inWordCorrectSpot }

class LingoScreen extends StatefulWidget {
  final int level;
  final int wordLength;
  final int maxAttempts;
  final String difficulty;

  const LingoScreen({
    super.key,
    required this.level,
    required this.wordLength,
    required this.maxAttempts,
    required this.difficulty,
  });

  @override
  State<LingoScreen> createState() => _LingoScreenState();
}

class _LingoScreenState extends State<LingoScreen> {
  late String _targetWord;
  int _currentAttempt = 0;
  int _hintsUsed = 0;

  late List<List<String>> _grid;
  late List<List<LetterState>> _states;
  final Map<String, LetterState> _keyboardStates = {};

  final WordService _wordService = WordService();
  final LanguageService _langService = LanguageService();
  final LivesService _livesService = LivesService();
  final ScoreService _scoreService = ScoreService();

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    _targetWord = _wordService.getRandomWord(
      widget.wordLength,
      _langService.currentLanguage,
    );
    _currentAttempt = 0;
    _hintsUsed = 0;
    _grid = List.generate(widget.maxAttempts, (_) => List.filled(widget.wordLength, ''));
    _states = List.generate(
      widget.maxAttempts,
      (_) => List.filled(widget.wordLength, LetterState.initial),
    );
    _keyboardStates.clear();
    print("🎯 Mot cible : $_targetWord");
  }

  void _onKeyPressed(String key) {
    if (_currentAttempt >= widget.maxAttempts) return;

    setState(() {
      if (key == 'ENTER') {
        _submitGuess();
      } else if (key == 'DEL') {
        _deleteLetter();
      } else {
        _addLetter(key);
      }
    });
  }

  void _addLetter(String letter) {
    int col = _grid[_currentAttempt].indexOf('');
    if (col != -1) {
      _grid[_currentAttempt][col] = letter;
      HapticFeedback.lightImpact();
    }
  }

  void _deleteLetter() {
    for (int i = widget.wordLength - 1; i >= 0; i--) {
      if (_grid[_currentAttempt][i].isNotEmpty) {
        _grid[_currentAttempt][i] = '';
        HapticFeedback.lightImpact();
        break;
      }
    }
  }

  void _submitGuess() {
    if (_grid[_currentAttempt].contains('')) {
      _showSnackBar(_langService.translate('too_short'));
      return;
    }

    String guess = _grid[_currentAttempt].join('');

    _calculateStates(guess);

    if (guess == _targetWord) {
      _handleEndGame(true);
    } else {
      setState(() {
        _currentAttempt++;
        if (_currentAttempt >= widget.maxAttempts) {
          _handleEndGame(false);
        }
      });
    }
  }

  void _calculateStates(String guess) {
    List<LetterState> newStates = List.filled(widget.wordLength, LetterState.notInWord);
    List<bool> targetUsed = List.filled(widget.wordLength, false);

    for (int i = 0; i < widget.wordLength; i++) {
      if (guess[i] == _targetWord[i]) {
        newStates[i] = LetterState.inWordCorrectSpot;
        targetUsed[i] = true;
        _updateKeyboardState(guess[i], LetterState.inWordCorrectSpot);
      }
    }

    for (int i = 0; i < widget.wordLength; i++) {
      if (newStates[i] == LetterState.inWordCorrectSpot) continue;
      for (int j = 0; j < widget.wordLength; j++) {
        if (!targetUsed[j] && guess[i] == _targetWord[j]) {
          newStates[i] = LetterState.inWordWrongSpot;
          targetUsed[j] = true;
          _updateKeyboardState(guess[i], LetterState.inWordWrongSpot);
          break;
        }
      }
      if (newStates[i] == LetterState.notInWord) {
        _updateKeyboardState(guess[i], LetterState.notInWord);
      }
    }

    setState(() {
      _states[_currentAttempt] = newStates;
    });
  }

  void _updateKeyboardState(String letter, LetterState state) {
    LetterState current = _keyboardStates[letter] ?? LetterState.initial;
    if (current == LetterState.inWordCorrectSpot) return;
    if (current == LetterState.inWordWrongSpot && state == LetterState.notInWord) return;
    _keyboardStates[letter] = state;
  }

  void _handleEndGame(bool isWin) {
    HapticFeedback.heavyImpact();
    if (!isWin) {
      _livesService.consumeLife();
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EndGameDialog(
        isWin: isWin,
        word: _targetWord,
        level: widget.level,
      ),
    ).then((_) {
      if (mounted && !isWin && _livesService.lives > 0) {
        setState(() {
          _startNewGame();
        });
      }
    });
  }

  void _useHint() {
    bool usedFree = _scoreService.useFreeHint();
    int price = _hintsUsed == 0 ? 150 : 200;
    
    if (usedFree || _scoreService.spendCoins(price)) {
      if (usedFree) {
        _showSnackBar("Indice gratuit utilisé ! 🎟️");
      }
      setState(() {
        _hintsUsed++;
        // Trouver une lettre non encore trouvée (non verte dans le clavier ou la grille)
        // Pour simplifier, on révèle une lettre à une position aléatoire non encore correcte.
        List<int> availableIndices = [];
        for(int i=0; i<widget.wordLength; i++) {
          bool alreadyCorrect = false;
          for(int a=0; a<_currentAttempt; a++) {
            if(_states[a][i] == LetterState.inWordCorrectSpot) {
              alreadyCorrect = true;
              break;
            }
          }
          if(!alreadyCorrect) availableIndices.add(i);
        }

        if(availableIndices.isNotEmpty) {
          int idx = (availableIndices..shuffle()).first;
          _grid[_currentAttempt][idx] = _targetWord[idx];
          // On marque aussi l'état comme correct pour cette ligne pour aider l'utilisateur visuellement
          _states[_currentAttempt][idx] = LetterState.inWordCorrectSpot;
        }
      });
    } else {
      _showShop();
    }
  }

  void _revealAll() {
    if (_scoreService.spendCoins(500)) {
      setState(() {
        for(int i=0; i<widget.wordLength; i++) {
          _grid[_currentAttempt][i] = _targetWord[i];
          _states[_currentAttempt][i] = LetterState.inWordCorrectSpot;
        }
      });
      Future.delayed(const Duration(milliseconds: 500), () => _handleEndGame(true));
    } else {
      _showShop();
    }
  }

  void _showShop() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ShopSheet(),
    ).then((_) => setState(() {}));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
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
                color: AppColors.purple.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withOpacity(0.1),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Spacer(),
                _buildGrid(),
                const SizedBox(height: 20),
                _buildHintBar(),
                const Spacer(),
                _buildKeyboard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              Text(
                'NIVEAU ${widget.level}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
              ),
              Text(
                widget.difficulty,
                style: TextStyle(color: _getDifficultyColor(), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          GestureDetector(
            onTap: _showShop,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text('${_scoreService.coins}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Icon(Icons.add, size: 14, color: Colors.amber),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor() {
    switch(widget.difficulty) {
      case 'FACILE': return Colors.green;
      case 'INTERMÉDIAIRE': return Colors.blue;
      case 'DIFFICILE': return Colors.orange;
      case 'T-DIFFICILE': return Colors.deepOrange;
      case 'HELL': return Colors.red;
      default: return Colors.white;
    }
  }

  Widget _buildGrid() {
    return Column(
      children: List.generate(widget.maxAttempts, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.wordLength, (col) => _buildGridCell(row, col)),
          ),
        );
      }),
    );
  }

  Widget _buildGridCell(int row, int col) {
    String letter = _grid[row][col];
    LetterState state = _states[row][col];
    Color baseColor = Colors.white;
    if (state == LetterState.inWordCorrectSpot) baseColor = AppColors.green;
    else if (state == LetterState.inWordWrongSpot) baseColor = AppColors.orange;
    else if (state == LetterState.notInWord) baseColor = AppColors.red;
    else if (letter.isNotEmpty) baseColor = AppColors.cyan;

    double size = widget.wordLength >= 7 ? 40 : 48;

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: Stack(
        children: [
          // Glass Effect
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: (state == LetterState.initial ? Colors.white : baseColor).withOpacity(0.1),
                  border: Border.all(
                    color: (state == LetterState.initial ? Colors.white24 : baseColor.withOpacity(0.5)),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Glow and Content
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                if (state != LetterState.initial && state != LetterState.notInWord)
                  BoxShadow(color: baseColor.withOpacity(0.3), blurRadius: 10, spreadRadius: 1),
              ],
            ),
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    if (state != LetterState.initial && state != LetterState.notInWord)
                      Shadow(color: baseColor, blurRadius: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildHintButton(
          icon: Icons.lightbulb_outline,
          label: '${_hintsUsed == 0 ? 150 : 200} 🪙',
          onTap: _useHint,
          color: Colors.amber,
        ),
        const SizedBox(width: 20),
        _buildHintButton(
          icon: Icons.visibility,
          label: '500 🪙',
          onTap: _revealAll,
          color: Colors.cyan,
        ),
      ],
    );
  }

  Widget _buildHintButton({required IconData icon, required String label, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    List<List<String>> rows;
    if (_langService.currentLanguage == AppLanguage.ar) {
      rows = [
        ['ض', 'ص', 'ث', 'ق', 'ف', 'غ', 'ع', 'ه', 'خ', 'ح', 'ج'],
        ['ش', 'س', 'ي', 'ب', 'ل', 'ا', 'ت', 'ن', 'م', 'ك', 'ط'],
        ['DEL', 'ئ', 'ء', 'ؤ', 'ر', 'لا', 'ى', 'ة', 'و', 'ز', 'ظ', 'ENTER'],
      ];
    } else {
      rows = _langService.currentLanguage == AppLanguage.fr 
        ? [['A', 'Z', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'], ['Q', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M'], ['DEL', 'W', 'X', 'C', 'V', 'B', 'N', 'ENTER']]
        : [['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'], ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'], ['DEL', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'ENTER']];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: rows.map((row) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) => _buildKey(key)).toList(),
        )).toList(),
      ),
    );
  }

  Widget _buildKey(String key) {
    bool isSpecial = key == 'ENTER' || key == 'DEL';
    LetterState state = _keyboardStates[key] ?? LetterState.initial;
    
    Color baseColor = Colors.white;
    if (state == LetterState.inWordCorrectSpot) baseColor = AppColors.green;
    else if (state == LetterState.inWordWrongSpot) baseColor = AppColors.orange;
    else if (state == LetterState.notInWord) baseColor = Colors.black;

    return Expanded(
      flex: isSpecial ? 15 : 10,
      child: GestureDetector(
        onTap: () => _onKeyPressed(key),
        child: Container(
          height: 45,
          margin: const EdgeInsets.all(2),
          child: Stack(
            children: [
              // Glass Cube Effect
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: baseColor.withOpacity(0.15),
                      border: Border.all(
                        color: baseColor.withOpacity(0.8),
                        width: 1.5,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Letter and Glow
              Center(
                child: isSpecial 
                  ? Icon(key == 'DEL' ? Icons.backspace_outlined : Icons.check_circle_outline, size: 18, color: Colors.white)
                  : Text(
                      key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
