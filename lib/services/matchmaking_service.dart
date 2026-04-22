import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';
import 'language_service.dart';
import 'word_service.dart';

class MatchmakingService {
  static final MatchmakingService _instance = MatchmakingService._internal();
  factory MatchmakingService() => _instance;
  MatchmakingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? get currentUserId => _auth.currentUser?.uid;

  StreamSubscription? _matchSubscription;
  String? _currentMatchId;

  // Chercher un adversaire
  Future<void> findMatch({
    required AppLanguage language,
    required Function(String matchId, String targetWord, Map<String, dynamic> opponent) onMatchFound,
    required Function() onTimeout,
  }) async {
    final String myUid = _auth.currentUser?.uid ?? '';
    final String myName = _auth.currentUser?.displayName ?? 'Joueur';
    
    // 1. S'inscrire dans la file d'attente
    final queueRef = _firestore.collection('matchmaking').doc(myUid);
    await queueRef.set({
      'userId': myUid,
      'name': myName,
      'language': language.name,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'searching',
    });

    // 2. Chercher un adversaire déjà présent dans la file (même langue, statut 'searching')
    final query = await _firestore.collection('matchmaking')
        .where('language', isEqualTo: language.name)
        .where('status', isEqualTo: 'searching')
        .limit(2) // On en prend 2 pour être sûr de ne pas avoir que soi-même
        .get();

    final opponents = query.docs.where((doc) => doc.id != myUid).toList();

    if (opponents.isNotEmpty) {
      // Un adversaire est trouvé ! On crée le match.
      final opponentDoc = opponents.first;
      final opponentData = opponentDoc.data();
      final opponentUid = opponentData['userId'];
      
      final String matchId = 'match_${myUid}_$opponentUid';
      final String targetWord = WordService().getRandomWord(5, language); // Toujours 5 lettres pour les duels

      await _firestore.collection('matches').doc(matchId).set({
        'players': [myUid, opponentUid],
        'playerNames': {myUid: myName, opponentUid: opponentData['name']},
        'targetWord': targetWord,
        'language': language.name,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'ongoing',
        'scores': {myUid: 0, opponentUid: 0},
        'winner': null,
      });

      // Mettre à jour les statuts pour arrêter la recherche
      await queueRef.delete();
      await _firestore.collection('matchmaking').doc(opponentUid).update({'status': 'matched', 'matchId': matchId});
      
      onMatchFound(matchId, targetWord, opponentData);
      return;
    }

    // 3. Si pas d'adversaire immédiat, on écoute son propre doc pour voir si quelqu'un nous "match"
    _matchSubscription = queueRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data?['status'] == 'matched') {
          final matchId = data?['matchId'];
          _currentMatchId = matchId;
          _joinExistingMatch(matchId, onMatchFound);
          queueRef.delete();
        }
      }
    });

    // Timeout après 30 secondes
    Timer(const Duration(seconds: 30), () {
      if (_matchSubscription != null) {
        cancelSearch();
        onTimeout();
      }
    });
  }

  Future<void> _joinExistingMatch(String matchId, Function(String, String, Map<String, dynamic>) onMatchFound) async {
    final matchDoc = await _firestore.collection('matches').doc(matchId).get();
    if (matchDoc.exists) {
      final data = matchDoc.data()!;
      final myUid = _auth.currentUser?.uid;
      final opponentUid = (data['players'] as List).firstWhere((id) => id != myUid);
      
      onMatchFound(
        matchId, 
        data['targetWord'], 
        {'userId': opponentUid, 'name': data['playerNames'][opponentUid]}
      );
    }
  }

  void cancelSearch() {
    _matchSubscription?.cancel();
    _matchSubscription = null;
    final myUid = _auth.currentUser?.uid;
    if (myUid != null) {
      _firestore.collection('matchmaking').doc(myUid).delete();
    }
  }

  // Mettre à jour la progression pendant le match
  Future<void> updateProgress(String matchId, int score, int currentRow) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid != null) {
      await _firestore.collection('matches').doc(matchId).update({
        'scores.$myUid': score,
        'currentRow.$myUid': currentRow,
      });
    }
  }

  // Déclarer un gagnant
  Future<void> declareWinner(String matchId) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid != null) {
      await _firestore.collection('matches').doc(matchId).update({
        'winner': myUid,
        'status': 'finished',
      });
    }
  }

  // Abandonner le match
  Future<void> abandonMatch(String matchId) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid != null) {
      final matchDoc = await _firestore.collection('matches').doc(matchId).get();
      if (matchDoc.exists) {
        final players = List<String>.from(matchDoc.data()?['players'] ?? []);
        final opponentUid = players.firstWhere((id) => id != myUid, orElse: () => '');
        
        await _firestore.collection('matches').doc(matchId).update({
          'winner': opponentUid,
          'status': 'finished',
          'abandonedBy': myUid,
        });
      }
    }
  }
}
