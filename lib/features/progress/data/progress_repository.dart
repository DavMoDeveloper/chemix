import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressData {
  final int quizzesCompleted;
  final int streak;
  final double learnedPercent;

  const ProgressData({
    required this.quizzesCompleted,
    required this.streak,
    required this.learnedPercent,
  });
}

class ProgressRepository {
  ProgressRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  static const _kQuizzes = 'progress_quizzes_completed';
  static const _kStreak = 'progress_streak';
  static const _kLastDate = 'progress_last_quiz_date'; // yyyy-mm-dd
  static const _kCorrectIds = 'progress_correct_element_ids';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<ProgressData> load() async {
    final prefs = await SharedPreferences.getInstance();
    await _mergeFromCloud(prefs);
    return _fromPreferences(prefs);
  }

  ProgressData _fromPreferences(SharedPreferences prefs) {
    final quizzes = prefs.getInt(_kQuizzes) ?? 0;
    final streak = prefs.getInt(_kStreak) ?? 0;
    final correctIds = (prefs.getStringList(_kCorrectIds) ?? const []).toSet();
    final learnedPercent = (correctIds.length / 118).clamp(0.0, 1.0);

    return ProgressData(
      quizzesCompleted: quizzes,
      streak: streak,
      learnedPercent: learnedPercent,
    );
  }

  Future<void> updateAfterQuiz({
    required int score,
    required int total,
    List<String> correctElementIds = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final quizzes = (prefs.getInt(_kQuizzes) ?? 0) + 1;
    await prefs.setInt(_kQuizzes, quizzes);

    // Acumular IDs de elementos acertados únicos
    if (correctElementIds.isNotEmpty) {
      final existing = (prefs.getStringList(_kCorrectIds) ?? []).toSet();
      existing.addAll(correctElementIds);
      await prefs.setStringList(_kCorrectIds, existing.toList());
    }

    // ----- streak -----
    final today = _dateKey(DateTime.now());
    final last = prefs.getString(_kLastDate);

    int streak = prefs.getInt(_kStreak) ?? 0;

    if (last == null) {
      streak = 1;
    } else if (last == today) {
      // ya contó hoy, no cambia
    } else {
      final lastDt = DateTime.parse(last);
      final diff = DateTime.now()
          .difference(DateTime(lastDt.year, lastDt.month, lastDt.day))
          .inDays;

      streak = diff == 1 ? streak + 1 : 1;
    }

    await prefs.setInt(_kStreak, streak);
    await prefs.setString(_kLastDate, today);
    await _pushToCloud(prefs);
  }

  DocumentReference<Map<String, dynamic>>? get _userDocument {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid);
  }

  Future<void> _mergeFromCloud(SharedPreferences prefs) async {
    final document = _userDocument;
    if (document == null) return;

    try {
      final snapshot =
          await document.get().timeout(const Duration(seconds: 5));
      final remote = snapshot.data();
      if (remote == null) {
        await _pushToCloud(prefs);
        return;
      }

      final localQuizzes = prefs.getInt(_kQuizzes) ?? 0;
      final remoteQuizzes = (remote['quizzesCompleted'] as num?)?.toInt() ?? 0;
      await prefs.setInt(
        _kQuizzes,
        localQuizzes > remoteQuizzes ? localQuizzes : remoteQuizzes,
      );

      final localIds = (prefs.getStringList(_kCorrectIds) ?? const []).toSet();
      final remoteIds = _stringSet(remote['learnedElementIds']);
      localIds.addAll(remoteIds);
      await prefs.setStringList(_kCorrectIds, localIds.toList()..sort());

      final localDate = prefs.getString(_kLastDate);
      final remoteDate = remote['lastQuizDate'] as String?;
      final localStreak = prefs.getInt(_kStreak) ?? 0;
      final remoteStreak = (remote['streak'] as num?)?.toInt() ?? 0;

      if (remoteDate != null &&
          (localDate == null || remoteDate.compareTo(localDate) > 0)) {
        await prefs.setString(_kLastDate, remoteDate);
        await prefs.setInt(_kStreak, remoteStreak);
      } else if (remoteDate == localDate && remoteStreak > localStreak) {
        await prefs.setInt(_kStreak, remoteStreak);
      }

      await _pushToCloud(prefs);
    } on Object {
      // Local data remains the source of truth while Firestore is unavailable.
    }
  }

  Future<void> _pushToCloud(SharedPreferences prefs) async {
    final document = _userDocument;
    if (document == null) return;
    final learnedElementIds = [
      ...?prefs.getStringList(_kCorrectIds),
    ]..sort();

    try {
      await document.set({
        'quizzesCompleted': prefs.getInt(_kQuizzes) ?? 0,
        'streak': prefs.getInt(_kStreak) ?? 0,
        'learnedElementIds': learnedElementIds,
        'lastQuizDate': prefs.getString(_kLastDate),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on Object {
      // The next load or quiz completion retries the synchronization.
    }
  }

  Set<String> _stringSet(Object? value) {
    if (value is! Iterable) return {};
    return value.whereType<String>().toSet();
  }

  String _dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
