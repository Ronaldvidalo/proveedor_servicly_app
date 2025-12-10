// --- UX/UI Enhancement Comment ---
// Pantalla: ClientQuoteRequestScreen
// Responsabilidad: Formulario para que el cliente detalle su necesidad.
// Diseño: Formulario limpio con campos para medidas y detalles.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// Imports
import 'package:proveedor_servicly_app/core/models/user_model.dart'; // Usuario actual (Cliente)
import 'package:proveedor_servicly_app/features/budget/models/quote_request_model.dart';
import 'package:proveedor_servicly_app/features/budget/repositories/quote_request_repository.dart';

class ClientQuoteRequestScreen extends StatefulWidget {
  final String providerId;
  final String providerName; // Para mostrar "Pedir cotización a..."

  const ClientQuoteRequestScreen({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  @override
  State<ClientQuoteRequestScreen> createState() => _ClientQuoteRequestScreenState();
}

class _ClientQuoteRequestScreenState extends State<ClientQuoteRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _descController = TextEditingController();
  final _qtyController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _serviceType = 'Servicio General';
  
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.read<UserModel?>(); // Datos del cliente logueado

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Solicitar Cotización"),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Text(
                "Hola, ${user?.displayName ?? 'Cliente'}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
              Text(
                "Cuéntanos qué necesitas de ${widget.providerName}",
                style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),

              // 1. Tipo de Solicitud
              _buildLabel(theme, "Tipo de requerimiento"),
              DropdownButtonFormField<String>(
                value: _serviceType,
                dropdownColor: theme.cardColor,
                decoration: _inputDecoration(theme, Icons.category),
                items: ['Servicio General', 'Producto', 'Instalación', 'Mantenimiento', 'Proyecto a Medida']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _serviceType = val!),
              ),
              const SizedBox(height: 16),

              // 2. Descripción
              _buildLabel(theme, "¿Qué deseas realizar?"),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: _inputDecoration(theme, Icons.description, hint: "Ej: Pintar habitación, reparar fuga..."),
                validator: (val) => val!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // 3. Cantidad / Medidas
              _buildLabel(theme, "Medidas o Cantidad (m², unidades, etc)"),
              TextFormField(
                controller: _qtyController,
                decoration: _inputDecoration(theme, Icons.straighten, hint: "Ej: 50 m2, 3 unidades"),
                validator: (val) => val!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // 4. Ubicación
              _buildLabel(theme, "¿Dónde se realizará el servicio?"),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration(theme, Icons.location_on, hint: "Dirección o Zona"),
                validator: (val) => val!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              // 5. Fecha
              _buildLabel(theme, "¿Para cuándo lo necesitas?"),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(DateFormat.yMMMd('es_ES').format(_selectedDate)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Botón Enviar
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _submitForm(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("ENVIAR SOLICITUD", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm(UserModel? user) async {
    if (!_formKey.currentState!.validate()) return;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Debes iniciar sesión")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = QuoteRequestModel(
        id: const Uuid().v4(),
        clientId: user.uid,
        providerId: widget.providerId,
        clientName: user.displayName ?? 'Cliente',
        clientPhone: user.email ?? 'Sin contacto', // Idealmente user.phone
        serviceType: _serviceType,
        description: _descController.text,
        quantity: _qtyController.text,
        location: _locationController.text,
        preferredDate: _selectedDate,
        createdAt: DateTime.now(),
      );

      // Usamos el repositorio (puedes inyectarlo o instanciarlo aquí si es simple)
      await QuoteRequestRepository().sendRequest(request);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("¡Solicitud Enviada!"),
            content: const Text("El proveedor ha recibido tu solicitud detallada. Te responderá con una cotización formal pronto."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra diálogo
                  Navigator.pop(context); // Cierra pantalla
                },
                child: const Text("Entendido"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLabel(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
    );
  }

  InputDecoration _inputDecoration(ThemeData theme, IconData icon, {String? hint}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
      hintText: hint,
      filled: true,
      fillColor: theme.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}