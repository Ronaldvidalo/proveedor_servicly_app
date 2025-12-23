import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/services/auth_service.dart';

class AvailabilitySwitch extends StatefulWidget {
  const AvailabilitySwitch({super.key});

  @override
  State<AvailabilitySwitch> createState() => _AvailabilitySwitchState();
}

class _AvailabilitySwitchState extends State<AvailabilitySwitch> {
  bool _isAvailable = false; // Debería venir de tu UserModel/Firestore
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return SwitchListTile(
      title: const Text("Disponible para trabajos"),
      subtitle: const Text("Recibe notificaciones de nuevos clientes cercanos"),
      value: _isAvailable,
      secondary: Icon(
        _isAvailable ? Icons.notifications_active : Icons.notifications_off,
        color: _isAvailable ? Colors.green : Colors.grey,
      ),
      // Deshabilitamos el switch si está cargando
      onChanged: _isLoading ? null : (bool value) async {
        if (value == true) {
          // El usuario quiere activarse -> PEDIR PERMISO
          setState(() => _isLoading = true);
          
          // 1. Llamamos a la función que creamos en AuthService
          bool granted = await authService.requestNotificationPermission();
          
          // ✅ CORRECCIÓN: Verificar si el widget sigue montado antes de usar setState o context
          if (!mounted) return;

          setState(() => _isLoading = false);

          if (granted) {
            // Permiso concedido: Activamos el switch visualmente
            // TODO: Aquí deberías llamar a tu ProviderService para actualizar Firestore: 'isAvailable': true
            setState(() => _isAvailable = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("¡Estás activo! Te avisaremos cuando haya clientes.")),
            );
          } else {
            // Permiso denegado: No activamos el switch y explicamos por qué
            setState(() => _isAvailable = false);
            _showPermissionDeniedDialog(context);
          }
        } else {
          // El usuario se desactiva (no requiere permisos, solo lógica de negocio)
          setState(() => _isAvailable = false);
          // TODO: Actualizar Firestore: 'isAvailable': false
        }
      },
    );
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Notificaciones necesarias"),
        content: const Text(
          "Para estar 'Disponible', necesitas activar las notificaciones. "
          "De lo contrario, no te enterarás cuando un cliente te escriba."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Entendido"),
          ),
          // Opcional: Botón para ir a Configuración del sistema (usando package:app_settings)
        ],
      ),
    );
  }
}