// --- UX/UI Enhancement Comment ---
// Modelo: QuoteItem (Ítem de Cotización)
// Responsabilidad: Representar una línea de producto dentro de una cotización.
// Unificación: Diseñado para mapearse directamente desde 'ProductModel' de tu inventario.

import 'package:proveedor_servicly_app/core/models/product_model.dart';

class QuoteItem {
  final String id;          // UUID local para la lista visual
  final String inventoryId; // ID original del producto en 'products' collection
  final String sku;         // Mantenemos el SKU para logística
  final String name;        // Nombre del producto (Snapshot)
  final String description; // Descripción detallada
  final String imageUrl;    // Para mostrar foto en el PDF/Vista previa
  final String category;    // Para agrupar en el PDF si se desea
  
  final double quantity;    
  final double unitPrice;   // Precio de venta al cliente (editable)
  final double costSnapshot; // Costo real (para calcular tu ganancia interna)
  final double taxRate;     // Por si este producto tiene IVA específico

  QuoteItem({
    required this.id,
    this.inventoryId = '',
    this.sku = '',
    required this.name,
    this.description = '',
    this.imageUrl = '',
    this.category = 'General',
    this.quantity = 1.0,
    this.unitPrice = 0.0,
    this.costSnapshot = 0.0,
    this.taxRate = 0.0,
  });

  // Cálculo del total de línea (Cantidad * Precio Unitario)
  double get total => quantity * unitPrice;
  
  // Cálculo de ganancia estimada (Interno, el cliente no ve esto)
  double get estimatedProfit => (unitPrice - costSnapshot) * quantity;

  // --- MÉTODO DE UNIFICACIÓN: Convertir Inventario a Cotización ---
  // Este es el "puente" mágico. Recibe tu ProductModel complejo y extrae lo necesario
  // para la cotización, congelando los precios y costos en el tiempo.
  factory QuoteItem.fromProduct(ProductModel product) {
    // Generamos un ID temporal simple para manejo en UI antes de guardar en DB
    final tempId = DateTime.now().microsecondsSinceEpoch.toString();

    return QuoteItem(
      id: tempId,
      inventoryId: product.id,
      sku: product.sku,
      name: product.name,
      description: product.description,
      imageUrl: product.imageUrl,
      category: product.category,
      quantity: 1.0, // Por defecto inicia con 1 unidad
      unitPrice: product.price, // Precio sugerido del inventario (PVP)
      // Usamos tu getter inteligente 'costoTotalReal' (costo variable + fijo)
      // Esto es vital para tus analíticas de ganancias posteriores.
      costSnapshot: product.costoTotalReal, 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inventoryId': inventoryId,
      'sku': sku,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'costSnapshot': costSnapshot,
      'taxRate': taxRate,
    };
  }

  factory QuoteItem.fromMap(Map<String, dynamic> map) {
    return QuoteItem(
      id: map['id'] ?? '',
      inventoryId: map['inventoryId'] ?? '',
      sku: map['sku'] ?? '',
      name: map['name'] ?? 'Ítem sin nombre',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? 'General',
      quantity: (map['quantity'] ?? 1.0).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      costSnapshot: (map['costSnapshot'] ?? 0.0).toDouble(),
      taxRate: (map['taxRate'] ?? 0.0).toDouble(),
    );
  }

  QuoteItem copyWith({
    String? id,
    String? inventoryId,
    String? sku,
    String? name,
    String? description,
    String? imageUrl,
    String? category,
    double? quantity,
    double? unitPrice,
    double? costSnapshot,
    double? taxRate,
  }) {
    return QuoteItem(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      costSnapshot: costSnapshot ?? this.costSnapshot,
      taxRate: taxRate ?? this.taxRate,
    );
  }
}