import 'package:proveedor_servicly_app/core/models/product_model.dart';

/// Representa un único artículo dentro del carrito de compras.
class CartItem {
  /// El producto añadido al carrito.
  final ProductModel product;
  /// La cantidad de este producto que el usuario desea.
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  /// Calcula el precio subtotal para este artículo (precio x cantidad).
  /// Tiene en cuenta si el producto está en oferta.
  double get subtotal =>
      (product.isOnSale ? product.promoPrice! : product.price) * quantity;
}
