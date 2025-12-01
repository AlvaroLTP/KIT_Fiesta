import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/user_controller.dart';
import '../routes.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  void _navigateTo(BuildContext context, String routeName) {
    if (currentRoute != routeName) {
      Navigator.of(context).pushReplacementNamed(routeName);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userController = Provider.of<UserController>(context);
    final nombre = userController.nombre ?? 'Usuario';
    final rol = userController.rol?.toLowerCase() ?? 'cliente';

    // Define la ruta de inicio según el rol
    String homeRoute;
    switch (rol) {
      case 'administrador':
      case 'gestor':
        homeRoute = AppRoutes.adminKits;
        break;
      case 'almacen':
        homeRoute = AppRoutes.stock;
        break;
      default: // cliente
        homeRoute = AppRoutes.kits;
    }

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(nombre),
            accountEmail: Text('Rol: ${userController.rol ?? ''}'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            selected: currentRoute == homeRoute,
            onTap: () => _navigateTo(context, homeRoute),
          ),
          const Divider(),

          // HU-E1: Admin
          if (rol == 'administrador') ...[
            ListTile(
              leading: const Icon(Icons.build_circle),
              title: const Text('Gestionar Kits'),
              selected: currentRoute == AppRoutes.adminKits,
              onTap: () => _navigateTo(context, AppRoutes.adminKits),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Gestión de Stock'),
              selected: currentRoute == AppRoutes.stock,
              onTap: () => _navigateTo(context, AppRoutes.stock),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Reportes de Ventas'),
              selected: currentRoute == AppRoutes.reports,
              onTap: () => _navigateTo(context, AppRoutes.reports),
            ),
          ],

          // HU-E2: Almacén
          if (rol == 'almacen') ...[
             ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Gestión de Stock'),
              selected: currentRoute == AppRoutes.stock,
              onTap: () => _navigateTo(context, AppRoutes.stock),
            ),
          ],

          // HU-E3 & HU-E4: Gestor
          if (rol == 'gestor') ...[
            ListTile(
              leading: const Icon(Icons.build_circle),
              title: const Text('Gestionar Kits'),
              selected: currentRoute == AppRoutes.adminKits,
              onTap: () => _navigateTo(context, AppRoutes.adminKits),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Reporte de Ventas'),
              selected: currentRoute == AppRoutes.reports,
              onTap: () => _navigateTo(context, AppRoutes.reports),
            ),
          ],
          
          // Rutas para Clientes
          if (rol == 'cliente') ...[
             ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Mis Pedidos'),
              selected: currentRoute == AppRoutes.orders,
              onTap: () => _navigateTo(context, AppRoutes.orders),
            ),
          ],

          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi Perfil'),
            selected: currentRoute == AppRoutes.profile,
            onTap: () => _navigateTo(context, AppRoutes.profile),
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await userController.cerrarSesion();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}