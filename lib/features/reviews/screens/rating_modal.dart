// 📍 Ubicación: lib/features/reviews/screens/rating_modal.dart
import 'package:flutter/material.dart';
import '../../../shared/theme/cyber_theme.dart';
import '../models/review_model.dart';
import '../data/reviews_service.dart';
import '../widgets/animated_rating_stars.dart';

class RatingModal extends StatefulWidget {
  final String serviceId;
  final String authorId;
  final String targetId;
  final String role; // 'PROVIDER' o 'CLIENT'

  const RatingModal({
    super.key,
    required this.serviceId,
    required this.authorId,
    required this.targetId,
    required this.role,
  });

  static void show(BuildContext context, {
    required String serviceId,
    required String authorId,
    required String targetId,
    required String role,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: RatingModal(
          serviceId: serviceId,
          authorId: authorId,
          targetId: targetId,
          role: role,
        ),
      ),
    );
  }

  @override
  State<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> {
  final ReviewsService _service = ReviewsService();
  final TextEditingController _commentController = TextEditingController();
  
  int _rating = 0;
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;

  final List<String> _providerTags = ["Puntual", "Limpio", "Precio Justo", "Experto", "Amable"];
  final List<String> _clientTags = ["Amable", "Pago Rápido", "Comunicación Clara", "Hospitalario"];

  void _submit() async {
    if (_rating == 0) return;
    
    setState(() => _isSubmitting = true);

    final review = ReviewModel(
      serviceId: widget.serviceId,
      authorId: widget.authorId,
      targetId: widget.targetId,
      role: widget.role,
      rating: _rating,
      tags: _selectedTags,
      comment: _commentController.text.trim(),
    );

    try {
      await _service.sendReview(review);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // FIX: Usar color primario en lugar de CyberColors.neonGreen
            backgroundColor: Theme.of(context).primaryColor, 
            content: const Text("¡Valoración enviada!", style: TextStyle(color: Colors.black)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al enviar.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Obtener tema actual
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // FIX: Usar CyberStyles actualizado pasando el contexto
    Color activeColor = CyberStyles.getRatingColor(context, _rating == 0 ? 5 : _rating);
    List<String> tagsToShow = widget.role == 'PROVIDER' ? _providerTags : _clientTags;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // FIX: Usar theme.cardColor en lugar de CyberColors.surface
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: activeColor.withValues(alpha: 0.5))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Valoración del Servicio", 
            // FIX: Usar estilo del tema para que se vea en Light y Dark
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold
            )
          ),
          const SizedBox(height: 20),
          
          AnimatedRatingStars(
            currentRating: _rating,
            onRatingSelected: (val) => setState(() => _rating = val),
          ),
          
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tagsToShow.map((tag) {
              bool isSelected = _selectedTags.contains(tag);
              return ChoiceChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (val) => setState(() {
                  val ? _selectedTags.add(tag) : _selectedTags.remove(tag);
                }),
                // FIX: Usar colores del tema para los Chips
                backgroundColor: theme.scaffoldBackgroundColor,
                selectedColor: activeColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected 
                      ? activeColor 
                      : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
                side: BorderSide(
                  color: isSelected ? activeColor : theme.dividerColor
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _commentController,
            // FIX: Texto dinámico
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            decoration: InputDecoration(
              hintText: "Comentario opcional...",
              hintStyle: TextStyle(color: theme.disabledColor),
              filled: true,
              // FIX: Fondo del input dinámico
              fillColor: theme.scaffoldBackgroundColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _rating > 0 && !_isSubmitting ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                // FIX: Forma consistente
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : Text(
                    "ENVIAR", 
                    style: TextStyle(
                      // El texto del botón debe contrastar con el color activo (generalmente negro funciona bien sobre neón)
                      color: isDark ? Colors.black : Colors.white, 
                      fontWeight: FontWeight.bold
                    )
                  ),
            ),
          )
        ],
      ),
    );
  }
}