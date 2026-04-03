import 'package:equatable/equatable.dart';

sealed class QuizEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class QuizStarted extends QuizEvent {}

class AnswerSelected extends QuizEvent {
  final int index;
  AnswerSelected(this.index);

  @override
  List<Object?> get props => [index];
}

class NextQuestion extends QuizEvent {}

class QuizFinished extends QuizEvent {}

class ReviewQuizStarted extends QuizEvent {}
