import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _telefono = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _direccion = TextEditingController();

  String? _cargoSeleccionado;
  bool _isLoading = false;

  final List<String> cargos = ['Administrador', 'Almacen', 'Gestor', 'Cliente'];

  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreController.text.trim();
    final apellidos = _apellidosController.text.trim();
    final dni = _dniController.text.trim();
    final telefono = _telefono.text.trim();
    final password = _passwordController.text.trim();
    final cargo = _cargoSeleccionado;
    final direccion = _direccion.text.trim();

    setState(() => _isLoading = true);

    try {
      final existe = await FirebaseFirestore.instance
          .collection('Usuarios')
          .where('DNI', isEqualTo: dni)
          .get();

      if (existe.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("El DNI ya está registrado")),
        );
      } else {
        await FirebaseFirestore.instance.collection('Usuarios').add({
          'Nombre': nombre,
          'Apellidos': apellidos,
          'DNI': dni,
          'Teléfono': telefono,
          'Contraseña': password,
          'Cargo': cargo,
          'Direccion': direccion,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario registrado correctamente")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar usuario: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text("Registro de Usuario"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Crear nueva cuenta",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // 🧍‍♂️ Nombres
                    TextFormField(
                      controller: _nombreController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        labelText: "Nombres",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return "Ingrese sus nombres";
                        }
                        if (valor.trim().length < 3) {
                          return "Debe tener al menos 3 letras";
                        }
                        if (!RegExp(r'^[a-zA-ZÁÉÍÓÚáéíóúñÑ\s]+$')
                            .hasMatch(valor)) {
                          return "Solo se permiten letras";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // 👨‍👩‍👦 Apellidos
                    TextFormField(
                      controller: _apellidosController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        labelText: "Apellidos",
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return "Ingrese sus apellidos";
                        }
                        if (valor.trim().length < 3) {
                          return "Debe tener al menos 3 letras";
                        }
                        if (!RegExp(r'^[a-zA-ZÁÉÍÓÚáéíóúñÑ\s]+$')
                            .hasMatch(valor)) {
                          return "Solo se permiten letras";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // 🪪 DNI
                    TextFormField(
                      controller: _dniController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "DNI",
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return "Ingrese su DNI";
                        }
                        if (!RegExp(r'^\d{8}$').hasMatch(valor)) {
                          return "Debe tener exactamente 8 dígitos";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _telefono,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Telefono",
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return "Ingrese su telefono";
                        }
                        if (!RegExp(r'^\d{9}$').hasMatch(valor)) {
                          return "Debe tener exactamente 9 dígitos";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // 🔒 Contraseña
                    TextFormField(
                      controller: _passwordController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.isEmpty) {
                          return "Ingrese una contraseña";
                        }
                        if (valor.length < 8) {
                          return "Debe tener al menos 8 caracteres";
                        }
                        if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]+$')
                            .hasMatch(valor)) {
                          return "Debe contener letras y números";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // 🧰 Cargo
                    DropdownButtonFormField<String>(
                      value: _cargoSeleccionado,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      items: cargos
                          .map((cargo) => DropdownMenuItem(
                                value: cargo,
                                child: Text(cargo),
                              ))
                          .toList(),
                      onChanged: (valor) =>
                          setState(() => _cargoSeleccionado = valor),
                      decoration: const InputDecoration(
                        labelText: "Cargo",
                        prefixIcon: Icon(Icons.work),
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.isEmpty) {
                          return "Seleccione un cargo";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _direccion,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                        labelText: "Dirección",
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      validator: (valor) {
                        if (valor == null || valor.isEmpty) {
                          return "Ingrese una dirección";
                        }
                        if (valor.length < 8) {
                          return "Debe tener al menos 8 caracteres";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),
                                        // 🟢 Botón Registrar
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: _registrarUsuario,
                            icon: const Icon(Icons.save),
                            label: const Text("Registrar"),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 45),
                              backgroundColor: Colors.green,
                            ),
                          ),

                    const SizedBox(height: 20),

                    // 🔁 Volver al login
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text("¿Ya tienes cuenta? Inicia sesión"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}