import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/score_service.dart';

class ShopSheet extends StatefulWidget {
  const ShopSheet({super.key});

  @override
  State<ShopSheet> createState() => _ShopSheetState();
}

class _ShopSheetState extends State<ShopSheet> {
  final ScoreService _scoreService = ScoreService();

  void _watchAd() {
    // Simulation d'une publicité
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: Text('Publicité', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.cyan),
              SizedBox(height: 20),
              Text('Lecture de la vidéo...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context); // Fermer le dialogue de pub
      setState(() {
        _scoreService.addCoins(50);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci ! Vous avez gagné 50 🪙'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _buyCoins(int amount, String price) {
    // Simulation d'un achat in-app
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: const Text('Achat In-App (Simulation)', style: TextStyle(color: Colors.white)),
          content: Text('Voulez-vous simuler l\'achat de $amount 🪙 pour $price ?', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _scoreService.addCoins(amount);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Achat réussi ! +$amount 🪙'),
                    backgroundColor: AppColors.purple,
                  ),
                );
              },
              child: const Text('Acheter', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
          const Text(
            'BOUTIQUE',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Solde actuel : ${_scoreService.coins} 🪙',
            style: const TextStyle(fontSize: 18, color: AppColors.cyan, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 32),
          
          // Option Pub
          _buildShopItem(
            icon: Icons.ondemand_video,
            title: 'Regarder une vidéo',
            reward: '+50 🪙',
            actionText: 'GRATUIT',
            color: Colors.green,
            onTap: _watchAd,
          ),
          const SizedBox(height: 16),
          
          // Option Achat 1
          _buildShopItem(
            icon: Icons.monetization_on,
            title: 'Petit Pack',
            reward: '+500 🪙',
            actionText: '0.99 €',
            color: AppColors.purple,
            onTap: () => _buyCoins(500, '0.99 €'),
          ),
          const SizedBox(height: 16),
          
          // Option Achat 2
          _buildShopItem(
            icon: Icons.diamond,
            title: 'Gros Pack',
            reward: '+2000 🪙',
            actionText: '2.99 €',
            color: AppColors.cyan,
            onTap: () => _buyCoins(2000, '2.99 €'),
          ),
          const SizedBox(height: 40),
        ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
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
              ),
              child: Text(
                actionText,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
