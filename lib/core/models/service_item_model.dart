class ServiceItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes; // Duración estimada en minutos
  final String? categoryId;

  ServiceItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    this.categoryId,
  });

  // Para convertir desde/hacia Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
      'categoryId': categoryId,
    };
  }
}