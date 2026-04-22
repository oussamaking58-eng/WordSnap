import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/daily_reward_service.dart';
import '../services/language_service.dart';

class DailyRewardSheet extends StatefulWidget {
  const DailyRewardSheet({super.key});

  @override
  State<DailyRewardSheet> createState() => _DailyRewardSheetState();
}

class _DailyRewardSheetState extends State<DailyRewardSheet> {
  final DailyRewardService _rewardService = DailyRewardService();
  final LanguageService _langService = LanguageService();

  @override
  void initState() {
    super.initState();
    _langService.addListener(_rebuild);
  }

  @override
  void dispose() {
    _langService.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool canClaim = _rewardService.canClaimToday();
    int currentDay = _rewardService.currentDay;

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
            _langService.translate('daily_reward_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            _langService.translate('daily_reward_subtitle'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 30),
          
          // Grille des 30 jours (Scrollable)
          SizedBox(
            height: 350,
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 0.8,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: 30,
              itemBuilder: (context, index) {
                int day = index + 1;
                bool isPast = day < currentDay;
                bool isToday = day == currentDay;
                bool isFuture = day > currentDay;
                final reward = _rewardService.getRewardForDay(day);

                return _buildRewardNode(day, reward, isPast, isToday, isFuture);
              },
            ),
          ),
          
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: canClaim ? () {
              setState(() {
                _rewardService.claimReward();
              });
              Navigator.pop(context);
              _showSuccessDialog();
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              disabledBackgroundColor: Colors.white12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              canClaim ? _langService.translate('claim_reward') : _langService.translate('come_back_tomorrow'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRewardNode(int day, DailyReward reward, bool isPast, bool isToday, bool isFuture) {
    Color accentColor = AppColors.purple;
    if (reward.type == RewardType.mystery) accentColor = Colors.amber;
    if (reward.type == RewardType.infiniteLives) accentColor = AppColors.cyan;

    return Container(
      decoration: BoxDecoration(
        color: isToday ? accentColor.withValues(alpha: 0.2) : (isPast ? Colors.white10 : Colors.white.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? accentColor : (isPast ? Colors.green.withValues(alpha: 0.5) : Colors.white12),
          width: isToday ? 2 : 1,
        ),
        boxShadow: isToday ? [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 8)] : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'J$day',
            style: TextStyle(color: isFuture ? Colors.white24 : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          _getRewardIcon(reward.type, isFuture ? Colors.white24 : accentColor),
          const SizedBox(height: 4),
          FittedBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                reward.label,
                style: TextStyle(color: isFuture ? Colors.white24 : Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          if (isPast)
            const Icon(Icons.check_circle, color: Colors.green, size: 14),
        ],
      ),
    );
  }

  Widget _getRewardIcon(RewardType type, Color color) {
    switch (type) {
      case RewardType.coins: return Icon(Icons.monetization_on, color: color, size: 20);
      case RewardType.hints: return Icon(Icons.lightbulb, color: color, size: 20);
      case RewardType.infiniteLives: return Icon(Icons.timer, color: color, size: 20);
      case RewardType.mystery: return Icon(Icons.card_giftcard, color: color, size: 20);
    }
  }

  void _showSuccessDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_langService.translate('reward_claimed')),
        backgroundColor: Colors.green,
      ),
    );
  }
}
