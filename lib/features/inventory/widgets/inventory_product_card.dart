import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';

class InventoryProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const InventoryProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const surfaceColor = Color(0xFF2D2D5A);
    const accentColor = Color(0xFF00BFFF);

    // Lógica de Semáforo de Stock
    Color stockColor = Colors.greenAccent;
    String stockText = 'En Stock';
    
    if (product.isOutOfStock) {
      stockColor = Colors.redAccent;
      stockText = 'AGOTADO';
    } else if (product.isLowStock) {
      stockColor = Colors.orangeAccent;
      stockText = 'Bajo (${product.quantity})';
    } else {
      stockText = '${product.quantity} u.';
    }

    // Lógica de Margen (Usando el getter inteligente del modelo)
    // Si el margen es < 20% lo ponemos en amarillo, si es negativo en rojo
    final margen = product.margenGananciaPublico * 100;
    Color marginColor = Colors.green;
    if (margen < 0) marginColor = Colors.red;
    else if (margen < 20) marginColor = Colors.orange;

    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$', decimalDigits: 0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: product.isLowStock || product.isOutOfStock 
                ? stockColor.withOpacity(0.5) 
                : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // 1. Miniatura (Pequeña y funcional)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 50,
                height: 50,
                color: Colors.black26,
                child: product.imageUrl.isNotEmpty
                    ? Image.network(product.imageUrl, fit: BoxFit.cover)
                    : const Icon(Icons.image, color: Colors.white24),
              ),
            ),
            const SizedBox(width: 12),

            // 2. Datos Principales
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "PVP: ${currencyFormat.format(product.price)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            // 3. Métricas (Columna Derecha)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Indicador de Stock
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: stockColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    stockText,
                    style: TextStyle(color: stockColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                // Indicador de Margen
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, color: Colors.grey, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      "${margen.toStringAsFixed(1)}%",
                      style: TextStyle(color: marginColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}