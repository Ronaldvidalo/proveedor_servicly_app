import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/viewmodels/cart_provider.dart';

import '../../../../core/models/cart_item_model.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    final brandColor = Theme.of(context).primaryColor; // Usaremos un color de acento genérico

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_shopping_cart_outlined, size: 80, color: Colors.white24),
                  SizedBox(height: 24),
                  Text('Tu carrito está vacío',
                    style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
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
              _CartSummary(cart: cart, brandColor: brandColor),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D5A),
        borderRadius: BorderRadius.circular(12),
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
                  : const Icon(Icons.shopping_bag_outlined, color: Colors.white38, size: 40),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cartItem.product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  '\$${cartItem.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(color: Color(0xFF00BFFF), fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white70),
                onPressed: () {
                  cart.updateItemQuantity(cartItem.product.id, cartItem.quantity - 1);
                },
              ),
              Text('${cartItem.quantity}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add, color: Color(0xFF00BFFF)),
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
  final Color brandColor;

  const _CartSummary({required this.cart, required this.brandColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D5A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text('\$${cart.totalPrice.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF00BFFF), fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función de pago no implementada.'), backgroundColor: Colors.blueAccent),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: brandColor,
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
