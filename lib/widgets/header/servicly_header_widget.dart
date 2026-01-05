import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- IMPORTS NECESARIOS PARA LA LÓGICA INTERNA ---
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/dashboard/providers/dashboard_context_provider.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/presentation/screens/select_profile_template_screen.dart';

// --- IMPORTS NUEVOS (INTEGRACIÓN PRO) ---
import 'package:proveedor_servicly_app/shared/widgets/glow_avatar.dart'; // <--- El componente que brilla
import 'package:proveedor_servicly_app/features/subscriptions/screens/subscription_screen.dart'; // <--- Para el Upsell

class ServiclyHeader extends StatelessWidget {
  // Datos necesarios para la lógica
  final UserModel userModel; 
  final List<ProviderProfileModel> profiles; 
  
  const ServiclyHeader({
    super.key,
    required this.userModel,
    required this.profiles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Obtenemos el perfil seleccionado del Provider
    final selectedProfileId = context.watch<DashboardContext>().selectedProfile?.id;
    final isGlobalSelected = selectedProfileId == null;

    final glowColor = colorScheme.primary;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark 
                ? glowColor.withValues(alpha: 0.1) 
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NIVEL 1: MARCA Y PLAN
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBrandLogo(theme, colorScheme, isDark),
              _buildPlanBadge(userModel.planType, colorScheme, isDark),
            ],
          ),
          const SizedBox(height: 25),

