import 'package:flutter/material.dart';

class LogoCube extends StatelessWidget {
  final String letter;
  final Color color;
  final double size;

  const LogoCube({
    super.key,
    required this.letter,
    required this.color,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(
          color: color.withOpacity(0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: size * 0.4,
            spreadRadius: 2,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.transparent,
            Colors.black.withOpacity(0.4),
          ],
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: size * 0.6,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(color: color, blurRadius: 10),
            ],
          ),
        ),
      ),
    );
  }
}
