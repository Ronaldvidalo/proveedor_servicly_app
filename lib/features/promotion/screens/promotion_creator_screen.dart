import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importamos el modelo y servicio
import 'package:proveedor_servicly_app/features/promotion/models/promotion_model.dart';
import 'package:proveedor_servicly_app/core/models/user_model.dart';

class PromotionCreatorScreen extends StatefulWidget {
  // Recibe el JSON que generó el Engine + Gemini
  final Map<String, dynamic> initialData;

  const PromotionCreatorScreen({super.key, required this.initialData});

  @override
  State<PromotionCreatorScreen> createState() => _PromotionCreatorScreenState();
}

class _PromotionCreatorScreenState extends State<PromotionCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descController;
  
  // Variables de Estado
  double _currentDiscount = 20.0;
  DateTimeRange? _dateRange;
  List<int> _activeDays = [];
  bool _isSaving = false;

  // Datos Financieros (Blindaje)
  late double _originalPrice;
  late double _baseCost;
  late double _limitPrice; // Wholesale / Límite duro
  late String _productId;
  late String _productName;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;

    // 1. Extracción de Datos Seguros
    _titleController = TextEditingController(text: data['title'] ?? 'Oferta Especial');
    _descController = TextEditingController(text: "¡Aprovechá este descuento exclusivo por tiempo limitado!");
    
    _currentDiscount = double.tryParse(data['discount']?.toString() ?? '20') ?? 20.0;
    _activeDays = List<int>.from(data['activeDays'] ?? []);
    
    // 2. Extracción de Datos Financieros (Crítico)
    _productId = data['productId'] ?? '';
    _productName = data['productName'] ?? 'Producto';
    _originalPrice = double.tryParse(data['current_price']?.toString() ?? '0') ?? 0.0;
    _baseCost = double.tryParse(data['base_cost']?.toString() ?? '0') ?? 0.0;
    _limitPrice = double.tryParse(data['limit_price']?.toString() ?? '0') ?? 0.0;

    // Fechas por defecto (Próximos 30 días)
    final now = DateTime.now();
    _dateRange = DateTimeRange(start: now, end: now.add(const Duration(days: 30)));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- CÁLCULOS EN TIEMPO REAL ---
  double get _finalPrice => _originalPrice * (1 - (_currentDiscount / 100));
  double get _profit => _finalPrice - _baseCost;
  bool get _isSafe => _finalPrice >= _limitPrice;

  // --- ACCIÓN DE GUARDADO ---
  Future<void> _publishPromotion() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isSafe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Error: El precio está por debajo del costo límite."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = context.read<UserModel>();
      
      // ✅ FIX: Se añade 'providerId' requerido para la colección raíz
      final newPromo = PromotionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        providerId: user.uid, // <--- Identificador del dueño de la promo
        title: _titleController.text,
        description: _descController.text,
        productId: _productId,
        discountPercentage: _currentDiscount,
        promoPrice: _finalPrice,
        minPriceAllowed: _limitPrice,
        activeDays: _activeDays,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        trigger: PromotionTrigger.lowDensity,
        isActive: true,
        type: PromotionType.DISCOUNT, 
        createdAt: DateTime.now(),   
      );

      // ✅ FIX: Guardado en la colección RAÍZ 'promotions'
      await FirebaseFirestore.instance
          .collection('promotions')
          .doc(newPromo.id)
          .set(newPromo.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🚀 ¡Promoción Activada! Servi la monitoreará."), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      debugPrint("Error guardando promo: $e");
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFF1A1A2E);
    final cardColor = const Color(0xFF2D2D5A);
    final accentColor = const Color(0xFF00BFFF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Configurar Oportunidad"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER DE CONTEXTO
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.amber.shade900.withValues(alpha: 0.8), 
                    Colors.amber.shade700.withValues(alpha: 0.6)
                  ]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("INSIGHT DE SERVI", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          Text("Activación de $_productName", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text("Se detectó baja demanda. Una oferta controlada puede reactivar ventas.", style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // 2. CONFIGURACIÓN DEL DESCUENTO
              Text("NIVEL DE DESCUENTO", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${_currentDiscount.toStringAsFixed(0)}%", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("Precio Final", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                            Text("\$${NumberFormat("#,##0").format(_finalPrice)}", style: TextStyle(color: _isSafe ? Colors.greenAccent : Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                    Slider(
                      value: _currentDiscount,
                      min: 5,
                      max: 50,
                      divisions: 9,
                      activeColor: _isSafe ? accentColor : Colors.red,
                      onChanged: (val) => setState(() => _currentDiscount = val),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniMetric("Costo", _baseCost, Colors.grey),
                          const Icon(Icons.arrow_forward, color: Colors.grey, size: 14),
                          _buildMiniMetric("Límite", _limitPrice, Colors.orange),
                          const Icon(Icons.arrow_forward, color: Colors.grey, size: 14),
                          _buildMiniMetric("Margen", _profit, _profit > 0 ? Colors.green : Colors.red, isBold: true),
                        ],
                      ),
                    ),
                    if (!_isSafe)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text("⚠️ Cuidado: Estás rompiendo tu margen de seguridad.", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. DETALLES VISUALES
              Text("DETALLES DE LA PROMO", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Título del Cartel",
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true, fillColor: cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Condiciones / Descripción",
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true, fillColor: cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 24),

              // 4. PROGRAMACIÓN (DÍAS)
              Text("DÍAS ACTIVOS", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final dayIndex = index + 1;
                  final isSelected = _activeDays.contains(dayIndex);
                  final dayName = ["L", "M", "M", "J", "V", "S", "D"][index];
                  
                  return ChoiceChip(
                    label: Text(dayName),
                    selected: isSelected,
                    selectedColor: accentColor,
                    backgroundColor: cardColor,
                    labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _activeDays.add(dayIndex);
                        } else {
                          _activeDays.remove(dayIndex);
                        }
                      });
                    },
                  );
                }),
              ),

              const SizedBox(height: 32),

              // BOTÓN FINAL
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton.icon(
                  onPressed: _isSaving || !_isSafe ? null : _publishPromotion,
                  style: FilledButton.styleFrom(
                    backgroundColor: _isSafe ? Colors.green : Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.rocket_launch),
                  label: Text(_isSaving ? "ACTIVANDO..." : "LANZAR PROMOCIÓN"),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, double value, Color color, {bool isBold = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        Text(
          "\$${NumberFormat.compact().format(value)}", 
          style: TextStyle(color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 14)
        ),
      ],
    );
  }
}