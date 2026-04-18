import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../services/lives_service.dart';
import '../services/score_service.dart';
import 'sprint_screen.dart';
import 'lingo_screen.dart';
import '../widgets/leaderboard_sheet.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/logo_cube.dart';
import '../widgets/shop_sheet.dart';
import 'lingo_map_screen.dart';
import '../services/daily_reward_service.dart';
import '../widgets/daily_reward_sheet.dart';

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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (DailyRewardService().canClaimToday()) {
        _showDailyReward();
      }
    });
  }

  void _showDailyReward() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DailyRewardSheet(),
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

  void _onModeTap(BuildContext context, Widget screen) async {
    if (!_livesService.hasLives) {
      _showNoLivesDialog(context);
      return;
    }
    await _livesService.consumeLife();
    if (!mounted) return;
    
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
      .then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F021A), Color(0xFF1A0535)],
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.purple.withOpacity(0.3),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withOpacity(0.2),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          SafeArea(
          child: Column(
            children: [
              _buildTopStats(),
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const SizedBox(height: 20),
                      _buildDashboard(),
                      const SizedBox(height: 30),
                      const Text(
                        "JOUER",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2),
                      ),
                      const SizedBox(height: 12),
                      _buildHeroCard(context, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LingoMapScreen()),
                        ).then((_) => setState(() {}));
                      }),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildSecondaryCard(context, "Sprint", "Contre-la-montre", '⚡', const [Color(0xFF0F766E), Color(0xFF14B8A6)], const SprintScreen())),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSecondaryCard(context, "Duel", "Multijoueur", '⚔️', const [Color(0xFF9F1239), Color(0xFFF43F5E)], null)), // Null = Coming Soon
                        ],
                      ),
                      const SizedBox(height: 40),
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

  Widget _buildTopStats() {
    return StreamBuilder<void>(
      stream: _timerStream,
      builder: (context, snapshot) {
        final currentLives = _livesService.lives;
        final coins = _scoreService.coins;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              // Vies
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x1F22D3EE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x4022D3EE)),
                ),
                child: Row(
                  children: [
                    const Text('❤️', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text('$currentLives', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Coins
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const ShopSheet(),
                  ).then((_) => setState(() {}));
                },
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
                      Text('$coins', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(width: 4),
                      const Icon(Icons.add_circle, size: 16, color: Colors.amber),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (currentLives < LivesService.maxLives)
                Text(
                  _livesService.timeUntilNextLifeString,
                  style: const TextStyle(fontSize: 12, color: AppColors.cyan, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildGiftButton() {
    bool hasReward = DailyRewardService().canClaimToday();
    return GestureDetector(
      onTap: _showDailyReward,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: hasReward ? AppColors.purple.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: hasReward ? AppColors.purple : Colors.white24),
          boxShadow: hasReward ? [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 10)] : [],
        ),
        child: Text(
          hasReward ? '🎁' : '📅',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      LogoCube(letter: 'L', color: AppColors.purple, size: 22),
                      LogoCube(letter: 'I', color: AppColors.purple, size: 22),
                      LogoCube(letter: 'N', color: AppColors.purple, size: 22),
                      LogoCube(letter: 'G', color: AppColors.purple, size: 22),
                      LogoCube(letter: 'O', color: AppColors.purple, size: 22),
                      const SizedBox(width: 4),
                      LogoCube(letter: 'S', color: AppColors.cyan, size: 22),
                      LogoCube(letter: 'N', color: AppColors.cyan, size: 22),
                      LogoCube(letter: 'A', color: AppColors.cyan, size: 22),
                      LogoCube(letter: 'P', color: AppColors.cyan, size: 22),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "L'ULTIME DÉFI LINGUISTIQUE",
                  style: TextStyle(fontSize: 9, color: AppColors.textSecondary, letterSpacing: 2.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16), // Espace ajouté ici pour aérer
          Row(
            children: [
              _buildIconButton(Icons.settings, () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const SettingsSheet(),
                );
              }),
              const SizedBox(width: 10),
              _buildIconButton(Icons.emoji_events, () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, 
                  backgroundColor: Colors.transparent, 
                  builder: (context) => const LeaderboardSheet(),
                );
              }, isGold: true),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, {bool isGold = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: isGold ? Colors.amber.withOpacity(0.5) : Colors.white24),
          boxShadow: isGold ? [BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 8)] : null,
        ),
        child: Icon(icon, size: 22, color: isGold ? Colors.amber : Colors.white),
      ),
    );
  }

  Widget _buildLivesBanner() {
    return StreamBuilder<void>(
      stream: _timerStream,
      builder: (context, snapshot) {
        final currentLives = _livesService.lives;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0x1F22D3EE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x4022D3EE)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('❤️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text('$currentLives / ${LivesService.maxLives}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              if (currentLives < LivesService.maxLives)
                Text(
                  '+1 vie dans ${_livesService.timeUntilNextLifeString}',
                  style: const TextStyle(fontSize: 12, color: AppColors.cyan, fontWeight: FontWeight.w600),
                )
              else
                const Text('Vies au maximum', style: TextStyle(fontSize: 12, color: AppColors.cyan)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDashboard() {
    final streak = _scoreService.streak;
    final best = _scoreService.bestScore;
    
    return Row(
      children: [
        // Carte Streak
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DÉFI QUOTIDIEN', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 8),
                        Text('$streak', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.orangeAccent)),
                        const Spacer(),
                        _buildGiftButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Carte Meilleur Score
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MEILLEUR SCORE', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('🏅', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 8),
                        Text('$best', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.cyan)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.purple.withOpacity(0.5), width: 1.5),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.purple.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.3), shape: BoxShape.circle),
                      child: const Text('🎯', style: TextStyle(fontSize: 28)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.purple, borderRadius: BorderRadius.circular(12)),
                      child: const Text('MODE AVENTURE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Lingo Snap', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 4),
                const Text('Complétez la saga des mots mystères.', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryCard(BuildContext context, String title, String subtitle, String icon, List<Color> gradient, Widget? screen) {
    bool isLocked = screen == null;
    return GestureDetector(
      onTap: screen != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 160, // Augmenté pour éviter les débordements
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: gradient[0].withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: gradient[0].withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: gradient[0].withOpacity(0.3), shape: BoxShape.circle),
                  child: Text(icon, style: const TextStyle(fontSize: 20)),
                ),
                const Spacer(),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                if (isLocked) 
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('BIENTÔT', style: TextStyle(color: gradient[0], fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}