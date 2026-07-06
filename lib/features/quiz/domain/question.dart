import 'package:equatable/equatable.dart';

class Question extends Equatable {
  final String itemId;
  final String itemType; // element | compound
  final String questionType;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const Question({
    required this.itemId,
    required this.itemType,
    required this.questionType,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  String get elementId => itemId;
  String get masteryKey => '$itemType:$itemId:$questionType';
  String get topicKey => '$itemType:$questionType';
  String get correctAnswer => options[correctIndex];

  @override
  List<Object?> get props => [
        itemId,
        itemType,
        questionType,
        prompt,
        options,
        correctIndex,
        explanation,
      ];
}
