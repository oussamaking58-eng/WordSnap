import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../services/score_service.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';

class EndGameDialog extends StatefulWidget {
  final bool isWin;
  final String word;
  final int level;
  final String? customMessage;

  const EndGameDialog({
    super.key,
    required this.isWin,
    required this.word,
    this.level = 0,
    this.customMessage,
  });

  @override
  State<EndGameDialog> createState() => _EndGameDialogState();
}

class _EndGameDialogState extends State<EndGameDialog> {
  final ScoreService _scoreService = ScoreService();
  late ConfettiController _confettiController;
  bool _adWatched = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.isWin) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

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
      if (!mounted) return;
      Navigator.pop(context); // Fermer pub
      setState(() {
        _adWatched = true;
        _scoreService.addCoins(90); // +90 pour arriver à 100 total
      });
    });
  }

  void _shareResult() {
    String text;
    if (widget.isWin) {
      text = widget.level > 0 
        ? "🏆 J'ai réussi le niveau ${widget.level} sur WordSnap ! 🎉 Le mot était : ${widget.word.toUpperCase()}"
        : "🏆 J'ai trouvé le mot ${widget.word.toUpperCase()} sur WordSnap ! 🎉";
    } else {
      text = "🕹️ Je joue à WordSnap ! Viens me défier ! 🚀";
    }
    
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: (widget.isWin ? Colors.green : Colors.red).withValues(alpha: 0.5), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white.withValues(alpha: 0.05),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.customMessage ?? (widget.isWin ? 'VICTOIRE !' : 'DOMMAGE...'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
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
                              widget.level == -1 ? '+200' : (_adWatched ? '+100' : '+10'),
                              style: const TextStyle(color: Colors.amber, fontSize: 36, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(width: 8),
                            const Text('🪙', style: TextStyle(fontSize: 24)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (widget.level != -1 && !_adWatched)
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
                            if (widget.level > 0) {
                              _scoreService.unlockNextLevel();
                            } else if (widget.level == -1) {
                              _scoreService.addCoins(200);
                            }
                          }
                          Navigator.pop(context); // Fermer le dialogue
                          Navigator.pop(context); // Retour à l'écran précédent
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isWin ? Colors.green : Colors.white12,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          widget.isWin 
                            ? (widget.level <= 0 ? 'MENU' : 'CONTINUER') 
                            : (widget.level == -1 ? 'RETOUR' : 'RÉESSAYER'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _shareResult,
                        icon: const Icon(Icons.share, color: Colors.white70, size: 18),
                        label: const Text('PARTAGER', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.isWin)
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              AppColors.cyan,
              AppColors.purple,
              AppColors.pink,
              Colors.amber,
              Colors.white,
            ],
            strokeWidth: 1,
            strokeColor: Colors.white,
          ),
      ],
    );
  }
}
