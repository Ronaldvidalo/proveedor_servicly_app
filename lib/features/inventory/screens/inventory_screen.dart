import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore;

// --- Modelos ---
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:provider/provider.dart' as provider;

// --- Arquitectura ---
import '../providers/inventory_providers.dart';
import '../widgets/inventory_product_card.dart';

// --- Pantallas ---
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/add_edit_product_screen.dart';

// --- Widgets Reutilizables ---
import 'package:proveedor_servicly_app/features/cost_structure/screen/mentor_card.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';
  String _filterStatus = 'Todos'; // 'Todos', 'Bajo Stock', 'Agotado'
  bool _isImporting = false;
  bool _showMentor = true;

  // =========================================================
  // 1. LÓGICA DE IMPORTACIÓN (CSV)
  // =========================================================

  // --- A. Diálogo de Instrucciones ---
  void _showImportInfo(String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D5A), // Fondo Cyber Dark
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF00BFFF)),
            SizedBox(width: 10),
            Text("Formato del CSV", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Para importar correctamente, tu archivo Excel/CSV debe tener estas 5 columnas en este orden exacto:",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _buildFormatRow("1. Nombre", "Ej: Shampoo Premium"),
            _buildFormatRow("2. Descripción", "Ej: 500ml Anti-caída"),
            _buildFormatRow("3. Precio Venta", "Ej: 1500.00"),
            _buildFormatRow("4. Stock", "Ej: 50"),
            _buildFormatRow("5. Costo", "Ej: 800.00 (Opcional)"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.orangeAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                // ignore: deprecated_member_use
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.3))
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "La primera fila del archivo se ignorará (úsala para títulos).",
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00BFFF)),
            icon: const Icon(Icons.folder_open, color: Colors.black),
            label: const Text("Seleccionar Archivo", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx); // Cerrar alerta
              _importCSV(userId); // Abrir selector de archivos
            },
          ),
        ],
      ),
    );
  }

  // Helper visual para las filas del formato
  Widget _buildFormatRow(String title, String example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(example, style: const TextStyle(color: Colors.white38, fontSize: 12), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  // --- B. Procesamiento del Archivo ---
  Future<void> _importCSV(String userId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return;

      setState(() => _isImporting = true);

      // 1. OBTENER EL COSTO FIJO ACTUAL (EL CEREBRO)
      double currentFixedCost = 0.0;
      try {
        final configSnapshot = await cloud_firestore.FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('settings')
            .doc('financial_config')
            .get();

        if (configSnapshot.exists && configSnapshot.data() != null) {
          currentFixedCost = (configSnapshot.data()!['costoFijoUnitarioCalculado'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (e) {
        debugPrint("Advertencia CSV: No se pudo leer costos fijos: $e");
      }

      // 2. Procesar Archivo
      final file = File(result.files.single.path!);
      final input = file.openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter())
          .toList();

      List<ProductModel> newProducts = [];
      
      // Empezamos en i=1 para saltar encabezados
      for (int i = 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.isEmpty || row[0].toString().isEmpty) continue;

        final String name = row[0].toString();
        final String desc = row.length > 1 ? row[1].toString() : '';
        final double price = row.length > 2 ? (double.tryParse(row[2].toString()) ?? 0.0) : 0.0;
        final int stock = row.length > 3 ? (int.tryParse(row[3].toString()) ?? 0) : 0;
        final double cost = row.length > 4 ? (double.tryParse(row[4].toString()) ?? 0.0) : 0.0;

        newProducts.add(ProductModel(
          id: const Uuid().v4(),
          providerId: userId,
          name: name,
          description: desc,
          price: price,
          quantity: stock,
          costPrice: cost,
          createdAt: cloud_firestore.Timestamp.now(),
          imageUrl: '', 
          minStock: 5,
          // --- APLICAMOS EL COSTO INTELIGENTE AQUÍ TAMBIÉN ---
          fixedCostSnapshot: currentFixedCost, 
          wholesalePrice: 0,
          ambassadorPrice: 0,
        ));
      }

      if (newProducts.isNotEmpty) {
        final repo = ref.read(inventoryRepositoryProvider);
        await repo.uploadBulkProducts(newProducts);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('¡${newProducts.length} productos importados con Costo Fijo: $currentFixedCost!'), backgroundColor: Colors.green)
          );
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // =========================================================
  // 2. INTERFAZ (BUILD)
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final userModel = provider.Provider.of<UserModel?>(context);

    const backgroundColor = Color(0xFF1A1A2E);
    const surfaceColor = Color(0xFF2D2D5A);
    const accentColor = Color(0xFF00BFFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Inventario Smart"),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isImporting)
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Importar CSV',
              onPressed: () {
                // Ahora llama al diálogo explicativo primero
                if (userModel != null) _showImportInfo(userModel.uid);
              },
            ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Añadir Manual',
            onPressed: () {
              if (userModel != null) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AddEditProductScreen(user: userModel)
                ));
              }
            },
          )
        ],
      ),
      body: _isImporting 
        ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: accentColor),
              SizedBox(height: 16),
              Text("Procesando CSV...", style: TextStyle(color: Colors.white))
            ],
          ))
        : Column(
        children: [
          
          // --- A. MENTOR CARD ---
          if (_showMentor)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: MentorCard(
                title: "Centro de Comando",
                message: "Mantén tu stock al día para calcular ganancias reales. \n💡 Tip: Usa el botón de 'Carga' arriba para subir tu Excel masivo.",
                onDismiss: () => setState(() => _showMentor = false),
              ),
            ),

          // --- B. BARRA DE BÚSQUEDA ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Buscar producto...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: accentColor),
                filled: true,
                fillColor: surfaceColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // --- C. FILTROS RÁPIDOS ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(label: 'Todos', isSelected: _filterStatus == 'Todos', onSelected: (v) => setState(() => _filterStatus = 'Todos')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Bajo Stock', isSelected: _filterStatus == 'Bajo Stock', onSelected: (v) => setState(() => _filterStatus = 'Bajo Stock')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Agotado', isSelected: _filterStatus == 'Agotado', onSelected: (v) => setState(() => _filterStatus = 'Agotado')),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- D. LISTA DE PRODUCTOS ---
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: accentColor)),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              data: (allProducts) {
                // Lógica de Filtrado
                final filteredProducts = allProducts.where((product) {
                  final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase());
                  if (!matchesSearch) return false;
                  if (_filterStatus == 'Bajo Stock') return product.isLowStock;
                  if (_filterStatus == 'Agotado') return product.isOutOfStock;
                  return true;
                }).toList();

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ignore: deprecated_member_use
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        const Text("Inventario Vacío", style: TextStyle(color: Colors.white54, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text(
                          _filterStatus == 'Todos' 
                            ? "Sube tu primer CSV o agrega manual" 
                            : "No hay productos en este estado",
                          style: const TextStyle(color: Colors.white30)
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (ctx, i) => InventoryProductCard(
                    product: filteredProducts[i], 
                    onTap: () {
                       if (userModel != null) {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AddEditProductScreen(
                              user: userModel, 
                              productToEdit: filteredProducts[i]
                            )
                          ));
                        }
                    }
                  )
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({required this.label, required this.isSelected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: const Color(0xFF2D2D5A),
      // ignore: deprecated_member_use
      selectedColor: const Color(0xFF00BFFF).withOpacity(0.3),
      checkmarkColor: const Color(0xFF00BFFF),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF00BFFF) : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF00BFFF) : Colors.white12,
        ),
      ),
    );
  }
}