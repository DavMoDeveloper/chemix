import 'package:equatable/equatable.dart';
import '../domain/quiz_generator.dart';

sealed class QuizEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class QuizStarted extends QuizEvent {
  final QuizMode mode;

  QuizStarted({this.mode = QuizMode.mixed});

  @override
  List<Object?> get props => [mode];
}

class AnswerSelected extends QuizEvent {
  final int index;
  AnswerSelected(this.index);

  @override
  List<Object?> get props => [index];
}

class NextQuestion extends QuizEvent {}

class QuizFinished extends QuizEvent {}

class ReviewQuizStarted extends QuizEvent {
  final QuizMode mode;

  ReviewQuizStarted({this.mode = QuizMode.reviewDue});

  @override
  List<Object?> get props => [mode];
}
