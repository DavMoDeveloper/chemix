import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../compounds/data/compounds_repository.dart';
import '../../elements/data/elements_repository.dart';
import '../bloc/quiz_bloc.dart';
import '../bloc/quiz_event.dart';
import '../bloc/quiz_state.dart';
import '../domain/quiz_generator.dart';

class QuizPage extends StatefulWidget {
  final bool isReviewMode;
  final QuizMode mode;

  const QuizPage({
    super.key,
    this.isReviewMode = false,
    this.mode = QuizMode.mixed,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  bool _exitDialogOpen = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isReviewMode) {
      context.read<QuizBloc>().add(QuizStarted(mode: widget.mode));
    }
  }

  Future<void> _requestExit() async {
    if (_exitDialogOpen) return;

    final quizState = context.read<QuizBloc>().state;
    if (quizState is! QuizInProgress) {
      context.go('/learn');
      return;
    }

    _exitDialogOpen = true;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Salir del quiz?'),
        content: const Text(
          'Si sales ahora, perderás el progreso de este quiz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Seguir en el quiz'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    _exitDialogOpen = false;

    if (shouldExit == true && mounted) {
      context.go('/learn');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _requestExit,
            tooltip: 'Salir del quiz',
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            widget.isReviewMode ? 'Repaso de hoy' : widget.mode.title,
          ),
        ),
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
                        'Quieres mejorar mas rapido?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
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
              if (state is QuizInitial) {
                return const Center(child: CircularProgressIndicator());
              }

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
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            if (state.showPremiumAction)
                              FilledButton.icon(
                                onPressed: () => context.go('/premium'),
                                icon: const Icon(Icons.workspace_premium),
                                label: const Text('Ver Premium'),
                              ),
                            FilledButton.tonalIcon(
                              onPressed: () => context.go('/learn'),
                              icon: const Icon(Icons.route_outlined),
                              label: const Text('Volver'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is QuizInProgress) {
                return _QuizBody(state: state);
              }

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
      ),
    );
  }
}

class _QuizBody extends StatelessWidget {
  final QuizInProgress state;

  const _QuizBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final q = state.current;
    final hasAnswered = state.selected != null;
    final isCorrect = hasAnswered && state.selected == q.correctIndex;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(q.prompt, style: Theme.of(context).textTheme.titleMedium),
                if (hasAnswered)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _AnswerFeedback(
                      isCorrect: isCorrect,
                      selectedAnswer: q.options[state.selected!],
                      correctAnswer: q.correctAnswer,
                      explanation: q.explanation,
                    ),
                  ),
                const SizedBox(height: 16),
                ...List.generate(q.options.length, (i) {
                  final isSelected = state.selected == i;
                  final isCorrectOption = i == q.correctIndex;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _optionColor(
                            context: context,
                            isSelected: isSelected,
                            isCorrect: isCorrectOption,
                            hasAnswered: hasAnswered,
                          ),
                          foregroundColor: hasAnswered
                              ? Colors.white
                              : Theme.of(context).colorScheme.onPrimary,
                          disabledBackgroundColor: _optionColor(
                            context: context,
                            isSelected: isSelected,
                            isCorrect: isCorrectOption,
                            hasAnswered: hasAnswered,
                          ),
                          disabledForegroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: hasAnswered
                            ? null
                            : () =>
                                context.read<QuizBloc>().add(AnswerSelected(i)),
                        child: Text(q.options[i], textAlign: TextAlign.center),
                      ),
                    ),
                  );
                }),
                if (hasAnswered && !isCorrect) ...[
                  const SizedBox(height: 12),
                  _LearnCard(questionItemId: q.itemId, itemType: q.itemType),
                ],
                const Spacer(),
                AnimatedOpacity(
                  opacity: hasAnswered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
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
          ),
        ),
      ],
    );
  }

  Color _optionColor({
    required BuildContext context,
    required bool isSelected,
    required bool isCorrect,
    required bool hasAnswered,
  }) {
    if (!hasAnswered) return Theme.of(context).colorScheme.primary;
    if (isSelected && isCorrect) return Colors.green;
    if (isSelected && !isCorrect) return Colors.red;
    if (!isSelected && isCorrect) return Colors.green.shade300;
    return Colors.grey;
  }
}

class _AnswerFeedback extends StatelessWidget {
  final bool isCorrect;
  final String selectedAnswer;
  final String correctAnswer;
  final String explanation;

  const _AnswerFeedback({
    required this.isCorrect,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? Colors.green : Colors.red;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(110)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isCorrect ? 'Correcto' : 'Incorrecto',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 8),
              Text('Tu respuesta: $selectedAnswer'),
              Text('Respuesta correcta: $correctAnswer'),
            ],
            const SizedBox(height: 8),
            Text(explanation),
          ],
        ),
      ),
    );
  }
}

class _LearnCard extends StatelessWidget {
  final String questionItemId;
  final String itemType;

  const _LearnCard({
    required this.questionItemId,
    required this.itemType,
  });

  @override
  Widget build(BuildContext context) {
    if (itemType == 'compound') {
      final repo = context.read<CompoundsRepository>();
      return FutureBuilder(
        future: repo.getById(questionItemId),
        builder: (context, snapshot) {
          final compound = snapshot.data;
          if (compound == null) return const SizedBox.shrink();
          return _LearningSummary(
            title: 'Aprende: ${compound.name} (${compound.formula})',
            lines: [
              compound.summary,
              'Tipo: ${compound.category}',
              'Usos: ${compound.uses.join(', ')}',
              'Seguridad: ${compound.safety}',
            ],
          );
        },
      );
    }

    final repo = context.read<ElementsRepository>();
    return FutureBuilder(
      future: repo.getById(questionItemId),
      builder: (context, snapshot) {
        final el = snapshot.data;
        if (el == null) return const SizedBox.shrink();
        return _LearningSummary(
          title: 'Aprende: ${el.name} (${el.symbol})',
          lines: [
            el.summary,
            'Categoria: ${el.category}',
            'Usos: ${el.uses.join(', ')}',
            'Dato curioso: ${el.funFact}',
          ],
        );
      },
    );
  }
}

class _LearningSummary extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _LearningSummary({
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...lines.where((line) => line.trim().isNotEmpty).map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(line),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
