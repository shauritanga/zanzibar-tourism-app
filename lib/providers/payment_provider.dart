import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/services/payment_service.dart';

final paymentHistoryProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  final paymentService = ref.read(paymentServiceProvider);
  return Stream.fromFuture(paymentService.getPaymentHistory(userId));
});

final paymentDetailsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, paymentId) {
  final paymentService = ref.read(paymentServiceProvider);
  return paymentService.getPaymentDetails(paymentId);
});

class PaymentNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  PaymentNotifier(this._paymentService) : super(const AsyncValue.data(null));

  final PaymentService _paymentService;

  Future<void> processPayment({
    required String userId,
    required double amount,
    required String currency,
    required PaymentMethod method,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final result = await _paymentService.processPayment(
        userId: userId,
        amount: amount,
        currency: currency,
        method: method,
        description: description,
        metadata: metadata,
      );
      
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refundPayment(String paymentId, {String? reason}) async {
    try {
      await _paymentService.refundPayment(paymentId, reason: reason);
      // Refresh the current state or emit success
      state = AsyncValue.data({'success': true, 'action': 'refund'});
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearState() {
    state = const AsyncValue.data(null);
  }
}

final paymentNotifierProvider = StateNotifierProvider<PaymentNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  final paymentService = ref.read(paymentServiceProvider);
  return PaymentNotifier(paymentService);
});

// Shopping cart provider for marketplace
class CartItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String image;
  final String sellerId;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
    required this.sellerId,
  });

  double get total => price * quantity;

  CartItem copyWith({
    String? productId,
    String? name,
    double? price,
    int? quantity,
    String? image,
    String? sellerId,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      image: image ?? this.image,
      sellerId: sellerId ?? this.sellerId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image': image,
      'sellerId': sellerId,
    };
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CartItem item) {
    final existingIndex = state.indexWhere((cartItem) => cartItem.productId == item.productId);
    
    if (existingIndex >= 0) {
      // Update quantity if item already exists
      final updatedItem = state[existingIndex].copyWith(
        quantity: state[existingIndex].quantity + item.quantity,
      );
      state = [
        ...state.sublist(0, existingIndex),
        updatedItem,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      // Add new item
      state = [...state, item];
    }
  }

  void removeItem(String productId) {
    state = state.where((item) => item.productId != productId).toList();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = state.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      final updatedItem = state[index].copyWith(quantity: quantity);
      state = [
        ...state.sublist(0, index),
        updatedItem,
        ...state.sublist(index + 1),
      ];
    }
  }

  void clearCart() {
    state = [];
  }

  double get totalAmount => state.fold(0.0, (sum, item) => sum + item.total);
  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

// Computed providers for cart
final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.total);
});

final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

// Order management
class OrderNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  OrderNotifier(this._paymentService) : super(const AsyncValue.data(null));

  final PaymentService _paymentService;

  Future<void> createOrder({
    required String userId,
    required List<CartItem> items,
    required PaymentMethod paymentMethod,
    Map<String, dynamic>? shippingAddress,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final totalAmount = items.fold(0.0, (sum, item) => sum + item.total);
      
      // Process payment
      final paymentResult = await _paymentService.processPayment(
        userId: userId,
        amount: totalAmount,
        currency: 'USD',
        method: paymentMethod,
        description: 'Marketplace order - ${items.length} items',
        metadata: {
          'orderType': 'marketplace',
          'itemCount': items.length,
          'items': items.map((item) => item.toMap()).toList(),
          'shippingAddress': shippingAddress,
          'notes': notes,
        },
      );

      state = AsyncValue.data(paymentResult);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearState() {
    state = const AsyncValue.data(null);
  }
}

final orderNotifierProvider = StateNotifierProvider<OrderNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  final paymentService = ref.read(paymentServiceProvider);
  return OrderNotifier(paymentService);
});
