// --- UX/UI Enhancement Comment ---
// UX/UI Redesigned: 14/10/2025
// Style: Cyber Glow
// This screen was refactored to align with the "Cyber Glow" design philosophy.
// It features a responsive GridView layout, custom-designed interactive module cards,
// and confirmation dialogs for a professional and user-friendly experience.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/module_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';

// El mapa de íconos que es consistente con nuestra base de datos actual.
const Map<String, IconData> _iconMap = {
  'people_outline': Icons.people_outline_rounded,
  'calendar_today_outlined': Icons.calendar_today_rounded,
  'insights': Icons.insights_rounded,
  'add_card': Icons.add_card_rounded,
  'help_outline': Icons.help_outline_rounded,
};

class ModulesScreen extends StatefulWidget {
  // La pantalla recibe toda la información que necesita, haciéndola robusta.
  final UserModel userModel;
  final List<ModuleModel> allModules;

  const ModulesScreen({
    super.key,
    required this.userModel,
    required this.allModules,
  });

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  String? _isLoadingModuleId;
  static const int _freePlanModuleLimit = 4;

  late List<ModuleModel> _sortedModules;

  @override
  void initState() {
    super.initState();
    // Ordenamos la lista que recibimos una sola vez.
    _sortedModules = widget.allModules
      ..sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));
  }

  /// Lógica para activar un nuevo módulo.
  Future<void> _activateModule(ModuleModel moduleToActivate, UserModel currentUserModel) async {
    if (_isLoadingModuleId != null) return;
    setState(() => _isLoadingModuleId = moduleToActivate.moduleId);
    final firestoreService = context.read<FirestoreService>();

    if (moduleToActivate.isPremium && currentUserModel.planType == 'free') {
      _showUpgradeDialog('Este es un módulo premium. ¡Actualiza tu plan para activarlo!');
      setState(() => _isLoadingModuleId = null);
      return;
    }

    if (currentUserModel.planType == 'free' && currentUserModel.activeModules.length >= _freePlanModuleLimit) {
      _showUpgradeDialog('Has alcanzado el límite de $_freePlanModuleLimit módulos para el plan gratuito.');
      setState(() => _isLoadingModuleId = null);
      return;
    }

    try {
      await firestoreService.updateUser(currentUserModel.uid, {
        'activeModules': FieldValue.arrayUnion([moduleToActivate.moduleId])
      });
      _showSnackbar('¡Módulo "${moduleToActivate.name}" activado!');
    } catch (e) {
      _showSnackbar('Error al activar el módulo: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingModuleId = null);
    }
  }

  /// --- CORRECCIÓN: LÓGICA DE DESACTIVACIÓN COMPLETA ---
  Future<void> _deactivateModule(ModuleModel moduleToDeactivate, UserModel currentUserModel) async {
    if (_isLoadingModuleId != null) return;
    setState(() => _isLoadingModuleId = moduleToDeactivate.moduleId);
    final firestoreService = context.read<FirestoreService>();

    try {
      await firestoreService.updateUser(currentUserModel.uid, {
        'activeModules': FieldValue.arrayRemove([moduleToDeactivate.moduleId])
      });
      _showSnackbar('Módulo "${moduleToDeactivate.name}" desactivado.', isError: false);
    } catch (e) {
      _showSnackbar('Error al desactivar el módulo: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingModuleId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Tienda de Módulos'),
        backgroundColor: backgroundColor,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<UserModel?>(
        stream: context.read<FirestoreService>().getUserStream(widget.userModel.uid),
        initialData: widget.userModel,
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final currentUserModel = userSnapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            // --- MEJORA DE RESPONSIVIDAD ---
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              // Calcula cuántas columnas de 200px de ancho caben, con un mínimo de 2.
              crossAxisCount: (MediaQuery.of(context).size.width / 220).floor().clamp(2, 5),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: _sortedModules.length,
            itemBuilder: (context, index) {
              final module = _sortedModules[index];
              final isInstalled = currentUserModel.activeModules.contains(module.moduleId);

              return _ModuleGridCard(
                module: module,
                isInstalled: isInstalled,
                isLoading: _isLoadingModuleId == module.moduleId,
                onTap: () {
                  if (isInstalled) {
                    _showDeactivationDialog(module, currentUserModel);
                  } else {
                    _showActivationDialog(module, currentUserModel);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  // --- Tus excelentes diálogos de confirmación y métodos auxiliares ---
  void _showActivationDialog(ModuleModel module, UserModel currentUserModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D5A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_iconMap[module.icon] ?? Icons.help_outline_rounded, color: const Color(0xFF00BFFF)),
            const SizedBox(width: 12),
            Expanded(child: Text(module.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(
          "${module.description}\n\n¿Deseas activar este módulo en tu dashboard?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00BFFF), foregroundColor: Colors.black),
            child: const Text('Activar'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _activateModule(module, currentUserModel);
            },
          ),
        ],
      ),
    );
  }

  void _showDeactivationDialog(ModuleModel module, UserModel currentUserModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D5A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_iconMap[module.icon] ?? Icons.help_outline_rounded, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(child: Text('Desactivar ${module.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        content: const Text(
          "El módulo se quitará de tu dashboard, pero tus datos se conservarán por si decides volver a activarlo.\n\n¿Estás seguro?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Sí, desactivar'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _deactivateModule(module, currentUserModel);
            },
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D5A),
        title: const Text('Plan Premium Requerido', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: const Text('Más Tarde'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          FilledButton(
            child: const Text('Ver Planes'),
            onPressed: () {
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
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF00FF7F),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

/// --- TU WIDGET DE TARJETA REDISEÑADO SE MANTIENE IGUAL ---
class _ModuleGridCard extends StatelessWidget {
  final ModuleModel module;
  final bool isInstalled;
  final bool isLoading;
  final VoidCallback onTap;

  const _ModuleGridCard({
    required this.module,
    required this.isInstalled,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00BFFF);
    const surfaceColor = Color(0xFF2D2D5A);
    const successColor = Color(0xFF00FF7F);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4.0,
      color: surfaceColor,
      shadowColor: isInstalled ? successColor.withAlpha(100) : accentColor.withAlpha(80),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isInstalled ? successColor : accentColor.withAlpha(150),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _iconMap[module.icon] ?? Icons.help_outline_rounded,
                  size: 40,
                  color: isInstalled ? successColor : accentColor,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    module.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [
                        if (isInstalled) Shadow(color: successColor, blurRadius: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isLoading)
              Container(
                decoration: BoxDecoration(
                  // CORRECCIÓN: Se usa '.withAlpha()' en lugar de '.withOpacity()'.
                  color: Colors.black.withAlpha(128),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
            if (isInstalled && !isLoading)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: surfaceColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: successColor, size: 24),
                ),
              ),
            if (module.isPremium)
              Positioned(
                top: 8,
                left: 8,
                child: Tooltip(
                  message: 'Módulo Premium',
                  child: Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
