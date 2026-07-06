import 'dart:math';

import '../../compounds/data/compounds_repository.dart';
import '../../elements/data/elements_repository.dart';
import '../domain/question.dart';

enum QuizMode {
  mixed,
  elementsBasics,
  elementCategories,
  compounds,
  reviewDue,
}

extension QuizModeLabel on QuizMode {
  String get title {
    switch (this) {
      case QuizMode.mixed:
        return 'Quiz rapido';
      case QuizMode.elementsBasics:
        return 'Elementos basicos';
      case QuizMode.elementCategories:
        return 'Categorias';
      case QuizMode.compounds:
        return 'Compuestos';
      case QuizMode.reviewDue:
        return 'Repaso de hoy';
    }
  }

  String get description {
    switch (this) {
      case QuizMode.mixed:
        return 'Mezcla elementos y compuestos para practicar de forma variada.';
      case QuizMode.elementsBasics:
        return 'Practica nombres, simbolos y numeros atomicos.';
      case QuizMode.elementCategories:
        return 'Refuerza familias y categorias de la tabla periodica.';
      case QuizMode.compounds:
        return 'Relaciona nombres, formulas, tipos y seguridad.';
      case QuizMode.reviewDue:
        return 'Vuelve sobre lo que toca repasar hoy.';
    }
  }
}

QuizMode quizModeFromName(String? value) {
  return QuizMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => QuizMode.mixed,
  );
}

class QuizGenerator {
  static List<Question> generate({
    required List<ElementItem> elements,
    required List<CompoundItem> compounds,
    QuizMode mode = QuizMode.mixed,
    Set<String> allowedMasteryKeys = const {},
    int total = 10,
  }) {
    final rnd = Random();
    final questions = <Question>[];

    switch (mode) {
      case QuizMode.elementsBasics:
        questions.addAll(_elementQuestions(elements, rnd, basicOnly: true));
        break;
      case QuizMode.elementCategories:
        questions
            .addAll(_elementQuestions(elements, rnd, categoriesOnly: true));
        break;
      case QuizMode.compounds:
        questions.addAll(_compoundQuestions(compounds, rnd));
        break;
      case QuizMode.reviewDue:
        questions.addAll(_elementQuestions(elements, rnd));
        questions.addAll(_compoundQuestions(compounds, rnd));
        if (allowedMasteryKeys.isNotEmpty) {
          questions.removeWhere(
            (question) => !allowedMasteryKeys.contains(question.masteryKey),
          );
        }
        break;
      case QuizMode.mixed:
        questions.addAll(_elementQuestions(elements, rnd));
        questions.addAll(_compoundQuestions(compounds, rnd));
        break;
    }

    questions.shuffle(rnd);
    return questions.take(total).toList();
  }

  static List<Question> _elementQuestions(
    List<ElementItem> elements,
    Random rnd, {
    bool basicOnly = false,
    bool categoriesOnly = false,
  }) {
    final picked = [...elements]..shuffle(rnd);
    final questions = <Question>[];

    for (final el in picked) {
      if (!categoriesOnly) {
        questions.add(_symbolToName(el, elements, rnd));
        questions.add(_nameToSymbol(el, elements, rnd));
        questions.add(_atomicNumber(el, rnd));
      }
      if (!basicOnly) {
        questions.add(_category(el, elements, rnd));
      }
    }

    return questions;
  }

  static List<Question> _compoundQuestions(
    List<CompoundItem> compounds,
    Random rnd,
  ) {
    final picked = [...compounds]..shuffle(rnd);
    final questions = <Question>[];

    for (final compound in picked) {
      questions.add(_formulaToCompound(compound, compounds, rnd));
      questions.add(_compoundToFormula(compound, compounds, rnd));
      questions.add(_compoundCategory(compound, compounds, rnd));
      questions.add(_compoundSafety(compound, compounds, rnd));
    }

    return questions;
  }

  static Question _symbolToName(
    ElementItem el,
    List<ElementItem> all,
    Random rnd,
  ) {
    final correct = el.name;
    final wrongs =
        _pickDistinctElements(all, rnd, count: 3, excludeIds: {el.id})
            .map((e) => e.name)
            .toList();
    final options = [...wrongs, correct]..shuffle(rnd);

    return Question(
      itemId: el.id,
      itemType: 'element',
      questionType: 'symbol_to_name',
      prompt: 'Cual es el nombre del elemento ${el.symbol}?',
      options: options,
      correctIndex: options.indexOf(correct),
      explanation:
          '${el.symbol} es el simbolo quimico de ${el.name}. Numero atomico: ${el.atomicNumber}.',
    );
  }

  static Question _nameToSymbol(
    ElementItem el,
    List<ElementItem> all,
    Random rnd,
  ) {
    final correct = el.symbol;
    final wrongs =
        _pickDistinctElements(all, rnd, count: 3, excludeIds: {el.id})
            .map((e) => e.symbol)
            .toList();
    final options = [...wrongs, correct]..shuffle(rnd);

    return Question(
      itemId: el.id,
      itemType: 'element',
      questionType: 'name_to_symbol',
      prompt: 'Cual es el simbolo de ${el.name}?',
      options: options,
      correctIndex: options.indexOf(correct),
      explanation:
          'El simbolo de ${el.name} es ${el.symbol}. Los simbolos suelen venir del nombre latino o internacional.',
    );
  }

