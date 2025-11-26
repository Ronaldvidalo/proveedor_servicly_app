import 'package:proveedor_servicly_app/core/models/product_model.dart';

/// Representa un único artículo dentro del carrito de compras.

  class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;
  
  // --- NUEVO: Ganancia Neta del Ítem ---
  // (Precio Venta - Costo Total Real) * Cantidad
  double get totalProfit => (product.price - product.costoTotalReal) * quantity;
}