import 'package:flutter_bloc/flutter_bloc.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';
import '../domain/quiz_generator.dart';
import '../../elements/data/elements_repository.dart';
import '../../premium/bloc/premium_bloc.dart';
import '../../premium/bloc/premium_state.dart';
import '../../progress/bloc/progress_bloc.dart';
import '../../progress/bloc/progress_event.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/review_service.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  static const int premiumNudgeThreshold = 3;
  final ElementsRepository elementsRepo;
  final PremiumBloc premiumBloc;
  final ProgressBloc progressBloc;
  final ReviewService reviewService;
  // modo actual
  bool _isReviewMode = false;
  // ids acertados durante repaso (para eliminarlos al final)
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
      ReviewQuizStarted event, Emitter<QuizState> emit) async {
    _isReviewMode = true;
    _reviewSolvedIds.clear();

    final wrongIds = await reviewService.getWrongIds();
    if (wrongIds.isEmpty) {
      emit(QuizLocked('Aún no tienes errores para repasar ✅'));
      return;
    }

    final all = await elementsRepo.getAll();
    final subset = all.where((e) => wrongIds.contains(e.id)).toList();

    // si por alguna razón subset queda vacío
    if (subset.isEmpty) {
      emit(QuizLocked('No hay elementos disponibles para repasar.'));
      return;
    }

    final questions = QuizGenerator.generate(all, total: 10)
        .where((q) => wrongIds.contains(q.elementId))
        .toList();

    // fallback si no se generaron suficientes preguntas por el filtro:
    final safeQuestions = (questions.isNotEmpty)
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
      // FIX Bug #8: usar fecha completa YYYY-MM-DD en lugar de solo el día del mes
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final last = prefs.getString('last_quiz_date');
      if (last == today) {
        // Calcular tiempo restante hasta mañana
        final now = DateTime.now();
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        final diff = tomorrow.difference(now);
        final h = diff.inHours;
        final m = diff.inMinutes % 60;
        emit(QuizLocked(
          'Límite diario alcanzado.\nVuelve en ${h}h ${m}min.\nO hazte Premium para quizzes ilimitados.',
        ));
        return;
      }
      await prefs.setString('last_quiz_date', today);
    }

    final elements = await elementsRepo.getAll();
    final questions = QuizGenerator.generate(elements, total: 10);
    emit(QuizInProgress(
        index: 0, questions: questions, correctCount: 0, wrongCount: 0));
  }

  void _onAnswer(AnswerSelected e, Emitter<QuizState> emit) {
    final s = state;
    if (s is! QuizInProgress) return;

    final wasCorrect = e.index == s.current.correctIndex;

    // FIX Bug #5: registrar los elementos correctamente respondidos en modo repaso
    if (_isReviewMode && wasCorrect) {
      _reviewSolvedIds.add(s.current.elementId);
    }

    final isPremium = premiumBloc.state is PremiumActive;

    final newWrong = wasCorrect ? s.wrongCount : (s.wrongCount + 1);

    // ✅ solo muestra nudge si NO es premium y llegó al umbral
    final nudge =
        (!isPremium && !wasCorrect && newWrong >= premiumNudgeThreshold);

    // Acumular IDs de elementos respondidos correctamente
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

  void _onFinished(QuizFinished e, Emitter<QuizState> emit) {
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
      reviewService.removeMany(_reviewSolvedIds);
    }

    emit(QuizCompleted(score: s.correctCount, total: s.questions.length));
  }
}
