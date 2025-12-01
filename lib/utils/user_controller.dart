import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserController with ChangeNotifier {
  String? _nombre;
  String? _rol;
  String? _dni;
  String? _userID;
  String? _direccion;

  String? get nombre => _nombre;
  String? get rol => _rol;
  String? get dni => _dni;
  String? get userID => _userID;
  String? get direccion => _direccion;

  Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    _nombre = prefs.getString('nombre');
    _rol = prefs.getString('cargo');
    _dni = prefs.getString('dni');
    _userID = prefs.getString('userID');
    _direccion = prefs.getString('direccion');
    notifyListeners();
  }

  Future<void> actualizarNombre(String nuevoNombre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', nuevoNombre);
    _nombre = nuevoNombre;
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _nombre = null;
    _rol = null;
    _dni = null;
    _userID = null;
    _direccion = null;
    notifyListeners();
  }
}