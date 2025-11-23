import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/services/auth_service.dart'; // Importante para datos de Google
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';

enum ContactAction { whatsapp, phone, email, website, quote }

class LeadCaptureButton extends StatelessWidget {
  final ContactAction actionType;
  final String contactValue;
  final String providerId;
  final Color brandColor;
  final String? label;
  final String? message;
  final bool isOutline;
  final VoidCallback? onPressedOverride;

  const LeadCaptureButton({
    super.key,
    required this.actionType,
    required this.contactValue,
    required this.providerId,
    required this.brandColor,
    this.label,
    this.message,
    this.isOutline = false,
    this.onPressedOverride,
  });

  Future<void> _handlePress(BuildContext context) async {
    if (onPressedOverride != null) onPressedOverride!();

    final crmRepo = context.read<CrmRepository>();
    
    // 1. INTENTAMOS OBTENER EL USUARIO DE LA BASE DE DATOS
    final userModel = context.read<UserModel?>();
    
    // 2. INTENTAMOS OBTENER EL USUARIO DE FIREBASE AUTH (Google/Email)
    final authService = context.read<AuthService>();
    final firebaseUser = authService.currentUser;

    // --- LÓGICA DE EXTRACCIÓN ROBUSTA ---
    String name = 'Visitante Anónimo';
    String email = '';
    String? photoUrl;
    String? location;

    // A. Prioridad: Datos de Firebase Auth (Siempre están si está logueado)
    if (firebaseUser != null) {
      name = firebaseUser.displayName ?? 'Usuario Registrado';
      email = firebaseUser.email ?? '';
      photoUrl = firebaseUser.photoURL; // Foto de Google
    }

    // B. Prioridad: Datos de tu Base de Datos (Sobrescriben si existen)
    if (userModel != null) {
      if (userModel.displayName != null && userModel.displayName!.isNotEmpty) {
        name = userModel.displayName!;
      }
      
      // Buscamos la foto en la raíz O en personalización
      String? dbPhoto = userModel.logoUrl;
      if (dbPhoto == null || dbPhoto.isEmpty) {
         dbPhoto = userModel.personalization['logoUrl'] as String?;
      }
      
      // Si encontramos foto en BDD, la usamos. Si no, nos quedamos con la de Google.
      if (dbPhoto != null && dbPhoto.isNotEmpty) {
        photoUrl = dbPhoto;
      }

      // Ubicación
      location = userModel.personalization['address'] as String? 
              ?? userModel.personalization['country'] as String?;
    }
    // ---------------------------------------

    Uri? launchUri;
    String source = '';

    switch (actionType) {
      case ContactAction.whatsapp:
        source = 'whatsapp';
        String cleanNum = contactValue.replaceAll(RegExp(r'[^\d]'), '');
        if (!cleanNum.startsWith('+')) cleanNum = '+$cleanNum';
        String urlStr = "https://wa.me/$cleanNum";
        if (message != null) urlStr += "?text=${Uri.encodeComponent(message!)}";
        launchUri = Uri.parse(urlStr);
        break;
      case ContactAction.phone:
        source = 'telefono';
        launchUri = Uri.parse("tel:$contactValue");
        break;
      case ContactAction.email:
        source = 'email';
        launchUri = Uri.parse("mailto:$contactValue");
        break;
      case ContactAction.website:
        source = 'sitio_web';
        String url = contactValue;
        if (!url.startsWith('http')) url = 'https://$url';
        launchUri = Uri.parse(url);
        break;
      case ContactAction.quote:
        source = 'solicitud_presupuesto';
        break;
    }

    // Capturar Lead
    try {
      debugPrint("Capturando lead: $name, Foto: $photoUrl"); // Debug
      
      await crmRepo.captureLeadFromPublicProfile(
        providerId: providerId,
        source: source,
        email: email,
        nombreCompleto: name,
        telefono: null,
        logoUrl: photoUrl, // Enviamos la foto encontrada
        location: location,
      );
    } catch (e) {
      debugPrint("Error capturando lead: $e");
    }

    if (launchUri != null) {
      try {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    } else if (actionType == ContactAction.quote && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Solicitud registrada.'), backgroundColor: Colors.green)
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon();
    final text = label ?? _getDefaultLabel();

    if (isOutline) {
      return OutlinedButton.icon(
        onPressed: () => _handlePress(context),
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: OutlinedButton.styleFrom(foregroundColor: brandColor, side: BorderSide(color: brandColor)),
      );
    } else {
      return FilledButton.icon(
        onPressed: () => _handlePress(context),
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: FilledButton.styleFrom(backgroundColor: brandColor, foregroundColor: Colors.white),
      );
    }
  }

  IconData _getIcon() {
    switch (actionType) {
      case ContactAction.whatsapp: return Icons.chat_bubble;
      case ContactAction.phone: return Icons.phone;
      case ContactAction.email: return Icons.email;
      case ContactAction.website: return Icons.language;
      case ContactAction.quote: return Icons.request_quote;
    }
  }

  String _getDefaultLabel() {
    switch (actionType) {
      case ContactAction.whatsapp: return 'WhatsApp';
      case ContactAction.phone: return 'Llamar';
      case ContactAction.email: return 'Email';
      case ContactAction.website: return 'Web';
      case ContactAction.quote: return 'Cotizar';
    }
  }
}