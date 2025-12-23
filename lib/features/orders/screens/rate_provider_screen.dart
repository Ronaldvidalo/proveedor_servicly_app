import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/order_model.dart';
import 'package:proveedor_servicly_app/core/services/order_service.dart';

class RateProviderScreen extends StatefulWidget {
  final OrderModel order;
  const RateProviderScreen({super.key, required this.order});

  @override
  State<RateProviderScreen> createState() => _RateProviderScreenState();
}

class _RateProviderScreenState extends State<RateProviderScreen> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  void _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, selecciona al menos 1 estrella.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<OrderService>().rateProvider(
        orderId: widget.order.id,
        providerId: widget.order.providerId,
        clientId: widget.order.clientId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        // Volver atrás con éxito
        Navigator.pop(context, true); // true indica que se calificó
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Gracias por tu calificación!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Calificar Servicio")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
              child: Icon(Icons.storefront, size: 40, color: colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              "¿Qué te pareció el servicio?",
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Tu opinión ayuda a otros usuarios y mejora la reputación del proveedor.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            
            // --- ESTRELLAS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  iconSize: 40,
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() => _rating = index + 1.0);
                  },
                );
              }),
            ),
            Text(
              _rating == 5 ? "¡Excelente!" : 
              _rating >= 4 ? "Muy Bueno" : 
              _rating >= 3 ? "Regular" : 
              _rating > 0 ? "Malo" : "",
              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),
            
            // --- COMENTARIO ---
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Escribe un comentario (opcional)...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.cardColor,
              ),
            ),
            const SizedBox(height: 30),

            // --- BOTÓN ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _submitRating,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("ENVIAR CALIFICACIÓN"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}