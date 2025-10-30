import 'package:flutter/material.dart'; // Importado por si acaso (aunque no se use directamente aquí)
// Asegúrate que las rutas sean correctas desde lib/widgets/modules/

import 'package:proveedor_servicly_app/providers/catalog_editor_provider.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';

// --- Clase Base Abstracta ---
/// Define el contrato base para la configuración de cualquier módulo.
abstract class ModuleConfig {}


// === CONFIGURACIÓN DEL MÓDULO DE BIENVENIDA ===

abstract class WelcomeModuleConfig extends ModuleConfig {}

/// Configuración para VISTA PÚBLICA (Solo lectura).
class WelcomeModuleViewConfig extends WelcomeModuleConfig {
  final String welcomeText; // Corresponde a 'welcomeMessage' en el modelo
  final String? videoUrl;

  WelcomeModuleViewConfig({required this.welcomeText, this.videoUrl});

  // Constructor 'factory' desde el modelo principal
  factory WelcomeModuleViewConfig.fromProfile(ProviderProfileModel profile) {
    return WelcomeModuleViewConfig(
      welcomeText: profile.welcomeMessage,
      videoUrl: profile.welcomeVideoUrl,
    );
  }
}

/// Configuración para EDICIÓN (Interactiva).
class WelcomeModuleEditConfig extends WelcomeModuleConfig {
  final CatalogEditorProvider editorProvider;

  WelcomeModuleEditConfig({required this.editorProvider});
}

// === CONFIGURACIÓN DEL MÓDULO DE CONTACTO ===
// (Añadido previamente)
abstract class ContactModuleConfig extends ModuleConfig {}

class ContactModuleViewConfig extends ContactModuleConfig {
  final String? slogan;
  final String? openingHours;
  final String? phone;
  final String? whatsapp;
  final String contactEmail;

  ContactModuleViewConfig({
    this.slogan,
    this.openingHours,
    this.phone,
    this.whatsapp,
    required this.contactEmail,
  });

  factory ContactModuleViewConfig.fromProfile(ProviderProfileModel profile) {
    return ContactModuleViewConfig(
      slogan: profile.slogan,
      openingHours: profile.openingHours,
      phone: profile.phone,
      whatsapp: profile.whatsapp,
      contactEmail: profile.contactEmail,
    );
  }
}

class ContactModuleEditConfig extends ContactModuleConfig {
  final CatalogEditorProvider editorProvider;

  ContactModuleEditConfig({required this.editorProvider});
}


// === ¡AÑADIDO! CONFIGURACIÓN DEL MÓDULO DE PORTAFOLIO ===

abstract class PortfolioModuleConfig extends ModuleConfig {}

/// Configuración para VISTA PÚBLICA (Solo lectura).
class PortfolioModuleViewConfig extends PortfolioModuleConfig {
  final String providerId; // Necesario para obtener los streams públicos

  PortfolioModuleViewConfig({required this.providerId});
}

/// Configuración para EDICIÓN (Interactiva).
class PortfolioModuleEditConfig extends PortfolioModuleConfig {
  final CatalogEditorProvider editorProvider;
  final String userId; // Necesario para streams/acciones privadas

  PortfolioModuleEditConfig({required this.editorProvider, required this.userId});
}

// --- Aquí añadiríamos las configuraciones para otros módulos ---