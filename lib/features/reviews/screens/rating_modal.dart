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
    Key? key,
    required this.serviceId,
    required this.authorId,
    required this.targetId,
    required this.role,
  }) : super(key: key);

  // Método estático helper para mostrar el modal fácilmente desde cualquier lado
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
  _RatingModalState createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> {
  final ReviewsService _service = ReviewsService();
  final TextEditingController _commentController = TextEditingController();
  
  int _rating = 0;
  List<String> _selectedTags = [];
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
          SnackBar(backgroundColor: CyberColors.neonGreen, content: Text("¡Valoración enviada!")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al enviar.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color activeColor = getRatingColor(_rating == 0 ? 5 : _rating);
    List<String> tagsToShow = widget.role == 'PROVIDER' ? _providerTags : _clientTags;

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CyberColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: activeColor.withOpacity(0.5))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Valoración del Servicio", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          
          // Widget de Estrellas Reutilizable
          AnimatedRatingStars(
            currentRating: _rating,
            onRatingSelected: (val) => setState(() => _rating = val),
          ),
          
          SizedBox(height: 20),
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
                backgroundColor: CyberColors.background,
                selectedColor: activeColor.withOpacity(0.2),
                labelStyle: TextStyle(color: isSelected ? activeColor : Colors.white70),
                side: BorderSide(color: isSelected ? activeColor : Colors.white12),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          TextField(
            controller: _commentController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Comentario opcional...",
              hintStyle: TextStyle(color: Colors.white30),
              filled: true,
              fillColor: CyberColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _rating > 0 && !_isSubmitting ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting 
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black))
                : Text("ENVIAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}