import 'package:flutter/material.dart';

class ServiAvatar extends StatefulWidget {
  final bool isSpeaking;
  final bool isListening; 
  final bool isThinking; // NUEVO ESTADO
  final VoidCallback? onTap;
  final double size;

  const ServiAvatar({
    super.key,
    required this.isSpeaking,
    this.isListening = false,
    this.isThinking = false, // Por defecto falso
    this.onTap,
    this.size = 60,
  });

  @override
  State<ServiAvatar> createState() => _ServiAvatarState();
}

class _ServiAvatarState extends State<ServiAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Controlador para la rotación cuando piensa
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(ServiAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si entra en modo "Thinking", empezamos a girar
    if (widget.isThinking && !oldWidget.isThinking) {
      _controller.repeat();
    } else if (!widget.isThinking && oldWidget.isThinking) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final listeningColor = Colors.redAccent;
    // Color para "Pensando" (Cian o Ámbar queda muy "tech")
    final thinkingColor = Colors.amberAccent; 

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. ANILLO DE CARGA (Solo visible si piensa)
          if (widget.isThinking)
            RotationTransition(
              turns: _controller,
              child: Container(
                width: widget.size * 1.3,
                height: widget.size * 1.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: thinkingColor,
                    width: 3,
                    style: BorderStyle.solid,
                  ),
                  // Efecto de gradiente para que se note el giro
                  gradient: SweepGradient(
                    colors: [
                      thinkingColor.withOpacity(0.1),
                      thinkingColor,
                    ],
                  ),
                ),
              ),
            ),

          // 2. EL AVATAR PRINCIPAL
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            // Si escucha o piensa, crece un poco
            width: (widget.isSpeaking || widget.isListening || widget.isThinking) ? widget.size * 1.1 : widget.size,
            height: (widget.isSpeaking || widget.isListening || widget.isThinking) ? widget.size * 1.1 : widget.size,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.cardTheme.color,
              border: Border.all(
                // Prioridad de colores: Rojo (Escucha) -> Ambar (Piensa) -> Azul (Habla)
                color: widget.isListening ? listeningColor : (widget.isThinking ? thinkingColor : (widget.isSpeaking ? primaryColor : theme.dividerColor)),
                width: (widget.isSpeaking || widget.isListening || widget.isThinking) ? 3 : 1.5,
              ),
              boxShadow: [
                if (widget.isSpeaking)
                  BoxShadow(color: primaryColor.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)
                else if (widget.isListening)
                  BoxShadow(color: listeningColor.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)
                else if (widget.isThinking)
                  BoxShadow(color: thinkingColor.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.asset(
                      'assets/images/servicly_logo.png', 
                      fit: BoxFit.contain,
                      opacity: (widget.isListening || widget.isThinking) ? const AlwaysStoppedAnimation(0.5) : null,
                    ),
                  ),
                ),
                // Iconos de estado superpuestos
                if (widget.isListening)
                  const Icon(Icons.mic, color: Colors.red, size: 30)
                else if (widget.isThinking)
                  const Icon(Icons.psychology, color: Colors.amber, size: 30) // Icono de cerebro/proceso
              ],
            ),
          ),
        ],
      ),
    );
  }
}