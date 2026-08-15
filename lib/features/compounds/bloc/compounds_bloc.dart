import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/compounds_repository.dart';
import 'compounds_event.dart';
import 'compounds_state.dart';

class CompoundsBloc extends Bloc<CompoundsEvent, CompoundsState> {
  final CompoundsRepository repo;

  CompoundsBloc({required this.repo}) : super(CompoundsInitial()) {
    on<CompoundsStarted>(_onStarted);
    on<CompoundsSearchChanged>(_onSearchChanged);
  }

  Future<void> _onStarted(
    CompoundsStarted event,
    Emitter<CompoundsState> emit,
  ) async {
    emit(CompoundsLoading());
    try {
      final all = await repo.getAll();
      emit(CompoundsLoaded(all: all, filtered: all, query: ''));
    } catch (_) {
      emit(CompoundsError('No se pudo cargar compounds.json'));
    }
  }

  void _onSearchChanged(
    CompoundsSearchChanged event,
    Emitter<CompoundsState> emit,
  ) {
    final s = state;
    if (s is! CompoundsLoaded) return;

    final q = event.query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? s.all
        : s.all.where((compound) {
            return compound.name.toLowerCase().contains(q) ||
                compound.formula.toLowerCase().contains(q) ||
                compound.category.toLowerCase().contains(q) ||
                compound.state.toLowerCase().contains(q) ||
                compound.uses.any((use) => use.toLowerCase().contains(q));
          }).toList();

    emit(CompoundsLoaded(all: s.all, filtered: filtered, query: event.query));
  }
}
