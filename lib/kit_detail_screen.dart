import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'cart_screen.dart';

class KitDetailScreen extends StatefulWidget {
  final DocumentSnapshot kit;

  const KitDetailScreen({super.key, required this.kit});

  @override
  _KitDetailScreenState createState() => _KitDetailScreenState();
}

class Descuento {
  final int cantidadMinima;
  final double porcentaje;

  Descuento({required this.cantidadMinima, required this.porcentaje});

  factory Descuento.fromMap(Map<String, dynamic> map) {
    return Descuento(
      cantidadMinima: map['cantidadMinima'] as int,
      porcentaje: (map['porcentaje'] as num).toDouble(),
    );
  }
}

class _KitDetailScreenState extends State<KitDetailScreen> {
  int _numeroInvitados = 1;
  double _precioTotal = 0.0;
  List<Descuento> _descuentos = [];
  
  // HU-C2: Estado para componentes y extras
  List<Map<String, dynamic>> _componentesDelKit = [];
  List<DocumentSnapshot> _inventarioExtras = [];
  List<Map<String, dynamic>> _extrasSeleccionados = [];

  // HU-C3: Estado para sugerencias
  List<DocumentSnapshot> _sugerencias = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() {
    _cargarDescuentos();
    _cargarComponentesEInventario();
    _cargarSugerencias();
    _recalcularPrecio();
  }

