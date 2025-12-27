import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  double get totalPrice => product.price * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartState {
  final List<CartItem> items;

  CartState({this.items = const []});

  double get total => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return CartState();
  }

  void addItem(Product product) {
    if (!product.isAvailable) return;

    final existingIndex = state.items.indexWhere((i) => i.product.id == product.id);
    if (existingIndex >= 0) {
      final newItems = List<CartItem>.from(state.items);
      newItems[existingIndex] = newItems[existingIndex].copyWith(
        quantity: newItems[existingIndex].quantity + 1,
      );
      state = state.copyWith(items: newItems);
    } else {
      state = state.copyWith(items: [...state.items, CartItem(product: product, quantity: 1)]);
    }
  }

  void removeItem(Product product) {
    final existingIndex = state.items.indexWhere((i) => i.product.id == product.id);
    if (existingIndex >= 0) {
      final newItems = List<CartItem>.from(state.items);
      if (newItems[existingIndex].quantity > 1) {
        newItems[existingIndex] = newItems[existingIndex].copyWith(
          quantity: newItems[existingIndex].quantity - 1,
        );
        state = state.copyWith(items: newItems);
      } else {
        newItems.removeAt(existingIndex);
        state = state.copyWith(items: newItems);
      }
    }
  }

  void clear() {
    state = CartState();
  }
}

final posCartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
