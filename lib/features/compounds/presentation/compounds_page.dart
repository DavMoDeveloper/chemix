import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/compounds_bloc.dart';
import '../bloc/compounds_event.dart';
import '../bloc/compounds_state.dart';
import '../data/compounds_repository.dart';

class CompoundsPage extends StatelessWidget {
  const CompoundsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar compuesto (H2O, acido, sal...)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onChanged: (value) => context
                .read<CompoundsBloc>()
                .add(CompoundsSearchChanged(value)),
          ),
        ),
        Expanded(
          child: BlocBuilder<CompoundsBloc, CompoundsState>(
            builder: (context, state) {
              if (state is CompoundsLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is CompoundsError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 56,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => context
                            .read<CompoundsBloc>()
                            .add(CompoundsStarted()),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              if (state is CompoundsLoaded) {
                if (state.filtered.isEmpty && state.query.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, size: 56),
                        const SizedBox(height: 12),
                        Text(
                          'Sin resultados para "${state.query}"',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return _CompoundsList(compounds: state.filtered);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

class _CompoundsList extends StatelessWidget {
  final List<CompoundItem> compounds;

  const _CompoundsList({required this.compounds});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      itemCount: compounds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final compound = compounds[index];
        final color = _compoundColor(compound.category);

        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.go('/compound/${compound.id}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withAlpha(110)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      compound.formula,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          compound.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${compound.category} - ${compound.state}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Color _compoundColor(String category) {
  switch (category.toLowerCase()) {
    case 'acido':
      return const Color(0xFFE57373);
    case 'base':
      return const Color(0xFF64B5F6);
    case 'sal':
      return const Color(0xFF4DB6AC);
    case 'hidrocarburo':
      return const Color(0xFFFFB74D);
    case 'alcohol':
      return const Color(0xFFBA68C8);
    case 'carbohidrato':
      return const Color(0xFFAED581);
    case 'oxido':
      return const Color(0xFF7986CB);
    default:
      return const Color(0xFF9E9E9E);
  }
}
