import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../services/lives_service.dart';
import '../services/score_service.dart';
import 'game_screen.dart';
import 'sprint_screen.dart';
import '../widgets/leaderboard_sheet.dart'; // 👈 TON NOUVEL IMPORT EST LÀ

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LivesService _livesService = LivesService();
  final ScoreService _scoreService = ScoreService();
  late final Stream<void> _timerStream;

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(const Duration(seconds: 1)).asBroadcastStream();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onModeTap(BuildContext context, GameLevel level) async {
    if (!_livesService.hasLives) {
      _showNoLivesDialog(context);
      return;
    }
    await _livesService.consumeLife();
    if (!mounted) return;
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => GameScreen(level: level),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) => setState(() {}));
  }

  void _showNoLivesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Plus de vies !',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('❤️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'Prochaine vie dans\n${_livesService.timeUntilNextLifeString}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _livesService.addLife();
                setState(() {});
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.purple, AppColors.pink]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    '📺 Regarder une pub → +1 vie',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _showChallengeDialog() {
    TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Entrer un code", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: codeController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: "Ex: BONJOUR",
            hintStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.purple)),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Annuler", style: TextStyle(color: AppColors.textSecondary))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
            onPressed: () {
              final code = codeController.text.trim().toUpperCase();
              if (code.length >= 7) {
                Navigator.pop(context);
                _startChallenge(code);
              }
            },
            child: const Text("C'est parti !", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _startChallenge(String code) async {
    if (!_livesService.hasLives) {
      _showNoLivesDialog(context);
      return;
    }
    await _livesService.consumeLife();
    if (!mounted) return;

    List<String> fixedLetters = code.split('');
    GameLevel level = GameLevel.debutant;
    if (fixedLetters.length == 8) level = GameLevel.intermediaire;
    if (fixedLetters.length >= 9) level = GameLevel.expert;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => GameScreen(level: level, fixedLetters: fixedLetters),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0535), AppColors.bg],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context), // On passe le context ici !
                const SizedBox(height: 16),
                _buildStreakBanner(),
                const SizedBox(height: 16),
                _buildBestScore(),
                const SizedBox(height: 16),
                _buildModeGrid(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 👇 L'EN-TÊTE MODIFIÉ AVEC LE BOUTON TROPHÉE 👇
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(text: 'Word', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.purple)),
                  TextSpan(text: 'Snap', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.cyan)),
                ],
              ),
            ),
            const Text(
              'LE JEU DE MOTS',
              style: TextStyle(fontSize: 9, color: AppColors.textSecondary, letterSpacing: 3),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏆 LE NOUVEAU BOUTON CLASSEMENT 🏆
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, 
                  backgroundColor: Colors.transparent, 
                  builder: (context) => const LeaderboardSheet(),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16, top: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface, // Fond légèrement sombre
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 8),
                  ],
                ),
                child: const Text('🏆', style: TextStyle(fontSize: 18)),
              ),
            ),
            
            // ❤️ LES VIES (Optimisé avec StreamBuilder)
            StreamBuilder<void>(
              stream: _timerStream,
              builder: (context, snapshot) {
                final currentLives = _livesService.lives;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('VIES', style: TextStyle(fontSize: 9, color: AppColors.textSecondary, letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(LivesService.maxLives, (i) {
                        final active = i < currentLives;
                        return Container(
                          margin: const EdgeInsets.only(left: 4),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: active ? const LinearGradient(colors: [Color(0xFFF472B6), AppColors.pink]) : null,
                            color: active ? null : AppColors.border,
                          ),
                        );
                      }),
                    ),
                    if (currentLives < LivesService.maxLives)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('+1 dans ${_livesService.timeUntilNextLifeString}', style: const TextStyle(fontSize: 9, color: AppColors.purple, fontWeight: FontWeight.w600)),
                      ),
                  ],
                );
              }
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStreakBanner() {
    final streak = _scoreService.streak;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x1FA855F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x40A855F7)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFFF97316), Color(0xFFFACC15)]),
            ),
            child: const Center(child: Text('🔥', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$streak', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.purple)),
              Text(streak == 1 ? 'jour de streak' : 'jours de streak', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              Text(streak >= 7 ? '🏆' : streak >= 3 ? '⭐' : '🎯', style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 2),
              Text(streak >= 7 ? 'Légendaire' : streak >= 3 ? 'En feu !' : 'Objectif 7j', style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBestScore() {
    final best = _scoreService.bestScore;
    final total = _scoreService.totalGames;
    
    if (best == 0) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Text('🏅', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MEILLEUR SCORE', style: TextStyle(fontSize: 9, color: AppColors.textSecondary, letterSpacing: 2)),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(colors: [AppColors.purple, AppColors.cyan]).createShader(bounds),
                child: Text('$best pts', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('PARTIES', style: TextStyle(fontSize: 9, color: AppColors.textSecondary, letterSpacing: 2)),
              Text('$total', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.cyan)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeGrid(BuildContext context) {
    return StreamBuilder<void>(
      stream: _timerStream,
      builder: (context, snapshot) {
        return Column(
          children: [
            GestureDetector(
          onTap: () => _onModeTap(context, GameLevel.debutant),
          child: _buildModeCard(
            icon: '☀️', name: 'Défi du Jour', desc: '7 lettres — 90 sec',
            gradient: const [Color(0xFF1A0535), Color(0x33A855F7)],
            borderColor: const Color(0x50A855F7), badge: 'NOUVEAU', fullWidth: true,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _onModeTap(context, GameLevel.debutant),
                child: _buildModeCard(
                  icon: '⚡', name: 'Classique', desc: '7 lettres — 90 sec',
                  gradient: const [Color(0x1222D3EE), Color(0x0622D3EE)],
                  borderColor: const Color(0x3022D3EE),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => _onModeTap(context, GameLevel.intermediaire),
                child: _buildModeCard(
                  icon: '⚔️', name: 'Duel', desc: '8 lettres — 75 sec',
                  gradient: const [Color(0x12F43F5E), Color(0x06F43F5E)],
                  borderColor: const Color(0x30F43F5E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SprintScreen()));
          },
          child: _buildModeCard(
            icon: '⏱️', name: 'Mode Sprint', desc: 'Contre-la-montre infini',
            gradient: const [Color(0x124ADE80), Color(0x064ADE80)],
            borderColor: const Color(0x304ADE80), fullWidth: true,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showChallengeDialog,
          child: _buildModeCard(
            icon: '🔑', name: 'Entrer un Code', desc: 'Rejoins le défi d\'un ami',
            gradient: const [Color(0x12FACC15), Color(0x06FACC15)],
            borderColor: const Color(0x30FACC15), fullWidth: true,
          ),
        ),
          ],
        );
      }
    );
  }

  Widget _buildModeCard({
    required String icon, required String name, required String desc,
    required List<Color> gradient, required Color borderColor,
    String? badge, bool fullWidth = false,
  }) {
    final hasLives = _livesService.hasLives;
    
    return Opacity(
      opacity: (hasLives || name == 'Mode Sprint') ? 1.0 : 0.5,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppColors.purple, AppColors.pink]),
                  ),
                ),
                const SizedBox(height: 8),
                Text('$icon $name', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.purple, AppColors.cyan]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badge, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            if (!hasLives && name != 'Mode Sprint')
              const Positioned(top: 0, right: 0, child: Text('❤️', style: TextStyle(fontSize: 16))),
          ],
        ),
      ),
    );
  }
}