import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../services/score_service.dart';
import '../services/language_service.dart';

class ShopSheet extends StatefulWidget {
  const ShopSheet({super.key});

  @override
  State<ShopSheet> createState() => _ShopSheetState();
}

class _ShopSheetState extends State<ShopSheet> {
  final ScoreService _scoreService = ScoreService();
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

  void _watchAd() {
    // Simulation d'une publicité
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: Text(_langService.translate('ad_title'), style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.cyan),
              const SizedBox(height: 20),
              Text(_langService.translate('ad_body'), style: const TextStyle(color: Colors.white70)),
            ],
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pop(context); // Fermer le dialogue de pub
      setState(() {
        _scoreService.addCoins(50);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_langService.translate('reward_claimed')),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _buyCoins(int amount, String price) {
    _showPurchaseDialog(
      title: _langService.translate('purchase_title'),
      body: _langService.translate('purchase_body')
          .replaceAll('{amount}', '$amount 🪙')
          .replaceAll('{price}', price),
      onConfirm: () {
        setState(() => _scoreService.addCoins(amount));
        _showSuccessSnackBar(_langService.translate('purchase_success').replaceAll('{amount}', '$amount 🪙'));
      },
    );
  }

  void _buyInfiniteLives(Duration duration, String price) {
    _showPurchaseDialog(
      title: _langService.translate('booster_title'),
      body: _langService.translate('booster_body')
          .replaceAll('{hours}', '${duration.inHours}')
          .replaceAll('{price}', price),
      onConfirm: () {
        setState(() => _scoreService.addInfiniteLives(duration));
        _showSuccessSnackBar(_langService.translate('booster_success').replaceAll('{hours}', '${duration.inHours}'));
      },
    );
  }

  void _showPurchaseDialog({required String title, required String body, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(body, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_langService.translate('cancel'), style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(_langService.translate('confirm'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.purple),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                  _langService.translate('shop_menu'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_langService.translate('balance')} : ${_scoreService.coins} 🪙',
                  style: const TextStyle(fontSize: 18, color: AppColors.cyan, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                
                Expanded(
                  child: ListView(
                    children: [
                      _sectionTitle(_langService.translate('boosters')),
                      _buildShopItem(
                        icon: Icons.timer,
                        title: _langService.translate('infinite_lives_short'),
                        reward: _langService.translate('infinite_lives_2h'),
                        actionText: '1.49 €',
                        color: Colors.orange,
                        onTap: () => _buyInfiniteLives(const Duration(hours: 2), '1.49 €'),
                      ),
                      const SizedBox(height: 12),
                      _buildShopItem(
                        icon: Icons.all_inclusive,
                        title: _langService.translate('infinite_lives_long'),
                        reward: _langService.translate('infinite_lives_24h'),
                        actionText: '4.99 €',
                        color: Colors.redAccent,
                        onTap: () => _buyInfiniteLives(const Duration(hours: 24), '4.99 €'),
                      ),
                      const SizedBox(height: 24),
                      
                      _sectionTitle(_langService.translate('coins')),
                      _buildShopItem(
                        icon: Icons.ondemand_video,
                        title: _langService.translate('watch_ad_menu'),
                        reward: '+50 🪙',
                        actionText: _langService.translate('free'),
                        color: Colors.green,
                        onTap: _watchAd,
                      ),
                      const SizedBox(height: 12),
                      _buildShopItem(
                        icon: Icons.monetization_on,
                        title: _langService.translate('small_pack'),
                        reward: '+500 🪙',
                        actionText: '0.99 €',
                        color: AppColors.purple,
                        onTap: () => _buyCoins(500, '0.99 €'),
                      ),
                      const SizedBox(height: 12),
                      _buildShopItem(
                        icon: Icons.stars,
                        title: _langService.translate('medium_pack'),
                        reward: '+1500 🪙',
                        actionText: '1.99 €',
                        color: AppColors.pink,
                        onTap: () => _buyCoins(1500, '1.99 €'),
                      ),
                      const SizedBox(height: 12),
                      _buildShopItem(
                        icon: Icons.diamond,
                        title: _langService.translate('large_pack'),
                        reward: '+4000 🪙',
                        actionText: '3.99 €',
                        color: AppColors.cyan,
                        onTap: () => _buyCoins(4000, '3.99 €'),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildShopItem({
    required IconData icon,
    required String title,
    required String reward,
    required String actionText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white.withValues(alpha: 0.05),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(reward, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)],
                    ),
                    child: Text(
                      actionText,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
