import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/score_service.dart';
import '../services/language_service.dart';

class ProfileSheet extends StatelessWidget {
  const ProfileSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final scoreService = ScoreService();
    final langService = LanguageService();
    
    int bestScore = scoreService.bestScore;
    int totalGames = scoreService.totalGames;
    int totalScore = scoreService.totalScore;
    int avgScore = totalGames > 0 ? (totalScore / totalGames).round() : 0;
    int currentLevel = scoreService.currentLevel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Text(
            langService.translate('account').toUpperCase(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            'STATISTIQUES GLOBALES', // We can keep it hardcoded for now or use a translation if available
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, letterSpacing: 1),
          ),
          const SizedBox(height: 30),
          
          _buildStatRow(
            icon: '🏅', 
            title: langService.translate('best_score'), 
            value: '$bestScore', 
            color: AppColors.cyan
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            icon: '🎮', 
            title: 'PARTIES JOUÉES', 
            value: '$totalGames', 
            color: AppColors.purple
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            icon: '📊', 
            title: 'SCORE MOYEN', 
            value: '$avgScore', 
            color: Colors.orangeAccent
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            icon: '🗺️', 
            title: 'NIVEAU AVENTURE', 
            value: '$currentLevel', 
            color: Colors.greenAccent
          ),
          
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              langService.translate('cancel').toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatRow({required String icon, required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
