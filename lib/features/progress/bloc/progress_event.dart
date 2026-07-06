import 'package:equatable/equatable.dart';
import '../data/progress_repository.dart';

sealed class ProgressEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProgressStarted extends ProgressEvent {}

class ProgressUpdatedAfterQuiz extends ProgressEvent {
  final int score;
  final int total;
  final List<String> correctElementIds;
  final List<QuizAnswerRecord> answers;
  ProgressUpdatedAfterQuiz({
    required this.score,
    required this.total,
    this.correctElementIds = const [],
    this.answers = const [],
  });

  @override
  List<Object?> get props => [score, total, correctElementIds, answers];
}
