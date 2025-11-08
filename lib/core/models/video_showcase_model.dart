import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos para un video promocional (Vitrinas de Video).
///
/// Este modelo representa un video corto que un proveedor puede subir
/// para mostrar sus servicios. Contiene la lógica para determinar si
/// es una promoción pagada (`isPromoted`) o contenido orgánico.
class VideoShowcaseModel {
  /// El ID del documento de Firestore.
  final String id;
  
  /// El UID del proveedor (enlaza con la colección 'brandProfiles').
  final String providerId;
  
  /// La URL del archivo de video en Firebase Storage (ej. video.mp4).
  final String videoUrl;
  
  /// La URL de la miniatura del video en Firebase Storage (ej. thumb.jpg).
  /// Esencial para cargar la vista previa en el carrusel sin descargar el video.
  final String thumbnailUrl;
  
  /// El título del video (ej. "¡Nuevo servicio de Plomería!").
  final String title;
  
  /// La fecha en que el video fue subido.
  final Timestamp createdAt;
  
  /// Permite al proveedor "apagar" un video sin borrarlo.
  final bool isActive;
  
  // --- ¡CAMPO CLAVE DE NEGOCIO! ---
  /// `true` si el proveedor ha pagado para que este video aparezca
  /// en la sección "Descubrir" (HomeScreen) de otros clientes.
  /// `false` si es un video orgánico (solo para seguidores).
  final bool isPromoted;

  VideoShowcaseModel({
    required this.id,
    required this.providerId,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.title,
    required this.createdAt,
    this.isActive = true,
    this.isPromoted = false,
  });

  /// Convierte un documento de Firestore a una instancia de [VideoShowcaseModel].
  factory VideoShowcaseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return VideoShowcaseModel(
      id: doc.id,
      providerId: data['providerId'] as String? ?? '',
      videoUrl: data['videoUrl'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      title: data['title'] as String? ?? 'Video Promocional',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      isActive: data['isActive'] as bool? ?? true,
      isPromoted: data['isPromoted'] as bool? ?? false, // Default es 'false'
    );
  }

  /// Convierte la instancia del modelo a un mapa para guardarlo en Firestore.
  /// No se incluye el 'id' porque es el nombre del documento.
  Map<String, dynamic> toJson() {
    return {
      'providerId': providerId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'createdAt': createdAt,
      'isActive': isActive,
      'isPromoted': isPromoted,
    };
  }
}