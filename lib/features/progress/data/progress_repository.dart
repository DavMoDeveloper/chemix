import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../quiz/domain/question.dart';

class MasteryItem {
  final String key;
  final String itemId;
  final String itemType;
  final String questionType;
  final String topic;
  final int correctCount;
  final int wrongCount;
  final String? lastAnswer;
  final String? correctAnswer;
  final String? lastAnsweredAt;
  final String nextReviewAt;
  final double mastery;

  const MasteryItem({
    required this.key,
    required this.itemId,
    required this.itemType,
    required this.questionType,
    required this.topic,
    required this.correctCount,
    required this.wrongCount,
    required this.nextReviewAt,
    required this.mastery,
    this.lastAnswer,
    this.correctAnswer,
    this.lastAnsweredAt,
  });

  bool get isDue {
    final parsed = DateTime.tryParse(nextReviewAt) ?? DateTime.now();
    return parsed.isBefore(
      DateTime.now().add(const Duration(minutes: 1)),
    );
  }

  bool get isMastered => mastery >= 0.8 && correctCount >= 3;

  MasteryItem copyWith({
    int? correctCount,
    int? wrongCount,
    String? lastAnswer,
    String? correctAnswer,
    String? lastAnsweredAt,
    String? nextReviewAt,
    double? mastery,
  }) {
    return MasteryItem(
      key: key,
      itemId: itemId,
      itemType: itemType,
      questionType: questionType,
      topic: topic,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      lastAnswer: lastAnswer ?? this.lastAnswer,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      lastAnsweredAt: lastAnsweredAt ?? this.lastAnsweredAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      mastery: mastery ?? this.mastery,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'itemId': itemId,
      'itemType': itemType,
      'questionType': questionType,
      'topic': topic,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'lastAnswer': lastAnswer,
      'correctAnswer': correctAnswer,
      'lastAnsweredAt': lastAnsweredAt,
      'nextReviewAt': nextReviewAt,
      'mastery': mastery,
    };
  }

