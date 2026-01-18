import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- Modelos y Servicios ---
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart'; 
import 'package:proveedor_servicly_app/core/services/product_service.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';

// --- Widgets de Navegación y UI ---
import 'package:proveedor_servicly_app/widgets/navigation/servicly_sidebar.dart';
import 'package:proveedor_servicly_app/widgets/product_card_refactor.dart';
import 'package:proveedor_servicly_app/features/public_profile/screens/widgets/product_detail_dialog.dart';

// --- PANTALLAS DE DESTINO ---
// Asegúrate de que este archivo exista. Si no, usa el Stub al final.
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/add_edit_product_screen.dart';

// --- STUBS LOCALES (Solo por si falta el de editar perfil) ---
// Ver final del archivo

class ManageStoreScreen extends StatelessWidget {
  final UserModel? user;
  final ProviderProfileModel? profile;

  const ManageStoreScreen({super.key, this.user, this.profile});

  @override
  Widget build(BuildContext context) {
    // 1. Prioridad: Perfil pasado directo
    if (profile != null) return _ManageStoreContent(profile: profile!);

    // 2. Prioridad: Perfil desde el contexto (Provider)
    try {
      final contextProfile = Provider.of<ProviderProfileModel>(context, listen: false);
      return _ManageStoreContent(profile: contextProfile);
    } catch (_) {}

    // 3. Prioridad: Buscar en Firebase si tenemos usuario
    if (user != null) {
      return FutureBuilder<List<ProviderProfileModel>>(
        future: Provider.of<FirestoreService>(context, listen: false).getUserProviderProfiles(user!.uid).first,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return _ManageStoreContent(profile: snapshot.data!.first);
          }
          return const Scaffold(body: Center(child: Text("No se encontraron perfiles de tienda.")));
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Tienda")),
      body: const Center(child: Text("Cargando perfil...")),
    );
  }
}

class _ManageStoreContent extends StatefulWidget {
  final ProviderProfileModel profile;
  const _ManageStoreContent({required this.profile});

  @override
  State<_ManageStoreContent> createState() => _ManageStoreContentState();
}

class _ManageStoreContentState extends State<_ManageStoreContent> {
  int _selectedIndex = 1;
  final TextEditingController _searchController = TextEditingController(); 

