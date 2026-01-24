import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class UniversalDashboardCard extends StatefulWidget {
  final String? title;
  final IconData? icon;
  final Color primaryColor; // El color semántico base
  final String? mainValue;
  final Widget? subContent;
  final VoidCallback? onTap;
  final bool isLoading;
  
  // NUEVO: Permite contenido totalmente personalizado (para la tarjeta de métricas compleja)
  final Widget? customContent; 

  const UniversalDashboardCard({
    super.key,
    this.title,
    this.icon,
    required this.primaryColor,
    this.mainValue,
    this.subContent,
    this.onTap,
    this.isLoading = false,
    this.customContent,
  });

  @override
  State<UniversalDashboardCard> createState() => _UniversalDashboardCardState();
}

class _UniversalDashboardCardState extends State<UniversalDashboardCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // 1. AJUSTE DE COLOR
    final Color effectiveColor = isDark
        ? widget.primaryColor 
        : HSVColor.fromColor(widget.primaryColor).withSaturation(1.0).withValue(0.9).toColor();

    // 2. GRADIENTE DE FONDO
    final LinearGradient backgroundGradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardTheme.color!,
              Color.lerp(theme.cardTheme.color!, effectiveColor, 0.2)!,
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, const Color(0xFFF0F4F8)],
          );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: backgroundGradient,
              boxShadow: [
                BoxShadow(
                  color: effectiveColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                  spreadRadius: -5,
                ),
              ],
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : effectiveColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                // --- CAPA 1: EFECTOS DE LUZ (ATMÓSFERA) ---
                Positioned(
                  top: -80,
                  right: -80,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: effectiveColor.withValues(alpha: isDark ? 0.15 : 0.08),
                    ),
                    child: BackdropFilter(
                       filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                       child: Container(color: Colors.transparent),
                    ),
                  ),
                ),

                // --- CAPA 2: CONTENIDO ---
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: widget.isLoading
                      ? Center(child: CircularProgressIndicator(strokeWidth: 3, color: effectiveColor))
                      : widget.customContent ?? _buildStandardContent(theme, colorScheme, effectiveColor, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // El diseño estándar para las tarjetas pequeñas (Ventas, Stock, etc.)
  Widget _buildStandardContent(ThemeData theme, ColorScheme colorScheme, Color effectiveColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(widget.icon, color: effectiveColor, size: 22),
            ),
            if (widget.title != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.3) : effectiveColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: effectiveColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  widget.title!.toUpperCase(),
                  style: TextStyle(
                    color: effectiveColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
          ],
        ),
        const Spacer(),
        if (widget.mainValue != null)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              widget.mainValue!,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
                letterSpacing: -1.5,
                height: 1.0,
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (widget.subContent != null)
          DefaultTextStyle(
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: theme.textTheme.bodyMedium?.fontFamily,
            ),
            child: widget.subContent!,
          ),
      ],
    );
  }
}