import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pos_providers.dart';
import 'store_providers.dart';
import 'package:ibct_eventos/features/users/presentation/providers/user_providers.dart';

final storeControllerProvider = AsyncNotifierProvider<StoreController, void>(StoreController.new);

class StoreController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // No initial state
  }

  Future<void> processCartSale({
    required String eventId,
    required String participantId,
    required String participantName,
    required List<CartItem> items,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(processSaleUseCaseProvider);
      final currentUser = ref.read(currentUserProvider).value;
      
      await useCase.executeCart(
        eventId: eventId,
        participantId: participantId,
        participantName: participantName,
        items: items,
        sellerId: currentUser?.id ?? 'unknown',
      );
    });
  }
  
  Future<void> processSale({
    required String eventId,
    required String participantId,
    required String participantName,
    required String productName,
    required double price,
  }) async {
       state = const AsyncLoading();
       state = await AsyncValue.guard(() async {
          final useCase = ref.read(processSaleUseCaseProvider);
          final currentUser = ref.read(currentUserProvider).value;

          await useCase.executeSingle(
            eventId: eventId,
            participantId: participantId,
            participantName: participantName,
            productName: productName,
            price: price,
            sellerId: currentUser?.id ?? 'unknown',
          );
       });
  }
}
