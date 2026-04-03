import 'package:equatable/equatable.dart';

sealed class ProgressEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProgressStarted extends ProgressEvent {}

class ProgressUpdatedAfterQuiz extends ProgressEvent {
  final int score;
  final int total;
  final List<String> correctElementIds;
  ProgressUpdatedAfterQuiz({
    required this.score,
    required this.total,
    this.correctElementIds = const [],
  });

  @override
  List<Object?> get props => [score, total, correctElementIds];
}
