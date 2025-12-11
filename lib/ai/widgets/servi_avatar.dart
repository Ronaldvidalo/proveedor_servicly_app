import 'package:flutter/material.dart';

class ServiAvatar extends StatelessWidget {
  final bool isSpeaking;
  final VoidCallback? onTap;
  final double size;

  const ServiAvatar({
    super.key,
    required this.isSpeaking,
    this.onTap,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.cardTheme.color,
          border: Border.all(
            color: isSpeaking ? primaryColor : theme.dividerColor,
            width: isSpeaking ? 3 : 1,
          ),
          boxShadow: [
            if (isSpeaking)
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              )
          ],
        ),
        child: Icon(
          isSpeaking ? Icons.graphic_eq : Icons.smart_toy_rounded,
          color: isSpeaking ? primaryColor : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          size: size * 0.5,
        ),
      ),
    );
  }
}