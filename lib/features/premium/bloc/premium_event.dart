import 'package:equatable/equatable.dart';

sealed class PremiumEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PremiumStarted extends PremiumEvent {}
class PurchaseRequested extends PremiumEvent {
  final String productId;
  PurchaseRequested(this.productId);

  @override
  List<Object?> get props => [productId];
}
class PurchaseRestored extends PremiumEvent {}
