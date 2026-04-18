import 'package:flutter/material.dart';

enum AppLanguage { fr, en, ar }

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  AppLanguage _currentLanguage = AppLanguage.fr;

  AppLanguage get currentLanguage => _currentLanguage;

  bool get isRTL => _currentLanguage == AppLanguage.ar;

  void setLanguage(AppLanguage lang) {
    if (_currentLanguage != lang) {
      _currentLanguage = lang;
      notifyListeners();
    }
  }

  String translate(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }

  static const Map<AppLanguage, Map<String, String>> _translations = {
    AppLanguage.fr: {
      'loading': 'Chargement des mots...',
      'play': 'Jouer',
      'sprint': 'Sprint',
      'duel': 'Duel',
      'settings': 'Paramètres',
      'language': 'Langue',
      'sound': 'Son',
      'haptics': 'Vibrations',
      'lives': 'VIES',
      'streak': 'STREAK',
      'not_in_dict': 'Mot inconnu',
      'too_short': 'Mot trop court',
      'win': 'Bravo !',
      'lose': 'Perdu ! Le mot était',
      'next_life': 'Prochaine vie dans',
      'watch_ad': 'Regarder une pub (+1 vie)',
    },
    AppLanguage.en: {
      'loading': 'Loading words...',
      'play': 'Play',
      'sprint': 'Sprint',
      'duel': 'Duel',
      'settings': 'Settings',
      'language': 'Language',
      'sound': 'Sound',
      'haptics': 'Haptics',
      'lives': 'LIVES',
      'streak': 'STREAK',
      'not_in_dict': 'Not in word list',
      'too_short': 'Not enough letters',
      'win': 'Splendid!',
      'lose': 'Game Over! The word was',
      'next_life': 'Next life in',
      'watch_ad': 'Watch Ad (+1 life)',
    },
    AppLanguage.ar: {
      'loading': 'جاري تحميل الكلمات...',
      'play': 'العب',
      'sprint': 'سرعة',
      'duel': 'مبارزة',
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'sound': 'الصوت',
      'haptics': 'الاهتزاز',
      'lives': 'حياة',
      'streak': 'سلسلة',
      'not_in_dict': 'الكلمة غير موجودة',
      'too_short': 'حروف قليلة جدا',
      'win': 'أحسنت!',
      'lose': 'خسرت! الكلمة كانت',
      'next_life': 'الحياة القادمة في',
      'watch_ad': 'شاهد إعلان (+1 حياة)',
    }
  };
}
