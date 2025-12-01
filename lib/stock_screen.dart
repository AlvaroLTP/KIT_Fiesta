import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/app_drawer.dart';
import 'routes.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  _StockScreenState createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Muestra un diálogo para añadir un nuevo componente o editar su stock.
  void _mostrarDialogoGestionStock({DocumentSnapshot? componente}) {
    final nombreController = TextEditingController(text: componente != null ? componente.id : '');
    final stockController = TextEditingController(
        text: componente != null ? (componente.data() as Map<String, dynamic>)['stock'].toString() : '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(componente == null ? 'Añadir Componente al Inventario' : 'Actualizar Stock'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  // El nombre no se puede editar para evitar inconsistencias.
                  readOnly: componente != null,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Componente',
                    hintText: 'Ej: Globo metálico',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: 'Cantidad en Stock'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La cantidad es requerida';
                    }
                    if (int.tryParse(value) == null || int.parse(value) < 0) {
                      return 'Ingresa un número válido';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final nombre = nombreController.text;
                  final stock = int.parse(stockController.text);

                  // Usamos el nombre del componente como ID del documento para asegurar que sea único.
                  await _firestore.collection('inventario').doc(nombre).set({
                    'stock': stock,
                  });

                  Navigator.of(context).pop();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Stock'),
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.stock),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('inventario').orderBy(FieldPath.documentId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay componentes en el inventario. Añade uno con el botón "+".'),
            );
          }

          final componentes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: componentes.length,
            itemBuilder: (context, index) {
              final componente = componentes[index];
              final data = componente.data() as Map<String, dynamic>;
              final stock = data['stock'] ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  title: Text(componente.id),
                  subtitle: Text('Stock actual: $stock'),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _mostrarDialogoGestionStock(componente: componente),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoGestionStock(),
        child: const Icon(Icons.add),
        tooltip: 'Añadir Componente',
      ),
    );
  }
}