import 'package:flutter/material.dart';

class LetterRack extends StatelessWidget {
  final List<String> letters;
  final Function(String) onLetterTapped;

  const LetterRack({
    super.key,
    required this.letters,
    required this.onLetterTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12.0, // Espace horizontal
      runSpacing: 16.0, // Espace vertical entre les lignes
      children: letters.map((letter) => _buildLetterTile(letter)).toList(),
    );
  }

  Widget _buildLetterTile(String letter) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onLetterTapped(letter),
        customBorder: const CircleBorder(),
        splashColor: Colors.cyan.withOpacity(0.3),
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF150B2E), // Couleur sombre façon mode classique
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              letter.toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}