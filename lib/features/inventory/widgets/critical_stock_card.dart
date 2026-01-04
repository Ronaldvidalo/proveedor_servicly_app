import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/add_edit_product_screen.dart';

class CriticalStockCard extends StatelessWidget {
  final UserModel user;
  const CriticalStockCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const warningColor = Colors.redAccent;

    return StreamBuilder<QuerySnapshot>(
      // 🔍 CONSULTA TÉCNICA: Productos con stock menor o igual a 5 unidades
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('providerId', isEqualTo: user.uid)
          .where('stock', isLessThanOrEqualTo: 5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // No hay alertas, no ocupamos espacio
        }

        final lowStockItems = snapshot.data!.docs;
        final int count = lowStockItems.length;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: warningColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: warningColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: warningColor),
                  const SizedBox(width: 12),
                  Text(
                    "STOCK CRÍTICO ($count)",
                    style: const TextStyle(
                      color: warningColor, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.2, 
                      fontSize: 12
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Listado de los primeros 2 productos en riesgo
              ...lowStockItems.take(2).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(data['name'] ?? 'Producto', style: const TextStyle(color: Colors.white70)),
                      Text(
                        "${data['stock']} unid.", 
                        style: const TextStyle(color: warningColor, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                );
              }),
              const Divider(color: Colors.white10, height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    // Aquí podrías navegar a la lista completa de inventario
                  },
                  child: const Text("GESTIONAR INVENTARIO", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}