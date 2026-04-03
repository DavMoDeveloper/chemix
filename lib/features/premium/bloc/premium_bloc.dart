import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/purchase_service.dart';
import 'premium_event.dart';
import 'premium_state.dart';

class PremiumBloc extends Bloc<PremiumEvent, PremiumState> {
  final PurchaseService purchaseService;

  PremiumBloc({required this.purchaseService}) : super(PremiumLoading()) {
    on<PremiumStarted>(_onStarted);
    on<PurchaseRequested>(_onPurchaseRequested);
    on<PurchaseRestored>(_onRestored);
  }

  Future<void> _onStarted(PremiumStarted event, Emitter<PremiumState> emit) async {
    emit(PremiumLoading());
    final active = await purchaseService.hasActiveEntitlement();
    emit(active ? PremiumActive() : PremiumFree());
  }

  Future<void> _onPurchaseRequested(PurchaseRequested e, Emitter<PremiumState> emit) async {
    try {
      await purchaseService.buy(e.productId);
      emit(PremiumActive());
    } catch (_) {
      emit(PremiumError('No se pudo completar la compra.'));
    }
  }

  Future<void> _onRestored(PurchaseRestored event, Emitter<PremiumState> emit) async {
    await purchaseService.restore();
    add(PremiumStarted());
  }
}
