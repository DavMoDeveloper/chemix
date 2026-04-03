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
  static const _kQuizzes = 'progress_quizzes_completed';
  static const _kStreak = 'progress_streak';
  static const _kLastDate = 'progress_last_quiz_date'; // yyyy-mm-dd
  static const _kCorrectIds = 'progress_correct_element_ids';

  Future<ProgressData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final quizzes = prefs.getInt(_kQuizzes) ?? 0;
    final streak = prefs.getInt(_kStreak) ?? 0;
    final correctIds = (prefs.getStringList(_kCorrectIds) ?? []).toSet();
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
  }

  String _dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
