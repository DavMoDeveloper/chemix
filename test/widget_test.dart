// Tests básicos de humo para Chemix.
// TODO: añadir tests unitarios para QuizBloc, QuizGenerator, ProgressRepository.

import 'package:flutter_test/flutter_test.dart';
import 'package:chemix/features/quiz/domain/quiz_generator.dart';
import 'package:chemix/features/elements/data/elements_repository.dart';

void main() {
  group('QuizGenerator', () {
    final elements = List.generate(
      20,
      (i) => ElementItem(
        id: '$i',
        name: 'Elemento$i',
        symbol: 'E$i',
        atomicNumber: i + 1,
        category: i % 2 == 0 ? 'Nonmetal' : 'Alkali metal',
        summary: 'Resumen $i',
        uses: 'Usos $i',
        funFact: 'Dato $i',
        x: (i % 18) + 1,
        y: (i ~/ 18) + 1,
      ),
    );

    test('genera el número correcto de preguntas', () {
      final questions = QuizGenerator.generate(elements, total: 10);
      expect(questions.length, 10);
    });

    test('el índice correcto siempre está dentro del rango de opciones', () {
      final questions = QuizGenerator.generate(elements, total: 10);
      for (final q in questions) {
        expect(q.correctIndex, greaterThanOrEqualTo(0));
        expect(q.correctIndex, lessThan(q.options.length));
        expect(q.options[q.correctIndex], isNotEmpty);
      }
    });

    test('las preguntas tienen 4 opciones cada una', () {
      final questions = QuizGenerator.generate(elements, total: 5);
      for (final q in questions) {
        expect(q.options.length, 4);
      }
    });
  });
}
