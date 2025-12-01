import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:final_teoria/providers/orders_provider.dart';
import 'package:final_teoria/widgets/order_item_wigdet.dart';
import 'routes.dart';
import 'package:final_teoria/widgets/app_drawer.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future _ordersFuture;

  Future _obtainOrdersFuture() {
    return Provider.of<OrdersProvider>(context, listen: false).fetchAndSetOrders();
  }

  @override
  void initState() {
    super.initState();
    _ordersFuture = _obtainOrdersFuture();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        backgroundColor: Colors.pink[100],
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.adminKits),
      body: FutureBuilder(
        future: _ordersFuture,
        builder: (ctx, dataSnapshot) {
          if (dataSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (dataSnapshot.error != null) {
            return const Center(child: Text('Ocurrió un error al cargar los pedidos.'));
          } else {
            return Consumer<OrdersProvider>(
              builder: (ctx, orderData, child) {
                if (orderData.orders.isEmpty) {
                  return const Center(child: Text('Aún no has realizado ningún pedido.'));
                }
                return ListView.builder(
                  itemCount: orderData.orders.length,
                  itemBuilder: (ctx, i) => OrderItemWidget(order: orderData.orders[i]),
                );
              },
            );
          }
        },
      ),
    );
  }
}