          // NIVEL 2: USUARIO (BOTÓN GLOBAL)
          InkWell(
            onTap: () {
               context.read<DashboardContext>().selectGlobal();
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("Vista Global (Resumen Total)"), duration: Duration(milliseconds: 800))
               );
            },
            borderRadius: BorderRadius.circular(30),
            child: _buildUserInfo(theme, colorScheme, isDark, isGlobalSelected),
          ),

          const SizedBox(height: 30),

          // NIVEL 3: LISTA DE PERFILES (TIENDAS)
          _buildStoresSection(context, colorScheme, isDark, selectedProfileId),
        ],
      ),
    );
  }

  // --- LÓGICA DE NEGOCIO (MOVIDA DESDE EL DASHBOARD) ---

  void _handleOnAddStoreTap(BuildContext context) {
    final int currentCount = profiles.length;
    // Verificación robusta del plan (incluyendo corporate)
    final isPro = userModel.isPremium || 
                  userModel.planType.toLowerCase() == 'pro' || 
                  userModel.planType.toLowerCase() == 'corporate';
    
    // Regla de Negocio: FREE = Máximo 1 perfil.
    if (!isPro && currentCount >= 1) {
      _showUpgradeDialog(context);
      return;
    } 

    showDialog(
      context: context, 
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.storefront_rounded, color: Colors.cyanAccent),
            SizedBox(width: 10),
            Text("Nueva Tienda"),
          ],
        ),
        content: const Text(
          "Vas a crear una sucursal o negocio independiente. Tendrá su propio enlace, logo y productos.\n\n¿Deseas continuar?",
          style: TextStyle(height: 1.5),
        ),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Cancelar", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () { 
              Navigator.pop(dialogContext);
              
              // Navegar al selector enviando isNewProfile: true
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SelectProfileTemplateScreen(
                    user: userModel,
                    isNewProfile: true, 
                  ),
                ),
              );
            }, 
            child: const Text("SÍ, CREAR", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        title: const Text("🚀 Alcanzaste el límite"),
        content: const Text("Tu plan actual permite gestionar solo 1 perfil. Pásate a PRO para crear tiendas ilimitadas."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () { 
              Navigator.pop(context); 
              // --- NAVEGACIÓN REAL AL MÓDULO DE SUSCRIPCIONES ---
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            }, 
            child: const Text("SER PRO")
          ),
        ],
      )
    );
  }

  // --- WIDGETS DE UI ---

  Widget _buildBrandLogo(ThemeData theme, ColorScheme scheme, bool isDark) {
    return RichText(
      text: TextSpan(
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          fontSize: 22,
        ),
        children: [
          TextSpan(text: 'SERVIC', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
          TextSpan(text: 'LY', style: TextStyle(color: scheme.primary)),
        ],
      ),
    );
  }

  Widget _buildPlanBadge(String plan, ColorScheme scheme, bool isDark) {
    return Container(
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
       decoration: BoxDecoration(
         color: scheme.primary.withValues(alpha: 0.1),
         borderRadius: BorderRadius.circular(20),
         border: Border.all(color: scheme.primary.withValues(alpha: 0.5)),
       ),
       child: Text(plan.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: scheme.primary)),
    );
  }

  Widget _buildUserInfo(ThemeData theme, ColorScheme scheme, bool isDark, bool isSelected) {
    // Calculamos el nombre para mostrarlo en el texto
    String displayName = "Usuario";
    if (userModel.displayName != null && userModel.displayName!.isNotEmpty) {
      displayName = userModel.displayName!;
    }

    return Row(
      children: [
        // Envolvemos el GlowAvatar en el contenedor de "Selección Global"
        // Esto mantiene el indicador de "pestaña seleccionada" del dashboard
        // pero usa el Avatar inteligente dentro.
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Borde de selección de Dashboard (Global View)
            border: Border.all(
              color: isSelected ? scheme.primary : Colors.transparent, 
              width: isSelected ? 3 : 1
            ),
            // Sombra de selección de Dashboard
            boxShadow: isSelected && isDark
                ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.6), blurRadius: 15)]
                : [],
          ),
          // --- AQUÍ ESTÁ EL CAMBIO CLAVE ---
          child: GlowAvatar(
            user: userModel, // Le pasamos el modelo para que detecte si es PREMIUM
            radius: 24,      // Ajustamos el tamaño para encajar
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isSelected ? "Vista Global" : "Hola,", style: theme.textTheme.bodySmall),
            Row(
              children: [
                Text(displayName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (userModel.isVerified) ...[const SizedBox(width: 4), const Icon(Icons.verified, color: Colors.blueAccent, size: 16)]
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStoresSection(BuildContext context, ColorScheme scheme, bool isDark, String? selectedProfileId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("MIS PERFILES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: scheme.onSurface.withValues(alpha: 0.5), letterSpacing: 1.5)),
            if (profiles.isNotEmpty)
              Text("${profiles.length} Activos", style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 15),
        
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: profiles.length + 1, 
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              
              if (index == profiles.length) {
                // El botón '+' ahora llama a la función interna
                return _AddStoreButton(scheme: scheme, isDark: isDark, onTap: () => _handleOnAddStoreTap(context));
              }
              
              final profile = profiles[index];
              final isSelected = selectedProfileId == profile.id;

              return _StoreItem(
                imageUrl: profile.logoUrl,
                name: profile.businessName,
                scheme: scheme,
                isDark: isDark,
                isSelected: isSelected,
                onTap: () {
                   // Actualizar Provider directamente
                   context.read<DashboardContext>().selectProfile(profile);
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text("Viendo tienda: ${profile.businessName}"), duration: const Duration(milliseconds: 800))
                   );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StoreItem extends StatelessWidget {
  final String imageUrl;
  final String name; 
  final ColorScheme scheme;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  const _StoreItem({
    required this.imageUrl, 
    required this.name,
    required this.scheme, 
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? scheme.primary : (isDark ? Colors.white10 : Colors.black12), 
                width: isSelected ? 3 : 1
              ),
              boxShadow: isSelected && isDark 
                  ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.5), blurRadius: 12)] 
                  : null,
            ),
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.store, color: scheme.onSurface))
                  : Icon(Icons.store, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddStoreButton extends StatelessWidget {
  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback onTap;
  const _AddStoreButton({super.key, required this.scheme, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.5), width: 1),
        ),
        child: Icon(Icons.add, color: scheme.primary),
      ),
    );
  }
}