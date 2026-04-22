import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SeasonRewardsView extends StatelessWidget {
  const SeasonRewardsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "RÉCOMPENSES DE SAISON",
            style: TextStyle(
              color: AppColors.purple,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "SAISON 1 : L'ÉVEIL CYBER",
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 32),
          _buildRewardItem(
            rank: "TOP 1",
            reward: "5000 🪙 + Badge Fondateur Gold",
            color: Colors.amber,
          ),
          _buildRewardItem(
            rank: "TOP 10",
            reward: "2000 🪙 + Badge Elite Silver",
            color: Colors.blueGrey[200]!,
          ),
          _buildRewardItem(
            rank: "TOP 100",
            reward: "500 🪙 + Badge Participant Bronze",
            color: Colors.brown[300]!,
          ),
          const SizedBox(height: 24),
          const Text(
            "Les récompenses seront distribuées dans 12 jours.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRewardItem({required String rank, required String reward, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rank,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              reward,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
