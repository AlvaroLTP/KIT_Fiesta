import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_teoria/widgets/app_drawer.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  _ReportesScreenState createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Ventas'),
      ),
      drawer: AppDrawer(currentRoute: ModalRoute.of(context)?.settings.name ?? '/reportes'),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay ventas registradas.'));
          }

          // Procesar los datos para agregar las ventas por kit
          Map<String, int> ventasPorKit = {};
          Map<String, double> ingresosPorKit = {};

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final items = data['items'] as List<dynamic>;
            
            for (var item in items) {
              final kitNombre = item['kitNombre'] as String;
              final cantidad = item['cantidad'] as int;
              final precio = (item['precio'] as num).toDouble();
              
              ventasPorKit.update(kitNombre, (value) => value + cantidad, ifAbsent: () => cantidad);
              ingresosPorKit.update(kitNombre, (value) => value + (cantidad * precio), ifAbsent: () => cantidad * precio);
            }
          }

          if (ventasPorKit.isEmpty) {
            return const Center(child: Text('No hay ventas de kits para reportar.'));
          }

          return ListView(
            children: ventasPorKit.entries.map((entry) {
              final kitNombre = entry.key;
              final cantidadTotal = entry.value;
              final ingresoTotal = ingresosPorKit[kitNombre]!;

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(kitNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Unidades vendidas: $cantidadTotal\nIngresos: \$${ingresoTotal.toStringAsFixed(2)}'),
                  isThreeLine: true,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}