  factory MasteryItem.fromJson(Map<String, dynamic> json) {
    return MasteryItem(
      key: (json['key'] ?? '').toString(),
      itemId: (json['itemId'] ?? '').toString(),
      itemType: (json['itemType'] ?? '').toString(),
      questionType: (json['questionType'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      wrongCount: (json['wrongCount'] as num?)?.toInt() ?? 0,
      lastAnswer: json['lastAnswer'] as String?,
      correctAnswer: json['correctAnswer'] as String?,
      lastAnsweredAt: json['lastAnsweredAt'] as String?,
      nextReviewAt: (json['nextReviewAt'] ?? _todayIso()).toString(),
      mastery: ((json['mastery'] as num?)?.toDouble() ?? 0)
          .clamp(0.0, 1.0)
          .toDouble(),
    );
  }

  static String _todayIso() => DateTime.now().toIso8601String();
}

class TopicProgress {
  final String key;
  final String label;
  final int total;
  final int due;
  final double mastery;

  const TopicProgress({
    required this.key,
    required this.label,
    required this.total,
    required this.due,
    required this.mastery,
  });
}

class QuizAnswerRecord {
  final Question question;
  final int selectedIndex;

  const QuizAnswerRecord({
    required this.question,
    required this.selectedIndex,
  });

  bool get isCorrect => selectedIndex == question.correctIndex;
  String get selectedAnswer => question.options[selectedIndex];
}

class ProgressData {
  final int quizzesCompleted;
  final int streak;
  final double learnedPercent;
  final List<MasteryItem> masteryItems;
  final List<TopicProgress> topics;
  final int dueReviewCount;
  final int masteredCount;

  const ProgressData({
    required this.quizzesCompleted,
    required this.streak,
    required this.learnedPercent,
    required this.masteryItems,
    required this.topics,
    required this.dueReviewCount,
    required this.masteredCount,
  });

  Set<String> get dueMasteryKeys {
    return masteryItems
        .where((item) => item.isDue)
        .map((item) => item.key)
        .toSet();
  }
}

class ProgressRepository {
  ProgressRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  static const _kQuizzes = 'progress_quizzes_completed';
  static const _kStreak = 'progress_streak';
  static const _kLastDate = 'progress_last_quiz_date';
  static const _kCorrectIds = 'progress_correct_element_ids';
  static const _kMasteryItems = 'progress_mastery_items';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<ProgressData> load() async {
    final prefs = await SharedPreferences.getInstance();
    await _mergeFromCloud(prefs);
    return _fromPreferences(prefs);
  }

  Future<Set<String>> dueMasteryKeys() async {
    final data = await load();
    return data.dueMasteryKeys;
  }

  ProgressData _fromPreferences(SharedPreferences prefs) {
    final quizzes = prefs.getInt(_kQuizzes) ?? 0;
    final streak = prefs.getInt(_kStreak) ?? 0;
    final legacyCorrectIds =
        (prefs.getStringList(_kCorrectIds) ?? const []).toSet();
    final masteryItems = _readMasteryItems(prefs);
    final learnedPercent = _learnedPercent(legacyCorrectIds, masteryItems);
    final dueReviewCount = masteryItems.where((item) => item.isDue).length;
    final masteredCount = masteryItems.where((item) => item.isMastered).length;

    return ProgressData(
      quizzesCompleted: quizzes,
      streak: streak,
      learnedPercent: learnedPercent,
      masteryItems: masteryItems,
      topics: _topicsFrom(masteryItems),
      dueReviewCount: dueReviewCount,
      masteredCount: masteredCount,
    );
  }

  Future<void> updateAfterQuiz({
    required int score,
    required int total,
    List<String> correctElementIds = const [],
    List<QuizAnswerRecord> answers = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final quizzes = (prefs.getInt(_kQuizzes) ?? 0) + 1;
    await prefs.setInt(_kQuizzes, quizzes);

    if (correctElementIds.isNotEmpty) {
      final existing = (prefs.getStringList(_kCorrectIds) ?? []).toSet();
      existing.addAll(correctElementIds);
      await prefs.setStringList(_kCorrectIds, existing.toList()..sort());
    }

    if (answers.isNotEmpty) {
      final current = {
        for (final item in _readMasteryItems(prefs)) item.key: item,
      };
      final now = DateTime.now();

      for (final answer in answers) {
        final question = answer.question;
        final existing = current[question.masteryKey];
        final wasCorrect = answer.isCorrect;
        final correctCount =
            (existing?.correctCount ?? 0) + (wasCorrect ? 1 : 0);
        final wrongCount = (existing?.wrongCount ?? 0) + (wasCorrect ? 0 : 1);
        final mastery = _nextMastery(
          previous: existing?.mastery ?? 0,
          correctCount: correctCount,
          wrongCount: wrongCount,
          wasCorrect: wasCorrect,
        );

        current[question.masteryKey] = MasteryItem(
          key: question.masteryKey,
          itemId: question.itemId,
          itemType: question.itemType,
          questionType: question.questionType,
          topic: question.topicKey,
          correctCount: correctCount,
          wrongCount: wrongCount,
          lastAnswer: answer.selectedAnswer,
          correctAnswer: question.correctAnswer,
          lastAnsweredAt: now.toIso8601String(),
          nextReviewAt:
              _nextReviewDate(now, mastery, wasCorrect).toIso8601String(),
          mastery: mastery,
        );
      }

      await _saveMasteryItems(prefs, current.values.toList());
    }

    await _updateStreak(prefs);
    await _pushToCloud(prefs);
  }

  double _nextMastery({
    required double previous,
    required int correctCount,
    required int wrongCount,
    required bool wasCorrect,
  }) {
    final raw = previous + (wasCorrect ? 0.22 : -0.28);
    final ratio = correctCount / (correctCount + wrongCount).clamp(1, 999);
    return ((raw * 0.65) + (ratio * 0.35)).clamp(0.0, 1.0).toDouble();
  }

  DateTime _nextReviewDate(DateTime now, double mastery, bool wasCorrect) {
    if (!wasCorrect) return now.add(const Duration(days: 1));
    if (mastery < 0.35) return now.add(const Duration(days: 2));
    if (mastery < 0.65) return now.add(const Duration(days: 4));
    if (mastery < 0.85) return now.add(const Duration(days: 7));
    return now.add(const Duration(days: 14));
  }

  Future<void> _updateStreak(SharedPreferences prefs) async {
    final today = _dateKey(DateTime.now());
    final last = prefs.getString(_kLastDate);
    int streak = prefs.getInt(_kStreak) ?? 0;

    if (last == null) {
      streak = 1;
    } else if (last == today) {
      // Same day keeps the current streak.
    } else {
      final lastDt = DateTime.parse(last);
      final diff = DateTime.now()
          .difference(DateTime(lastDt.year, lastDt.month, lastDt.day))
          .inDays;
      streak = diff == 1 ? streak + 1 : 1;
    }

    await prefs.setInt(_kStreak, streak);
    await prefs.setString(_kLastDate, today);
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
      final snapshot = await document.get().timeout(const Duration(seconds: 5));
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

      final mergedMastery = {
        for (final item in _readMasteryItems(prefs)) item.key: item,
      };
      for (final item in _remoteMasteryItems(remote['masteryItems'])) {
        final local = mergedMastery[item.key];
        if (local == null || _isRemoteNewer(item, local)) {
          mergedMastery[item.key] = item;
        }
      }
      await _saveMasteryItems(prefs, mergedMastery.values.toList());

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

  bool _isRemoteNewer(MasteryItem remote, MasteryItem local) {
    final remoteDate = remote.lastAnsweredAt ?? '';
    final localDate = local.lastAnsweredAt ?? '';
    return remoteDate.compareTo(localDate) >= 0;
  }

  Future<void> _pushToCloud(SharedPreferences prefs) async {
    final document = _userDocument;
    if (document == null) return;
    final learnedElementIds = [
      ...?prefs.getStringList(_kCorrectIds),
    ]..sort();
    final masteryItems = _readMasteryItems(prefs)
        .map((item) => item.toJson())
        .take(500)
        .toList();

    try {
      await document.set({
        'quizzesCompleted': prefs.getInt(_kQuizzes) ?? 0,
        'streak': prefs.getInt(_kStreak) ?? 0,
        'learnedElementIds': learnedElementIds,
        'masteryItems': masteryItems,
        'lastQuizDate': prefs.getString(_kLastDate),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on Object {
      // The next load or quiz completion retries the synchronization.
    }
  }

  List<MasteryItem> _readMasteryItems(SharedPreferences prefs) {
    final raw = prefs.getStringList(_kMasteryItems) ?? const [];
    return raw
        .map((value) {
          try {
            return MasteryItem.fromJson(
                jsonDecode(value) as Map<String, dynamic>);
          } on Object {
            return null;
          }
        })
        .whereType<MasteryItem>()
        .toList();
  }

  Future<void> _saveMasteryItems(
    SharedPreferences prefs,
    List<MasteryItem> items,
  ) {
    final encoded = items.map((item) => jsonEncode(item.toJson())).toList()
      ..sort();
    return prefs.setStringList(_kMasteryItems, encoded);
  }

  List<MasteryItem> _remoteMasteryItems(Object? value) {
    if (value is! Iterable) return const [];
    return value
        .whereType<Map>()
        .map((map) => MasteryItem.fromJson(Map<String, dynamic>.from(map)))
        .toList();
  }

  List<TopicProgress> _topicsFrom(List<MasteryItem> items) {
    final grouped = <String, List<MasteryItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.topic, () => []).add(item);
    }

    final topics = grouped.entries.map((entry) {
      final list = entry.value;
      final mastery = list.fold<double>(
            0,
            (total, item) => total + item.mastery,
          ) /
          list.length;
      return TopicProgress(
        key: entry.key,
        label: _topicLabel(entry.key),
        total: list.length,
        due: list.where((item) => item.isDue).length,
        mastery: mastery,
      );
    }).toList()
      ..sort((a, b) => a.mastery.compareTo(b.mastery));

    return topics;
  }

  double _learnedPercent(
      Set<String> legacyCorrectIds, List<MasteryItem> items) {
    final uniqueMastered = items
        .where((item) => item.itemType == 'element' && item.isMastered)
        .map((item) => item.itemId)
        .toSet();
    uniqueMastered.addAll(legacyCorrectIds);
    return (uniqueMastered.length / 118).clamp(0.0, 1.0).toDouble();
  }

  String _topicLabel(String key) {
    switch (key) {
      case 'element:symbol_to_name':
        return 'Simbolo a nombre';
      case 'element:name_to_symbol':
        return 'Nombre a simbolo';
      case 'element:atomic_number':
        return 'Numero atomico';
      case 'element:category':
        return 'Categorias de elementos';
      case 'compound:formula_to_name':
        return 'Formula a compuesto';
      case 'compound:name_to_formula':
        return 'Compuesto a formula';
      case 'compound:compound_category':
        return 'Tipos de compuestos';
      case 'compound:safety':
        return 'Seguridad quimica';
      default:
        return key;
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
