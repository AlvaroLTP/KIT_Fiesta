import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> populateKits(BuildContext context) async {
  final firestore = FirebaseFirestore.instance;
  final collection = firestore.collection('kits');

  // Para evitar duplicados, podrías añadir una comprobación
  final snapshot = await collection.limit(1).get();
  if (snapshot.docs.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Los kits de ejemplo ya han sido agregados.')),
    );
    return;
  }

  final kitsData = [
    {
      'nombre': 'Kit Fiesta de Cumpleaños',
      'descripcion': 'Todo lo que necesitas para una fiesta de cumpleaños inolvidable. ¡Ideal para 10 personas!',
      'precioPorPersona': 15.50,
      'imagenUrl': 'https://firebasestorage.googleapis.com/v0/b/final-teoria-a72a7.appspot.com/o/kits_imagenes%2Ffiesta.png?alt=media&token=26c8510c-5e38-4338-913a-739a20a032f1',
      'componentes': [
        {'nombre': 'Platos', 'cantidad': 10},
        {'nombre': 'Vasos', 'cantidad': 10},
        {'nombre': 'Servilletas', 'cantidad': 20},
        {'nombre': 'Globos', 'cantidad': 15},
      ],
      'descuentos': [
        {'cantidadMinima': 20, 'porcentaje': 10.0},
        {'cantidadMinima': 50, 'porcentaje': 20.0},
      ],
    },
    {
      'nombre': 'Kit Superhéroes al Rescate',
      'descripcion': '¡Convierte tu fiesta en una aventura de superhéroes! Perfecto para los pequeños fans.',
      'precioPorPersona': 22.00,
      'imagenUrl': 'https://firebasestorage.googleapis.com/v0/b/final-teoria-a72a7.appspot.com/o/kits_imagenes%2Fsuperheroes.png?alt=media&token=014b7329-a79e-4c53-82d2-21313829284a',
      'componentes': [
        {'nombre': 'Máscaras de superhéroe', 'cantidad': 8},
        {'nombre': 'Capas de superhéroe', 'cantidad': 8},
        {'nombre': 'Piñata temática', 'cantidad': 1},
        {'nombre': 'Bolsas de dulces', 'cantidad': 8},
      ],
      'descuentos': [
        {'cantidadMinima': 15, 'porcentaje': 5.0},
        {'cantidadMinima': 30, 'porcentaje': 15.0},
      ],
    },
    {
      'nombre': 'Kit Boda Elegante',
      'descripcion': 'Detalles sofisticados para celebrar un día especial. Calidad y elegancia en un solo paquete.',
      'precioPorPersona': 35.75,
      'imagenUrl': 'https://firebasestorage.googleapis.com/v0/b/final-teoria-a72a7.appspot.com/o/kits_imagenes%2Fboda.png?alt=media&token=8c0a3a9b-8b3a-4e8e-8b1a-9a8b7c6d5e4f',
      'componentes': [
        {'nombre': 'Copas de champán', 'cantidad': 12},
        {'nombre': 'Centros de mesa florales', 'cantidad': 2},
        {'nombre': 'Tarjetas de agradecimiento', 'cantidad': 12},
        {'nombre': 'Velas decorativas', 'cantidad': 24},
      ],
      'descuentos': [
        {'cantidadMinima': 25, 'porcentaje': 12.0},
        {'cantidadMinima': 60, 'porcentaje': 25.0},
      ],
    },
  ];

  WriteBatch batch = firestore.batch();

  for (var kitData in kitsData) {
    DocumentReference docRef = collection.doc();
    batch.set(docRef, kitData);
  }

  try {
    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡3 kits de ejemplo agregados exitosamente!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al agregar kits: $e')),
    );
  }
}