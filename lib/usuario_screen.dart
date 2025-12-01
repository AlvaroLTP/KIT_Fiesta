import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/user_controller.dart';
import 'routes.dart';
import 'widgets/app_drawer.dart';
import 'orders_screen.dart';

class UsuarioScreen extends StatefulWidget {
  const UsuarioScreen({super.key});

  @override
  State<UsuarioScreen> createState() => _UsuarioScreenState();
}

class _UsuarioScreenState extends State<UsuarioScreen> {
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios(UserController userController) async {
    if (userController.userID == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(userController.userID)
          .update({
        'Nombre': _nombreController.text,
        'Apellidos': _apellidoController.text,
        // 'Teléfono' no parece estar en tu modelo de datos, lo omito por ahora
      });
      
      // Actualizamos el estado localmente
      await userController.cargar();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado con éxito')),
        );
      }
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: ${e.toString()}')),
        );
    }
  }

  void _mostrarDialogoEditar(UserController userController) {
    _nombreController.text = userController.nombre ?? '';
    // No hay apellidos en el userController, así que lo dejamos vacío por ahora
    _apellidoController.text = ''; 
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: _apellidoController,
                decoration: const InputDecoration(labelText: 'Apellidos'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Guardar'),
            onPressed: () => _guardarCambios(userController),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userController = Provider.of<UserController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.pink[100],
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.profile),
      body: userController.nombre == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => userController.cargar(),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildProfileHeader(userController),
                  const SizedBox(height: 30),
                  _buildActionButtons(userController),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(UserController userController) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.pinkAccent,
          child: Icon(Icons.person, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          userController.nombre ?? 'Usuario',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'DNI: ${userController.dni ?? ''}',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildActionButtons(UserController userController) {
    return Column(
      children: [
        _buildBoton('Editar Perfil', Icons.edit, () => _mostrarDialogoEditar(userController)),
        const SizedBox(height: 12),
        _buildBoton('Mis Pedidos', Icons.list_alt, () {
          Navigator.of(context).pushNamed(AppRoutes.orders);
        }),
        const SizedBox(height: 24),
        _buildBoton(
          'Cerrar Sesión',
          Icons.exit_to_app,
          () async {
            await userController.cerrarSesion();
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.login,
              (route) => false,
            );
          },
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildBoton(String texto, IconData icono, VoidCallback onPressed, {bool isDestructive = false}) {
    return ElevatedButton.icon(
      icon: Icon(icono),
      label: Text(texto),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: isDestructive ? Colors.red[400] : Colors.pink[300],
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }
}