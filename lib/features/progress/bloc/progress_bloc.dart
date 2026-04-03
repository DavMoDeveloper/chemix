import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/progress_repository.dart';
import 'progress_event.dart';
import 'progress_state.dart';

class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  final ProgressRepository repo;

  ProgressBloc({required this.repo}) : super(ProgressLoading()) {
    on<ProgressStarted>(_onStarted);
    on<ProgressUpdatedAfterQuiz>(_onUpdatedAfterQuiz);
  }

  Future<void> _onStarted(ProgressStarted event, Emitter<ProgressState> emit) async {
    final data = await repo.load();
    emit(ProgressLoaded(data));
  }

  Future<void> _onUpdatedAfterQuiz(ProgressUpdatedAfterQuiz e, Emitter<ProgressState> emit) async {
    await repo.updateAfterQuiz(
      score: e.score,
      total: e.total,
      correctElementIds: e.correctElementIds,
    );
    final data = await repo.load();
    emit(ProgressLoaded(data));
  }
}
