import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './cart_provider.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;
  // HU-C4: Nuevos campos
  final String tipoEntrega;
  final String? direccion;
  final DateTime fechaProgramada;

  OrderItem({
    required this.id,
    required this.amount,
    required this.products,
    required this.dateTime,
    // HU-C4: Campos requeridos en el constructor
    required this.tipoEntrega,
    this.direccion,
    required this.fechaProgramada,
  });
}

class OrdersProvider with ChangeNotifier {
  List<OrderItem> _orders = [];

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> fetchAndSetOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final List<OrderItem> loadedOrders = [];
    final querySnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('dateTime', descending: true)
        .get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      loadedOrders.add(
        OrderItem(
          id: doc.id,
          amount: data['amount'],
          dateTime: DateTime.parse(data['dateTime']),
          // HU-C4: Leer los nuevos campos de Firestore
          tipoEntrega: data['tipoEntrega'] ?? 'No especificado',
          direccion: data['direccion'],
          fechaProgramada: data['fechaProgramada'] != null
              ? DateTime.parse(data['fechaProgramada'])
              : DateTime.now(), // Fallback por si acaso
          products: (data['products'] as List<dynamic>)
              .map(
                (item) => CartItem(
                  id: item['id'],
                  productId: item['productId'],
                  title: item['title'],
                  quantity: item['quantity'],
                  price: item['price'],
                  imagenUrl: item['imagenUrl'],
                  isExtra: item['isExtra'] ?? false,
                ),
              )
              .toList(),
        ),
      );
    }
    _orders = loadedOrders;
    notifyListeners();
  }

  // HU-C4: El método ahora acepta los nuevos datos
  Future<void> addOrder({
    required List<CartItem> cartProducts,
    required double total,
    required String tipoEntrega,
    String? direccion,
    required DateTime fechaProgramada,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final timestamp = DateTime.now();
    
    final orderData = {
      'userId': user.uid,
      'amount': total,
      'dateTime': timestamp.toIso8601String(),
      // HU-C4: Guardar los nuevos campos
      'tipoEntrega': tipoEntrega,
      'direccion': direccion,
      'fechaProgramada': fechaProgramada.toIso8601String(),
      'products': cartProducts
          .map((cp) => {
                'id': cp.id,
                'productId': cp.productId,
                'title': cp.title,
                'quantity': cp.quantity,
                'price': cp.price,
                'imagenUrl': cp.imagenUrl,
                'isExtra': cp.isExtra,
              })
          .toList(),
    };

    final docRef = await FirebaseFirestore.instance.collection('orders').add(orderData);

    _orders.insert(
      0,
      OrderItem(
        id: docRef.id,
        amount: total,
        products: cartProducts,
        dateTime: timestamp,
        // HU-C4: Añadir al objeto local también
        tipoEntrega: tipoEntrega,
        direccion: direccion,
        fechaProgramada: fechaProgramada,
      ),
    );
    notifyListeners();
  }
}