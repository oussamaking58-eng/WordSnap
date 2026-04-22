import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Import nécessaire pour récupérer la locale

class FirebaseStorageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fonction privée pour récupérer le code pays du téléphone
  String _getDeviceCountry() {
    // Récupère le code pays (ex: FR, TN, CA) depuis les paramètres système
    // Si non trouvé, on met 'WW' (World Wide) par défaut
    return WidgetsBinding.instance.platformDispatcher.locale.countryCode ?? 'WW';
  }

  // Sauvegarder le score
  Future<void> updateHighScore(int newScore) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _db.collection('scores').doc(user.uid).set({
        'score': newScore,
        'userId': user.uid,
        'country': _getDeviceCountry(), // 👈 Détection automatique !
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print("🏆 Score de $newScore envoyé sur Firestore pour ${user.uid} (${_getDeviceCountry()})");
    } catch (e) {
      print("❌ Erreur lors de l'envoi du score : $e");
    }
  }

  // Met à jour ou crée le pseudo de l'utilisateur
  Future<void> updateUsername(String newName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _db.collection('scores').doc(user.uid).set({
        'name': newName,
        'userId': user.uid,
        'country': _getDeviceCountry(), // 👈 On assure le pays ici aussi
      }, SetOptions(merge: true));
      print("✅ Pseudo mis à jour : $newName");
    } catch (e) {
      print("❌ Erreur updateUsername : $e");
    }
  }
}
