import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/question.dart';

class ReviewMistake {
  final String masteryKey;
  final String itemId;
  final String itemType;
  final String questionType;
  final String prompt;
  final String selectedAnswer;
  final String correctAnswer;
  final String explanation;
  final String answeredAt;
  final int count;

  const ReviewMistake({
    required this.masteryKey,
    required this.itemId,
    required this.itemType,
    required this.questionType,
    required this.prompt,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.explanation,
    required this.answeredAt,
    required this.count,
  });

  factory ReviewMistake.fromQuestion(Question question, int selectedIndex) {
    return ReviewMistake(
      masteryKey: question.masteryKey,
      itemId: question.itemId,
      itemType: question.itemType,
      questionType: question.questionType,
      prompt: question.prompt,
      selectedAnswer: question.options[selectedIndex],
      correctAnswer: question.correctAnswer,
      explanation: question.explanation,
      answeredAt: DateTime.now().toIso8601String(),
      count: 1,
    );
  }

  ReviewMistake incrementedFrom(ReviewMistake other) {
    return ReviewMistake(
      masteryKey: masteryKey,
      itemId: itemId,
      itemType: itemType,
      questionType: questionType,
      prompt: prompt,
      selectedAnswer: selectedAnswer,
      correctAnswer: correctAnswer,
      explanation: explanation,
      answeredAt: answeredAt,
      count: other.count + 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'masteryKey': masteryKey,
      'itemId': itemId,
      'itemType': itemType,
      'questionType': questionType,
      'prompt': prompt,
      'selectedAnswer': selectedAnswer,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'answeredAt': answeredAt,
      'count': count,
    };
  }

  factory ReviewMistake.fromJson(Map<String, dynamic> json) {
    return ReviewMistake(
      masteryKey: (json['masteryKey'] ?? '').toString(),
      itemId: (json['itemId'] ?? '').toString(),
      itemType: (json['itemType'] ?? '').toString(),
      questionType: (json['questionType'] ?? '').toString(),
      prompt: (json['prompt'] ?? '').toString(),
      selectedAnswer: (json['selectedAnswer'] ?? '').toString(),
      correctAnswer: (json['correctAnswer'] ?? '').toString(),
      explanation: (json['explanation'] ?? '').toString(),
      answeredAt: (json['answeredAt'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 1,
    );
  }
}

class ReviewService {
  ReviewService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  static const _legacyKey = 'review_wrong_ids';
  static const _mistakesKey = 'review_mistakes';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<Set<String>> getWrongIds() async {
    final mistakes = await getMistakes();
    final ids = mistakes.map((mistake) => mistake.itemId).toSet();
    final prefs = await SharedPreferences.getInstance();
    ids.addAll(prefs.getStringList(_legacyKey) ?? const []);
    return ids;
  }

  Future<Set<String>> getWrongMasteryKeys() async {
    final mistakes = await getMistakes();
    return mistakes.map((mistake) => mistake.masteryKey).toSet();
  }

  Future<List<ReviewMistake>> getMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    final current = {
      for (final mistake in _readLocalMistakes(prefs))
        mistake.masteryKey: mistake,
    };
    final document = _userDocument;
    if (document == null) return current.values.toList();

    try {
      final snapshot = await document.get().timeout(const Duration(seconds: 5));
      final remote = snapshot.data()?['reviewMistakes'];
      if (remote is Iterable) {
        for (final item in remote.whereType<Map>()) {
          final mistake =
              ReviewMistake.fromJson(Map<String, dynamic>.from(item));
          final local = current[mistake.masteryKey];
          if (local == null || mistake.count >= local.count) {
            current[mistake.masteryKey] = mistake;
          }
        }
        await _saveLocalMistakes(prefs, current.values.toList());
      }
    } on Object {
      // Keep the locally available review list.
    }

    return current.values.toList();
  }

  Future<void> addWrongQuestion(Question question, int selectedIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final current = {
      for (final mistake in _readLocalMistakes(prefs))
        mistake.masteryKey: mistake,
    };
    final next = ReviewMistake.fromQuestion(question, selectedIndex);
    final existing = current[next.masteryKey];
    current[next.masteryKey] =
        existing == null ? next : next.incrementedFrom(existing);
    await _saveLocalMistakes(prefs, current.values.toList());
    await _pushMistakes(current.values.toList());
  }

  Future<void> addWrong(String elementId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_legacyKey) ?? const []).toSet();
    current.add(elementId);
    await prefs.setStringList(_legacyKey, current.toList()..sort());
    await _updateLegacyCloud(current);
  }

  Future<void> removeMany(Set<String> keysOrIds) async {
    final prefs = await SharedPreferences.getInstance();
    final current = _readLocalMistakes(prefs)
        .where(
          (mistake) =>
              !keysOrIds.contains(mistake.masteryKey) &&
              !keysOrIds.contains(mistake.itemId),
        )
        .toList();
    await _saveLocalMistakes(prefs, current);

    final legacy = (prefs.getStringList(_legacyKey) ?? const []).toSet();
    legacy.removeAll(keysOrIds);
    await prefs.setStringList(_legacyKey, legacy.toList()..sort());
    await _pushMistakes(current);
    await _updateLegacyCloud(legacy);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyKey);
    await prefs.remove(_mistakesKey);
    await _pushMistakes(const []);
    await _updateLegacyCloud(const {});
  }

  DocumentReference<Map<String, dynamic>>? get _userDocument {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid);
  }

  List<ReviewMistake> _readLocalMistakes(SharedPreferences prefs) {
    final raw = prefs.getStringList(_mistakesKey) ?? const [];
    return raw
        .map((value) {
          try {
            return ReviewMistake.fromJson(
                jsonDecode(value) as Map<String, dynamic>);
          } on Object {
            return null;
          }
        })
        .whereType<ReviewMistake>()
        .toList();
  }

  Future<void> _saveLocalMistakes(
    SharedPreferences prefs,
    List<ReviewMistake> mistakes,
  ) {
    final encoded = mistakes
        .map((mistake) => jsonEncode(mistake.toJson()))
        .toList()
      ..sort();
    return prefs.setStringList(_mistakesKey, encoded);
  }

  Future<void> _pushMistakes(List<ReviewMistake> mistakes) async {
    final document = _userDocument;
    if (document == null) return;

    try {
      await document.set({
        'reviewMistakes': mistakes.map((mistake) => mistake.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on Object {
      // A later read merges the local and remote review lists.
    }
  }

  Future<void> _updateLegacyCloud(Set<String> ids) async {
    final document = _userDocument;
    if (document == null) return;

    try {
      await document.set({
        'wrongElementIds': ids.toList()..sort(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on Object {
      // A later read merges the local and remote review lists.
    }
  }
}
