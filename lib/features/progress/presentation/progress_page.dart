import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/progress_bloc.dart';
import '../bloc/progress_state.dart';
import '../data/progress_repository.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressBloc, ProgressState>(
      builder: (context, state) {
        if (state is! ProgressLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = state.data;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final weakTopics = data.topics.take(4).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tu aprendizaje',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/quiz/review'),
                  icon: const Icon(Icons.today_outlined),
                  label: Text('${data.dueReviewCount}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ReviewTodayCard(data: data),
            const SizedBox(height: 12),
            _StatCard(
              title: 'Dominio de elementos',
              icon: Icons.science_outlined,
              color: colorScheme.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(data.learnedPercent * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${(data.learnedPercent * 118).round()} / 118',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: data.learnedPercent,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    title: 'Quizzes',
                    value: '${data.quizzesCompleted}',
                    icon: Icons.quiz_outlined,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    title: 'Racha',
                    value: '${data.streak} dias',
                    icon: Icons.local_fire_department_outlined,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    title: 'Dominados',
                    value: '${data.masteredCount}',
                    icon: Icons.verified_outlined,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    title: 'Pendientes',
                    value: '${data.dueReviewCount}',
                    icon: Icons.schedule_outlined,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Temas que conviene reforzar',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (weakTopics.isEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.route_outlined),
                  title: const Text('Empieza una ruta'),
                  subtitle:
                      const Text('Practica para desbloquear diagnosticos.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/learn'),
                ),
              )
            else
              ...weakTopics.map((topic) => _TopicTile(topic: topic)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.route_outlined),
                title: const Text('Rutas de aprendizaje'),
                subtitle: const Text('Elige que quieres practicar ahora.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/learn'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReviewTodayCard extends StatelessWidget {
  final ProgressData data;

  const _ReviewTodayCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasDue = data.dueReviewCount > 0;
    final color = hasDue ? Colors.indigo : Colors.green;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(hasDue ? Icons.today_outlined : Icons.check_circle_outline,
                color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasDue ? 'Repaso de hoy' : 'Vas al dia',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasDue
                        ? '${data.dueReviewCount} preguntas listas para reforzar.'
                        : 'No tienes repasos pendientes por ahora.',
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: hasDue ? () => context.go('/quiz/review') : null,
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Repasar',
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _StatCard(
      title: title,
      icon: icon,
      color: color,
      child: Text(
        value,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final TopicProgress topic;

  const _TopicTile({required this.topic});

  @override
  Widget build(BuildContext context) {
    final percent = (topic.mastery * 100).round();
    return Card(
      child: ListTile(
        title: Text(topic.label),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: LinearProgressIndicator(
            value: topic.mastery,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$percent%',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            if (topic.due > 0)
              Text(
                '${topic.due} por repasar',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
