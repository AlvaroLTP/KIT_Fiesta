import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String productId; // ID del kit o del componente extra
  final String title;
  final int quantity;
  final double price;
  final String? imagenUrl;
  final bool isExtra;

  CartItem({
    required this.id,
    required this.productId,
    required this.title,
    required this.quantity,
    required this.price,
    this.imagenUrl,
    this.isExtra = false,
  });

  double get precioTotal => price * quantity;
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.precioTotal;
    });
    return total;
  }

  void addItem(String productId, String title, int quantity, double price, String? imagenUrl, {bool isExtra = false}) {
    // Generar un ID único para cada item del carrito para evitar colisiones
    final cartItemId = isExtra ? 'extra_${productId}_${DateTime.now().toIso8601String()}' : productId;

    if (_items.containsKey(cartItemId) && !isExtra) {
      // Si es un kit (no extra) y ya existe, actualiza la cantidad
      _items.update(
        cartItemId,
        (existingItem) => CartItem(
          id: existingItem.id,
          productId: existingItem.productId,
          title: existingItem.title,
          quantity: existingItem.quantity + quantity,
          price: existingItem.price,
          imagenUrl: existingItem.imagenUrl,
          isExtra: existingItem.isExtra,
        ),
      );
    } else {
      // Si es un extra o un kit nuevo, añade una nueva entrada
      _items.putIfAbsent(
        cartItemId,
        () => CartItem(
          id: DateTime.now().toString(), // ID único para el widget
          productId: productId,
          title: title,
          quantity: quantity,
          price: price,
          imagenUrl: imagenUrl,
          isExtra: isExtra,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String cartItemId) {
    _items.remove(cartItemId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}