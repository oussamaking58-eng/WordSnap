import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LeaderboardSheet extends StatefulWidget {
  const LeaderboardSheet({super.key});

  @override
  State<LeaderboardSheet> createState() => _LeaderboardSheetState();
}

class _LeaderboardSheetState extends State<LeaderboardSheet> {
  int _selectedTab = 0; // 0: MONDIAL, 1: LOCAL
  bool _isLoading = false;

  // Variables pour ton profil en bas
  String _myRank = "--";
  int _myBestScore = 0;

  List<Map<String, dynamic>>? _mondialCache;
  List<Map<String, dynamic>>? _localCache;

  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadDataForTab(0);
  }

  Future<void> _loadDataForTab(int index) async {
    setState(() {
      _selectedTab = index;
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('scores')
          .orderBy('score', descending: true)
          .limit(50);

      if (index == 1) {
        // Détection du pays pour l'onglet LOCAL
        String country =
            WidgetsBinding.instance.platformDispatcher.locale.countryCode ??
            'TN';
        query = query.where('country', isEqualTo: country);
      }

      final snapshot = await query.get();

      // On réinitialise ton rang avant de parcourir les résultats
      _myRank = "--";

      final results = snapshot.docs.asMap().entries.map((entry) {
        final data = entry.value.data() as Map<String, dynamic>;
        final bool isMe = data['userId'] == _myUid;
        final int rank = entry.key + 1; // Correction : on commence à 1, pas 0

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

      setState(() {
        if (index == 0) _mondialCache = results;
        if (index == 1) _localCache = results;
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur Leaderboard: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentList = _selectedTab == 0 ? _mondialCache : _localCache;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildTabs(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.cyan),
                  )
                : _buildList(currentList ?? []),
          ),
          _buildMyRankFooter(), // Ton footer dynamique
        ],
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
          _tabButton("MONDIAL 🌎", 0),
          const SizedBox(width: 10),
          _tabButton("LOCAL 📍", 1),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => _loadDataForTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purple : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.cyan : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          "Aucun score trouvé",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildUserRow(list[index]),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> player) {
    bool isMe = player['isMe'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isMe ? AppColors.purple.withOpacity(0.2) : AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isMe ? AppColors.cyan : Colors.transparent),
      ),
      child: Row(
        children: [
          Text(
            "#${player['rank']}",
            style: TextStyle(
              color: isMe ? AppColors.cyan : Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              player['name'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            "${player['score']}",
            style: const TextStyle(
              color: AppColors.pink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRankFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0525),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "MON RANG",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "#$_myRank",
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "MON RECORD",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$_myBestScore pts",
                style: const TextStyle(
                  color: AppColors.pink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
