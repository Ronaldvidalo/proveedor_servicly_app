import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/viewmodels/cart_provider.dart';
import '../../../../core/models/cart_item_model.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // QA FIX: Obtener tema del contexto
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Fondo dinámico
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface, // Texto dinámico
        elevation: 0,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.remove_shopping_cart_outlined, 
                    size: 80, 
                    // Color inactivo dinámico
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

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (ctx, i) => _CartItemTile(cartItem: cart.items[i]),
                ),
              ),
              _CartSummary(cart: cart),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem cartItem;

  const _CartItemTile({required this.cartItem});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    
    // QA FIX: Colores del tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Fondo tarjeta del tema (Blanco/Azul)
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        // Borde sutil para modo claro
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
           BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: cartItem.product.imageUrl.isNotEmpty
                  ? Image.network(cartItem.product.imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: theme.scaffoldBackgroundColor,
                      child: Icon(Icons.shopping_bag_outlined, 
                          color: colorScheme.onSurface.withValues(alpha: 0.3), 
                          size: 40
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.product.name, 
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface, 
                    fontWeight: FontWeight.bold, 
                  )
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${cartItem.subtotal.toStringAsFixed(2)}',
                  // Precio usa color primario (Neón)
                  style: TextStyle(
                    color: colorScheme.primary, 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                onPressed: () {
                  cart.updateItemQuantity(cartItem.product.id, cartItem.quantity - 1);
                },
              ),
              Text(
                '${cartItem.quantity}', 
                style: TextStyle(
                  color: colorScheme.onSurface, 
                  fontSize: 18, 
                  fontWeight: FontWeight.bold
                )
              ),
              IconButton(
                icon: Icon(Icons.add, color: colorScheme.primary),
                onPressed: () {
                  cart.updateItemQuantity(cartItem.product.id, cartItem.quantity + 1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartProvider cart;

  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    // QA FIX: Colores del tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color, // Fondo dinámico
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        // Sombra superior para separar del contenido
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2)
          )
        ]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:', 
                style: TextStyle(
                  color: colorScheme.onSurface, 
                  fontSize: 20, 
                  fontWeight: FontWeight.bold
                )
              ),
              Text(
                '\$${cart.totalPrice.toStringAsFixed(2)}', 
                style: TextStyle(
                  color: colorScheme.primary, 
                  fontSize: 22, 
                  fontWeight: FontWeight.bold
                )
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CheckoutScreen(cart: cart),
                ));
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary, // Texto botón (Negro/Blanco)
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Proceder al Pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
            const SizedBox(height: 12),
            TextButton(
            onPressed: () => cart.clearCart(),
            child: const Text('Vaciar Carrito', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }
}