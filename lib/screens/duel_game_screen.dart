import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';

import '../services/language_service.dart';
import '../services/matchmaking_service.dart';
import '../services/word_service.dart';
import '../theme/app_theme.dart';
import '../widgets/end_game_dialog.dart';
import '../services/sound_service.dart';

enum LetterState { initial, notInWord, inWordWrongSpot, inWordCorrectSpot }

class DuelGameScreen extends StatefulWidget {
  final String matchId;
  final String targetWord;
  final Map<String, dynamic> opponent;

  const DuelGameScreen({
    super.key,
    required this.matchId,
    required this.targetWord,
    required this.opponent,
  });

  @override
  State<DuelGameScreen> createState() => _DuelGameScreenState();
}

class _DuelGameScreenState extends State<DuelGameScreen> {
  int _currentAttempt = 0;
  late List<List<String>> _grid;
  late List<List<LetterState>> _states;
  final Map<String, LetterState> _keyboardStates = {};
  
  final LanguageService _langService = LanguageService();
  final MatchmakingService _matchService = MatchmakingService();
  
  int _opponentScore = 0;
  int _opponentRow = 0;
  bool _isGameOver = false;

  StreamSubscription? _matchSub;

  @override
  void initState() {
    super.initState();
    _initGame();
    _listenToMatch();
  }

  void _initGame() {
    _grid = List.generate(6, (_) => List.filled(5, ''));
    _states = List.generate(6, (_) => List.filled(5, LetterState.initial));
  }

