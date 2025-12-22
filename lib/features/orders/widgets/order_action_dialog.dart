import 'package:flutter/material.dart';

class OrderActionDialog extends StatefulWidget {
  final String orderType; // 'pickup' o 'delivery'
  final Function(String message) onConfirm;

  const OrderActionDialog({
    super.key, 
    required this.orderType, 
    required this.onConfirm
  });

  @override
  State<OrderActionDialog> createState() => _OrderActionDialogState();
}

class _OrderActionDialogState extends State<OrderActionDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Texto dinámico según si es Envío o Retiro
    final isPickup = widget.orderType == 'pickup';
    final title = isPickup ? "Confirmar Retiro" : "Confirmar Envío";
    final hint = isPickup 
        ? "Ej: Ya puedes pasar. Horario 09:00 - 18:00hs" 
        : "Ej: Tu paquete sale mañana. Llega entre 14:00 y 16:00hs";

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Indícale al cliente los detalles para completar el pedido:"),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onConfirm(_controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text("Confirmar e Informar"),
        ),
      ],
    );
  }
}