  void _cargarDescuentos() {
    final data = widget.kit.data() as Map<String, dynamic>;
    if (data.containsKey('descuentos') && data['descuentos'] is List) {
      final descuentosData = data['descuentos'] as List<dynamic>;
      _descuentos = descuentosData
          .map((d) => Descuento.fromMap(d as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.cantidadMinima.compareTo(a.cantidadMinima));
    }
  }

  void _cargarComponentesEInventario() async {
    final data = widget.kit.data() as Map<String, dynamic>;
    if (data.containsKey('componentes') && data['componentes'] is List) {
      _componentesDelKit = List<Map<String, dynamic>>.from(data['componentes']);
    }
    
    final inventarioSnapshot = await FirebaseFirestore.instance.collection('inventario').get();
    _inventarioExtras = inventarioSnapshot.docs;

    if (mounted) {
      setState(() {});
    }
  }

  void _cargarSugerencias() async {
    final data = widget.kit.data() as Map<String, dynamic>?;
    if (data == null || !data.containsKey('tema')) return;

    final tema = data['tema'];
    final querySnapshot = await FirebaseFirestore.instance
        .collection('kits')
        .where('tema', isEqualTo: tema)
        .where(FieldPath.documentId, isNotEqualTo: widget.kit.id)
        .limit(5)
        .get();

    if (mounted) {
      setState(() {
        _sugerencias = querySnapshot.docs;
      });
    }
  }

  void _recalcularPrecio() {
    final data = widget.kit.data() as Map<String, dynamic>;
    final precioPorPersona = (data['precioPorPersona'] ?? 0.0) as double;
    double precioBase = precioPorPersona * _numeroInvitados;
    double descuentoAplicado = 0.0;

    for (final descuento in _descuentos) {
      if (_numeroInvitados >= descuento.cantidadMinima) {
        descuentoAplicado = precioBase * (descuento.porcentaje / 100);
        break;
      }
    }
    
    double precioExtras = _extrasSeleccionados.fold(0.0, (sum, extra) => sum + (extra['precio'] * extra['cantidad']));

    setState(() {
      _precioTotal = (precioBase - descuentoAplicado) + precioExtras;
    });
  }

  void _incrementarInvitados() {
    setState(() {
      _numeroInvitados++;
      _recalcularPrecio();
    });
  }

  void _decrementarInvitados() {
    if (_numeroInvitados > 1) {
      setState(() {
        _numeroInvitados--;
        _recalcularPrecio();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.kit.data() as Map<String, dynamic>;
    final imagenUrl = data['imagenUrl'] as String?;
    final nombre = data['nombre'] ?? 'Sin nombre';
    final descripcion = data['descripcion'] ?? 'Sin descripción.';

    return Scaffold(
      appBar: AppBar(title: Text(nombre)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (imagenUrl != null && imagenUrl.isNotEmpty)
              Image.network(imagenUrl, height: 250, fit: BoxFit.cover)
            else
              Container(height: 250, color: Colors.grey[200], child: const Icon(Icons.party_mode, size: 50)),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(descripcion, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Número de invitados:', style: Theme.of(context).textTheme.titleMedium),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: _decrementarInvitados),
                      Text('$_numeroInvitados', style: Theme.of(context).textTheme.titleLarge),
                      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _incrementarInvitados),
                    ],
                  ),
                ],
              ),
            ),
            if (_descuentos.isNotEmpty) _buildDescuentosSection(),
            const Divider(),
            _buildComponentesSection(), // HU-C2
            const Divider(),
            _buildSugerenciasSection(), // HU-C3
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildDescuentosSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Descuentos por cantidad', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._descuentos.map((d) => Text('• ${d.cantidadMinima} o más invitados: ${d.porcentaje}% de descuento')).toList(),
        ],
      ),
    );
  }

  Widget _buildComponentesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Este kit incluye', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ..._componentesDelKit.map((c) => ListTile(title: Text('${c['cantidad']} x ${c['nombre']}'))),
          ..._extrasSeleccionados.map((e) => ListTile(
            title: Text('${e['cantidad']} x ${e['nombre']} (Extra)'),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () {
                setState(() {
                  _extrasSeleccionados.remove(e);
                  _recalcularPrecio();
                });
              },
            ),
          )),
          const SizedBox(height: 8),
          Center(
            child: ElevatedButton(
              child: const Text('Añadir Extras'),
              onPressed: _mostrarDialogoExtras,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoExtras() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Añadir Extras'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _inventarioExtras.length,
              itemBuilder: (ctx, i) {
                final item = _inventarioExtras[i];
                final itemData = item.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(itemData['nombre']),
                  subtitle: Text('S/. ${itemData['precio'].toStringAsFixed(2)}'),
                  onTap: () {
                    setState(() {
                      _extrasSeleccionados.add({
                        'id': item.id,
                        'nombre': itemData['nombre'],
                        'precio': itemData['precio'],
                        'cantidad': 1,
                        'imagenUrl': itemData['imagenUrl'],
                      });
                      _recalcularPrecio();
                    });
                    Navigator.of(ctx).pop();
                  },
                );
              },
            ),
          ),
          actions: [TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop())],
        );
      },
    );
  }

  Widget _buildSugerenciasSection() {
    if (_sugerencias.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text('También te podría gustar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _sugerencias.length,
            itemBuilder: (context, index) => _buildSugerenciaCard(_sugerencias[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildSugerenciaCard(DocumentSnapshot kitSugerido) {
    final data = kitSugerido.data() as Map<String, dynamic>;
    final nombre = data['nombre'] ?? 'Kit';
    final imagenUrl = data['imagenUrl'] as String?;
    return SizedBox(
      width: 140,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: InkWell(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => KitDetailScreen(kit: kitSugerido)),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imagenUrl != null && imagenUrl.isNotEmpty)
                Image.network(imagenUrl, height: 100, width: double.infinity, fit: BoxFit.cover)
              else
                Container(height: 100, color: Colors.grey[200], child: const Icon(Icons.party_mode, size: 30)),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(nombre, style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final data = widget.kit.data() as Map<String, dynamic>;
    final nombre = data['nombre'] ?? 'Sin nombre';
    final imagenUrl = data['imagenUrl'] as String?;
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Precio Total', style: TextStyle(color: Colors.grey)),
              Text('S/. ${_precioTotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Añadir el kit principal
              cart.addItem(widget.kit.id, nombre, _numeroInvitados, _precioTotal / _numeroInvitados, imagenUrl);
              // Añadir los extras
              for (final extra in _extrasSeleccionados) {
                cart.addItem(extra['id'], extra['nombre'], extra['cantidad'], extra['precio'], extra['imagenUrl'], isExtra: true);
              }
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('\"$nombre\" y extras fueron añadidos.'),
                action: SnackBarAction(
                  label: 'VER CARRITO',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => CartScreen()),
                  ),
                ),
              ));
            },
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text('Añadir al Carrito'),
          ),
        ],
      ),
    );
  }
}