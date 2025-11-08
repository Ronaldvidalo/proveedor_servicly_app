import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/video_showcase_model.dart';
// ¡Necesitarás el paquete video_player!
// import 'package:video_player/video_player.dart';

/// Esta pantalla reproduce un video a pantalla completa
/// (similar a un Reel o TikTok).
class VideoPlayerScreen extends StatefulWidget {
  final VideoShowcaseModel videoShowcase;

  const VideoPlayerScreen({super.key, required this.videoShowcase});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  // late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Aquí inicializarías el video controller
    // _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoShowcase.videoUrl))
    //   ..initialize().then((_) {
    //     setState(() {});
    //     _controller.play();
    //   });
  }

  @override
  void dispose() {
    // _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aquí iría el reproductor de video
            Container(
              width: double.infinity,
              height: 400,
              color: Colors.grey[900],
              child: const Center(
                child: Icon(Icons.play_arrow, color: Colors.white, size: 80),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.videoShowcase.title,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '(Placeholder para el reproductor de video)',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}