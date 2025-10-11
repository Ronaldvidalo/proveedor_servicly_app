// lib/features/dashboard/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/module_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../profile/screens/create_profile_screen.dart';
import '../../modules/screens/modules_screen.dart';

/// Un mapa para convertir los nombres de los íconos (String desde Firestore) a objetos IconData.
const Map<String, IconData> _iconMap = {
  'people_outline': Icons.people_outline,
  'calendar_today_outlined': Icons.calendar_today_outlined,
  'insights': Icons.insights,
  'add_card': Icons.add_card,
  'add_circle_outline': Icons.add_circle_outline,
  'store_mall_directory_outlined': Icons.store_mall_directory_outlined,
  'person_search_outlined': Icons.person_search_outlined,
  'sync_alt_rounded': Icons.sync_alt_rounded,
  'help_outline': Icons.help_outline,
};

/// La pantalla principal y dashboard para el usuario proveedor.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<ModuleModel>> _modulesFuture;

  @override
  void initState() {
    super.initState();
    _modulesFuture = context.read<FirestoreService>().getAvailableModules();
  }

  void _navigateToCreateProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<UserModel?>();
    final authService = context.read<AuthService>();

    if (userModel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final personalization = userModel.personalization;
    final businessName = personalization['businessName'] as String? ?? 'Mi Negocio';
    final brandColor = _colorFromHex(personalization['primaryColor'] as String?) ?? Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(businessName),
        backgroundColor: brandColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async => await authService.signOut(),
          ),
        ],
      ),
      body: FutureBuilder<List<ModuleModel>>(
        future: _modulesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Error al cargar los módulos.'));
          }

          final allModules = snapshot.data!;
          final activeModules = allModules
              .where((module) => userModel.activeModules.contains(module.moduleId))
              .toList()
            ..sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  Text('¡Hola, ${userModel.displayName ?? 'bienvenido'}!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  
                  if (!userModel.isProfileComplete)
                    _ProfileCompletionBanner(
                      onCompleteProfile: () => _navigateToCreateProfile(context),
                    ),

                  const SizedBox(height: 24),
                  Text('Mis Módulos Activos', style: Theme.of(context).textTheme.titleLarge),
                  const Divider(height: 24),

                  Wrap(
                    spacing: 16.0,
                    runSpacing: 16.0,
                    children: [
                      ...activeModules.map((module) {
                        return _ActionCard(
                          title: module.name,
                          icon: _iconMap[module.icon] ?? Icons.help_outline,
                          onTap: () {
                            // TODO: Implementar navegación a la pantalla del módulo
                            print('Navegando al módulo: ${module.moduleId}');
                          },
                        );
                      }),
                      
                      _ActionCard(
                        title: 'Añadir Módulo',
                        icon: Icons.add_circle_outline,
                        onTap: () {
                          Navigator.of(context).push(
                            // --- INICIO DE LA CORRECCIÓN ---
                            // Le pasamos el userModel que ya tenemos a la ModulesScreen.
                            MaterialPageRoute(builder: (_) => ModulesScreen(userModel: userModel)),
                            // --- FIN DE LA CORRECCIÓN ---
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color? _colorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;
    final hexCode = hexColor.replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('FF$hexCode', radix: 16));
    }
    return null;
  }
}

// --- WIDGETS AUXILIARES COMPLETOS ---

class _ProfileCompletionBanner extends StatelessWidget {
  final VoidCallback onCompleteProfile;
  const _ProfileCompletionBanner({required this.onCompleteProfile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.primaryColor.withAlpha(25),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.primaryColor.withAlpha(77))
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: theme.primaryColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Finaliza la configuración de tu cuenta',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('Completa tu perfil para poder generar contratos y presupuestos.'),
                ],
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: onCompleteProfile,
              child: const Text('COMPLETAR'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 160,
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}