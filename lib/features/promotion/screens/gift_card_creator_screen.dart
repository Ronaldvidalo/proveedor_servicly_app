// --- UX/UI Enhancement Comment ---
// Screen: Gift Card Creator
// Focus: Digital Product Design
// Style: Cyber Glow
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/promotion/models/promotion_model.dart'; // Reutilizamos modelo o creamos uno nuevo

class GiftCardCreatorScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const GiftCardCreatorScreen({super.key, required this.initialData});

  @override
  State<GiftCardCreatorScreen> createState() => _GiftCardCreatorScreenState();
}

class _GiftCardCreatorScreenState extends State<GiftCardCreatorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  
  String _selectedTheme = 'Gold';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Precarga inteligente basada en el evento detectado
    _titleController = TextEditingController(text: widget.initialData['title'] ?? 'Gift Card');
    _amountController = TextEditingController(text: widget.initialData['suggested_amount']?.toString() ?? '20000');
  }

  @override
  Widget build(BuildContext context) {
    // Definimos colores fijos para mantener el estilo Cyber independientemente del tema claro/oscuro
    final bgColor = const Color(0xFF121212); // Fondo oscuro profundo
    final cardBgColor = const Color(0xFF1E1E2C);
    final accentColor = _getThemeColor(_selectedTheme);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Diseñar Gift Card", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. HEADER DEL EVENTO (Contexto)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Text(widget.initialData['icon'] ?? '🎁', style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Especial: ${widget.initialData['event_name'] ?? 'Ocasión Especial'}", 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        const Text(
                          "Los clientes compran esto para regalar. ¡Diseño atractivo = Más ventas!", 
                          style: TextStyle(color: Colors.white70, fontSize: 12)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. PREVISUALIZACIÓN DE LA TARJETA (El "Gancho")
            Hero(
              tag: 'gift_card_preview',
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: _getGradient(_selectedTheme),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _getThemeColor(_selectedTheme).withOpacity(0.6), 
                      blurRadius: 25, 
                      offset: const Offset(0, 10)
                    )
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                          child: Text("GIFT CARD", style: TextStyle(color: Colors.white.withOpacity(0.9), letterSpacing: 1.5, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const Icon(Icons.nfc, color: Colors.white54, size: 30),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleController.text.isEmpty ? "Tu Título" : _titleController.text, 
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Valor: \$${NumberFormat("#,##0", "es_AR").format(double.tryParse(_amountController.text) ?? 0)}", 
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 3. CAMPOS DE EDICIÓN
            _buildCyberTextField("Título de la Tarjeta", _titleController, cardBgColor),
            const SizedBox(height: 16),
            _buildCyberTextField("Valor del Regalo (\$)", _amountController, cardBgColor, isNumber: true),

            const SizedBox(height: 24),
            
            // 4. SELECTOR DE TEMA
            const Align(alignment: Alignment.centerLeft, child: Text("ESTILO VISUAL", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Gold', 'Cyber', 'Love', 'Nature'].map((theme) {
                final isSelected = _selectedTheme == theme;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTheme = theme),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isSelected ? 55 : 45, 
                    height: isSelected ? 55 : 45,
                    decoration: BoxDecoration(
                      gradient: _getGradient(theme),
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: isSelected ? [BoxShadow(color: _getThemeColor(theme).withOpacity(0.5), blurRadius: 10)] : [],
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            // 5. BOTÓN DE ACCIÓN
            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveGiftCard,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                  : const Icon(Icons.rocket_launch, color: Colors.black),
                label: Text(
                  _isSaving ? "PUBLICANDO..." : "ACTIVAR GIFT CARD", 
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCyberTextField(String label, TextEditingController controller, Color fillColor, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          onChanged: (_) => setState(() {}), // Rebuild para actualizar preview
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _getThemeColor(_selectedTheme), width: 1)),
          ),
        ),
      ],
    );
  }

  void _saveGiftCard() async {
    setState(() => _isSaving = true);
    
    // Aquí iría la lógica real de guardado en Firestore
    // Reutilizando el modelo PromotionModel con un flag especial
    try {
      final user = context.read<UserModel>();
      
      final promoData = {
        'title': _titleController.text,
        'promoPrice': double.tryParse(_amountController.text) ?? 0,
        'type': 'GIFT_CARD',
        'style': _selectedTheme,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      await FirebaseFirestore.instance
          .collection('catalogs')
          .doc(user.uid)
          .collection('promotions')
          .add(promoData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🎁 ¡Gift Card publicada!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al guardar"), backgroundColor: Colors.red));
      }
    }
  }

  // Helpers de Estilo
  LinearGradient _getGradient(String theme) {
    switch (theme) {
      case 'Gold': return const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case 'Cyber': return const LinearGradient(colors: [Color(0xFF00BFFF), Color(0xFF8A2BE2)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case 'Love': return const LinearGradient(colors: [Color(0xFFFF1493), Color(0xFFFF69B4)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case 'Nature': return const LinearGradient(colors: [Color(0xFF00FF7F), Color(0xFF008080)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      default: return const LinearGradient(colors: [Colors.grey, Colors.black]);
    }
  }

  Color _getThemeColor(String theme) {
    switch (theme) {
      case 'Gold': return const Color(0xFFFFD700);
      case 'Cyber': return const Color(0xFF00BFFF);
      case 'Love': return const Color(0xFFFF1493);
      case 'Nature': return const Color(0xFF00FF7F);
      default: return Colors.white;
    }
  }
}