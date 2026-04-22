import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import '../theme/app_theme.dart';
import '../services/language_service.dart';
import '../services/season_service.dart';
import 'season_rewards_view.dart';

class LeaderboardSheet extends StatefulWidget {
  const LeaderboardSheet({super.key});

  @override
  State<LeaderboardSheet> createState() => _LeaderboardSheetState();
}

class _LeaderboardSheetState extends State<LeaderboardSheet> {
  int _selectedTab = 0; // 0: MONDIAL, 1: LOCAL
  bool _isLoading = false;
  final LanguageService _langService = LanguageService();
  final SeasonService _seasonService = SeasonService();

  // Variables pour ton profil en bas
  String _myRank = "--";
  int _myBestScore = 0;

  List<Map<String, dynamic>>? _mondialCache;
  List<Map<String, dynamic>>? _localCache;

  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _langService.addListener(_rebuild);
    _loadDataForTab(0);
  }

  @override
  void dispose() {
    _langService.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDataForTab(int index) async {
    setState(() {
      _selectedTab = index;
      _isLoading = true;
    });

    try {
      // Query specific to current season
      Query query = FirebaseFirestore.instance
          .collection('seasons')
          .doc(_seasonService.currentSeasonId)
          .collection('scores')
          .orderBy('score', descending: true)
          .limit(50);

      if (index == 1) {
        String country = WidgetsBinding.instance.platformDispatcher.locale.countryCode ?? 'TN';
        query = query.where('country', isEqualTo: country);
      }

      final snapshot = await query.get();
      _myRank = "--";

      final results = snapshot.docs.asMap().entries.map((entry) {
        final data = entry.value.data() as Map<String, dynamic>;
        final bool isMe = data['userId'] == _myUid;
        final int rank = entry.key + 1;

        if (isMe) {
          _myRank = rank.toString();
          _myBestScore = data['score'] ?? 0;
        }

        return {
          'rank': rank,
          'name': data['name'] ?? 'Joueur',
          'score': data['score'] ?? 0,
          'isMe': isMe,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        if (index == 0) _mondialCache = results;
        if (index == 1) _localCache = results;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        print("Erreur Leaderboard: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentList = _selectedTab == 0 ? _mondialCache : _localCache;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              _buildHandle(),
              const SizedBox(height: 10),
              _buildSeasonHeader(),
              _buildTabs(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.cyan),
                      )
                    : _buildList(currentList ?? []),
              ),
              _buildMyRankFooter(),
            ],
          ),
        ),
      ),
    );
  }

  void _showRewards(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const SeasonRewardsView(),
    );
  }

  Widget _buildSeasonHeader() {
    return GestureDetector(
      onTap: () => _showRewards(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars, color: Colors.amber, size: 16),
            const SizedBox(width: 8),
            Column(
              children: [
                Text(
                  _seasonService.currentSeasonName,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                Text(
                  _seasonService.timeLeft.toUpperCase(),
                  style: const TextStyle(color: AppColors.cyan, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.card_giftcard, color: Colors.amber, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _tabButton("${_langService.translate('mondial')} 🌎", 0),
          const SizedBox(width: 10),
          _tabButton("${_langService.translate('local')} 📍", 1),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => _loadDataForTab(index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.cyan : Colors.white12,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: isSelected ? AppColors.purple.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          _langService.translate('no_scores'),
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    final top3 = list.take(3).toList();
    final rest = list.skip(3).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (top3.isNotEmpty) _buildPodium(top3),
        const SizedBox(height: 20),
        ...rest.map((player) => _buildUserRow(player)),
      ],
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> top3) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top3.length > 1) _buildPodiumItem(top3[1], 2, 70), // 2nd
          _buildPodiumItem(top3[0], 1, 90), // 1st
          if (top3.length > 2) _buildPodiumItem(top3[2], 3, 65), // 3rd
        ],
      ),
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> player, int rank, double size) {
    Color medalColor = rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey[300]! : Colors.orangeAccent);
    bool isMe = player['isMe'];

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (rank == 1)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Container(
                    width: size + 20,
                    height: size + 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.2 * value),
                          blurRadius: 20 * value,
                          spreadRadius: 5 * value,
                        ),
                      ],
                    ),
                  );
                },
              ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: medalColor, width: 3),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    medalColor.withValues(alpha: 0.4),
                    medalColor.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(rank == 1 ? "🥇" : (rank == 2 ? "🥈" : "🥉"), style: TextStyle(fontSize: size * 0.4)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          player['name'],
          style: TextStyle(
            color: isMe ? AppColors.cyan : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: rank == 1 ? 14 : 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          "${player['score']}",
          style: TextStyle(
            color: AppColors.pink,
            fontWeight: FontWeight.w900,
            fontSize: rank == 1 ? 18 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildUserRow(Map<String, dynamic> player) {
    bool isMe = player['isMe'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isMe ? AppColors.cyan : Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: isMe ? AppColors.purple.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    "${player['rank']}",
                    style: TextStyle(
                      color: isMe ? AppColors.cyan : Colors.white54,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    player['name'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  "${player['score']}",
                  style: const TextStyle(color: AppColors.pink, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyRankFooter() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            color: Colors.white.withValues(alpha: 0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_langService.translate('rank').toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text("#$_myRank", style: const TextStyle(color: AppColors.cyan, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_langService.translate('best_score').toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text("$_myBestScore pts", style: const TextStyle(color: AppColors.pink, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
