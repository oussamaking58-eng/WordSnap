import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../services/lives_service.dart';
import '../services/score_service.dart';
import 'classic_lingo_screen.dart';
import 'duel_screen.dart';
import '../widgets/leaderboard_sheet.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/logo_cube.dart';
import '../widgets/shop_sheet.dart';
import 'lingo_map_screen.dart';
import '../services/daily_reward_service.dart';
import '../widgets/daily_reward_sheet.dart';
import '../services/language_service.dart';
import 'lingo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LivesService _livesService = LivesService();
  final ScoreService _scoreService = ScoreService();
  final LanguageService _langService = LanguageService();
  late final Stream<void> _timerStream;
  List<String> _dynamicNews = [];

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(const Duration(seconds: 1)).asBroadcastStream();
    
    // Écouter le changement de langue pour reconstruire l'accueil
    _langService.addListener(_onLanguageChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (DailyRewardService().canClaimToday()) {
        _showDailyReward();
      }
      _fetchDynamicNews();
    });
  }

  Future<void> _fetchDynamicNews() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('leaderboard')
          .orderBy('score', descending: true)
          .limit(3)
          .get();
      
      if (mounted) {
        setState(() {
          _dynamicNews = snapshot.docs.map((doc) {
            final name = doc.data()['name'] ?? 'Inconnu';
            final score = doc.data()['score'] ?? 0;
            return "FÉLICITATIONS À $name QUI DOMINE LE CLASSEMENT AVEC $score POINTS !";
          }).toList();
        });
      }
    } catch (e) {
      // Fallback si Firestore échoue
    }
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _langService.removeListener(_onLanguageChanged);
    super.dispose();
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
          // Background Glows
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.purple.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: 0.08),
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
                      Text(
                        _langService.translate('play_menu'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2),
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
                          Expanded(child: _buildSecondaryCard(context, _langService.translate('classic_mode'), _langService.translate('classic_subtitle'), '🅰️', const [Color(0xFF0F766E), Color(0xFF14B8A6)], ClassicLingoScreen())),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSecondaryCard(context, _langService.translate('duel_mode'), _langService.translate('duel_subtitle'), '⚔️', const [Color(0xFF9F1239), Color(0xFFF43F5E)], DuelScreen())),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSecondaryCard(
                        context, 
                        _langService.translate('daily_reward'), 
                        'MOT UNIQUE DU JOUR', 
                        '📅', 
                        const [Color(0xFF374151), Color(0xFF1F2937)], 
                        LingoScreen(level: -2, wordLength: 6, maxAttempts: 6, difficulty: 'DAILY')
                      ),
                      const SizedBox(height: 30),
                      Text(
                        _langService.translate('shop_menu'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2),
                      ),
                      const SizedBox(height: 12),
                      _buildShopCard(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              _buildNewsTicker(),
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
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
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
          color: hasReward ? AppColors.purple.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: hasReward ? AppColors.purple : Colors.white24),
          boxShadow: hasReward ? [BoxShadow(color: AppColors.purple.withValues(alpha: 0.3), blurRadius: 10)] : [],
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
                      LogoCube(letter: 'L', color: AppColors.purple, size: 28),
                      LogoCube(letter: 'I', color: AppColors.purple, size: 28),
                      LogoCube(letter: 'N', color: AppColors.purple, size: 28),
                      LogoCube(letter: 'G', color: AppColors.purple, size: 28),
                      LogoCube(letter: 'O', color: AppColors.purple, size: 28),
                      const SizedBox(width: 8),
                      LogoCube(letter: 'S', color: AppColors.cyan, size: 28),
                      LogoCube(letter: 'N', color: AppColors.cyan, size: 28),
                      LogoCube(letter: 'A', color: AppColors.cyan, size: 28),
                      LogoCube(letter: 'P', color: AppColors.cyan, size: 28),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _langService.translate('app_subtitle'),
                    style: const TextStyle(
                      fontSize: 8, 
                      color: AppColors.textSecondary, 
                      letterSpacing: 3, 
                      fontWeight: FontWeight.w900
                    ),
                  ),
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
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: isGold ? Colors.amber.withValues(alpha: 0.5) : Colors.white24),
          boxShadow: isGold ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.2), blurRadius: 8)] : null,
        ),
        child: Icon(icon, size: 22, color: isGold ? Colors.amber : Colors.white),
      ),
    );
  }

  Widget _buildLivesBanner() {
    return StreamBuilder<int>(
      stream: _livesService.livesStream,
      initialData: _livesService.lives,
      builder: (context, snapshot) {
        final currentLives = snapshot.data ?? LivesService.maxLives;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.white.withValues(alpha: 0.05),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('❤️', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text('$currentLives / ${LivesService.maxLives}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    if (currentLives < LivesService.maxLives)
                      Text(
                        '+1 vie dans ${_livesService.timeUntilNextLifeString}',
                        style: const TextStyle(fontSize: 10, color: AppColors.cyan, fontWeight: FontWeight.w600),
                      )
                    else
                      const Text('Vies au maximum', style: TextStyle(fontSize: 10, color: AppColors.cyan)),
                  ],
                ),
              ),
            ),
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
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.1), blurRadius: 15),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_langService.translate('daily_reward'), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
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
        ),
        const SizedBox(width: 16),
        // Carte Meilleur Score
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppColors.cyan.withValues(alpha: 0.1), blurRadius: 15),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_langService.translate('best_score'), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
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
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppColors.purple.withValues(alpha: 0.2), blurRadius: 20),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.5), width: 2),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.purple.withValues(alpha: 0.2),
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
                        decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.3), shape: BoxShape.circle),
                        child: const Text('🎯', style: TextStyle(fontSize: 28)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.purple,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.5), blurRadius: 8)],
                        ),
                        child: Text(_langService.translate('adventure_mode'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Lingo Snap'.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 28, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 4,
                      shadows: [Shadow(color: AppColors.purple, blurRadius: 10)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_langService.translate('adventure_subtitle'), style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withValues(alpha: 0.15),
            Colors.orange.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => ShopSheet(),
            ).then((_) => setState(() {}));
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.redeem, color: Colors.amber, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _langService.translate('shop_menu'),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _langService.translate('shop_subtitle'),
                        style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.amber),
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
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isLocked) BoxShadow(color: gradient[0].withValues(alpha: 0.2), blurRadius: 15),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLocked ? Colors.white.withValues(alpha: 0.02) : gradient[0].withValues(alpha: 0.1),
                border: Border.all(color: isLocked ? Colors.white12 : gradient[0].withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: isLocked ? Colors.white10 : gradient[0].withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: Text(icon, style: TextStyle(fontSize: 20, color: isLocked ? Colors.white24 : Colors.white)),
                  ),
                  const Spacer(),
                  Text(
                    title.toUpperCase(), 
                    style: TextStyle(
                      color: isLocked ? Colors.white24 : Colors.white, 
                      fontSize: 16, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 1
                    )
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle, 
                    style: TextStyle(
                      color: isLocked ? Colors.white12 : Colors.white60, 
                      fontSize: 9, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                  if (isLocked) 
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_langService.translate('coming_soon'), style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsTicker() {
    final List<String> messages = [
      ..._dynamicNews,
      _langService.translate('news_1').replaceAll('{name}', 'PLAYER_X').replaceAll('{level}', '42'),
      _langService.translate('news_2').replaceAll('{days}', '12'),
      _langService.translate('news_3'),
    ];
    
    return Container(
      width: double.infinity,
      height: 35,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: const Border(top: BorderSide(color: AppColors.cyan, width: 0.5)),
      ),
      child: ClipRect(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: -1.0),
          duration: const Duration(seconds: 20),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(MediaQuery.of(context).size.width * value, 0),
              child: child,
            );
          },
          onEnd: () {
            // This is a simple trick to loop: rebuild when animation ends
            setState(() {});
          },
          child: OverflowBox(
            maxWidth: double.infinity,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: messages.map((m) => Padding(
                padding: const EdgeInsets.only(right: 100),
                child: Text(
                  m.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              )).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
