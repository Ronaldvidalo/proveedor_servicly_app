import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/core/models/video_showcase_model.dart';
import 'package:proveedor_servicly_app/core/services/video_service.dart';
import 'package:proveedor_servicly_app/features/manage_store/presentation/screens/video_player_screen.dart';
import 'package:proveedor_servicly_app/widgets/VideoCard.dart';

class VideoShowcaseSection extends StatelessWidget {
  const VideoShowcaseSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el servicio directamente del árbol de widgets
    final videoService = context.read<VideoService>();
    const accentColor = Color(0xFF00BFFF);

    // Solicitamos los videos promocionados
    Stream<List<VideoShowcaseModel>> videoStream = videoService.getPromotedVideos();

    return SizedBox(
      height: 220, // Altura fija para el carrusel
      child: StreamBuilder<List<VideoShowcaseModel>>(
        stream: videoStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                height: 30, 
                width: 30, 
                child: CircularProgressIndicator(strokeWidth: 3, color: accentColor),
              ),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar videos', style: TextStyle(color: Colors.redAccent))
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No hay destacados por ahora.', style: TextStyle(color: Colors.white54))
            );
          }

          final videos = snapshot.data!;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              
              // Usamos tu VideoCard reutilizable
              return VideoCard(
                video: video,
                brandColor: accentColor,
                onPlayTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => VideoPlayerScreen(videoShowcase: video),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}