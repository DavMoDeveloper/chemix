import 'package:chemix/features/compounds/data/compounds_repository.dart';
import 'package:chemix/features/elements/data/elements_repository.dart';
import 'package:chemix/features/quiz/domain/quiz_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ElementsRepository', () {
    test('carga los 118 elementos con posiciones unicas', () async {
      final elements = await ElementsRepository().getAll();
      final atomicNumbers = elements.map((element) => element.atomicNumber);
      final positions = elements.map((element) => '${element.x},${element.y}');

      expect(elements.length, 118);
      expect(
        atomicNumbers.toSet(),
        equals(List.generate(118, (index) => index + 1).toSet()),
      );
      expect(positions.toSet().length, 118);
      expect(
        elements.every((element) => element.x > 0 && element.y > 0),
        isTrue,
      );
      expect(elements.every((element) => element.uses.isNotEmpty), isTrue);
      expect(elements.every((element) => element.name.isNotEmpty), isTrue);
    });
  });

  group('CompoundsRepository', () {
    test('carga compuestos con datos estructurados válidos', () async {
      final compounds = await CompoundsRepository().getAll();

      expect(compounds, isNotEmpty);
      expect(compounds.map((item) => item.id).toSet().length, compounds.length);
      expect(compounds.every((item) => item.molarMass > 0), isTrue);
      expect(compounds.every((item) => item.molarMassUnit == 'g/mol'), isTrue);
      expect(compounds.every((item) => item.uses.isNotEmpty), isTrue);
    });
  });

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
        uses: ['Uso $i'],
        funFact: 'Dato $i',
        x: (i % 18) + 1,
        y: (i ~/ 18) + 1,
      ),
    );

    final compounds = List.generate(
      6,
      (i) => CompoundItem(
        id: 'compound-$i',
        name: 'Compuesto$i',
        formula: 'C$i',
        category: i % 2 == 0 ? 'Sal' : 'Acido',
        molarMass: (10 + i).toDouble(),
        molarMassUnit: 'g/mol',
        state: i % 2 == 0 ? 'Solido' : 'Liquido',
        summary: 'Resumen compuesto $i',
        uses: ['Uso compuesto $i'],
        safety: 'Seguridad compuesto $i',
      ),
    );

    test('genera el numero correcto de preguntas', () {
      final questions = QuizGenerator.generate(
        elements: elements,
        compounds: compounds,
        total: 10,
      );
      expect(questions.length, 10);
    });

    test('el indice correcto siempre esta dentro del rango de opciones', () {
      final questions = QuizGenerator.generate(
        elements: elements,
        compounds: compounds,
        total: 10,
      );
      for (final q in questions) {
        expect(q.correctIndex, greaterThanOrEqualTo(0));
        expect(q.correctIndex, lessThan(q.options.length));
        expect(q.options[q.correctIndex], isNotEmpty);
        expect(q.explanation, isNotEmpty);
      }
    });

    test('las preguntas basicas tienen 4 opciones cada una', () {
      final questions = QuizGenerator.generate(
        elements: elements,
        compounds: compounds,
        mode: QuizMode.elementsBasics,
        total: 5,
      );
      for (final q in questions) {
        expect(q.options.length, 4);
      }
    });

    test('genera preguntas nuevas de compuestos con opciones únicas', () {
      final questions = QuizGenerator.generate(
        elements: elements,
        compounds: compounds,
        mode: QuizMode.compounds,
        total: 100,
      );
      final types = questions.map((question) => question.questionType).toSet();

      expect(types, containsAll(['compound_use', 'state', 'molar_mass']));
      for (final question in questions) {
        expect(question.options.length, 4);
        expect(question.options.toSet().length, question.options.length);
      }
    });
  });
}
