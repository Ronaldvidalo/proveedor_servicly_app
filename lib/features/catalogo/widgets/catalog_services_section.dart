import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Modelos y Servicios
import 'package:proveedor_servicly_app/core/models/category_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/core/services/category_service.dart';
import 'package:proveedor_servicly_app/core/services/product_service.dart';

// UI
import 'package:proveedor_servicly_app/features/catalogo/modules/_category_chip.dart';

class CatalogServicesSection extends StatefulWidget {
  final String providerId;
  final Color brandColor;
  final List<ProductModel> selectedServices; // Lista de servicios seleccionados
  final Function(ProductModel) onServiceTap; // Función para añadir/quitar servicios

  const CatalogServicesSection({
    super.key,
    required this.providerId,
    required this.brandColor,
    required this.selectedServices, // Requerido
    required this.onServiceTap,      // Requerido
  });

  @override
  State<CatalogServicesSection> createState() => _CatalogServicesSectionState();
}

class _CatalogServicesSectionState extends State<CatalogServicesSection> {
  String? _selectedServiceCategoryId;

  @override
  Widget build(BuildContext context) {
    final productService = context.read<ProductService>();

    return SliverList(
      delegate: SliverChildListDelegate([
        // Título de la sección
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 16, 8),
          child: Text(
            'Servicios y Precios',
            style: TextStyle(
              color: Colors.white, 
              fontSize: 20, 
              fontWeight: FontWeight.bold
            ),
          ),
        ),
        
        // 1. FILTRO DE CATEGORÍAS
        _buildServiceCategorySelector(),

        // 2. LISTA DE PRODUCTOS FILTRADA
        StreamBuilder<List<ProductModel>>(
          stream: productService.getProducts(
            widget.providerId, 
            categoryId: _selectedServiceCategoryId
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    "No hay servicios disponibles", 
                    style: TextStyle(color: Colors.white24)
                  )
                ),
              );
            }

            final services = snapshot.data!;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                itemBuilder: (context, index) => _ServiceItemRow(
                  service: services[index], 
                  brandColor: widget.brandColor,
                  selectedServices: widget.selectedServices, // Pasar lista al hijo
                  onServiceTap: widget.onServiceTap,         // Pasar función al hijo
                ),
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildServiceCategorySelector() {
    final categoryService = context.read<CategoryService>();
    return StreamBuilder<List<CategoryModel>>(
      stream: categoryService.getCategories(widget.providerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final categories = snapshot.data!;

        return SizedBox(
          height: 55,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final cat = isAll ? null : categories[index - 1];
              final isSelected = isAll 
                  ? _selectedServiceCategoryId == null 
                  : _selectedServiceCategoryId == cat?.id;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CategoryChip(
                  label: isAll ? 'Todos' : cat!.name,
                  isSelected: isSelected,
                  onTap: () => setState(() => 
                    _selectedServiceCategoryId = isAll ? null : cat?.id
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ServiceItemRow extends StatelessWidget {
  final ProductModel service;
  final Color brandColor;
  final List<ProductModel> selectedServices;
  final Function(ProductModel) onServiceTap;

  const _ServiceItemRow({
    required this.service, 
    required this.brandColor,
    required this.selectedServices,
    required this.onServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    // Verificación de selección para UI
    final bool isSelected = selectedServices.any((s) => s.id == service.id);

    final String priceText = service.price > 0 
        ? '\$${service.price.toStringAsFixed(0)}' 
        : 'Consultar';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D5A).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // Si está seleccionado, resalta el borde con el color de marca
          color: isSelected ? brandColor : Colors.white.withValues(alpha: 0.05),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          service.name, 
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 16
          )
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (service.description.isNotEmpty)
              Text(
                service.description, 
                style: const TextStyle(color: Colors.white60, fontSize: 13), 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: brandColor),
                const SizedBox(width: 4),
                // En el futuro usa service.duration si lo añades al modelo
                const Text("45 min", style: TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(width: 16),
                Text(
                  priceText, 
                  style: TextStyle(
                    color: brandColor, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 15
                  )
                ),
              ],
            ),
          ],
        ),
        // Botón dinámico que añade/quita del borrador
        trailing: IconButton(
          icon: Icon(
            isSelected ? Icons.check_circle : Icons.add_circle_outline, 
            color: brandColor, 
            size: 30
          ),
          onPressed: () => onServiceTap(service),
        ),
      ),
    );
  }
}