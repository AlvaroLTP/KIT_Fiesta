import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_kit_screen.dart'; // Importamos la pantalla de edición
import 'package:final_teoria/widgets/app_drawer.dart';
import 'routes.dart';
import 'package:final_teoria/utils/populate_kits.dart';


class AdminKitsScreen extends StatefulWidget {
  const AdminKitsScreen({super.key});

  @override
  _AdminKitsScreenState createState() => _AdminKitsScreenState();
}

class _AdminKitsScreenState extends State<AdminKitsScreen> {
  // Navega a la pantalla de edición. Si no se pasa kit, es para crear uno nuevo.
  void _navegarAEditarKit([DocumentSnapshot? kit]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditKitScreen(kit: kit),
      ),
    );
  }

  // Muestra un diálogo de confirmación antes de eliminar
  Future<void> _confirmarYEliminarKit(DocumentSnapshot kit) async {
    final bool? confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar el kit "${kit['nombre']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await kit.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kit eliminado correctamente.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el kit: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Kits'),
        actions: [
           IconButton(
            icon: const Icon(Icons.add_box),
            tooltip: 'Agregar Kits de Ejemplo',
            onPressed: () => populateKits(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navegarAEditarKit(), // Llama sin argumentos para crear
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.adminKits),
      body: StreamBuilder<QuerySnapshot>(
        // Escuchamos los cambios en la colección 'kits' en tiempo real
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
              child: Text('No hay kits. ¡Añade uno nuevo!'),
            );
          }

          // Si tenemos datos, construimos la lista
          final kits = snapshot.data!.docs;

          return ListView.builder(
            itemCount: kits.length,
            itemBuilder: (context, index) {
              final kit = kits[index];
              final data = kit.data() as Map<String, dynamic>;
              final imagenUrl = data['imagenUrl'] as String?;
              final nombre = data['nombre'] ?? 'Sin nombre';
              final precio = (data['precioPorPersona'] ?? 0.0).toStringAsFixed(2);

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (imagenUrl != null && imagenUrl.isNotEmpty)
                      ? NetworkImage(imagenUrl)
                      : null,
                  child: (imagenUrl == null || imagenUrl.isEmpty)
                      ? const Icon(Icons.party_mode)
                      : null,
                ),
                title: Text(nombre),
                subtitle: Text('S/. $precio por persona'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmarYEliminarKit(kit),
                ),
                onTap: () => _navegarAEditarKit(kit), // Llama con el kit para editar
              );
            },
          );
        },
      ),
    );
  }
}