  static Question _atomicNumber(ElementItem el, Random rnd) {
    final correct = el.atomicNumber.toString();
    final set = <String>{correct};
    while (set.length < 4) {
      final delta = rnd.nextInt(10) - 5;
      final n = (el.atomicNumber + delta).clamp(1, 118);
      set.add(n.toString());
    }

    final options = set.toList()..shuffle(rnd);
    return Question(
      itemId: el.id,
      itemType: 'element',
      questionType: 'atomic_number',
      prompt: 'Cual es el numero atomico de ${el.symbol}?',
      options: options,
      correctIndex: options.indexOf(correct),
      explanation:
          'El numero atomico de ${el.name} es ${el.atomicNumber}; indica cuantos protones tiene su nucleo.',
    );
  }

  static Question _category(
    ElementItem el,
    List<ElementItem> all,
    Random rnd,
  ) {
    final correct = el.category;
    final categories = all
        .map((e) => e.category)
        .where((c) => c.trim().isNotEmpty)
        .toSet()
        .toList();
    final fallback = <String>{
      'Nonmetal',
      'Halogen',
      'Noble gas',
      'Metalloid',
      'Alkali metal',
      'Alkaline earth metal',
      'Transition metal',
      'Post-transition metal',
    };
    final pool = {...categories, ...fallback}
        .where((c) => c != correct)
        .toList()
      ..shuffle(rnd);
    final options = ([...pool.take(3), correct]..shuffle(rnd));

    return Question(
      itemId: el.id,
      itemType: 'element',
      questionType: 'category',
      prompt: 'A que categoria pertenece ${el.name}?',
      options: options,
      correctIndex: options.indexOf(correct),
      explanation:
          '${el.name} pertenece a "$correct". Ubicar la categoria ayuda a predecir comportamiento y reactividad.',
    );
  }

  static Question _formulaToCompound(
    CompoundItem compound,
    List<CompoundItem> all,
    Random rnd,
  ) {
    final correct = compound.name;
    final wrongs = _pickDistinctCompounds(
      all,
      rnd,
      count: 3,
      excludeIds: {compound.id},
    ).map((e) => e.name).toList();
    final options = [...wrongs, correct]..shuffle(rnd);

    return Question(
      itemId: compound.id,
      itemType: 'compound',
      questionType: 'formula_to_name',
      prompt: 'Que compuesto tiene la formula ${compound.formula}?',
      options: options,
      correctIndex: options.indexOf(correct),
      explanation:
          '${compound.formula} corresponde a ${compound.name}. ${compound.summary}',
    );
  }

  static Question _compoundToFormula(
    CompoundItem compound,
    List<CompoundItem> all,
    Random rnd,
  ) {
    final correct = compound.formula;
    final wrongs = _pickDistinctCompounds(
      all,
      rnd,
      count: 3,
      excludeIds: {compound.id},
    ).map((e) => e.formula).toList();
    final options = [...wrongs, correct]..shuffle(rnd);

    return Question(
      itemId: compound.id,
      itemType: 'compound',
      questionType: 'name_to_formula',
      prompt: 'Cual es la formula de ${compound.name}?',
      options: options,
      correctIndex: options.indexOf(correct),
      explanation:
          'La formula de ${compound.name} es ${compound.formula}. Su masa molar es ${compound.molarMass}.',
    );
  }

  static Question _compoundCategory(
    CompoundItem compound,
    List<CompoundItem> all,
    Random rnd,
  ) {
    final correct = compound.category;
    final categories = all
        .map((e) => e.category)
        .where((c) => c.trim().isNotEmpty && c != correct)
        .toSet()
        .toList()
      ..shuffle(rnd);
    final options = ([...categories.take(3), correct]..shuffle(rnd));

    return Question(
      itemId: compound.id,
      itemType: 'compound',
      questionType: 'compound_category',
      prompt: 'Que tipo de compuesto es ${compound.name}?',
      options: options,
      correctIndex: options.indexOf(correct),
      explanation:
          '${compound.name} se clasifica como "$correct". Reconocer el tipo ayuda a anticipar sus propiedades.',
    );
  }

  static Question _compoundSafety(
    CompoundItem compound,
    List<CompoundItem> all,
    Random rnd,
  ) {
    final correct = compound.safety;
    final wrongs = _pickDistinctCompounds(
      all.where((e) => e.safety.trim().isNotEmpty).toList(),
      rnd,
      count: 3,
      excludeIds: {compound.id},
    ).map((e) => e.safety).toList();
    final options = [...wrongs, correct]..shuffle(rnd);

    return Question(
      itemId: compound.id,
      itemType: 'compound',
      questionType: 'safety',
      prompt: 'Que cuidado se asocia mejor con ${compound.name}?',
      options: options,
      correctIndex: options.indexOf(correct),
      explanation:
          'Seguridad para ${compound.name}: ${compound.safety.isEmpty ? 'revisar ficha de seguridad antes de manipularlo.' : compound.safety}',
    );
  }

  static List<ElementItem> _pickDistinctElements(
    List<ElementItem> all,
    Random rnd, {
    required int count,
    required Set<String> excludeIds,
  }) {
    final list = all.where((e) => !excludeIds.contains(e.id)).toList()
      ..shuffle(rnd);
    return list.take(count).toList();
  }

  static List<CompoundItem> _pickDistinctCompounds(
    List<CompoundItem> all,
    Random rnd, {
    required int count,
    required Set<String> excludeIds,
  }) {
    final list = all.where((e) => !excludeIds.contains(e.id)).toList()
      ..shuffle(rnd);
    return list.take(count).toList();
  }
}
