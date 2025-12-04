import 'package:flutter/material.dart';
import 'dart:ui'; // Para PathMetric

// Constantes de Diseño (Cyber Glow Theme)
const kCyberBg = Color(0xFF1A1A2E);
const kCyberSurface = Color(0xFF2D2D5A);
const kCyberAccent = Color(0xFF00BFFF);

// --- 1. Tarjeta de Acción Pequeña (Ej: Categorías, Ver Todos) ---
class SmallActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const SmallActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: kCyberAccent.withOpacity(0.3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
            color: kCyberSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kCyberAccent.withOpacity(0.3))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kCyberAccent, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. Tarjeta Punteada Genérica (Para "Añadir X") ---
class DashedActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double width;
  final double height;

  const DashedActionCard({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.add_rounded,
    this.width = 120, // Ancho por defecto
    this.height = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: kCyberAccent.withOpacity(0.3),
          child: DottedBorder(
            color: kCyberAccent.withOpacity(0.6),
            strokeWidth: 2,
            radius: const Radius.circular(16),
            borderType: BorderType.rRect,
            dashPattern: const [8, 6],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 40, color: kCyberAccent),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.w600,
                      fontSize: 12
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- 3. Tarjeta "Ver Más" ---
class SeeAllCard extends StatelessWidget {
  final VoidCallback onTap;
  const SeeAllCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
          color: kCyberSurface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kCyberAccent.withOpacity(0.4)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_forward_rounded, size: 40, color: kCyberAccent),
              SizedBox(height: 12),
              Text('Ver Más',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- UTILIDAD: DottedBorder (Optimizado) ---
enum BorderType { rect, rRect }

class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final Radius radius;
  final BorderType borderType;
  final List<double> dashPattern;

  const DottedBorder({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.strokeWidth = 1,
    this.radius = const Radius.circular(0),
    this.borderType = BorderType.rect,
    this.dashPattern = const <double>[3, 1],
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedPainter(
        color: color,
        strokeWidth: strokeWidth,
        radius: radius,
        borderType: borderType,
        dashPattern: dashPattern,
      ),
      child: child,
    );
  }
}

class _DottedPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final Radius radius;
  final BorderType borderType;
  final List<double> dashPattern;

  _DottedPainter({required this.color, required this.strokeWidth, required this.radius, required this.borderType, required this.dashPattern});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path;
    if (borderType == BorderType.rRect) {
      path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), radius));
    } else {
      path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }

    Path dashPath = Path();
    double distance = 0.0;
    // Lógica simplificada para optimización visual
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final double len = dashPattern[0];
        final double gap = dashPattern.length > 1 ? dashPattern[1] : len;
        dashPath.addPath(pathMetric.extractPath(distance, distance + len), Offset.zero);
        distance += (len + gap);
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_DottedPainter old) => old.color != color || old.dashPattern != dashPattern;
}