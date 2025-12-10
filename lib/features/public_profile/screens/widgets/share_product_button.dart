import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // NECESARIO PARA EL PORTAPAPELES
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';

class ShareProductButton extends StatelessWidget {
  final ProductModel product;
  final Color color;
  final Color? backgroundColor;

  const ShareProductButton({
    super.key,
    required this.product,
    this.color = Colors.white,
    this.backgroundColor,
  });

  static Future<void> share(BuildContext context, ProductModel product) async {
    final String appDownloadLink = "https://servicly.app/download"; 
    
    // El mensaje que se copiará
    final String message = 
        "¡Mira lo que encontré en Servicly! 🚀\n\n"
        "*${product.name}*\n"
        "A solo: \$${product.price.toStringAsFixed(2)}\n\n"
        "${product.description.length > 80 ? product.description.substring(0, 80) + '...' : product.description}\n\n"
        "📲 Descárgalo aquí: $appDownloadLink";

    // --- PASO 1: COPIAR AL PORTAPAPELES ---
    await Clipboard.setData(ClipboardData(text: message));
    
    // --- PASO 2: AVISAR AL USUARIO (EDUCACIÓN UX) ---
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Texto copiado! 📋 PÉGALO en Instagram o Facebook.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ), 
          duration: Duration(seconds: 3), 
          backgroundColor: Color(0xFF2D2D5A), // Color de tu marca
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        )
      );
    }

    // --- PASO 3: PREPARAR IMAGEN ---
    String imageUrl = product.imageUrl;
    
    if (imageUrl.isEmpty && product.mediaGallery.isNotEmpty) {
       final media = product.mediaGallery.firstWhere(
         (m) => m['url'] != null && m['url'].toString().isNotEmpty,
         orElse: () => {},
       );
       
       if (media.isNotEmpty) {
         imageUrl = (media['type'] == 'video' && media['thumbnailUrl'] != null) 
             ? media['thumbnailUrl'] 
             : media['url'];
       }
    }

    if (imageUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(imageUrl);
        final response = await http.get(uri);
        final bytes = response.bodyBytes;
        final temp = await getTemporaryDirectory();
        final path = '${temp.path}/share_image.jpg';
        File(path).writeAsBytesSync(bytes);

        // --- PASO 4: ABRIR MENÚ COMPARTIR ---
        // WhatsApp usará el 'text' automáticamente.
        // Instagram ignorará el 'text', pero el usuario ya lo tiene en el portapapeles.
        await Share.shareXFiles(
          [XFile(path)],
          text: message,
          subject: "Mira este producto: ${product.name}",
        );
      } catch (e) {
        debugPrint("Error compartiendo imagen: $e");
        Share.share(message, subject: "Mira este producto: ${product.name}");
      }
    } else {
      Share.share(message, subject: "Mira este producto: ${product.name}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: OutlinedButton.icon(
        onPressed: () => share(context, product),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withAlpha(50)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: backgroundColor ?? color.withAlpha(10),
        ),
        icon: const Icon(Icons.share_rounded, size: 20),
        label: const Text("Compartir"),
      ),
    );
  }
}