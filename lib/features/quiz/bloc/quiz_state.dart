import 'package:equatable/equatable.dart';
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

  QuizInProgress({
    required this.index,
    required this.questions,
    required this.correctCount,
    this.selected,
    this.wrongCount = 0,
    this.showPremiumNudge = false,
    this.correctElementIds = const [],
  });

  Question get current => questions[index];

  @override
  List<Object?> get props => [index, questions, correctCount, selected, wrongCount, showPremiumNudge, correctElementIds];
}


class QuizCompleted extends QuizState {
  final int score;
  final int total;

  QuizCompleted({required this.score, required this.total});

  @override
  List<Object?> get props => [score, total];
}
