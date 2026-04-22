import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../services/language_service.dart';
import '../services/matchmaking_service.dart';
import 'duel_game_screen.dart';

class DuelScreen extends StatefulWidget {
  const DuelScreen({super.key});

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> {
  final MatchmakingService _matchService = MatchmakingService();
  final LanguageService _langService = LanguageService();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _langService.addListener(_rebuild);
  }

  @override
  void dispose() {
    _langService.removeListener(_rebuild);
    _matchService.cancelSearch();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _startSearch() {
    setState(() => _isSearching = true);
    
    _matchService.findMatch(
      language: _langService.currentLanguage,
      onMatchFound: (matchId, targetWord, opponent) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DuelGameScreen(
                matchId: matchId,
                targetWord: targetWord,
                opponent: opponent,
              ),
            ),
          );
        }
      },
      onTimeout: () {
        if (mounted) {
          setState(() => _isSearching = false);
          _showNoOpponentDialog();
        }
      },
    );
  }

  void _showNoOpponentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0535).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.pink.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⌛', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              Text(
                _langService.translate('no_opponent_title'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                _langService.translate('no_opponent_body'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                _buildHeader(),
                const Spacer(),
                
                if (!_isSearching) ...[
                  Text(
                    _langService.translate('duel_mode'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _langService.translate('duel_subtitle'),
                    style: const TextStyle(color: AppColors.pink, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  const Spacer(),
                  _buildDuelCard(),
                  const Spacer(),
                  _buildStartButton(),
                ] else ...[
                  _buildSearchingUI(),
                ],
                
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Text(
            'BETA',
            style: TextStyle(color: AppColors.pink, fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildDuelCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CircleAvatar(radius: 35, backgroundColor: AppColors.purple, child: Text(_langService.translate('you'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              const Text('VS', style: TextStyle(color: AppColors.pink, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              const CircleAvatar(radius: 35, backgroundColor: Colors.white12, child: Icon(Icons.person, color: Colors.white54)),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            _langService.translate('duel_win_reward'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _startSearch,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.purple, AppColors.pink]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.pink.withValues(alpha: 0.3), blurRadius: 20)],
        ),
        child: Center(
          child: Text(
            _langService.translate('find_match'),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingUI() {
    return Column(
      children: [
        const SizedBox(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(
            color: AppColors.pink,
            strokeWidth: 8,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          _langService.translate('searching_opponent'),
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => setState(() => _isSearching = false),
          child: Text(_langService.translate('cancel'), style: const TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}
