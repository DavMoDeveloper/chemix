import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/elements_repository.dart';

class ElementDetailPage extends StatelessWidget {
  final String elementId;
  const ElementDetailPage({super.key, required this.elementId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ElementsRepository>();

    return FutureBuilder<ElementItem?>(
      future: repo.getById(elementId),
      builder: (context, snapshot) {
        final el = snapshot.data;
        // UX-15: título dinámico con el nombre del elemento
        final title = el != null
            ? '${el.name} (${el.symbol})'
            : snapshot.connectionState != ConnectionState.done
                ? 'Cargando…'
                : 'Elemento no encontrado';

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : el == null
                  ? const Center(child: Text('Elemento no encontrado'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('Nº atómico: ${el.atomicNumber} • ${el.category}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        _Card(title: 'Resumen', body: el.summary),
                        _Card(title: 'Usos', body: el.uses),
                        _Card(title: 'Dato curioso', body: el.funFact),
                      ],
                    ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String body;
  const _Card({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(body.isEmpty ? '—' : body),
          ],
        ),
      ),
    );
  }
}
