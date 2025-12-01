import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routes.dart';

class VerificarSesion extends StatefulWidget {
  const VerificarSesion({super.key});

  @override
  State<VerificarSesion> createState() => _VerificarSesionState();
}

class _VerificarSesionState extends State<VerificarSesion> {
  @override
  void initState() {
    super.initState();
    // Esperar a que el frame se dibuje antes de navegar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarSesion();
    });
  }

  Future<void> _verificarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final dni = prefs.getString('dni');
    final cargo = prefs.getString('cargo');

    // Pequeño retardo para mostrar el indicador de carga
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    if (dni != null && cargo != null) {
      // ✅ Sesión activa → ir al menú principal
      if (cargo.toLowerCase() == 'administrador') {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.adminKits,
          (route) => false,
        );
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.kits,
          (route) => false,
        );
      }
    } else {
      // 🔐 Sin sesión → ir al login
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text(
              "Verificando sesión...",
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}