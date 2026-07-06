import 'package:equatable/equatable.dart';
import '../../progress/data/progress_repository.dart';
import '../domain/question.dart';

sealed class QuizState extends Equatable {
  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {}

class QuizLocked extends QuizState {
  final String reason;
  QuizLocked(this.reason);

  @override
  List<Object?> get props => [reason];
}

class QuizInProgress extends QuizState {
  final int index;
  final List<Question> questions;
  final int correctCount;
  final int? selected;
  final int wrongCount;
  final bool showPremiumNudge;

  /// IDs de elementos respondidos correctamente en este quiz
  final List<String> correctElementIds;
  final List<QuizAnswerRecord> answers;

  QuizInProgress({
    required this.index,
    required this.questions,
    required this.correctCount,
    this.selected,
    this.wrongCount = 0,
    this.showPremiumNudge = false,
    this.correctElementIds = const [],
    this.answers = const [],
  });

  Question get current => questions[index];

  @override
  List<Object?> get props => [
        index,
        questions,
        correctCount,
        selected,
        wrongCount,
        showPremiumNudge,
        correctElementIds,
        answers,
      ];
}

class QuizCompleted extends QuizState {
  final int score;
  final int total;

  QuizCompleted({required this.score, required this.total});

  @override
  List<Object?> get props => [score, total];
}