  void _handleNavigation(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- NAVEGACIÓN CENTRALIZADA ---
  void _navigateToAddEditProduct([ProductModel? product]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Si pasas product, es edición. Si es null, es creación.
        builder: (_) => AddEditProductScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // ignore: dead_null_aware_expression
    final String safeProviderId = widget.profile.providerId ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        // ============================================================
        // VISTA WEB (> 900px) - DISEÑO 2 COLUMNAS (Master-Detail)
        // ============================================================
        if (constraints.maxWidth > 900) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Row(
              children: [
                ServiclySidebar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _handleNavigation,
                ),
                Expanded(
                  child: _buildWebLayout(context, theme, isDark, safeProviderId),
                ),
              ],
            ),
          );
        } 
        
        // ============================================================
        // VISTA MÓVIL (< 900px) - DISEÑO ORIGINAL RESTAURADO
        // ============================================================
        else {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text("Gestión de Tienda"),
              backgroundColor: theme.appBarTheme.backgroundColor,
              foregroundColor: theme.appBarTheme.foregroundColor,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProviderProfileScreen(profile: widget.profile))),
                )
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMobileHeader(widget.profile, theme),
                  const SizedBox(height: 24),
                  // BOTONES GRANDES HORIZONTALES (ORIGINAL)
                  _buildQuickActions(context, theme, widget.profile.brandColor, isDark),
                  const SizedBox(height: 24),
                  _buildStatsSection(context, theme, isDark),
                  const SizedBox(height: 24),
                  Text("Productos", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildProductGrid(context, safeProviderId, widget.profile.brandColor, isWeb: false),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: widget.profile.brandColor,
              onPressed: () => _navigateToAddEditProduct(), // Navegación FAB Móvil
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
        }
      },
    );
  }

  // ===========================================================================
  // ✨ LÓGICA DE LAYOUT WEB (70% Inventario - 30% Tools)
  // ===========================================================================
  Widget _buildWebLayout(BuildContext context, ThemeData theme, bool isDark, String providerId) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- IZQUIERDA: INVENTARIO (70%) ---
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de Herramientas Web
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.08)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Text("Mi Inventario", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 32),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: "Buscar producto...",
                              prefixIcon: const Icon(Icons.search),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          // NAVEGACIÓN WEB (Barra Superior)
                          onPressed: () => _navigateToAddEditProduct(),
                          icon: const Icon(Icons.add),
                          label: const Text("Crear"),
                          style: FilledButton.styleFrom(
                            backgroundColor: widget.profile.brandColor, 
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18)
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Grid Web
                  Expanded(
                    child: _buildProductGrid(context, providerId, widget.profile.brandColor, isWeb: true),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 24),

            // --- DERECHA: HERRAMIENTAS (30%) ---
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildWebSideProfile(context, widget.profile, theme, isDark),
                    const SizedBox(height: 20),
                    _buildStatsSection(context, theme, isDark),
                    const SizedBox(height: 20),
                    // Lista Vertical de Acciones (Exclusiva Web Sidebar)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Accesos Directos", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          // NAVEGACIÓN WEB (Sidebar)
                          _ActionCard(
                            icon: Icons.add_box_rounded, 
                            label: "Nuevo Producto", 
                            color: widget.profile.brandColor, isDark: isDark, 
                            isCompact: true,
                            onTap: () => _navigateToAddEditProduct(),
                          ),
                          const SizedBox(height: 12),
                          _ActionCard(
                            icon: Icons.category_rounded, 
                            label: "Categorías", 
                            color: Colors.orange, isDark: isDark, 
                            isCompact: true,
                            onTap: () {},
                          ),
                          const SizedBox(height: 12),
                          _ActionCard(
                            icon: Icons.qr_code, 
                            label: "Ver mi Código QR", 
                            color: Colors.purple, isDark: isDark, 
                            isCompact: true,
                            onTap: () {},
                          ),
                          const SizedBox(height: 12),
                          _ActionCard(
                            icon: Icons.settings_outlined, 
                            label: "Configuración", 
                            color: Colors.blueGrey, isDark: isDark, 
                            isCompact: true,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProviderProfileScreen(profile: widget.profile))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGETS COMPARTIDOS
  // ===========================================================================

  Widget _buildWebSideProfile(BuildContext context, ProviderProfileModel profile, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: profile.brandColor, width: 3),
              image: profile.logoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(profile.logoUrl), fit: BoxFit.cover) : null,
              color: profile.brandColor.withValues(alpha: 0.1),
            ),
            child: profile.logoUrl.isEmpty ? Center(child: Text(profile.businessName.isNotEmpty ? profile.businessName[0].toUpperCase() : 'S', style: TextStyle(fontSize: 32, color: profile.brandColor, fontWeight: FontWeight.bold))) : null,
          ),
          const SizedBox(height: 16),
          Text(profile.businessName, textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text("${profile.ratingAvg > 0 ? profile.ratingAvg.toStringAsFixed(1) : 'Nuevo'} • ${profile.category ?? 'General'}", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(ProviderProfileModel profile, ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: profile.brandColor.withValues(alpha: 0.1),
          backgroundImage: profile.logoUrl.isNotEmpty ? NetworkImage(profile.logoUrl) : null,
          child: profile.logoUrl.isEmpty ? Text(profile.businessName.isNotEmpty ? profile.businessName[0].toUpperCase() : 'S') : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.businessName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text(profile.category ?? 'General', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  // --- VERSION MÓVIL ORIGINAL ---
  Widget _buildQuickActions(BuildContext context, ThemeData theme, Color brandColor, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.add_box_rounded,
            label: "Nuevo Producto",
            color: brandColor,
            isDark: isDark,
            // NAVEGACIÓN MÓVIL (Action Card)
            onTap: () => _navigateToAddEditProduct(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionCard(
            icon: Icons.category_rounded,
            label: "Categorías",
            color: Colors.orange,
            isDark: isDark,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 16),
        if (MediaQuery.of(context).size.width > 600)
          Expanded(
            child: _ActionCard(
              icon: Icons.qr_code,
              label: "Mi QR",
              color: Colors.purple,
              isDark: isDark,
              onTap: () {},
            ),
          ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(label: "Pedidos", value: "0", color: Colors.blue),
          Container(width: 1, height: 30, color: theme.dividerColor.withValues(alpha: 0.3)),
          _StatItem(label: "Ventas", value: "\$0", color: Colors.green),
          Container(width: 1, height: 30, color: theme.dividerColor.withValues(alpha: 0.3)),
          _StatItem(label: "Visitas", value: "124", color: Colors.purple),
        ],
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, String providerId, Color brandColor, {required bool isWeb}) {
    final productService = context.read<ProductService>();

    return StreamBuilder<List<ProductModel>>(
      stream: productService.getProducts(providerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 300,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text("Tu inventario está vacío"),
                const SizedBox(height: 8),
                if (!isWeb) 
                  FilledButton.icon(
                    // Navegación estado vacío Móvil
                    onPressed: () => _navigateToAddEditProduct(),
                    icon: const Icon(Icons.add), label: const Text("Agregar Primer Producto"),
                    style: FilledButton.styleFrom(backgroundColor: brandColor),
                  )
              ],
            ),
          );
        }

        final products = snapshot.data!;

        return GridView.builder(
          shrinkWrap: true,
          // En Web permitimos scroll si hay muchos productos, en móvil no (usa el scroll padre)
          physics: isWeb ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: isWeb ? 40 : 0),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 280, 
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8, 
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCardRefactor(
              product: product,
              brandColor: brandColor,
              isEditable: true, 
              // Navegación para Editar (Web y Móvil)
              onTap: () => ProductDetailDialog.show(context, product, brandColor),
              onAddToCart: () => _navigateToAddEditProduct(product), // Botón editar rápido
            );
          },
        );
      },
    );
  }
}

// Widget de Tarjeta de Acción (Adaptable)
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool isCompact; // Para modo Sidebar Web
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon, required this.label, required this.color, required this.isDark, required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // MODO SIDEBAR (WEB): Lista compacta vertical
    if (isCompact) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    // MODO ORIGINAL (MÓVIL): Tarjeta cuadrada grande
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.08)),
          boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
      ],
    );
  }
}

// --- STUBS (Clases Placeholder si no tienes los archivos) ---
// NOTA: Si AddEditProductScreen da error de importación, descomenta esta clase temporal:
/*
class AddEditProductScreen extends StatelessWidget {
  final ProductModel? product;
  const AddEditProductScreen({super.key, this.product});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(product == null ? "Crear" : "Editar")));
}
*/

class EditProviderProfileScreen extends StatelessWidget {
  final ProviderProfileModel profile;
  const EditProviderProfileScreen({super.key, required this.profile});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Editar Perfil")));
}