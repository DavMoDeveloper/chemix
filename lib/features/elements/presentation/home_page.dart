import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../elements/bloc/elements_bloc.dart';
import '../../elements/bloc/elements_event.dart';
import '../../elements/bloc/elements_state.dart';
import '../../elements/data/elements_repository.dart';
import '../../progress/presentation/progress_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _ElementsTab(),
      const ProgressPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/branding/logo.png'),
        ),
        title: const Text('Chemix'),
        actions: [
          IconButton(
            onPressed: () => context.go('/quiz'),
            icon: const Icon(Icons.quiz_outlined),
            tooltip: 'Quiz',
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          if (i == 2) {
            context.go('/quiz');
          } else {
            setState(() => index = i);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.format_list_bulleted_outlined),
            selectedIcon: Icon(Icons.format_list_bulleted),
            label: 'Elementos',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Progreso',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
        ],
      ),
    );
  }
}

class _ElementsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar elemento (H, Helio, 8...)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onChanged: (v) =>
                context.read<ElementsBloc>().add(ElementsSearchChanged(v)),
          ),
        ),
        Expanded(
          child: BlocBuilder<ElementsBloc, ElementsState>(
            builder: (context, state) {
              if (state is ElementsLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ElementsError) {
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
                        onPressed: () =>
                            context.read<ElementsBloc>().add(ElementsStarted()),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              if (state is ElementsLoaded) {
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

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final usePeriodicTable = constraints.maxWidth >= 700;
                    if (usePeriodicTable) {
                      return _PeriodicTable(
                        all: state.all,
                        filtered: state.filtered,
                        isSearching: state.query.isNotEmpty,
                      );
                    }

                    return _ElementsList(elements: state.filtered);
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

class _ElementsList extends StatelessWidget {
  final List<ElementItem> elements;

  const _ElementsList({required this.elements});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      itemCount: elements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final el = elements[index];
        final color = _categoryColor(el.category);

        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.go('/element/${el.id}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withAlpha(110)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${el.atomicNumber}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        Text(
                          el.symbol,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          el.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          el.category,
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

class _PeriodicTable extends StatelessWidget {
  final List<ElementItem> all;
  final List<ElementItem> filtered;
  final bool isSearching;

  const _PeriodicTable({
    required this.all,
    required this.filtered,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    final elementMap = {
      for (final el in all) '${el.x},${el.y}': el,
    };
    final filteredIds = filtered.map((e) => e.id).toSet();
    final maxRow = all.map((e) => e.y).fold(4, (max, y) => y > max ? y : max);

    return ClipRect(
      child: InteractiveViewer(
        maxScale: 4.0,
        minScale: 0.4,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(40),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 18 * 65.0,
            height: maxRow * 75.0,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 18,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 0.8,
              ),
              itemCount: 18 * maxRow,
              itemBuilder: (context, i) {
                final x = (i % 18) + 1;
                final y = (i ~/ 18) + 1;

                final el = elementMap['$x,$y'];
                if (el == null) return const SizedBox.shrink();

                final matches = !isSearching || filteredIds.contains(el.id);
                final color = _categoryColor(el.category);

                return Opacity(
                  opacity: matches ? 1.0 : 0.2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.go('/element/${el.id}'),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: color.withAlpha(30),
                        border: Border.all(color: color.withAlpha(100)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${el.atomicNumber}',
                            style: TextStyle(
                              fontSize: 9,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            el.symbol,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            el.name,
                            style: const TextStyle(fontSize: 7),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

Color _categoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'alkali metal':
      return const Color(0xFFE57373);
    case 'alkaline earth metal':
      return const Color(0xFFFFB74D);
    case 'transition metal':
      return const Color(0xFF90CAF9);
    case 'post-transition metal':
      return const Color(0xFF80CBC4);
    case 'metalloid':
      return const Color(0xFFA5D6A7);
    case 'nonmetal':
      return const Color(0xFFCE93D8);
    case 'halogen':
      return const Color(0xFFF48FB1);
    case 'noble gas':
      return const Color(0xFF80DEEA);
    case 'lanthanide':
      return const Color(0xFFFFCC02);
    case 'actinide':
      return const Color(0xFFBCAAA4);
    default:
      return const Color(0xFF9E9E9E);
  }
}
