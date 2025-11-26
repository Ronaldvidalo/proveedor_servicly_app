import 'package:flutter/foundation.dart';
import 'package:proveedor_servicly_app/core/models/cart_item_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';

/// Gestiona el estado del carrito de compras en toda la aplicación.
/// Actualizado para soportar cálculo de Ganancia Neta (POS).
class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  /// Devuelve una lista de todos los artículos en el carrito.
  List<CartItem> get items => _items.values.toList();

  /// Devuelve el número total de artículos únicos en el carrito.
  int get totalItems => _items.values.fold(0, (sum, item) => sum + item.quantity);

  /// Calcula el precio total de venta (PVP) de todos los artículos.
  double get totalPrice {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.subtotal;
    });
    return total;
  }

  // --- ¡NUEVO! CÁLCULO DE GANANCIA NETA ---
  /// Calcula la ganancia real estimada de esta venta.
  /// Fórmula: (Precio Venta - (Costo Variable + Costo Fijo)) * Cantidad
  double get totalProfit {
    var profit = 0.0;
    _items.forEach((key, cartItem) {
      // Obtenemos el costo total unitario desde el nuevo ProductModel
      final double costoUnitario = cartItem.product.costPrice + cartItem.product.fixedCostSnapshot;
      
      // Margen por unidad
      final double margenUnitario = cartItem.product.price - costoUnitario;
      
      // Sumamos al total
      profit += margenUnitario * cartItem.quantity;
    });
    return profit;
  }

  /// Añade un producto al carrito.
  /// [quantity] es opcional (por defecto 1), ideal para toques rápidos en POS.
  void addItem(ProductModel product, [int quantity = 1]) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existingItem) {
          existingItem.quantity += quantity;
          return existingItem;
        },
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItem(product: product, quantity: quantity),
      );
    }
    notifyListeners();
  }

  /// Elimina un artículo del carrito por completo.
  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  /// Actualiza la cantidad de un artículo específico en el carrito.
  /// Si la cantidad es 0 o menos, elimina el artículo.
  void updateItemQuantity(String productId, int newQuantity) {
    if (!_items.containsKey(productId)) return;

    if (newQuantity > 0) {
      _items.update(productId, (existingItem) {
        existingItem.quantity = newQuantity;
        return existingItem;
      });
    } else {
      removeItem(productId);
    }
    notifyListeners();
  }

  /// Vacía el carrito por completo.
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}