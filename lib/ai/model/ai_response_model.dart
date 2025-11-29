// /lib/ai/ai_response_model.dart
class LineItem {
  final String description;
  final int quantity;
  final double unitPrice;

  LineItem({required this.description, required this.quantity, required this.unitPrice});

  factory LineItem.fromJson(Map<String, dynamic> json) {
    // Manejo de tipo robusto para evitar errores de deserialización
    return LineItem(
      description: json['description'] as String? ?? 'Desconocido',
      quantity: (json['quantity'] is String
          ? int.tryParse(json['quantity'])
          : json['quantity'])?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] is String
          ? double.tryParse(json['unitPrice'])
          : json['unitPrice'])?.toDouble() ?? 0.0,
    );
  }
}

class Invoice {
  final String vendorName;
  final String invoiceNumber;
  final double totalAmount;
  final List<LineItem> lineItems;
  final DateTime scanDate;

  Invoice({
    required this.vendorName,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.lineItems,
    required this.scanDate,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    // La clave es deserializar el JSON del modelo de Gemini
    final List<dynamic> items = json['lineItems'] ?? [];
    return Invoice(
      vendorName: json['vendorName'] as String? ?? 'N/A',
      invoiceNumber: json['invoiceNumber'] as String? ?? 'N/A',
      totalAmount: (json['totalAmount'] is String
          ? double.tryParse(json['totalAmount'])
          : json['totalAmount'])?.toDouble() ?? 0.0,
      lineItems: items.map((i) => LineItem.fromJson(i)).toList(),
      scanDate: DateTime.now(), // Se añade en el cliente
    );
  }

  // Método para guardar en Firestore si es necesario
  Map<String, dynamic> toFirestore() {
    return {
      'vendorName': vendorName,
      'invoiceNumber': invoiceNumber,
      'totalAmount': totalAmount,
      'lineItems': lineItems.map((i) => {
        'description': i.description,
        'quantity': i.quantity,
        'unitPrice': i.unitPrice,
      }).toList(),
      'scanDate': scanDate,
      'status': 'pending_review',
    };
  }
}
