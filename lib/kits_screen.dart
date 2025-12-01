import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import 'providers/cart_provider.dart';
import 'cart_screen.dart';
import 'kit_detail_screen.dart';
import 'widgets/app_drawer.dart';

class KitsScreen extends StatelessWidget {
  const KitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kits Disponibles'),
        backgroundColor: Colors.pink[100],
        actions: <Widget>[
          Consumer<CartProvider>(
            builder: (_, cart, ch) => Badge(
              label: Text(cart.itemCount.toString()),
              child: ch,
            ),
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.cart);
              },
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.kits),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('kits').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay kits disponibles en este momento.'),
            );
          }

          final kits = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 0.75,
            ),
            itemCount: kits.length,
            itemBuilder: (context, index) {
              final kit = kits[index];
              return _buildKitCard(context, kit);
            },
          );
        },
      ),
    );
  }

  Widget _buildKitCard(BuildContext context, DocumentSnapshot kit) {
    final data = kit.data() as Map<String, dynamic>;
    final imagenUrl = data['imagenUrl'] as String?;
    final nombre = data['nombre'] ?? 'Sin nombre';
    final precio = (data['precioPorPersona'] ?? 0.0).toStringAsFixed(2);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.kitDetail,
          arguments: {'kit': kit},
        );
      },
      child: Card(
        elevation: 4.0,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: (imagenUrl != null && imagenUrl.isNotEmpty)
                  ? Image.network(
                      imagenUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 40);
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.party_mode, size: 40, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'S/. $precio / persona',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}