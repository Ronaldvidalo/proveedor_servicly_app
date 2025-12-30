import 'dart:async';
import 'package:flutter/material.dart';
import 'package:proveedor_servicly_app/ai/widgets/servi_avatar.dart'; // Asegúrate que la ruta sea correcta

class ServiCoachWidget extends StatefulWidget {
  final String message; // El mensaje que dirá
  final String title;   // Título de la burbuja (ej. "Estrategia Servi")
  final bool autoPlay;  // ¿Habla apenas aparece?
  final Duration duration; // Cuánto dura visible (Default 6 seg)

  const ServiCoachWidget({
    super.key,
    required this.message,
    this.title = "ASISTENTE SERVI",
    this.autoPlay = true,
    this.duration = const Duration(seconds: 6),
  });

  @override
  State<ServiCoachWidget> createState() => _ServiCoachWidgetState();
}

class _ServiCoachWidgetState extends State<ServiCoachWidget> {
  bool _isVisible = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay && widget.message.isNotEmpty) {
      // Pequeño delay para que la entrada sea suave al cargar la pantalla
      Future.delayed(const Duration(milliseconds: 500), _showBubble);
    }
  }

  @override
  void didUpdateWidget(covariant ServiCoachWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambia el mensaje (ej. detecta otro insight), reactivamos
    if (oldWidget.message != widget.message && widget.message.isNotEmpty) {
      _showBubble();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _showBubble() {
    if (!mounted) return;
    
    setState(() => _isVisible = true);
    
    // Reiniciar el timer si ya existía
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.duration, () {
      if (mounted) setState(() => _isVisible = false);
    });
  }

  void _handleTap() {
    if (_isVisible) {
      // Si ya está visible y lo tocan, lo ocultamos (o podríamos extender el tiempo)
      // En este caso, reiniciamos el tiempo para que el usuario termine de leer
      _hideTimer?.cancel();
      _hideTimer = Timer(widget.duration, () {
        if (mounted) setState(() => _isVisible = false);
      });
    } else {
      // Si estaba oculto, lo mostramos (REACTIVACIÓN)
      _showBubble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Colores Cyber adaptables
    final bubbleColor = isDark ? const Color(0xFF2D2D5A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final accentColor = const Color(0xFF00E5FF); // Cyber Blue

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 💭 BURBUJA DE DIÁLOGO (Animada)
        AnimatedOpacity(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          opacity: _isVisible ? 1.0 : 0.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12, right: 8),
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 260), // Ancho máximo
            decoration: BoxDecoration(
              color: bubbleColor.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(4), // Pico hacia el avatar
              ),
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2), 
                  blurRadius: 10, 
                  offset: const Offset(0, 5)
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: accentColor),
                    const SizedBox(width: 6),
                    Text(
                      widget.title.toUpperCase(), 
                      style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.message, 
                  style: TextStyle(color: textColor, fontSize: 14, height: 1.4)
                ),
              ],
            ),
          ),
        ),

        // 🤖 AVATAR INTERACTIVO
        GestureDetector(
          onTap: _handleTap,
          child: ServiAvatar(
            // El avatar "habla" (pulsa) solo si la burbuja es visible
            isSpeaking: _isVisible, 
            isListening: false,
            isThinking: false, 
            size: 70, 
          ),
        ),
      ],
    );
  }
}