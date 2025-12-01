import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final dni = _dniController.text.trim();
    final password = _passwordController.text.trim();

    if (dni.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, completa todos los campos")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Usuarios')
          .where('DNI', isEqualTo: dni)
          .where('Contraseña', isEqualTo: password)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final user = snapshot.docs.first.data();
        final prefs = await SharedPreferences.getInstance();
        final cargo = user['Cargo'] as String;

        await prefs.setString('userID', snapshot.docs.first.id);
        await prefs.setString('nombre', user['Nombre']);
        await prefs.setString('apellidos', user['Apellidos']);
        await prefs.setString('dni', user['DNI']);
        await prefs.setString('cargo', cargo);
        await prefs.setString('direccion', user['Direccion']);

        if (!mounted) return;

        // Redirección directa según el rol usando rutas con nombre
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("DNI o contraseña incorrectos")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al iniciar sesión: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "KIT Fiesta",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _dniController,
                    decoration: const InputDecoration(
                      labelText: "DNI",
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: _login,
                          icon: const Icon(Icons.login),
                          label: const Text("Iniciar Sesión"),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 45),
                            backgroundColor: Colors.blueAccent,
                          ),
                        ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.register);
                    },
                    child: const Text("¿No tienes cuenta?\nRegístrate aquí"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}