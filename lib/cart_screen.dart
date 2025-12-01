import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
import 'package:final_teoria/providers/cart_provider.dart';
import 'package:final_teoria/providers/orders_provider.dart';

// Enum para las opciones de entrega
enum DeliveryOption { Recojo, Envio }

class CartScreen extends StatefulWidget {
  static const routeName = '/cart';

  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;
  
  // Estado para las opciones de entrega
  DeliveryOption _deliveryOption = DeliveryOption.Recojo;
  final _addressController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // Lógica de checkout actualizada
  Future<void> _performCheckout(CartProvider cart) async {
    if (cart.totalAmount <= 0 || _isLoading) return;

    // Validaciones
    if (_deliveryOption == DeliveryOption.Envio && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa una dirección de envío.')),
      );
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una fecha y hora.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    // Combinar fecha y hora
    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      // Llamada corregida a addOrder con todos los datos
      await Provider.of<OrdersProvider>(context, listen: false).addOrder(
        cartProducts: cart.items.values.toList(),
        total: cart.totalAmount,
        tipoEntrega: _deliveryOption == DeliveryOption.Envio ? 'Envío a domicilio' : 'Recojo en tienda',
        direccion: _deliveryOption == DeliveryOption.Envio ? _addressController.text : null,
        fechaProgramada: scheduledDateTime,
      );

      cart.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Pedido realizado con éxito!')),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        // MEJORA: En lugar de una SnackBar, mostramos un diálogo de error persistente.
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¡Ocurrió un Error!'),
            content: const Text(
              'No se pudo guardar el pedido. Esto puede deberse a un problema de conexión o a un error de configuración del servidor. Por favor, inténtalo de nuevo.',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Entendido'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              )
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // Selectores de fecha y hora
  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate != null) setState(() => _selectedDate = pickedDate);
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (pickedTime != null) setState(() => _selectedTime = pickedTime);
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Compra'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resumen del Pedido', style: Theme.of(context).textTheme.titleLarge),
                        _buildCartList(cart),
                        const Divider(height: 32),
                        Text('Opciones de Entrega', style: Theme.of(context).textTheme.titleLarge),
                        _buildDeliveryOptions(),
                        if (_deliveryOption == DeliveryOption.Envio) _buildAddressInput(),
                        const SizedBox(height: 16),
                        Text('Programar Fecha y Hora', style: Theme.of(context).textTheme.titleLarge),
                        _buildDateTimePicker(),
                      ],
                    ),
                  ),
                ),
                _buildCheckoutCard(cart),
              ],
            ),
    );
  }

  Widget _buildCartList(CartProvider cart) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cart.items.length,
      itemBuilder: (ctx, i) {
        final cartItem = cart.items.values.elementAt(i);
        return ListTile(
          title: Text(cartItem.title),
          subtitle: Text('${cartItem.quantity} x S/. ${cartItem.price.toStringAsFixed(2)}'),
          trailing: Text('S/. ${cartItem.precioTotal.toStringAsFixed(2)}'),
        );
      },
    );
  }

  Widget _buildDeliveryOptions() {
    return Column(
      children: [
        RadioListTile<DeliveryOption>(
          title: const Text('Recojo en Tienda'),
          value: DeliveryOption.Recojo,
          groupValue: _deliveryOption,
          onChanged: (value) => setState(() => _deliveryOption = value!),
        ),
        RadioListTile<DeliveryOption>(
          title: const Text('Envío a Domicilio'),
          value: DeliveryOption.Envio,
          groupValue: _deliveryOption,
          onChanged: (value) => setState(() => _deliveryOption = value!),
        ),
      ],
    );
  }

  Widget _buildAddressInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _addressController,
        decoration: const InputDecoration(
          labelText: 'Dirección de Envío',
          hintText: 'Ej: Av. Siempre Viva 123',
          icon: Icon(Icons.home_work_outlined),
        ),
        keyboardType: TextInputType.streetAddress,
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(_selectedDate == null ? 'Seleccionar Fecha' : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
            onPressed: _selectDate,
          ),
          TextButton.icon(
            icon: const Icon(Icons.access_time),
            label: Text(_selectedTime == null ? 'Seleccionar Hora' : _selectedTime!.format(context)),
            onPressed: _selectTime,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutCard(CartProvider cart) {
    return Card(
      margin: const EdgeInsets.all(0),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Total', style: TextStyle(fontSize: 20)),
                Text('S/. ${cart.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            ElevatedButton(
              onPressed: () => _performCheckout(cart),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white)) : const Text('ORDENAR'),
            )
          ],
        ),
      ),
    );
  }
}