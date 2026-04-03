import 'package:equatable/equatable.dart';
import '../data/elements_repository.dart';

sealed class ElementsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ElementsInitial extends ElementsState {}

class ElementsLoading extends ElementsState {}

class ElementsLoaded extends ElementsState {
  final List<ElementItem> all;
  final List<ElementItem> filtered;
  final String query;

  ElementsLoaded({required this.all, required this.filtered, required this.query});

  @override
  List<Object?> get props => [all, filtered, query];
}

class ElementsError extends ElementsState {
  final String message;
  ElementsError(this.message);

  @override
  List<Object?> get props => [message];
}
