// --- UX/UI Enhancement Comment ---
// UX/UI Refactor: 18/11/2025
// Style: Cyber Glow (Aplicación de Tema Público)
//
// 1. (¡NUEVO!) Este widget ahora actúa como el "Inyector de Tema"
//    para el perfil público del cliente.
// 2. Lee los campos 'publicProfileTheme' y 'brandColor'
//    directamente desde el 'profile' (ProviderProfileModel).
// 3. Se copió la lógica de 'brand_settings_screen.dart'
//    (_PublicThemeData, _getOnColor) para interpretar
//    estos valores.
// 4. Se crea un 'ThemeData' personalizado en vivo.
// 5. Este 'customTheme' se inyecta a los layouts hijos
//    (Catalog, Tienda, CV) usando un widget `Theme`.
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/services/provider_service.dart';
import 'package:proveedor_servicly_app/core/models/public_profile_view_model.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/templates/tienda_layout.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/templates/cv_layout.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/templates/catalog_layout.dart';
// Módulo CRM
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';

// ===================================================================
// --- DEFINICIONES DE TEMA PÚBLICO (Copiado de brand_settings_screen) ---
// Esta es la lógica "traductora" que necesitamos
// ===================================================================

/// Clase de datos simple para nuestros "Skins" de perfil público
class _PublicThemeData {
  final String id;
  final String name;
  final Color background;
  final Color surface;

  const _PublicThemeData({
    required this.id,
    required this.name,
    required this.background,
    required this.surface,
  });
}

/// Define los "Skins" permitidos
final List<_PublicThemeData> _publicProfileThemes = [
  const _PublicThemeData(
    id: 'cyber_glow',
    name: 'Cyber Glow',
    background: Color(0xFF1A1A2E),
    surface: Color(0xFF2D2D5A),
  ),
  const _PublicThemeData(
    id: 'nebula_purple',
    name: 'Nebula Purple',
    background: Color(0xFF2E1A2E),
    surface: Color(0xFF4A2D4A),
  ),
  const _PublicThemeData(
    id: 'crimson_red',
    name: 'Crimson Red',
    background: Color(0xFF2E1A1A),
    surface: Color(0xFF4A2D2D),
  ),
  const _PublicThemeData(
    id: 'matrix_green',
    name: 'Matrix Green',
    background: Color(0xFF1A2E1A),
    surface: Color(0xFF2D4A2D),
  ),
];

/// Helper para obtener el color de contraste (blanco/negro)
Color _getOnColor(Color color) {
  return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? Colors.white
      : Colors.black;
}
// ===================================================================


/// La "mini-app" pública de un proveedor, visible para sus clientes.
/// Ahora actúa como el inyector del CrmRepository para la captura de Leads.
class PublicProfileScreen extends StatelessWidget {
  final String providerId;

  const PublicProfileScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    // Inyectamos el Repositorio y el ViewModel para que las plantillas puedan acceder al CRM
    return MultiProvider(
      providers: [
        // 1. Inyectar el ViewModel de Perfil
        ChangeNotifierProvider(
          create: (context) => PublicProfileViewModel(
            providerService: context.read<ProviderService>(),
          )..fetchProfile(providerId),
        ),
        // 2. Inyectar el Repositorio CRM (esencial para la captura de leads)
        // Ya que el Dashboard no inyecta este Provider, lo hacemos aquí.
        Provider(create: (_) => CrmRepository()),
      ],
      child: Consumer<PublicProfileViewModel>(
        builder: (context, viewModel, child) {
          
          // --- Pantalla de Carga (Themeable) ---
          if (viewModel.isLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFF1A1A2E), // Default Cyber Glow BG
              body: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }

          // --- Pantalla de Error (Themeable) ---
          if (viewModel.hasError || viewModel.profile == null) {
            return Scaffold(
              backgroundColor: const Color(0xFF1A1A2E), // Default Cyber Glow BG
              appBar: AppBar(
                backgroundColor: Colors.transparent, 
                elevation: 0, 
                iconTheme: const IconThemeData(color: Colors.white)
              ),
              body: Center(
                  child: Text(
                viewModel.error ?? 'No se pudo encontrar el perfil del proveedor.',
                style: const TextStyle(color: Colors.white70),
              )),
            );
          }

          // --- Perfil Cargado: Aplicar Tema ---
          final profile = viewModel.profile!;

          // --- ¡AQUÍ COMIENZA LA MAGIA DEL TEMA! ---
          
          // 1. Leer los valores guardados (Usando los campos del Model)
          final String themeId = profile.publicProfileTheme ?? 'cyber_glow';
          final Color primaryColor = profile.brandColor; // Leemos el Color directamente

          // 2. Encontrar el tema de fondo/superficie
          final _PublicThemeData publicThemeData = _publicProfileThemes.firstWhere(
            (t) => t.id == themeId,
            orElse: () => _publicProfileThemes.first, // Default a cyber_glow
          );
          
          // 3. Crear los colores personalizados
          final Color backgroundColor = publicThemeData.background;
          final Color surfaceColor = publicThemeData.surface;
          final Color onPrimaryColor = _getOnColor(primaryColor);
          
          // 4. Crear el ThemeData personalizado
          final ThemeData baseTheme = Theme.of(context); // Tema base de la app
          final ThemeData customTheme = baseTheme.copyWith(
            scaffoldBackgroundColor: backgroundColor,
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: primaryColor,
              onPrimary: onPrimaryColor,
              surface: surfaceColor,
              onSurface: Colors.white,
              background: backgroundColor,
              onBackground: Colors.white, // Asumimos texto blanco en fondo oscuro
            ),
            // Asegurarnos de que los textos sean legibles
            textTheme: baseTheme.textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
            // Estilo de tarjetas
            cardTheme: baseTheme.cardTheme.copyWith(
              color: surfaceColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            // Estilo de botones
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: onPrimaryColor,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              )
            ),
            appBarTheme: baseTheme.appBarTheme.copyWith(
              backgroundColor: backgroundColor,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle: baseTheme.textTheme.titleLarge?.copyWith(color: Colors.white)
            )
          );
          
          // 5. Determinar el layout (tu código original)
          Widget layout;
          switch (profile.profileType) { 
            case 'catalog':
              layout = CatalogLayout(providerId: providerId, profile: profile);
              break;
            case 'store':
              layout = TiendaLayout(providerId: providerId, profile: profile);
              break;
            case 'cv':
              layout = CvLayout(profile: profile);
              break;
            default:
              layout = CvLayout(profile: profile);
          }

          // 6. Devolver el layout envuelto en el Tema personalizado
          return Theme(
            data: customTheme,
            child: layout,
          );
          // --- FIN DE LA INYECCIÓN DE TEMA ---
        },
      ),
    );
  }
}