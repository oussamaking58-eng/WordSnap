import 'dart:math';

class LetterGenerator {
  // 1. On crée des "sacs" de lettres basés sur les fréquences du français
  static const String _voyelles = 'AAAAAAAAEEEEEEEEEEEEEEIIIIIIIIOOOOOOOUUUUUUY';
  static const String _consonnes = 'BBCCDDDDFFGGHHJJKLLLLMMNNNNNNPPQQRRRRRRSSSSSSTTTTTTVVWXYZ';

  /// Génère une main de lettres équilibrée
  /// [size] : Le nombre total de lettres que tu veux donner au joueur (ex: 10, 12)
  static List<String> generateHand(int size) {
    final random = Random();
    List<String> hand = [];
    
    // 2. On impose une règle stricte : 40% de la main DOIT être des voyelles
    int minVoyelles = (size * 0.4).ceil(); 
    int minConsonnes = size - minVoyelles;
    
    // 3. On pioche les voyelles dans le sac
    for (int i = 0; i < minVoyelles; i++) {
      hand.add(_voyelles[random.nextInt(_voyelles.length)]);
    }
    
    // 4. On pioche les consonnes dans le sac
    for (int i = 0; i < minConsonnes; i++) {
      hand.add(_consonnes[random.nextInt(_consonnes.length)]);
    }
    
    // 5. On mélange bien la liste pour que les voyelles ne soient pas toutes au début
    hand.shuffle(random);
    
    return hand;
  }
}