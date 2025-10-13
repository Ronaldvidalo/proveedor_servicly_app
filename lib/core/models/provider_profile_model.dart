import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Un modelo de datos que representa el perfil público de un proveedor.
///
/// Este modelo es inmutable y contiene toda la información necesaria
/// para construir la [PublicProfileScreen].
class ProviderProfileModel {
  /// El identificador único del proveedor.
  final String providerId;

  /// El nombre comercial personalizado establecido por el proveedor.
  final String businessName;

  /// La URL del logo del proveedor.
  final String logoUrl;

  /// El color de marca principal elegido por el proveedor.
  final Color brandColor;

  /// Una lista de los IDs de los módulos que están activos para este proveedor.
  final List<String> activeModules;

  /// El formato para el diseño del perfil público (ej: 'cv', 'portfolio').
  final String publicProfileFormat;

  /// Un mensaje de bienvenida para el perfil.
  final String welcomeMessage;

  /// El email de contacto público.
  final String contactEmail;

  /// La dirección física del negocio, si se ha proporcionado.
  final String? address;

  /// Crea una instancia de [ProviderProfileModel].
  const ProviderProfileModel({
    required this.providerId,
    required this.businessName,
    required this.logoUrl,
    required this.brandColor,
    required this.activeModules,
    required this.publicProfileFormat,
    required this.welcomeMessage,
    required this.contactEmail,
    this.address,
  });

  /// Constructor factory para crear un [ProviderProfileModel] desde un documento de Firestore.
  factory ProviderProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final personalization = data['personalization'] as Map<String, dynamic>? ?? {};

    return ProviderProfileModel(
      providerId: doc.id,
      businessName: personalization['businessName'] as String? ?? 'Nombre del Negocio',
      logoUrl: personalization['logoUrl'] as String? ?? '',
      brandColor: _colorFromHex(personalization['primaryColor'] as String?) ?? Colors.deepPurple,
      activeModules: List<String>.from(data['activeModules'] as List<dynamic>? ?? []),
      publicProfileFormat: personalization['publicProfileFormat'] as String? ?? 'cv',
      welcomeMessage: personalization['welcomeMessage'] as String? ?? 'Bienvenido a mi perfil.',
      contactEmail: personalization['contactEmail'] as String? ?? data['email'] as String? ?? '',
      address: personalization['address'] as String?,
    );
  }
}

/// Función de utilidad para convertir un string de color hexadecimal a un objeto [Color].
Color? _colorFromHex(String? hexColor) {
  if (hexColor == null) return null;
  final hexCode = hexColor.replaceAll('#', '');
  if (hexCode.length == 6) {
    return Color(int.parse('FF$hexCode', radix: 16));
  }
  return null;
}

