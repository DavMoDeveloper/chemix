import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/quiz_bloc.dart';
import '../bloc/quiz_event.dart';
import '../bloc/quiz_state.dart';

import '../../elements/data/elements_repository.dart';

class QuizPage extends StatefulWidget {
  /// En modo repaso, el evento ya fue enviado por QuizReviewPage antes de construir.
  /// [isReviewMode] solo sirve para mostrar el título correcto en el AppBar.
  final bool isReviewMode;
  const QuizPage({super.key, this.isReviewMode = false});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  @override
  void initState() {
    super.initState();
    // FIX Bug #2: iniciar el quiz en initState, no dentro del builder
    if (!widget.isReviewMode) {
      context.read<QuizBloc>().add(QuizStarted());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // UX-10: título diferenciado por modo
        title: Text(widget.isReviewMode ? 'Repaso de errores' : 'Quiz'),
      ),

      // FIX Bug #3: BlocListener separado para mostrar el modal premium UNA sola vez
      body: BlocListener<QuizBloc, QuizState>(
        listenWhen: (prev, curr) =>
            curr is QuizInProgress &&
            curr.showPremiumNudge &&
            (prev is! QuizInProgress || !prev.showPremiumNudge),
        listener: (context, state) async {
          if (state is! QuizInProgress) return;
          final goPremium = await showModalBottomSheet<bool>(
            context: context,
            showDragHandle: true,
            builder: (_) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '¿Quieres mejorar más rápido? 🚀',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Con Premium tienes quizzes ilimitados, progreso completo y sin anuncios.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Ver Premium'),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Seguir practicando'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
          if (goPremium == true && context.mounted) {
            context.go('/premium');
          }
        },

        child: BlocBuilder<QuizBloc, QuizState>(
          builder: (context, state) {
            // 1️⃣ Cargando
            if (state is QuizInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2️⃣ Bloqueado
            if (state is QuizLocked) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_clock_outlined, size: 56),
                      const SizedBox(height: 16),
                      Text(
                        state.reason,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => context.go('/premium'),
                        icon: const Icon(Icons.star_outlined),
                        label: const Text('Hazte Premium'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // 3️⃣ Quiz en progreso
            if (state is QuizInProgress) {
              final q = state.current;
              final hasAnswered = state.selected != null;
              final isCorrect = hasAnswered && state.selected == q.correctIndex;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // UX-3: barra de progreso
                    LinearProgressIndicator(
                      value: (state.index + 1) / state.questions.length,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Pregunta ${state.index + 1} de ${state.questions.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),

                    // Pregunta
                    Text(
                      q.prompt,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    // Feedback texto
                    if (hasAnswered)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          state.selected == q.correctIndex
                              ? '✅ Correcto'
                              : '❌ Incorrecto',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: state.selected == q.correctIndex
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Opciones
                    ...List.generate(q.options.length, (i) {
                      final isSelected = state.selected == i;
                      final isCorrectOption = i == q.correctIndex;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: SizedBox(
                          width: double.infinity,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _optionColor(
                                  isSelected: isSelected,
                                  isCorrect: isCorrectOption,
                                  hasAnswered: hasAnswered,
                                ),
                                foregroundColor: hasAnswered
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onPrimary,
                                disabledBackgroundColor: _optionColor(
                                  isSelected: isSelected,
                                  isCorrect: isCorrectOption,
                                  hasAnswered: hasAnswered,
                                ),
                                disabledForegroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: hasAnswered
                                  ? null
                                  : () => context
                                      .read<QuizBloc>()
                                      .add(AnswerSelected(i)),
                              child: Text(q.options[i]),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Card de aprendizaje cuando la respuesta es incorrecta
                    if (hasAnswered && !isCorrect) ...[
                      const SizedBox(height: 12),
                      _LearnCard(elementId: q.elementId),
                    ],

                    const Spacer(),

                    // UX-4: botón siguiente con animación suave
                    AnimatedOpacity(
                      opacity: hasAnswered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: hasAnswered
                              ? () => context.read<QuizBloc>().add(NextQuestion())
                              : null,
                          child: const Text('Siguiente'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // 4️⃣ Quiz terminado → navega a resultado
            if (state is QuizCompleted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go(
                    '/quiz/result',
                    extra: {
                      'score': state.score,
                      'total': state.total,
                    },
                  );
                }
              });
              return const SizedBox.shrink();
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Color _optionColor({
    required bool isSelected,
    required bool isCorrect,
    required bool hasAnswered,
  }) {
    if (!hasAnswered) return Colors.indigo;
    if (isSelected && isCorrect) return Colors.green;
    if (isSelected && !isCorrect) return Colors.red;
    if (!isSelected && isCorrect) return Colors.green.shade300;
    return Colors.grey;
  }
}

class _LearnCard extends StatelessWidget {
  final String elementId;
  const _LearnCard({required this.elementId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ElementsRepository>();

    return FutureBuilder(
      future: repo.getById(elementId),
      builder: (context, snapshot) {
        final el = snapshot.data;
        if (el == null) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aprende: ${el.name} (${el.symbol})',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(el.summary.isEmpty ? '—' : el.summary),
                const SizedBox(height: 10),
                const Text('Usos:',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text(el.uses.isEmpty ? '—' : el.uses),
                const SizedBox(height: 10),
                const Text('Dato curioso:',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text(el.funFact.isEmpty ? '—' : el.funFact),
              ],
            ),
          ),
        );
      },
    );
  }
}
