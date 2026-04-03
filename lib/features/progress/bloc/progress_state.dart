import 'package:equatable/equatable.dart';
import '../data/progress_repository.dart';

sealed class ProgressState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProgressLoading extends ProgressState {}
class ProgressLoaded extends ProgressState {
  final ProgressData data;
  ProgressLoaded(this.data);

  @override
  List<Object?> get props => [data];
}
