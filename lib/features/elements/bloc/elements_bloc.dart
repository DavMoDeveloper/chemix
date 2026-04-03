import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/elements_repository.dart';
import 'elements_event.dart';
import 'elements_state.dart';

class ElementsBloc extends Bloc<ElementsEvent, ElementsState> {
  final ElementsRepository repo;

  ElementsBloc({required this.repo}) : super(ElementsInitial()) {
    on<ElementsStarted>(_onStarted);
    on<ElementsSearchChanged>(_onSearchChanged);
  }

  Future<void> _onStarted(ElementsStarted event, Emitter<ElementsState> emit) async {
    emit(ElementsLoading());
    try {
      final all = await repo.getAll();
      emit(ElementsLoaded(all: all, filtered: all, query: ''));
    } catch (e) {
      emit(ElementsError('No se pudo cargar elements.json'));
    }
  }

  void _onSearchChanged(ElementsSearchChanged event, Emitter<ElementsState> emit) {
    final s = state;
    if (s is! ElementsLoaded) return;

    final q = event.query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? s.all
        : s.all.where((el) {
            return el.name.toLowerCase().contains(q) ||
                el.symbol.toLowerCase().contains(q) ||
                el.atomicNumber.toString() == q;
          }).toList();

    emit(ElementsLoaded(all: s.all, filtered: filtered, query: event.query));
  }
}
