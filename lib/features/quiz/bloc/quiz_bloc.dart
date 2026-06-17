import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../elements/data/elements_repository.dart';
import '../../premium/bloc/premium_bloc.dart';
import '../../premium/bloc/premium_state.dart';
import '../../progress/bloc/progress_bloc.dart';
import '../../progress/bloc/progress_event.dart';
import '../data/review_service.dart';
import '../domain/quiz_generator.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  static const int premiumNudgeThreshold = 3;
  static const int firstDayFreeQuizLimit = 7;
  static const int dailyFreeQuizLimit = 3;
  static const String _firstQuizDateKey = 'quiz_first_quiz_date';
  static const String _dailyQuizDateKey = 'quiz_daily_quiz_date';
  static const String _dailyQuizCountKey = 'quiz_daily_quiz_count';

  final ElementsRepository elementsRepo;
  final PremiumBloc premiumBloc;
  final ProgressBloc progressBloc;
  final ReviewService reviewService;

  bool _isReviewMode = false;
  final Set<String> _reviewSolvedIds = {};

  QuizBloc({
    required this.elementsRepo,
    required this.premiumBloc,
    required this.progressBloc,
    required this.reviewService,
  }) : super(QuizInitial()) {
    on<QuizStarted>(_onStarted);
    on<ReviewQuizStarted>(_onReviewStarted);
    on<AnswerSelected>(_onAnswer);
    on<NextQuestion>(_onNext);
    on<QuizFinished>(_onFinished);
  }

  Future<void> _onReviewStarted(
    ReviewQuizStarted event,
    Emitter<QuizState> emit,
  ) async {
    _isReviewMode = true;
    _reviewSolvedIds.clear();

    final wrongIds = await reviewService.getWrongIds();
    if (wrongIds.isEmpty) {
      emit(QuizLocked('Aún no tienes errores para repasar ✅'));
      return;
    }

    final all = await elementsRepo.getAll();
    final subset = all.where((e) => wrongIds.contains(e.id)).toList();

    if (subset.isEmpty) {
      emit(QuizLocked('No hay elementos disponibles para repasar.'));
      return;
    }

    final questions = QuizGenerator.generate(all, total: 10)
        .where((q) => wrongIds.contains(q.elementId))
        .toList();

    final safeQuestions = questions.isNotEmpty
        ? questions.take(10).toList()
        : QuizGenerator.generate(subset, total: subset.length.clamp(1, 10));

    emit(QuizInProgress(index: 0, questions: safeQuestions, correctCount: 0));
  }

  Future<void> _onStarted(QuizStarted event, Emitter<QuizState> emit) async {
    _isReviewMode = false;
    _reviewSolvedIds.clear();
    final isPremium = premiumBloc.state is PremiumActive;

    if (!isPremium) {
      final prefs = await SharedPreferences.getInstance();
      final quota = await _reserveFreeQuizQuota(prefs);
      if (!quota.allowed) {
        final diff = _timeUntilTomorrow();
        final h = diff.inHours;
        final m = diff.inMinutes % 60;
        emit(QuizLocked(
          'Limite diario alcanzado.\n'
          'Hoy usaste ${quota.limit}/${quota.limit} quizzes gratis.\n'
          'Vuelve en ${h}h ${m}min.\n'
          'O hazte Premium para quizzes ilimitados.',
        ));
        return;
      }
    }

    final elements = await elementsRepo.getAll();
    final questions = QuizGenerator.generate(elements, total: 10);
    emit(QuizInProgress(
      index: 0,
      questions: questions,
      correctCount: 0,
      wrongCount: 0,
    ));
  }

  Future<void> _onAnswer(
    AnswerSelected e,
    Emitter<QuizState> emit,
  ) async {
    final s = state;
    if (s is! QuizInProgress) return;

    final wasCorrect = e.index == s.current.correctIndex;

    if (!wasCorrect) {
      await reviewService.addWrong(s.current.elementId);
    }

    if (_isReviewMode && wasCorrect) {
      _reviewSolvedIds.add(s.current.elementId);
    }

    final isPremium = premiumBloc.state is PremiumActive;
    final newWrong = wasCorrect ? s.wrongCount : s.wrongCount + 1;
    final nudge =
        !isPremium && !wasCorrect && newWrong >= premiumNudgeThreshold;
    final updatedCorrectIds = [
      ...s.correctElementIds,
      if (wasCorrect) s.current.elementId,
    ];

    emit(QuizInProgress(
      index: s.index,
      questions: s.questions,
      correctCount: s.correctCount + (wasCorrect ? 1 : 0),
      selected: e.index,
      wrongCount: newWrong,
      showPremiumNudge: nudge,
      correctElementIds: updatedCorrectIds,
    ));
  }

  void _onNext(NextQuestion e, Emitter<QuizState> emit) {
    final s = state;
    if (s is! QuizInProgress) return;
    if (s.index + 1 >= s.questions.length) {
      add(QuizFinished());
    } else {
      emit(QuizInProgress(
        index: s.index + 1,
        questions: s.questions,
        correctCount: s.correctCount,
        wrongCount: s.wrongCount,
        showPremiumNudge: false,
        correctElementIds: s.correctElementIds,
      ));
    }
  }

  Future<void> _onFinished(
    QuizFinished e,
    Emitter<QuizState> emit,
  ) async {
    final s = state;
    if (s is! QuizInProgress) return;
    progressBloc.add(
      ProgressUpdatedAfterQuiz(
        score: s.correctCount,
        total: s.questions.length,
        correctElementIds: s.correctElementIds,
      ),
    );
    if (_isReviewMode && _reviewSolvedIds.isNotEmpty) {
      await reviewService.removeMany(_reviewSolvedIds);
    }

    emit(QuizCompleted(score: s.correctCount, total: s.questions.length));
  }

  Future<_FreeQuizQuota> _reserveFreeQuizQuota(SharedPreferences prefs) async {
    final today = _dateKey(DateTime.now());
    final firstQuizDate = prefs.getString(_firstQuizDateKey) ?? today;
    final storedDate = prefs.getString(_dailyQuizDateKey);

    if (!prefs.containsKey(_firstQuizDateKey)) {
      await prefs.setString(_firstQuizDateKey, today);
    }

    final limit =
        firstQuizDate == today ? firstDayFreeQuizLimit : dailyFreeQuizLimit;
    final currentCount =
        storedDate == today ? prefs.getInt(_dailyQuizCountKey) ?? 0 : 0;

    if (currentCount >= limit) {
      return _FreeQuizQuota(allowed: false, limit: limit);
    }

    await prefs.setString(_dailyQuizDateKey, today);
    await prefs.setInt(_dailyQuizCountKey, currentCount + 1);
    return _FreeQuizQuota(allowed: true, limit: limit);
  }

  Duration _timeUntilTomorrow() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  String _dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _FreeQuizQuota {
  final bool allowed;
  final int limit;

  const _FreeQuizQuota({
    required this.allowed,
    required this.limit,
  });
}
