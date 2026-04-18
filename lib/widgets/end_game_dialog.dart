import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/score_service.dart';

class EndGameDialog extends StatefulWidget {
  final bool isWin;
  final String word;
  final int level;

  const EndGameDialog({
    super.key,
    required this.isWin,
    required this.word,
    this.level = 0,
  });

  @override
  State<EndGameDialog> createState() => _EndGameDialogState();
}

class _EndGameDialogState extends State<EndGameDialog> {
  final ScoreService _scoreService = ScoreService();
  bool _adWatched = false;

  void _watchAd() {
    // Simulation pub
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: AppColors.cardBg,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.cyan),
            SizedBox(height: 20),
            Text('Vidéo publicitaire...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context); // Fermer pub
      setState(() {
        _adWatched = true;
        _scoreService.addCoins(90); // +90 pour arriver à 100 total
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: widget.isWin ? Colors.green : Colors.red, width: 2),
          boxShadow: [
            BoxShadow(
              color: (widget.isWin ? Colors.green : Colors.red).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isWin ? 'VICTOIRE !' : 'DOMMAGE...',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: widget.isWin ? Colors.green : Colors.red,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Le mot était :',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              widget.word.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 24),
            
            if (widget.isWin) ...[
              const Text(
                'Récompense :',
                style: TextStyle(color: Colors.white70),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _adWatched ? '+100' : '+10',
                    style: const TextStyle(color: Colors.amber, fontSize: 36, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 8),
                  const Text('🪙', style: TextStyle(fontSize: 24)),
                ],
              ),
              const SizedBox(height: 24),
              if (!_adWatched)
                ElevatedButton.icon(
                  onPressed: _watchAd,
                  icon: const Icon(Icons.play_circle_filled, color: Colors.white),
                  label: const Text('x10 GAINS (PUB)', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
            ],
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (widget.isWin) {
                  _scoreService.unlockNextLevel();
                }
                Navigator.pop(context); // Retour à la carte
                Navigator.pop(context); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isWin ? Colors.green : Colors.white12,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                widget.isWin ? 'CONTINUER' : 'RÉESSAYER',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
