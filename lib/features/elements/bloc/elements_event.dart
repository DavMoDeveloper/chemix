import 'package:equatable/equatable.dart';

sealed class ElementsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ElementsStarted extends ElementsEvent {}

class ElementsSearchChanged extends ElementsEvent {
  final String query;
  ElementsSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}
