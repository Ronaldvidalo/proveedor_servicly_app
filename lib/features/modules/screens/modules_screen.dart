// lib/features/modules/screens/modules_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/module_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';

// El mapa de íconos sigue siendo necesario para la UI
const Map<String, IconData> _iconMap = {
  'people_outline': Icons.people_outline,
  'calendar_today_outlined': Icons.calendar_today_outlined,
  'insights': Icons.insights,
  'add_card': Icons.add_card,
  'help_outline': Icons.help_outline,
};

// Un modelo de datos simple para contener los datos que necesita la pantalla
class _ModulesScreenData {
  final List<ModuleModel> allModules;
  final UserModel userModel;
  _ModulesScreenData({required this.allModules, required this.userModel});
}

class ModulesScreen extends StatefulWidget {
  final UserModel userModel;
  const ModulesScreen({super.key, required this.userModel});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  // 1. Usamos un Future para cargar TODOS los datos necesarios a la vez.
  late Future<_ModulesScreenData> _dataFuture;

  @override
  void initState() {
    super.initState();
    // 2. En initState, preparamos la carga de datos.
    _dataFuture = _loadScreenData();
  }

  // 3. Este método se encarga de obtener todo lo que la pantalla necesita.
  Future<_ModulesScreenData> _loadScreenData() async {
    final firestoreService = context.read<FirestoreService>();
    // Usamos Future.wait para esperar a que el catálogo de módulos cargue.
    final allModules = await firestoreService.getAvailableModules();
    // El UserModel ya lo tenemos desde el widget.
    return _ModulesScreenData(allModules: allModules, userModel: widget.userModel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda de Módulos'),
      ),
      // 4. Usamos un solo FutureBuilder que espera a que TODOS los datos estén listos.
      body: FutureBuilder<_ModulesScreenData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error fatal al cargar los datos.'));
          }

          final screenData = snapshot.data!;
          final allModules = screenData.allModules
            ..sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));
          
          // 5. Una vez que tenemos los datos, usamos un StreamBuilder para la reactividad.
          return StreamBuilder<UserModel?>(
            stream: context.read<FirestoreService>().getUserStream(screenData.userModel.uid),
            initialData: screenData.userModel,
            builder: (context, userSnapshot) {
              final currentUserModel = userSnapshot.data ?? screenData.userModel;

              // Si llegamos aquí, es seguro construir la lista.
              return _ModulesListView(
                allModules: allModules,
                currentUserModel: currentUserModel,
                onActivateModule: (module) => _activateModule(context, module),
              );
            },
          );
        },
      ),
    );
  }

  // --- Lógica de Activación (ahora separada) ---
  Future<void> _activateModule(BuildContext context, ModuleModel moduleToActivate) async {
    // ... La lógica interna de esta función se mantiene igual que antes ...
  }
}

// --- WIDGET DE UI (SEPARADO) ---
// Separar la UI en su propio widget hace el código más limpio.
class _ModulesListView extends StatefulWidget {
  final List<ModuleModel> allModules;
  final UserModel currentUserModel;
  final Function(ModuleModel) onActivateModule;

  const _ModulesListView({
    required this.allModules,
    required this.currentUserModel,
    required this.onActivateModule,
  });

  @override
  State<_ModulesListView> createState() => _ModulesListViewState();
}

class _ModulesListViewState extends State<_ModulesListView> {
  String? _isLoadingModuleId;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: widget.allModules.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final module = widget.allModules[index];
        final isInstalled = widget.currentUserModel.activeModules.contains(module.moduleId);

        return ListTile(
          leading: Icon(
            _iconMap[module.icon] ?? Icons.help_outline,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(module.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(module.description),
          trailing: isInstalled
              ? const Text('Instalado', style: TextStyle(color: Colors.green))
              : ElevatedButton(
                  onPressed: _isLoadingModuleId == module.moduleId ? null : () async {
                    setState(() => _isLoadingModuleId = module.moduleId);
                    await widget.onActivateModule(module);
                    if (mounted) setState(() => _isLoadingModuleId = null);
                  },
                  child: _isLoadingModuleId == module.moduleId
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Activar'),
                ),
        );
      },
    );
  }
}