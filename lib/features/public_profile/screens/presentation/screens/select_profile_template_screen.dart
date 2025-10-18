import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';
import 'package:proveedor_servicly_app/features/settings/screens/brand_settings_screen.dart';

/// Una pantalla donde los usuarios eligen una plantilla para su perfil público.
class SelectProfileTemplateScreen extends StatelessWidget {
  /// El modelo del usuario actual. Se pasa directamente para evitar errores de provider.
  final UserModel user;

  const SelectProfileTemplateScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elige una Plantilla'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Selecciona cómo quieres presentar tus servicios a tus clientes.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          _TemplateOptionCard(
            icon: Icons.person_outline,
            title: 'Perfil Profesional (CV)',
            description: 'Ideal para freelancers y consultores. Muestra tu experiencia y habilidades.',
            templateId: 'cv',
            onTap: (ctx, id) => _navigateToEditPage(ctx, id, user),
          ),
          _TemplateOptionCard(
            icon: Icons.store_outlined,
            title: 'Tienda de Servicios',
            description: 'Perfecto para quienes ofrecen servicios con precios definidos, como clases o reparaciones.',
            templateId: 'store',
            onTap: (ctx, id) => _navigateToEditPage(ctx, id, user),
          ),
          _TemplateOptionCard(
            icon: Icons.collections_bookmark_outlined,
            title: 'Catálogo de Servicios',
            description: 'Ideal para profesionales. Muestra tus servicios y permite a los clientes agendar turnos.',
            templateId: 'catalog',
            onTap: (ctx, id) => _navigateToEditPage(ctx, id, user),
          ),
        ],
      ),
    );
  }

  /// Navega a la página de edición de perfil, pasando la plantilla seleccionada.
  void _navigateToEditPage(BuildContext context, String templateId, UserModel user) {
    // Al seleccionar una plantilla, llevamos al usuario a la pantalla de configuración
    // y le pasamos el ID de la plantilla para que se preseleccione.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BrandSettingsScreen(
          user: user,
          initialTemplateId: templateId,
        ),
      ),
    );
  }
}

/// Widget para una tarjeta de opción de plantilla con un diseño mejorado.
class _TemplateOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String templateId;
  final void Function(BuildContext context, String templateId) onTap;

  const _TemplateOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.templateId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(context, templateId),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(description, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

