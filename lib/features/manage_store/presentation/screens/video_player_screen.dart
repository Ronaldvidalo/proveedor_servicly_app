import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/core/models/video_showcase_model.dart';
import 'package:video_player/video_player.dart';

/// Esta pantalla reproduce un video a pantalla completa.
class VideoPlayerScreen extends StatefulWidget {
final VideoShowcaseModel videoShowcase;

const VideoPlayerScreen({super.key, required this.videoShowcase});

@override
State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
late VideoPlayerController _controller;
bool _isInitialized = false;
// Estado para mostrar/ocultar los controles (al tocar la pantalla)
bool _controlsVisible = true;
// Temporizador para que los controles se oculten automáticamente
static const _controlHideDuration = Duration(seconds: 3);

@override
void initState() {
super.initState();
_initializePlayer();
}

Future<void> _initializePlayer() async {
_controller = VideoPlayerController.networkUrl(
Uri.parse(widget.videoShowcase.videoUrl));

try {
  await _controller.initialize();
  // Empezar a reproducir automáticamente
  _controller.play(); 
  _startControlHideTimer();
  
  setState(() {
    _isInitialized = true;
  });
} catch (error) {
  // Registrar error si la URL no es válida o hay un problema de red
  debugPrint('Error al inicializar el video: $error');
  setState(() {
    _isInitialized = false;
  });
}


}

@override
void dispose() {
_controller.dispose();
super.dispose();
}

// Lógica para iniciar el temporizador de ocultación de controles
void _startControlHideTimer() {
if (!_controller.value.isInitialized || !_controller.value.isPlaying) {
return;
}
// Ocultar los controles después de 3 segundos
Future.delayed(_controlHideDuration, () {
if (mounted && _controlsVisible) {
setState(() {
_controlsVisible = false;
});
}
});
}

// Lógica para alternar la visibilidad de los controles al hacer tap
void _toggleControlsVisibility() {
setState(() {
_controlsVisible = !_controlsVisible;
});

if (_controlsVisible) {
  _startControlHideTimer();
}


}

// El botón de Play/Pause que aparece en el centro
Widget _buildPlayPauseButtonOverlay() {
// Si está reproduciendo y los controles están ocultos, no mostrar nada
if (_controller.value.isPlaying && !_controlsVisible) {
return const SizedBox.shrink();
}

return Container(
  // Se usa un color semi-transparente para darle un fondo al ícono
  color: Colors.black38, 
  child: IconButton(
    icon: Icon(
      _controller.value.isPlaying
          ? Icons.pause_circle_filled
          : Icons.play_circle_fill,
      color: Colors.white,
      size: 70.0,
    ),
    onPressed: () {
      setState(() {
        _controller.value.isPlaying
            ? _controller.pause()
            : _controller.play();
        // Si se pone a reproducir, inicia el temporizador para ocultar
        if (_controller.value.isPlaying) {
          _startControlHideTimer();
        }
      });
    },
  ),
);


}

@override
Widget build(BuildContext context) {
return Scaffold(
// Fondo negro para una experiencia inmersiva
backgroundColor: Colors.black,
body: Center(
child: _isInitialized
? GestureDetector(
onTap: _toggleControlsVisibility, // Toca para mostrar/ocultar
child: Stack(
fit: StackFit.expand, // Expande para llenar el Scaffold
children: <Widget>[
// 1. Reproductor de Video (centrado y manteniendo aspecto)
Center(
child: AspectRatio(
aspectRatio: _controller.value.aspectRatio,
child: VideoPlayer(_controller),
),
),

                // 2. Overlay de Controles (Animación de Desvanecimiento)
                AnimatedOpacity(
                  opacity: _controlsVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Stack(
                    children: [
                      // 2.1 Botón de Control (Play/Pause en el centro)
                      Align(
                        alignment: Alignment.center,
                        child: _buildPlayPauseButtonOverlay(),
                      ),
                      
                      // 2.2 Barra de Progreso (Abajo)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          colors: const VideoProgressColors(
                            playedColor: Colors.blueAccent,
                            bufferedColor: Colors.white30,
                            backgroundColor: Colors.white10,
                          ),
                        ),
                      ),
                      
                      // 2.3 AppBar (Arriba, para navegación y título)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: AppBar(
                          title: Text(widget.videoShowcase.title,
                              style: const TextStyle(color: Colors.white, fontSize: 16)),
                          backgroundColor: Colors.black.withValues(alpha: 0.5), 
                          elevation: 0,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        )
        : const Center(
            // Indicador de carga visible mientras se inicializa
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.blueAccent),
                SizedBox(height: 16),
                Text(
                  'Cargando video...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
  ),
);


}
}