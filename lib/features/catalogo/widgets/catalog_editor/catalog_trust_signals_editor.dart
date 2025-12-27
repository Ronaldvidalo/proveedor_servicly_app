import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';
import 'package:proveedor_servicly_app/core/services/firestore_service.dart';

class CatalogTrustSignalsEditor extends StatelessWidget {
  final ProviderProfileModel profile;

  const CatalogTrustSignalsEditor({super.key, required this.profile});

  // Mapa extendido de iconos para diferentes rubros (Ingeniería, Salud, Estética)
  static const Map<String, IconData> _iconRegistry = {
    'verified_user': Icons.verified_user_outlined,
    'stars': Icons.stars_outlined,
    'history': Icons.history_rounded,
    'security': Icons.security_outlined,
    'engineering': Icons.engineering_outlined, // Para ingenieros
    'architecture': Icons.architecture_outlined, 
    'construction': Icons.construction_outlined,
    'workspace_premium': Icons.workspace_premium_outlined,
    'local_police': Icons.local_police_outlined,
    'handyman': Icons.handyman_outlined,
    'assignment_turned_in': Icons.assignment_turned_in_outlined,
  };

  @override
  Widget build(BuildContext context) {
    // Si está vacío, mostramos una lista base de ejemplo
    final signals = profile.trustSignals.isEmpty 
        ? [{'icon': 'verified_user', 'label': 'Certificado'}] 
        : profile.trustSignals;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Garantía y Calidad", 
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("Insignias que generan confianza", 
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
                IconButton.filledTonal(
                  onPressed: () => _showSignalDialog(context),
                  icon: const Icon(Icons.add, size: 20),
                  style: IconButton.styleFrom(backgroundColor: profile.brandColor.withValues(alpha: 0.2)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: signals.length,
              itemBuilder: (context, index) {
                final item = signals[index];
                return _buildSignalCard(context, item, index, signals);
              },
            ),
          ),
          const Divider(color: Colors.white10, indent: 20, endIndent: 20, height: 32),
        ],
      ),
    );
  }

  Widget _buildSignalCard(BuildContext context, Map<String, dynamic> item, int index, List<Map<String, dynamic>> all) {
    return GestureDetector(
      onTap: () => _showSignalDialog(context, existingItem: item, index: index, allSignals: all),
      onLongPress: () => _confirmDelete(context, index, all),
      child: Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_iconRegistry[item['icon']] ?? Icons.help_outline, color: profile.brandColor, size: 28),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item['label'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignalDialog(BuildContext context, {Map<String, dynamic>? existingItem, int? index, List<Map<String, dynamic>>? allSignals}) {
    final labelController = TextEditingController(text: existingItem?['label']);
    String selectedIcon = existingItem?['icon'] ?? 'verified_user';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text(existingItem == null ? "Añadir Insignia" : "Editar Insignia", style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Texto (ej: 10+ Años)", labelStyle: TextStyle(color: Colors.white38)),
                ),
                const SizedBox(height: 20),
                const Text("Seleccionar Icono", style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),
                // Grid de selección de iconos
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _iconRegistry.entries.map((entry) {
                    final isSelected = selectedIcon == entry.key;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? profile.brandColor : Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(entry.value, color: isSelected ? Colors.white : Colors.white60, size: 24),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
            FilledButton(
              onPressed: () async {
                if (labelController.text.isEmpty) return;
                
                List<Map<String, dynamic>> newList = List.from(allSignals ?? profile.trustSignals);
                final Map<String, dynamic> itemData = {'icon': selectedIcon, 'label': labelController.text.trim()};

                if (index == null) {
                  newList.add(itemData);
                } else {
                  newList[index] = itemData;
                }

                await context.read<FirestoreService>().updateCatalogField(profile.id, {'trustSignals': newList});
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("APLICAR"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int index, List<Map<String, dynamic>> all) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("¿Eliminar insignia?", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("NO")),
          TextButton(
            onPressed: () async {
              List<Map<String, dynamic>> newList = List.from(all);
              newList.removeAt(index);
              await context.read<FirestoreService>().updateCatalogField(profile.id, {'trustSignals': newList});
              if (context.mounted) Navigator.pop(context);
            }, 
            child: const Text("SÍ, ELIMINAR", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }
}