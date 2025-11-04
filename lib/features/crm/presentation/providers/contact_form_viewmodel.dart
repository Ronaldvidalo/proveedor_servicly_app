import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';
import 'package:proveedor_servicly_app/features/crm/core/crm_enums.dart';

// ViewModel que gestiona el estado y la lógica para crear un nuevo Lead/Cliente
class ContactFormViewModel extends ChangeNotifier {
  final CrmRepository _repository;

  String _nombre = '';
  String _email = '';
  String _telefono = '';
  CrmEstado _estadoSeleccionado = CrmEstado.lead; // Por defecto: Lead (Free)
  bool _isLoading = false;

  ContactFormViewModel(this._repository);

  // --- Getters Públicos ---
  bool get isLoading => _isLoading;
  String get nombre => _nombre;
  String get email => _email;
  String get telefono => _telefono;
  CrmEstado get estadoSeleccionado => _estadoSeleccionado;

  // Los estados disponibles para creación (Lead para Free, Lead o Cliente Activo)
  List<CrmEstado> get availableStates => [CrmEstado.lead, CrmEstado.clienteActivo];

  // --- Setters de Formulario ---
  void setNombre(String value) {
    _nombre = value;
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void setTelefono(String value) {
    _telefono = value;
    notifyListeners();
  }

  void setEstadoSeleccionado(CrmEstado? value) {
    if (value != null) {
      _estadoSeleccionado = value;
      notifyListeners();
    }
  }

  // --- Lógica de Creación ---

  Future<void> createContact(BuildContext context) async {
    if (_isLoading) return;

    // 1. Validación simple: al menos nombre o un método de contacto
    if (_nombre.isEmpty || (_email.isEmpty && _telefono.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa el nombre y al menos un contacto (email o teléfono).')),
      );
      return;
    }

    _setLoading(true);

    try {
      // 2. Preparar los datos para el Repositorio
      final Map<String, dynamic> data = {
        'nombreCompleto': _nombre.trim(),
        'email': _email.trim(),
        'telefono': _telefono.trim(),
        'estadoCRM': _estadoSeleccionado.name,
        // Los campos de fecha, monto y etiquetas se añaden en el Repositorio/Backend
      };

      // 3. Llamar al Repositorio para crear el contacto en Firestore
      await _repository.createCliente(data);

      // 4. Éxito y limpieza
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contacto ${_nombre.trim()} creado exitosamente como ${_estadoSeleccionado.name.toUpperCase()}')),
      );
      
      // Limpiar el formulario y cerrar la pantalla (Navegación)
      Navigator.of(context).pop(); 

    } catch (e) {
      // 5. Manejo de errores (ej. error de límite Free)
      String message = 'Error al crear contacto: $e';
      if (e.toString().contains('PERMISSION_DENIED')) {
         message = 'Límite de contactos alcanzado. Por favor, mejora a Plan Pro.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
