import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'language_service.dart';
import 'curated_words.dart';

String _removeDiacritics(String str) {
  const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
  const withoutDia = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';
  for (int i = 0; i < withDia.length; i++) {
    str = str.replaceAll(withDia[i], withoutDia[i]);
  }
  return str;
}

Set<String> _parseDictionary(String response) {
  return response
      .split('\n')
      .map((word) => _removeDiacritics(word.trim()).toUpperCase()) // On stocke tout en majuscules et sans accents
      .where((word) => word.isNotEmpty)
      .toSet();
}

class WordService {
  static final WordService _instance = WordService._internal();
  factory WordService() => _instance;
  WordService._internal();

  final Map<AppLanguage, Set<String>> _dictionaries = {
    AppLanguage.fr: {},
    AppLanguage.en: {},
    AppLanguage.ar: {},
  };

  Future<void> loadDictionary(AppLanguage lang) async {
    if (_dictionaries[lang]!.isNotEmpty) return; // Déjà chargé

    String assetPath;
    switch (lang) {
      case AppLanguage.fr:
        assetPath = 'assets/dictionnaire.txt'; // Fichier actuel
        break;
      case AppLanguage.en:
        assetPath = 'assets/en.txt'; // Fichier à créer/ajouter plus tard
        break;
      case AppLanguage.ar:
        assetPath = 'assets/ar.txt'; // Fichier à créer/ajouter plus tard
        break;
    }

    try {
      final String response = await rootBundle.loadString(assetPath);
      _dictionaries[lang] = await compute(_parseDictionary, response);
      print("✅ Dictionnaire ${lang.name} chargé : ${_dictionaries[lang]!.length} mots !");
    } catch (e) {
      print("❌ Erreur de chargement du dictionnaire $assetPath : $e");
      // Fallback au cas où le fichier n'existe pas encore
      if (lang != AppLanguage.fr) {
         try {
            final String fallback = await rootBundle.loadString('assets/dictionnaire.txt');
            _dictionaries[lang] = await compute(_parseDictionary, fallback);
            print("⚠️ Fallback sur le dico FR pour ${lang.name}");
         } catch (e) {
            print("❌ Erreur fatale dico fallback");
         }
      }
    }
  }

  Future<void> loadAllDictionaries() async {
    await Future.wait([
      loadDictionary(AppLanguage.fr),
      loadDictionary(AppLanguage.en),
      loadDictionary(AppLanguage.ar),
    ]);
  }

  bool isValidWord(String word, AppLanguage lang) {
    final cleanWord = _removeDiacritics(word.trim()).toUpperCase();
    
    // Vérifier les listes sûres d'abord
    if (lang == AppLanguage.fr && commonFrenchWords.contains(cleanWord)) return true;
    if (lang == AppLanguage.en && commonEnglishWords.contains(cleanWord)) return true;
    if (lang == AppLanguage.ar && commonArabicWords.contains(cleanWord)) return true;

    return _dictionaries[lang]?.contains(cleanWord) ?? false;
  }

  String getRandomWord(int length, AppLanguage lang) {
    if (lang == AppLanguage.fr) {
       final validCurated = commonFrenchWords.where((w) => w.length == length).toList();
       if (validCurated.isNotEmpty) {
          return validCurated[Random().nextInt(validCurated.length)];
       }
    } else if (lang == AppLanguage.en) {
       final validCurated = commonEnglishWords.where((w) => w.length == length).toList();
       if (validCurated.isNotEmpty) {
          return validCurated[Random().nextInt(validCurated.length)];
       }
    } else if (lang == AppLanguage.ar) {
       // On filtre par longueur si possible, mais les mots arabes varient
       final validCurated = commonArabicWords.where((w) => w.length == length).toList();
       if (validCurated.isNotEmpty) {
          return validCurated[Random().nextInt(validCurated.length)];
       } else if (commonArabicWords.isNotEmpty) {
          // Fallback sur n'importe quel mot arabe si la longueur précise manque
          return commonArabicWords[Random().nextInt(commonArabicWords.length)];
       }
    }

    final words = _dictionaries[lang] ?? {};
    final validWords = words.where((w) => w.length == length).toList();
    
    if (validWords.isEmpty) {
       // Fallback de secours si le dico ne contient pas de mots de cette taille
       if (length == 5) return "POMME";
       if (length == 6) return "BANANE";
       return "ABRICOT";
    }
    
    return validWords[Random().nextInt(validWords.length)];
  }
}
