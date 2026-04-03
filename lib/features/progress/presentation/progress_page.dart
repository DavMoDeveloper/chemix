import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/progress_bloc.dart';
import '../bloc/progress_state.dart';
import 'package:go_router/go_router.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressBloc, ProgressState>(
      builder: (context, state) {
        if (state is! ProgressLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = state.data;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Tu progreso',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            // Tarjeta: tabla aprendida
            _StatCard(
              title: 'Tabla aprendida',
              icon: Icons.science_outlined,
              color: colorScheme.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(d.learnedPercent * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${(d.learnedPercent * 118).round()} / 118 elementos',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: d.learnedPercent,
                      minHeight: 10,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Fila: quizzes y racha
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Quizzes',
                    icon: Icons.quiz_outlined,
                    color: Colors.orange,
                    child: Text(
                      '${d.quizzesCompleted}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Racha',
                    icon: Icons.local_fire_department_outlined,
                    color: Colors.red,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${d.streak}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.red,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 4),
                          child: Text('días',
                              style: theme.textTheme.bodySmall),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Acciones
            Card(
              child: ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Repasar errores'),
                subtitle: const Text('Practica solo lo que fallaste'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/quiz/review'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Estadísticas avanzadas'),
                subtitle: const Text('Disponible en Premium'),
                trailing: const Icon(Icons.star_outlined, color: Colors.amber),
                onTap: () => context.go('/premium'),
              ),
            ),
          ],
        );
      },
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
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
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
