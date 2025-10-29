import 'package:proveedor_servicly_app/providers/catalog_editor_provider.dart';
import 'package:proveedor_servicly_app/core/models/provider_profile_model.dart';

// --- Clase Base Abstracta ---
/// Define el contrato base para la configuración de cualquier módulo.
abstract class ModuleConfig {}


// === CONFIGURACIÓN DEL MÓDULO DE BIENVENIDA ===

abstract class WelcomeModuleConfig extends ModuleConfig {}

/// Configuración para VISTA PÚBLICA (Solo lectura).
/// Contiene los datos 'crudos' que necesita para dibujarse.
class WelcomeModuleViewConfig extends WelcomeModuleConfig {
  final String welcomeText; // Corresponde a 'welcomeMessage' en el modelo
  final String? videoUrl;

  WelcomeModuleViewConfig({required this.welcomeText, this.videoUrl});

  // Constructor 'factory' para facilitar la creación desde el modelo principal
  factory WelcomeModuleViewConfig.fromProfile(ProviderProfileModel profile) {
    return WelcomeModuleViewConfig(
      welcomeText: profile.welcomeMessage,
      videoUrl: profile.welcomeVideoUrl,
    );
  }
}

/// Configuración para EDICIÓN (Interactiva).
/// Solo necesita una referencia al provider, ya que el provider
/// contiene el estado del borrador y los métodos para actualizarlo.
class WelcomeModuleEditConfig extends WelcomeModuleConfig {
  final CatalogEditorProvider editorProvider;

  WelcomeModuleEditConfig({required this.editorProvider});
}


// === CONFIGURACIÓN DEL MÓDULO DE CONTACTO ===

abstract class ContactModuleConfig extends ModuleConfig {}

/// Configuración para VISTA PÚBLICA (Solo lectura).
class ContactModuleViewConfig extends ContactModuleConfig {
  final String? slogan;
  final String? openingHours;
  final String? phone;
  final String? whatsapp;
  final String contactEmail; // Asumo que el email siempre está

  ContactModuleViewConfig({
    this.slogan,
    this.openingHours,
    this.phone,
    this.whatsapp,
    required this.contactEmail,
  });

  // Constructor 'factory' desde el modelo principal
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

/// Configuración para EDICIÓN (Interactiva).
class ContactModuleEditConfig extends ContactModuleConfig {
  final CatalogEditorProvider editorProvider;

  ContactModuleEditConfig({required this.editorProvider});
}
abstract class PortfolioModuleConfig extends ModuleConfig {}

/// Configuración para VISTA PÚBLICA (Solo lectura).
/// Necesita el ID del proveedor para obtener los streams.
class PortfolioModuleViewConfig extends PortfolioModuleConfig {
  final String providerId;

  PortfolioModuleViewConfig({required this.providerId});

  // No necesitamos 'fromProfile' aquí, ya que los datos se cargan vía stream.
}

/// Configuración para EDICIÓN (Interactiva).
/// Necesita el provider y el ID del usuario para streams y acciones.
class PortfolioModuleEditConfig extends PortfolioModuleConfig {
  final CatalogEditorProvider editorProvider;
  final String userId; // Necesario para los streams/acciones de Firestore/Storage

  PortfolioModuleEditConfig({required this.editorProvider, required this.userId});
}

// --- Aquí añadiríamos las configuraciones para otros módulos (Portafolio, etc.) ---