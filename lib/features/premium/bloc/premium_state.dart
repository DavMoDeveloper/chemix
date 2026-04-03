import 'package:equatable/equatable.dart';

sealed class PremiumState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PremiumLoading extends PremiumState {}
class PremiumFree extends PremiumState {}
class PremiumActive extends PremiumState {}
class PremiumError extends PremiumState {
  final String message;
  PremiumError(this.message);

  @override
  List<Object?> get props => [message];
}
