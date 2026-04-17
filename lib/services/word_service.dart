import 'package:flutter/services.dart';

class WordService {
  static final WordService _instance = WordService._internal();
  factory WordService() => _instance;
  WordService._internal();

  Set<String> _words = {};

  Future<void> loadDictionary() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/dictionnaire.txt',
      );

      // On découpe, on nettoie les '\r' invisibles, et on passe en minuscules
      _words = response
          .split('\n')
          .map((word) => word.trim().toLowerCase())
          .where((word) => word.isNotEmpty)
          .toSet();

      print("✅ Dictionnaire chargé : ${_words.length} mots !");
    } catch (e) {
      print("❌ Erreur de chargement du dictionnaire : $e");
    }
  }

  bool isValidWord(String word) {
    // On nettoie et met en minuscules le mot tapé par le joueur avant de comparer
    return _words.contains(word.trim().toLowerCase());
  }
}
