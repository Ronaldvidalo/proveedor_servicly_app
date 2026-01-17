import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/viewmodels/cart_provider.dart';
import '../../../../core/models/cart_item_model.dart';
import 'checkout_screen.dart';

// Constantes de Diseño
const double kMaxWebWidth = 1200.0;
const double kMobileBreakpoint = 900.0;

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false, // Alineado a la izquierda (Estándar Web)
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          // 1. ESTADO VACÍO (Común para ambos)
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.remove_shopping_cart_outlined, 
                    size: 80, 
                    color: colorScheme.onSurface.withValues(alpha: 0.2)
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tu carrito está vacío',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold
                    )
                  ),
                ],
              ),
            );
          }

          // 2. DETECTOR DE PANTALLA (Aquí ocurre la magia)
          return LayoutBuilder(
            builder: (context, constraints) {
              // --- RAMA WEB (NUEVA LÓGICA) ---
              if (constraints.maxWidth > kMobileBreakpoint) {
                return Center(
                  child: ConstrainedBox(
                    // Evita que se estire al infinito en monitores grandes
                    constraints: const BoxConstraints(maxWidth: kMaxWebWidth),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Columna Izquierda: Lista de Productos (60%)
                          Expanded(
                            flex: 6,
                            child: ListView.separated(
                              itemCount: cart.items.length,
                              separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                              itemBuilder: (ctx, i) => _CartItemTile(cartItem: cart.items[i]),
                            ),
                          ),
                          
                          const SizedBox(width: 32), // Espacio entre columnas

                          // Columna Derecha: Resumen Flotante (40%)
                          Expanded(
                            flex: 4,
                            child: _CartSummaryWeb(cart: cart), // Widget específico para web
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } 
              
              // --- RAMA MÓVIL (INTACTA) ---
              else {
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 20),
                        itemCount: cart.items.length,
                        itemBuilder: (ctx, i) => _CartItemTile(cartItem: cart.items[i]),
                      ),
                    ),
                    _CartSummaryMobile(cart: cart), // Widget clásico estilo BottomSheet
                  ],
                );
              }
            },
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGETS REUTILIZABLES (Items de lista)
// -----------------------------------------------------------------------------

class _CartItemTile extends StatelessWidget {
  final CartItem cartItem;
  const _CartItemTile({required this.cartItem});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // --- LÓGICA DE IMAGEN INTELIGENTE (Corrección) ---
    String displayImage = cartItem.product.imageUrl;
    
    // Si no hay imagen principal, buscamos en la galería
    if (displayImage.isEmpty && cartItem.product.mediaGallery.isNotEmpty) {
       final firstMedia = cartItem.product.mediaGallery.firstWhere(
         (m) => m['url'] != null && m['url'].toString().isNotEmpty,
         orElse: () => {},
       );
       if (firstMedia.isNotEmpty) {
         displayImage = firstMedia['url'];
       }
    }
    // --------------------------------------------------

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: Row(
        children: [
          // Imagen del producto
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: theme.scaffoldBackgroundColor,
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: displayImage.isNotEmpty
                  ? Image.network(
                      displayImage, 
                      fit: BoxFit.cover,
                      // Agregamos manejo de errores por si la URL falla
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.broken_image_outlined, color: colorScheme.onSurface.withValues(alpha: 0.3));
                      },
                    )
                  : Icon(Icons.shopping_bag_outlined, color: colorScheme.onSurface.withValues(alpha: 0.3)),
            ),
          ),
          const SizedBox(width: 16),
          
          // Datos del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.product.name, 
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${cartItem.subtotal.toStringAsFixed(2)}',
                  style: TextStyle(color: colorScheme.primary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Selector de Cantidad
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QuantityBtn(icon: Icons.remove, onTap: () => cart.updateItemQuantity(cartItem.product.id, cartItem.quantity - 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('${cartItem.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                _QuantityBtn(icon: Icons.add, isAdd: true, onTap: () => cart.updateItemQuantity(cartItem.product.id, cartItem.quantity + 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isAdd;
  const _QuantityBtn({required this.icon, required this.onTap, this.isAdd = false});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 16, color: isAdd ? Theme.of(context).colorScheme.primary : null),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      splashRadius: 16,
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGET ESPECÍFICO WEB: TARJETA DE RESUMEN
// -----------------------------------------------------------------------------
class _CartSummaryWeb extends StatelessWidget {
  final CartProvider cart;
  const _CartSummaryWeb({required this.cart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Resumen de compra", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal (${cart.items.length} productos)', style: theme.textTheme.bodyMedium),
              Text('\$${cart.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          
          const Divider(height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('\$${cart.totalPrice.toStringAsFixed(2)}', style: TextStyle(color: colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          
          const SizedBox(height: 24),
          _CheckoutButton(cart: cart, isWeb: true),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => cart.clearCart(),
              child: const Text('Vaciar Carrito', style: TextStyle(color: Colors.redAccent)),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGET ESPECÍFICO MÓVIL: BARRA INFERIOR
// -----------------------------------------------------------------------------
class _CartSummaryMobile extends StatelessWidget {
  final CartProvider cart;
  const _CartSummaryMobile({required this.cart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))
        ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('\$${cart.totalPrice.toStringAsFixed(2)}', style: TextStyle(color: colorScheme.primary, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          _CheckoutButton(cart: cart, isWeb: false),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => cart.clearCart(),
            child: const Text('Vaciar Carrito', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// Botón de Pago Compartido
class _CheckoutButton extends StatelessWidget {
  final CartProvider cart;
  final bool isWeb;
  const _CheckoutButton({required this.cart, required this.isWeb});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CheckoutScreen(cart: cart),
          ));
        },
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: isWeb ? 22 : 16), // Más alto en web
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: isWeb ? 0 : 2,
        ),
        child: const Text('PROCEDER AL PAGO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
      ),
    );
  }
}