  void _listenToMatch() {
    _matchSub = FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final opponentUid = widget.opponent['userId'];
        
        setState(() {
          _opponentScore = data['scores']?[opponentUid] ?? 0;
          _opponentRow = data['currentRow']?[opponentUid] ?? 0;
        });

        // Vérifier si quelqu'un a gagné ou abandonné
        if (data['status'] == 'finished' && data['winner'] != null) {
          bool amIWinner = data['winner'] == _matchService.currentUserId;
          String? abandonedBy = data['abandonedBy'];
          _handleGameOver(amIWinner, abandonedBy: abandonedBy);
        }
      }
    });
  }

  @override
  void dispose() {
    _matchSub?.cancel();
    super.dispose();
  }

  void _onKeyPressed(String key) {
    if (_isGameOver || _currentAttempt >= 6) return;

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
      SoundService().playTick();
    }
  }

  void _deleteLetter() {
    for (int i = 4; i >= 0; i--) {
      if (_grid[_currentAttempt][i].isNotEmpty) {
        _grid[_currentAttempt][i] = '';
        HapticFeedback.lightImpact();
        SoundService().playTick();
        break;
      }
    }
  }

  void _submitGuess() {
    String guess = _grid[_currentAttempt].join('');
    if (guess.length < 5) return;

    // Vérifier le mot dans le dictionnaire
    if (!WordService().isValidWord(guess, _langService.currentLanguage)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_langService.translate('not_in_dict'))),
      );
      SoundService().playError();
      return;
    }

    _evaluateGuess(guess);
  }

  void _evaluateGuess(String guess) {
    String target = widget.targetWord.toUpperCase();
    List<LetterState> rowStates = List.filled(5, LetterState.notInWord);
    List<bool> targetUsed = List.filled(5, false);

    // 1. Correct spot
    for (int i = 0; i < 5; i++) {
      if (guess[i] == target[i]) {
        rowStates[i] = LetterState.inWordCorrectSpot;
        targetUsed[i] = true;
      }
    }

    // 2. Wrong spot
    for (int i = 0; i < 5; i++) {
      if (rowStates[i] == LetterState.initial || rowStates[i] == LetterState.notInWord) {
        for (int j = 0; j < 5; j++) {
          if (!targetUsed[j] && guess[i] == target[j]) {
            rowStates[i] = LetterState.inWordWrongSpot;
            targetUsed[j] = true;
            break;
          }
        }
      }
    }

    setState(() {
      _states[_currentAttempt] = rowStates;
      // Update keyboard
      for (int i = 0; i < 5; i++) {
        String char = guess[i];
        if (_keyboardStates[char] != LetterState.inWordCorrectSpot) {
          _keyboardStates[char] = rowStates[i];
        }
      }
      _currentAttempt++;
      
      // Update score and row in Firebase
      _matchService.updateProgress(widget.matchId, _currentAttempt * 10, _currentAttempt);
    });

    if (guess == target) {
      _handleGameOver(true);
    } else if (_currentAttempt >= 6) {
      _handleGameOver(false);
    }
  }
  void _handleGameOver(bool isWin, {String? abandonedBy}) {
    if (_isGameOver) return;
    _isGameOver = true;
    
    if (isWin && abandonedBy == null) {
      _matchService.declareWinner(widget.matchId);
    }

    String message = isWin ? _langService.translate('win') : _langService.translate('lose');
    if (abandonedBy != null) {
      if (abandonedBy == _matchService.currentUserId) {
         message = _langService.translate('you_abandoned');
      } else {
         message = _langService.translate('opponent_abandoned');
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EndGameDialog(
        isWin: isWin,
        level: -1, // -1 for Duel mode
        word: widget.targetWord,
        customMessage: message,
      ),
    );
  }

  void _onQuit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0535),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_langService.translate('cancel'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(_langService.translate('confirm_abandon') ?? "Voulez-vous vraiment abandonner la partie ?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_langService.translate('no') ?? "NON", style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              _matchService.abandonMatch(widget.matchId);
            },
            child: Text(_langService.translate('yes_abandon') ?? "OUI, ABANDONNER", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
           // Fond (Réutiliser le style)
           Positioned.fill(child: Container(decoration: const BoxDecoration(color: Color(0xFF0F021A)))),
           
           SafeArea(
             child: Column(
               children: [
                 _buildTopBar(),
                 Expanded(child: _buildGrid()),
                 _buildKeyboard(),
               ],
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _onQuit,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)),
              child: const Icon(Icons.close, color: Colors.white70, size: 20),
            ),
          ),
          const Spacer(),
          _playerInfo(_langService.translate('you'), _currentAttempt * 10, true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Text('VS', style: TextStyle(color: AppColors.pink, fontWeight: FontWeight.w900, fontSize: 24, fontStyle: FontStyle.italic, letterSpacing: -2)),
                Container(width: 40, height: 2, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.cyan, AppColors.pink]))),
              ],
            ),
          ),
          _playerInfo(widget.opponent['name'], _opponentScore, false, rowProgress: _opponentRow),
          const Spacer(),
          const SizedBox(width: 36), // Balanced
        ],
      ),
    );
  }

  Widget _playerInfo(String name, int score, bool isMe, {int rowProgress = 0}) {
    return Column(
      children: [
        Container(
          width: 45, height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: isMe ? AppColors.cyan : Colors.white24, width: 2),
            boxShadow: [
              if (isMe) BoxShadow(color: AppColors.cyan.withValues(alpha: 0.3), blurRadius: 10),
            ],
          ),
          child: Center(
            child: Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 8),
        Text(name.toUpperCase(), style: TextStyle(color: isMe ? AppColors.cyan : Colors.white54, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        Text('$score pts', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        if (!isMe) ...[
          const SizedBox(height: 5),
          _buildOpponentGhostGrid(rowProgress),
        ],
      ],
    );
  }

  Widget _buildOpponentGhostGrid(int rowProgress) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(6, (r) => Container(
        width: 6, height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: r < rowProgress ? AppColors.pink : Colors.white12,
          borderRadius: BorderRadius.circular(1),
        ),
      )),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (r) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (c) => _buildCell(r, c)),
        )),
      ),
    );
  }

  Widget _buildCell(int r, int c) {
    String char = _grid[r][c];
    LetterState state = _states[r][c];
    
    Color bgColor = Colors.white.withValues(alpha: 0.05);
    Color borderColor = Colors.white.withValues(alpha: 0.1);
    Color shadowColor = Colors.transparent;
    
    if (state == LetterState.notInWord) {
      bgColor = Colors.white.withValues(alpha: 0.05);
      borderColor = Colors.white24;
    }
    if (state == LetterState.inWordWrongSpot) {
      bgColor = Colors.amber.withValues(alpha: 0.2);
      borderColor = Colors.amber;
      shadowColor = Colors.amber.withValues(alpha: 0.3);
    }
    if (state == LetterState.inWordCorrectSpot) {
      bgColor = Colors.green.withValues(alpha: 0.2);
      borderColor = Colors.green;
      shadowColor = Colors.green.withValues(alpha: 0.3);
    }

    return Container(
      width: 52, height: 52,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          if (shadowColor != Colors.transparent) BoxShadow(color: shadowColor, blurRadius: 10),
        ],
      ),
      child: Center(
        child: Text(
          char,
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    final List<List<String>> keys = [
      ['A', 'Z', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['Q', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M'],
      ['ENTER', 'W', 'X', 'C', 'V', 'B', 'N', 'DEL'],
    ];

    return Container(
      padding: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
      child: Column(
        children: keys.map((row) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) => _buildKey(key)).toList(),
        )).toList(),
      ),
    );
  }

  Widget _buildKey(String key) {
    LetterState state = _keyboardStates[key] ?? LetterState.initial;
    double width = 34;
    if (key == 'ENTER' || key == 'DEL') width = 58;

    Color bgColor = Colors.white.withValues(alpha: 0.08);
    Color textColor = Colors.white;
    
    if (state == LetterState.notInWord) {
      bgColor = Colors.black45;
      textColor = Colors.white24;
    }
    if (state == LetterState.inWordWrongSpot) bgColor = Colors.amber.withValues(alpha: 0.5);
    if (state == LetterState.inWordCorrectSpot) bgColor = Colors.green.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () => _onKeyPressed(key),
      child: Container(
        width: width, height: 48,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Center(
          child: Text(
            key == 'DEL' ? '⌫' : key,
            style: TextStyle(color: textColor, fontSize: key.length > 1 ? 10 : 14, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}
