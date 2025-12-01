import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'verificar_sesion.dart';
import 'kits_screen.dart';
import 'admin_kits_screens.dart';
import 'orders_screen.dart';
import 'cart_screen.dart';
import 'kit_detail_screen.dart';
import 'usuario_screen.dart';
import 'stock_screen.dart';
import 'reportes_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String verificarSesion = '/verificar-sesion';
  static const String kits = '/kits';
  static const String adminKits = '/admin-kits';
  static const String orders = '/orders';
  static const String cart = '/cart';
  static const String kitDetail = '/kit-detail';
  static const String profile = '/profile';
  static const String stock = '/stock'; // Nueva ruta
  static const String reports = '/reports'; 

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case verificarSesion:
        return MaterialPageRoute(builder: (_) => const VerificarSesion());
      case kits:
        return MaterialPageRoute(builder: (_) => const KitsScreen());
      case adminKits:
        return MaterialPageRoute(builder: (_) => const AdminKitsScreen());
      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const UsuarioScreen());
      case stock: // Nuevo case
        return MaterialPageRoute(builder: (_) => const StockScreen());
      case reports: // Nuevo case
        return MaterialPageRoute(builder: (_) => const ReportesScreen());
      case kitDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('kit')) {
          return MaterialPageRoute(
            builder: (_) => KitDetailScreen(kit: args['kit']),
          );
        }
        return _errorRoute();
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Página no encontrada')),
      );
    });
  }
}