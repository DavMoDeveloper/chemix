import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/premium_bloc.dart';
import '../bloc/premium_event.dart';
import '../bloc/premium_state.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Premium'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocConsumer<PremiumBloc, PremiumState>(
        listener: (context, state) {
          if (state is PremiumError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
          if (state is PremiumActive) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Bienvenido a Chemix Premium! 🎉')),
            );
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          final isLoading = state is PremiumLoading;
          final isPremium = state is PremiumActive;

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primaryContainer.withAlpha(150),
                      colorScheme.surface,
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            const Icon(Icons.star_rounded, size: 80, color: Colors.amber),
                            const SizedBox(height: 16),
                            Text(
                              'Domina la Química',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Consigue todas las herramientas para ser un experto',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
                              ),
                            ),
                            const SizedBox(height: 40),

                            _BenefitCard(
                              icon: Icons.quiz_rounded,
                              iconColor: Colors.blue,
                              title: 'Quizzes Ilimitados',
                              subtitle: 'No te detengas, practica cuanto quieras.',
                            ),
                            _BenefitCard(
                              icon: Icons.auto_graph_rounded,
                              iconColor: Colors.green,
                              title: 'Estadísticas Avanzadas',
                              subtitle: 'Visualiza tu progreso elemento a elemento.',
                            ),
                            _BenefitCard(
                              icon: Icons.no_accounts_rounded,
                              iconColor: Colors.orange,
                              title: 'Cero Anuncios',
                              subtitle: 'Concentración total en tu estudio.',
                            ),
                            _BenefitCard(
                              icon: Icons.offline_bolt_rounded,
                              iconColor: Colors.purple,
                              title: 'Modo Offline',
                              subtitle: 'Estudia incluso sin conexión a internet.',
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPremium)
                            Text(
                              '✓ Ya eres miembro Premium',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          else ...[
                            _PricingOption(
                              title: 'Anual (Recomendado)',
                              price: '\$19.99 / año',
                              savings: 'Ahorra 40%',
                              isSelected: true,
                              onTap: isLoading ? null : () => 
                                context.read<PremiumBloc>().add(PurchaseRequested('premium_yearly')),
                            ),
                            const SizedBox(height: 12),
                            _PricingOption(
                              title: 'Mensual',
                              price: '\$3.99 / mes',
                              savings: '',
                              isSelected: false,
                              onTap: isLoading ? null : () => 
                                context.read<PremiumBloc>().add(PurchaseRequested('premium_monthly')),
                            ),
                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: isLoading ? null : () => context.read<PremiumBloc>().add(PurchaseRestored()),
                              child: const Text('¿Ya lo compraste? Restaurar compra'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (isLoading)
                Container(
                  color: Colors.black.withAlpha(60),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _BenefitCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingOption extends StatelessWidget {
  final String title;
  final String price;
  final String savings;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PricingOption({
    required this.title,
    required this.price,
    required this.savings,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.grey.withAlpha(50),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? colorScheme.primary.withAlpha(10) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (savings.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            savings,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(price, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
