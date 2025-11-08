import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
// ¡Importante! Necesitarás crear la pantalla para subir videos
// import 'add_edit_video_screen.dart'; 

/// Esta pantalla mostrará la lista COMPLETA de videos del proveedor,
/// permitiendo gestionar promociones, editar títulos, etc.
class VideoManagerScreen extends StatelessWidget {
  final UserModel user;
  const VideoManagerScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1A1A2E);
    const accentColor = Color(0xFF00BFFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Gestionar Mis Videos'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Aquí irá la lista completa de "Vitrinas de Video",\ncon búsqueda, filtros y el toggle "Promocionar".',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
      // El FAB para añadir videos vivirá aquí
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigator.of(context).push(MaterialPageRoute(
          //   builder: (_) => AddEditVideoScreen(user: user),
          // ));
        },
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        child: const Icon(Icons.video_call_rounded),
      ),
    );
  }
}