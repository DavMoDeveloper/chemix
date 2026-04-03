import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuizResultPage extends StatefulWidget {
  final int score;
  final int total;

  const QuizResultPage({super.key, required this.score, required this.total});

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final AnimationController _progressCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _progressAnim;

  bool get perfect => widget.score == widget.total;
  bool get great => widget.score >= (widget.total * 0.8).ceil();

  double get percent => widget.score / widget.total;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _progressAnim = CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut);

    _progressCtrl.forward();
    if (perfect || great) _scaleCtrl.forward();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (emoji, message, messageColor) = switch (true) {
      _ when perfect => ('🎉', '¡Perfecto! ¡Eres increíble!', Colors.amber),
      _ when great => ('🔥', '¡Muy bien! Sigue así', Colors.orange),
      _ when widget.score >= widget.total ~/ 2 => ('💪', 'Buen intento, puedes hacerlo mejor', colorScheme.primary),
      _ => ('📚', 'Sigue practicando, ¡tú puedes!', Colors.grey),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji animado
              ScaleTransition(
                scale: _scaleAnim.value == 0 && !(perfect || great)
                    ? const AlwaysStoppedAnimation(1.0)
                    : _scaleAnim,
                child: Text(emoji, style: const TextStyle(fontSize: 72)),
              ),
              const SizedBox(height: 24),

              // Indicador circular de progreso
              SizedBox(
                width: 140,
                height: 140,
                child: AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (context, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: percent * _progressAnim.value,
                          strokeWidth: 10,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            perfect
                                ? Colors.amber
                                : great
                                    ? Colors.orange
                                    : colorScheme.primary,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${widget.score}/${widget.total}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${(percent * 100).toStringAsFixed(0)}%',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Mensaje
              Text(
                message,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: messageColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Botones
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go('/quiz'),
                  icon: const Icon(Icons.replay),
                  label: const Text('Repetir quiz'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/quiz/review'),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Repasar errores'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
