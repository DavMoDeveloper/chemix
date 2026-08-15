import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../compounds/data/compounds_repository.dart';
import '../../elements/data/elements_repository.dart';
import '../../premium/bloc/premium_bloc.dart';
import '../../premium/bloc/premium_state.dart';
import '../../progress/bloc/progress_bloc.dart';
import '../../progress/bloc/progress_event.dart';
import '../../progress/data/progress_repository.dart';
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
  final CompoundsRepository compoundsRepo;
  final PremiumBloc premiumBloc;
  final ProgressBloc progressBloc;
  final ProgressRepository progressRepo;
  final ReviewService reviewService;

  bool _isReviewMode = false;
  final Set<String> _reviewSolvedKeys = {};

  QuizBloc({
    required this.elementsRepo,
    required this.compoundsRepo,
    required this.premiumBloc,
    required this.progressBloc,
    required this.progressRepo,
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
    _reviewSolvedKeys.clear();

    final wrongKeys = await reviewService.getWrongMasteryKeys();
    final dueKeys = await progressRepo.dueMasteryKeys();
    final targetKeys = {...wrongKeys, ...dueKeys};

    if (targetKeys.isEmpty) {
      emit(QuizLocked('Aun no tienes repasos pendientes.'));
      return;
    }

    final elements = await elementsRepo.getAll();
    final compounds = await compoundsRepo.getAll();
    final questions = QuizGenerator.generate(
      elements: elements,
      compounds: compounds,
      mode: QuizMode.reviewDue,
      allowedMasteryKeys: targetKeys,
      total: 10,
    );

    if (questions.isEmpty) {
      emit(QuizLocked('No hay preguntas disponibles para tu repaso.'));
      return;
    }

    emit(QuizInProgress(index: 0, questions: questions, correctCount: 0));
  }

  Future<void> _onStarted(QuizStarted event, Emitter<QuizState> emit) async {
    _isReviewMode = false;
    _reviewSolvedKeys.clear();
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
          showPremiumAction: true,
        ));
        return;
      }
    }

    final elements = await elementsRepo.getAll();
    final compounds = await compoundsRepo.getAll();
    final questions = QuizGenerator.generate(
      elements: elements,
      compounds: compounds,
      mode: event.mode,
      total: 10,
    );

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
    if (s is! QuizInProgress || s.selected != null) return;

    final question = s.current;
    final wasCorrect = e.index == question.correctIndex;

    if (!wasCorrect) {
      await reviewService.addWrongQuestion(question, e.index);
    }

    if (_isReviewMode && wasCorrect) {
      _reviewSolvedKeys.add(question.masteryKey);
    }

    final isPremium = premiumBloc.state is PremiumActive;
    final newWrong = wasCorrect ? s.wrongCount : s.wrongCount + 1;
    final nudge =
        !isPremium && !wasCorrect && newWrong >= premiumNudgeThreshold;
    final updatedCorrectIds = [
      ...s.correctElementIds,
      if (wasCorrect && question.itemType == 'element') question.itemId,
    ];
    final answers = [
      ...s.answers,
      QuizAnswerRecord(question: question, selectedIndex: e.index),
    ];

    emit(QuizInProgress(
      index: s.index,
      questions: s.questions,
      correctCount: s.correctCount + (wasCorrect ? 1 : 0),
      selected: e.index,
      wrongCount: newWrong,
      showPremiumNudge: nudge,
      correctElementIds: updatedCorrectIds,
      answers: answers,
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
        answers: s.answers,
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
        answers: s.answers,
      ),
    );
    if (_isReviewMode && _reviewSolvedKeys.isNotEmpty) {
      await reviewService.removeMany(_reviewSolvedKeys);
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
