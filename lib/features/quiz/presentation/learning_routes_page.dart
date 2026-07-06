import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/quiz_generator.dart';

class LearningRoutesPage extends StatelessWidget {
  const LearningRoutesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final routes = [
      QuizMode.reviewDue,
      QuizMode.mixed,
      QuizMode.elementsBasics,
      QuizMode.elementCategories,
      QuizMode.compounds,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Rutas de aprendizaje')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: routes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final mode = routes[index];
          return Card(
            child: ListTile(
              leading: Icon(_iconFor(mode)),
              title: Text(
                mode.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(mode.description),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                if (mode == QuizMode.reviewDue) {
                  context.go('/quiz/review');
                } else {
                  context.go('/quiz?mode=${mode.name}');
                }
              },
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(QuizMode mode) {
    switch (mode) {
      case QuizMode.reviewDue:
        return Icons.today_outlined;
      case QuizMode.mixed:
        return Icons.shuffle_outlined;
      case QuizMode.elementsBasics:
        return Icons.abc_outlined;
      case QuizMode.elementCategories:
        return Icons.category_outlined;
      case QuizMode.compounds:
        return Icons.science_outlined;
    }
  }
}
