import 'package:equatable/equatable.dart';

import '../data/compounds_repository.dart';

sealed class CompoundsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CompoundsInitial extends CompoundsState {}

class CompoundsLoading extends CompoundsState {}

class CompoundsLoaded extends CompoundsState {
  final List<CompoundItem> all;
  final List<CompoundItem> filtered;
  final String query;

  CompoundsLoaded({
    required this.all,
    required this.filtered,
    required this.query,
  });

  @override
  List<Object?> get props => [all, filtered, query];
}

class CompoundsError extends CompoundsState {
  final String message;

  CompoundsError(this.message);

  @override
  List<Object?> get props => [message];
}
