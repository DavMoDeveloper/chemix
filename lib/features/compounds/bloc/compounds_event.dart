import 'package:equatable/equatable.dart';

sealed class CompoundsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CompoundsStarted extends CompoundsEvent {}

class CompoundsSearchChanged extends CompoundsEvent {
  final String query;

  CompoundsSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}
