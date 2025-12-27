import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/features/store/domain/models/product.dart';
import 'package:ibct_eventos/features/store/presentation/providers/store_providers.dart';
import 'package:ibct_eventos/features/store/presentation/providers/pos_providers.dart';
import 'package:ibct_eventos/features/store/domain/usecases/process_sale_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockProcessSaleUseCase extends Mock implements ProcessSaleUseCase {}

void main() {
  late MockProcessSaleUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockProcessSaleUseCase();
  });

  group('StoreController', () {
    test('processSale should call use case and set state', () async {
      when(() => mockUseCase.executeSingle(
        eventId: any(named: 'eventId'),
        participantId: any(named: 'participantId'),
        participantName: any(named: 'participantName'),
        productName: any(named: 'productName'),
        price: any(named: 'price'),
        sellerId: any(named: 'sellerId'),
      )).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          processSaleUseCaseProvider.overrideWithValue(mockUseCase),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(storeControllerProvider.notifier);

      await controller.processSale(
        eventId: 'event_1',
        participantId: 'p1',
        participantName: 'John',
        productName: 'T-Shirt',
        price: 20.0,
      );

      verify(() => mockUseCase.executeSingle(
        eventId: 'event_1',
        participantId: 'p1',
        participantName: 'John',
        productName: 'T-Shirt',
        price: 20.0,
        sellerId: 'unknown', // Default when no user logged in
      )).called(1);

      final actualState = container.read(storeControllerProvider);
      expect(actualState, isA<AsyncData>());
    });

    test('processSale should set error state on failure', () async {
      final exception = Exception('Failed');
      when(() => mockUseCase.executeSingle(
        eventId: any(named: 'eventId'),
        participantId: any(named: 'participantId'),
        participantName: any(named: 'participantName'),
        productName: any(named: 'productName'),
        price: any(named: 'price'),
        sellerId: any(named: 'sellerId'),
      )).thenThrow(exception);

      final container = ProviderContainer(
        overrides: [
          processSaleUseCaseProvider.overrideWithValue(mockUseCase),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(storeControllerProvider.notifier);

      await controller.processSale(
        eventId: 'event_1',
        participantId: 'p1',
        participantName: 'John',
        productName: 'T-Shirt',
        price: 20.0,
      );

      final state = container.read(storeControllerProvider);
      expect(state, isA<AsyncError>());
    });

    test('processCartSale should call use case and set state', () async {
       when(() => mockUseCase.executeCart(
        eventId: any(named: 'eventId'),
        participantId: any(named: 'participantId'),
        participantName: any(named: 'participantName'),
        items: any(named: 'items'),
        sellerId: any(named: 'sellerId'),
      )).thenAnswer((_) async {});

       final container = ProviderContainer(
        overrides: [
           processSaleUseCaseProvider.overrideWithValue(mockUseCase),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(storeControllerProvider.notifier);

      final product1 = Product(id: '1', name: 'Item 1', price: 10.0, eventId: 'e1', description: '', imageUrl: '', isAvailable: true, category: '');
      final items = [
        CartItem(product: product1, quantity: 2), 
      ];

      await controller.processCartSale(
        eventId: 'e1',
        participantId: 'p1',
        participantName: 'John',
        items: items,
      );
      
      verify(() => mockUseCase.executeCart(
        eventId: 'e1',
        participantId: 'p1',
        participantName: 'John',
        items: items,
        sellerId: 'unknown',
      )).called(1);
      
      final state = container.read(storeControllerProvider);
      expect(state, isA<AsyncData>());
    });
  });
}

