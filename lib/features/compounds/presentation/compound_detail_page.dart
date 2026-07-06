import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/compounds_repository.dart';

class CompoundDetailPage extends StatelessWidget {
  final String compoundId;

  const CompoundDetailPage({super.key, required this.compoundId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CompoundsRepository>();

    return FutureBuilder<CompoundItem?>(
      future: repo.getById(compoundId),
      builder: (context, snapshot) {
        final compound = snapshot.data;
        final title = compound != null
            ? '${compound.name} (${compound.formula})'
            : snapshot.connectionState != ConnectionState.done
                ? 'Cargando...'
                : 'Compuesto no encontrado';

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : compound == null
                  ? const Center(child: Text('Compuesto no encontrado'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          '${compound.category} - ${compound.state}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masa molar: ${compound.molarMass}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        _Card(title: 'Resumen', body: compound.summary),
                        _Card(title: 'Usos', body: compound.uses),
                        _Card(title: 'Seguridad', body: compound.safety),
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
            Text(body.isEmpty ? '-' : body),
          ],
        ),
      ),
    );
  }
}
