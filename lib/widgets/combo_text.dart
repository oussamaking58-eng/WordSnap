import 'package:flutter/material.dart';

class ComboText extends StatelessWidget {
  final int comboCount;

  const ComboText({super.key, required this.comboCount});

  @override
  Widget build(BuildContext context) {
    // Si pas de combo (moins de 2 mots de suite), on ne montre rien
    if (comboCount < 2) return const SizedBox.shrink();

    // L'animation "Elastique" qui donne beaucoup de satisfaction
    return TweenAnimationBuilder<double>(
      // Le ValueKey est la magie : il force l'animation à rejouer à chaque nouveau score !
      key: ValueKey(comboCount), 
      tween: Tween<double>(begin: 0.2, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut, // L'effet de rebond
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Text(
            '🔥 COMBO x$comboCount !',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: Colors.amberAccent,
              shadows: [
                Shadow(
                  color: Colors.deepOrangeAccent,
                  blurRadius: 15 * scale, // Le halo lumineux grandit avec le texte
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}