/// lib/features/modules/screens/modules_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/module_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';

/// Un mapa para convertir los nombres de los íconos (String desde Firestore) a objetos IconData.
const Map<String, IconData> _iconMap = {
  'people_outline': Icons.people_outline,
  'calendar_today_outlined': Icons.calendar_today_outlined,
  'insights': Icons.insights,
  'add_card': Icons.add_card,
  'help_outline': Icons.help_outline,
};

/// La "Tienda de Módulos", donde el usuario puede ver y activar nuevas funcionalidades.
class ModulesScreen extends StatefulWidget {
  // CORRECCIÓN: Se unifican los constructores en uno solo.
  final UserModel userModel;
  const ModulesScreen({super.key, required this.userModel});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  late Future<List<ModuleModel>> _modulesFuture;
  
  String? _isLoadingModuleId;
  static const int _freePlanModuleLimit = 4;

  @override
  void initState() {
    super.initState();
    _modulesFuture = context.read<FirestoreService>().getAvailableModules();
  }

  /// Lógica para activar un nuevo módulo para el usuario.
  Future<void> _activateModule(ModuleModel moduleToActivate) async {
    if (_isLoadingModuleId != null) return;

    // CORRECCIÓN: Se accede al userModel a través de 'widget.userModel'.
    final userModel = widget.userModel;
    final firestoreService = context.read<FirestoreService>();

    setState(() => _isLoadingModuleId = moduleToActivate.moduleId);

    // --- LÓGICA DE PAYWALL ---
    if (moduleToActivate.isPremium && userModel.planType == 'free') {
      _showUpgradeDialog('Este es un módulo premium. ¡Actualiza tu plan para activarlo!');
      setState(() => _isLoadingModuleId = null);
      return;
    }
    
    if (userModel.planType == 'free' && userModel.activeModules.length >= _freePlanModuleLimit) {
       _showUpgradeDialog('Has alcanzado el límite de $_freePlanModuleLimit módulos para el plan gratuito.');
       setState(() => _isLoadingModuleId = null);
       return;
    }

    try {
      await firestoreService.updateUser(userModel.uid, {
        'activeModules': FieldValue.arrayUnion([moduleToActivate.moduleId])
      });
      _showSnackbar('¡Módulo "${moduleToActivate.name}" activado!');
    } catch (e) {
      _showSnackbar('Error al activar el módulo: $e', isError: true);
    } finally {
      if(mounted) setState(() => _isLoadingModuleId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // CORRECCIÓN: Se accede al userModel a través de 'widget.userModel'.
    // También escuchamos los cambios del Provider para que la lista se actualice en tiempo real.
    final userModel = context.watch<UserModel?>();
    
    // Capa de seguridad por si el widget se reconstruye en un estado inesperado.
    if (userModel == null) {
      return Scaffold(appBar: AppBar(title: const Text('Tienda de Módulos')), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda de Módulos'),
      ),
      body: FutureBuilder<List<ModuleModel>>(
        future: _modulesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error al cargar el catálogo de módulos.'));
          }

          final allModules = snapshot.data!
            ..sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));
          
          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: allModules.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final module = allModules[index];
              final isInstalled = userModel.activeModules.contains(module.moduleId);

              return ListTile(
                leading: Icon(_iconMap[module.icon] ?? Icons.help_outline, size: 40),
                title: Text(module.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(module.description),
                trailing: isInstalled
                    ? const Text('Instalado', style: TextStyle(color: Colors.green))
                    : ElevatedButton(
                        onPressed: _isLoadingModuleId == module.moduleId ? null : () => _activateModule(module),
                        child: _isLoadingModuleId == module.moduleId
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Activar'),
                      ),
              );
            },
          );
        },
      ),
    );
  }

  void _showUpgradeDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Plan Premium Requerido'),
        content: Text('$message\n\nActualiza a nuestro plan premium para disfrutar de esta y muchas otras funcionalidades sin límites.'),
        actions: [
          TextButton(
            child: const Text('Más Tarde'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          FilledButton(
            child: const Text('Ver Planes'),
            onPressed: () {
              // TODO: Navegar a la pantalla de suscripciones.
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
     if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }
}