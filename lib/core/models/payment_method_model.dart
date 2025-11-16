import 'package:cloud_firestore/cloud_firestore.dart';

// --- ¡ENUM ACTUALIZADO! ---
enum PaymentMethodType { bank, wallet, crypto, other }

class PaymentMethodModel {
  final String id;
  final String name; // Ej: "Banco Galicia" o "Mercado Pago" o "Bitcoin (BTC)"
  final PaymentMethodType type;
  final String? alias; // Ej: "mi.alias.mp"
  final String? cbu;   // Ej: "00700..."
  final String? cryptoAddress; // --- ¡NUEVO CAMPO! ---
  final String? otherDetails; // Ej: "Titular: Juan Perez, CUIT: 20-..."
  final bool isPrimary; // ¿Es este el método preferido?

  PaymentMethodModel({
    required this.id,
    required this.name,
    required this.type,
    this.alias,
    this.cbu,
    this.cryptoAddress, // --- ¡NUEVO CAMPO! ---
    this.otherDetails,
    this.isPrimary = false,
  });

  factory PaymentMethodModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    PaymentMethodType type;
    switch (data['type'] as String?) {
      case 'wallet':
        type = PaymentMethodType.wallet;
        break;
      case 'bank':
        type = PaymentMethodType.bank;
        break;
      // --- ¡NUEVO CASO! ---
      case 'crypto':
        type = PaymentMethodType.crypto;
        break;
      default:
        type = PaymentMethodType.other;
    }

    return PaymentMethodModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Sin Nombre',
      type: type,
      alias: data['alias'] as String?,
      cbu: data['cbu'] as String?,
      cryptoAddress: data['cryptoAddress'] as String?, // --- ¡NUEVO CAMPO! ---
      otherDetails: data['otherDetails'] as String?,
      isPrimary: data['isPrimary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    String typeString;
    switch (type) {
      case PaymentMethodType.wallet:
        typeString = 'wallet';
        break;
      case PaymentMethodType.bank:
        typeString = 'bank';
        break;
      // --- ¡NUEVO CASO! ---
      case PaymentMethodType.crypto:
        typeString = 'crypto';
        break;
      default:
        typeString = 'other';
    }

    return {
      'name': name,
      'type': typeString,
      'alias': alias,
      'cbu': cbu,
      'cryptoAddress': cryptoAddress, // --- ¡NUEVO CAMPO! ---
      'otherDetails': otherDetails,
      'isPrimary': isPrimary,
      // 'id' no se guarda, es el ID del documento
    };
  }
  
  /// Crea una copia de este modelo con los campos proporcionados sobrescritos.
  PaymentMethodModel copyWith({
    String? id,
    String? name,
    PaymentMethodType? type,
    String? alias,
    String? cbu,
    String? cryptoAddress, // --- ¡NUEVO CAMPO! ---
    String? otherDetails,
    bool? isPrimary,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      alias: alias ?? this.alias,
      cbu: cbu ?? this.cbu,
      cryptoAddress: cryptoAddress ?? this.cryptoAddress, // --- ¡NUEVO CAMPO! ---
      otherDetails: otherDetails ?? this.otherDetails,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
