import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;

class EditKitScreen extends StatefulWidget {
  // Si pasamos un kit, es para editarlo. Si es nulo, es para crear uno nuevo.
  final DocumentSnapshot? kit;

  const EditKitScreen({super.key, this.kit});

  @override
  _EditKitScreenState createState() => _EditKitScreenState();
}

class Componente {
  String nombre;
  int cantidad;

  Componente({required this.nombre, required this.cantidad});

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {'nombre': nombre, 'cantidad': cantidad};
  }

  // Crear desde Map de Firestore
  factory Componente.fromMap(Map<String, dynamic> map) {
    return Componente(
      nombre: map['nombre'] ?? '',
      cantidad: map['cantidad'] ?? 0,
    );
  }
}

class Descuento {
  int cantidadMinima;
  double porcentaje;

  Descuento({required this.cantidadMinima, required this.porcentaje});

  Map<String, dynamic> toMap() {
    return {'cantidadMinima': cantidadMinima, 'porcentaje': porcentaje};
  }

  factory Descuento.fromMap(Map<String, dynamic> map) {
    return Descuento(
      cantidadMinima: map['cantidadMinima'] ?? 0,
      porcentaje: (map['porcentaje'] ?? 0.0).toDouble(),
    );
  }
}

class _EditKitScreenState extends State<EditKitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();

  File? _imagenSeleccionada;
  String? _urlImagenExistente;
  bool _estaGuardando = false;

  List<Componente> _componentes = [];
  List<Descuento> _descuentos = [];

  @override
  void initState() {
    super.initState();
    // Si estamos editando un kit, llenamos los campos con sus datos
    if (widget.kit != null) {
      final data = widget.kit!.data() as Map<String, dynamic>;
      _nombreController.text = data['nombre'] ?? '';
      _descripcionController.text = data['descripcion'] ?? '';
      _precioController.text = (data['precioPorPersona'] ?? 0).toString();
      _urlImagenExistente = data['imagenUrl'];

     if (data['componentes'] != null) {
        _componentes = (data['componentes'] as List)
            .map((comp) => Componente.fromMap(comp as Map<String, dynamic>))
            .toList();
      }
      // Cargar descuentos existentes
      if (data['descuentos'] != null) {
        _descuentos = (data['descuentos'] as List)
            .map((desc) => Descuento.fromMap(desc as Map<String, dynamic>))
            .toList();
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imagenSeleccionada = File(pickedFile.path);
      });
    }
  }

  Future<String> _subirImagen(File imagen) async {
    // Usamos el nombre del archivo para crear una referencia única en Storage
    String nombreArchivo = path.basename(imagen.path);
    Reference ref = FirebaseStorage.instance.ref().child('kits_imagenes').child(nombreArchivo);

    UploadTask uploadTask = ref.putFile(imagen);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

    Future<void> _guardarKit() async {
    if (_formKey.currentState!.validate() && !_estaGuardando) {
      setState(() {
        _estaGuardando = true;
      });

      try {
        String? urlImagen;

        if (_imagenSeleccionada != null) {
          urlImagen = await _subirImagen(_imagenSeleccionada!)
              .timeout(const Duration(seconds: 30));
        } else {
          urlImagen = _urlImagenExistente;
        }

        if (urlImagen == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Por favor, selecciona una imagen para el kit.')),
          );
          setState(() {
            _estaGuardando = false;
          });
          return;
        }

        final data = {
          'nombre': _nombreController.text,
          'descripcion': _descripcionController.text,
          'precioPorPersona': double.tryParse(_precioController.text) ?? 0.0,
          'imagenUrl': urlImagen,
          'componentes': _componentes.map((c) => c.toMap()).toList(),
          'descuentos': _descuentos.map((d) => d.toMap()).toList(),
        };

        Future<void> databaseOperation;
        if (widget.kit == null) {
          databaseOperation =
              FirebaseFirestore.instance.collection('kits').add(data);
        } else {
          databaseOperation = widget.kit!.reference.update(data);
        }

        await databaseOperation.timeout(const Duration(seconds: 20));

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar el kit: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _estaGuardando = false;
          });
        }
      }
    }
  }

  void _mostrarDialogoComponente({Componente? componente, int? index}) {
    final nombreController = TextEditingController(text: componente?.nombre ?? '');
    final cantidadController = TextEditingController(text: componente?.cantidad.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(componente == null ? 'Añadir Componente' : 'Editar Componente'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                ),
                TextFormField(
                  controller: cantidadController,
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Campo requerido';
                    if (int.tryParse(value) == null) return 'Número inválido';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final nuevoComponente = Componente(
                    nombre: nombreController.text,
                    cantidad: int.parse(cantidadController.text),
                  );
                  setState(() {
                    if (index == null) {
                      // Añadir nuevo
                      _componentes.add(nuevoComponente);
                    } else {
                      // Actualizar existente
                      _componentes[index] = nuevoComponente;
                    }
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoDescuento({Descuento? descuento, int? index}) {
    final cantidadController = TextEditingController(text: descuento?.cantidadMinima.toString() ?? '');
    final porcentajeController = TextEditingController(text: descuento?.porcentaje.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(descuento == null ? 'Añadir Descuento' : 'Editar Descuento'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: cantidadController,
                  decoration: const InputDecoration(labelText: 'Cantidad Mínima'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty || int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Número inválido';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: porcentajeController,
                  decoration: const InputDecoration(labelText: 'Porcentaje de Descuento (%)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value!.isEmpty || double.tryParse(value) == null || double.parse(value) <= 0 || double.parse(value) > 100) {
                      return 'Porcentaje inválido (1-100)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final nuevoDescuento = Descuento(
                    cantidadMinima: int.parse(cantidadController.text),
                    porcentaje: double.parse(porcentajeController.text),
                  );
                  setState(() {
                    if (index == null) {
                      _descuentos.add(nuevoDescuento);
                    } else {
                      _descuentos[index] = nuevoDescuento;
                    }
                    // Ordenar descuentos por cantidad mínima
                    _descuentos.sort((a, b) => a.cantidadMinima.compareTo(b.cantidadMinima));
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kit == null ? 'Nuevo Kit' : 'Editar Kit'),
        actions: [
          if (_estaGuardando)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _guardarKit,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Detalles del Kit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              // Vista previa de la imagen
              _buildImagePreview(),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _seleccionarImagen,
                icon: const Icon(Icons.image),
                label: const Text('Seleccionar Imagen'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del Kit'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(labelText: 'Precio por Persona'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value!.isEmpty) return 'Campo requerido';
                  if (double.tryParse(value) == null) return 'Ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
              const Text('Componentes del Kit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildComponentesList(),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Descuentos por Cantidad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: () => _mostrarDialogoDescuento(),
                    tooltip: 'Añadir Descuento',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildDescuentosList(),
            ],
          ),
        ),
      ),
        floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoComponente(),
        child: const Icon(Icons.add),
        tooltip: 'Añadir Componente',
      ),
    );
  }

  Widget _buildImagePreview() {
    // Si hay una imagen nueva seleccionada, la mostramos
    if (_imagenSeleccionada != null) {
      return Image.file(_imagenSeleccionada!, height: 150, fit: BoxFit.cover);
    }
    // Si no, pero hay una URL de una imagen existente (editando), la mostramos
    if (_urlImagenExistente != null) {
      return Image.network(_urlImagenExistente!, height: 150, fit: BoxFit.cover);
    }
    // Si no hay ninguna imagen, mostramos un placeholder
    return Container(
      height: 150,
      color: Colors.grey[300],
      child: const Icon(Icons.party_mode, size: 60, color: Colors.grey),
    );
  }

  Widget _buildComponentesList() {
    if (_componentes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Añade componentes con el botón \'+\'.'),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _componentes.length,
      itemBuilder: (context, index) {
        final componente = _componentes[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(componente.nombre),
            subtitle: Text('Cantidad: ${componente.cantidad}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _mostrarDialogoComponente(componente: componente, index: index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _componentes.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDescuentosList() {
    if (_descuentos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Añade descuentos por cantidad con el botón '+'."),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _descuentos.length,
      itemBuilder: (context, index) {
        final descuento = _descuentos[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text('A partir de ${descuento.cantidadMinima} unidades'),
            subtitle: Text('${descuento.porcentaje}% de descuento'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () => _mostrarDialogoDescuento(descuento: descuento, index: index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _descuentos.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}