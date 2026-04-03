import 'package:equatable/equatable.dart';

class Question extends Equatable {
  final String elementId; // <- para saber de qué elemento es la pregunta
  final String prompt;
  final List<String> options;
  final int correctIndex;

  const Question({
    required this.elementId,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  @override
  List<Object?> get props => [elementId, prompt, options, correctIndex];
}
