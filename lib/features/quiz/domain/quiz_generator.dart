import 'dart:math';
import '../../elements/data/elements_repository.dart';
import '../domain/question.dart';

class QuizGenerator {
  static List<Question> generate(List<ElementItem> elements, {int total = 10}) {
    final rnd = Random();

    // Para no repetir elemento en una misma pregunta
    final base = [...elements]..shuffle(rnd);
    final picked = base.take(total).toList();

    final questions = <Question>[];

    for (final el in picked) {
      final type = rnd.nextInt(4); // 0..3

      switch (type) {
        case 0:
          questions.add(_symbolToName(el, elements, rnd));
          break;
        case 1:
          questions.add(_nameToSymbol(el, elements, rnd));
          break;
        case 2:
          questions.add(_atomicNumber(el, elements, rnd));
          break;
        case 3:
        default:
          questions.add(_category(el, elements, rnd));
          break;
      }
    }

    return questions;
  }

  static Question _symbolToName(
      ElementItem el, List<ElementItem> all, Random rnd) {
    final correct = el.name;
    final wrongs = _pickDistinct(all, rnd, count: 3, excludeIds: {el.id})
        .map((e) => e.name)
        .toList();

    final options = [...wrongs, correct]..shuffle(rnd);
    return Question(
      elementId: el.id,
      prompt: '¿Cuál es el nombre del elemento ${el.symbol}?',
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }

  static Question _nameToSymbol(
      ElementItem el, List<ElementItem> all, Random rnd) {
    final correct = el.symbol;
    final wrongs = _pickDistinct(all, rnd, count: 3, excludeIds: {el.id})
        .map((e) => e.symbol)
        .toList();

    final options = [...wrongs, correct]..shuffle(rnd);
    return Question(
      elementId: el.id,
      prompt: '¿Cuál es el símbolo de ${el.name}?',
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }

  static Question _atomicNumber(
      ElementItem el, List<ElementItem> all, Random rnd) {
    final correct = el.atomicNumber.toString();

    // Genera 3 números cercanos pero distintos
    final set = <String>{correct};
    while (set.length < 4) {
      final delta = rnd.nextInt(10) - 5; // -5..+4
      final n = (el.atomicNumber + delta).clamp(1, 118);
      set.add(n.toString());
    }

    final options = set.toList()..shuffle(rnd);
    return Question(
      elementId: el.id,
      prompt: '¿Cuál es el número atómico de ${el.symbol}?',
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }

  static Question _category(ElementItem el, List<ElementItem> all, Random rnd) {
    final correct = el.category;

    // Opciones de categorías tomadas del dataset (únicas)
    final categories = all
        .map((e) => e.category)
        .where((c) => c.trim().isNotEmpty)
        .toSet()
        .toList();

    // Si aún tienes pocas categorías en tu JSON inicial, refuerza con una lista mínima
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

    final pool = {...categories, ...fallback}.toList();

    final wrongs = pool.where((c) => c != correct).toList()..shuffle(rnd);
    final options = ([...wrongs.take(3), correct]..shuffle(rnd));

    return Question(
      elementId: el.id,
      prompt: '¿A qué categoría pertenece ${el.name}?',
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }

  static List<ElementItem> _pickDistinct(
    List<ElementItem> all,
    Random rnd, {
    required int count,
    required Set<String> excludeIds,
  }) {
    final list = all.where((e) => !excludeIds.contains(e.id)).toList()
      ..shuffle(rnd);
    return list.take(count).toList();
  }
}
