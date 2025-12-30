import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart'; 

// Modelos y Servicios
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/core/models/product_model.dart';
import 'package:proveedor_servicly_app/features/promotion/models/promotion_model.dart';
import 'package:proveedor_servicly_app/ai/widgets/servi_avatar.dart'; 

class MarketingCenterScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData; // Datos que vienen de la IA (Insight)
  final int initialTabIndex; // 0=Promos, 1=GiftCards, 2=Difusión

  const MarketingCenterScreen({
    super.key, 
    this.initialData, 
    this.initialTabIndex = 0
  });

  @override
  State<MarketingCenterScreen> createState() => _MarketingCenterScreenState();
}

class _MarketingCenterScreenState extends State<MarketingCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // --- ESTADOS DE SERVI (COACH MODE) ---
  String _serviMessage = "";
  bool _showBubble = false;
  bool _isServiSpeaking = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3, 
      vsync: this, 
      initialIndex: widget.initialTabIndex
    );

    // Iniciar secuencia de bienvenida proactiva de Servi
    WidgetsBinding.instance.addPostFrameCallback((_) => _initServiGreeting());
  }

  void _initServiGreeting() async {
    String message = "¡Bienvenido al Centro de Marketing! Acá vamos a hacer crecer tu negocio.";

    // Análisis de contexto proactivo basado en initialData
    if (widget.initialData != null) {
      final type = widget.initialData!['type'];
      final event = widget.initialData!['event_name'] ?? "la próxima fecha especial";
      
      if (type == 'GIFT_CARD') {
        message = "¡Se acerca $event! 🎁 Es el momento perfecto para vender Gift Cards. Ya te dejé todo listo.";
      } else if (type == 'DISCOUNT') {
        message = "Detecté días flojos en tu agenda. 📉 Activemos esta oferta para llenarlos.";
      }
    }

    if (mounted) {
      setState(() { 
        _serviMessage = message; 
        _isServiSpeaking = true; 
        _showBubble = true; 
      });
    }
    
    // Simulación técnica de habla/lectura
    await Future.delayed(const Duration(seconds: 6));
    
    if (mounted) {
      setState(() { 
        _isServiSpeaking = false; 
        _showBubble = false; 
      });
    }
  }

  void _askServiHelp() {
    setState(() { 
      _serviMessage = "💡 Tip: Compartí tu perfil en Instagram los viernes para llenar la agenda del finde.";
      _showBubble = true;
      _isServiSpeaking = true;
    });
    Future.delayed(const Duration(seconds: 5), () {
      if(mounted) {
        setState(() { 
          _showBubble = false; 
          _isServiSpeaking = false; 
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0F0F1A);
    const tabBarColor = Color(0xFF1E1E2C);
    const accentColor = Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Centro de Marketing", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
        backgroundColor: tabBarColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: Colors.white54,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.percent), text: "OFERTAS"),
            Tab(icon: Icon(Icons.card_giftcard), text: "GIFT CARDS"),
            Tab(icon: Icon(Icons.campaign), text: "DIFUSIÓN"),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _CreatePromoView(initialData: widget.initialData),
              _CreateGiftCardView(initialData: widget.initialData),
              const _CampaignDashboardView(),
            ],
          ),

          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: _showBubble ? 1.0 : 0.0,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10, right: 10),
                    padding: const EdgeInsets.all(16),
                    width: 250,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D5A).withValues(alpha: 0.95),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(4),
                      ),
                      border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3), 
                          blurRadius: 10, 
                          offset: const Offset(0, 5)
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("ESTRATEGIA SERVI", style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_serviMessage, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: _askServiHelp,
                  child: ServiAvatar(
                    isSpeaking: _isServiSpeaking,
                    isListening: false,
                    isThinking: false,
                    size: 70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// 🧩 VISTA 1: CREACIÓN DE OFERTAS (DISCOUNTS)
// =========================================================
class _CreatePromoView extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const _CreatePromoView({this.initialData});

  @override
  State<_CreatePromoView> createState() => _CreatePromoViewState();
}

class _CreatePromoViewState extends State<_CreatePromoView> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descController; 
  
  double _currentDiscount = 20.0;
  List<int> _activeDays = []; 
  bool _isSaving = false;
  
  double _originalPrice = 0.0;
  double _baseCost = 0.0; 
  double _limitPrice = 0.0;
  String _productId = '';
  String _productName = ''; 

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {};
    
    _titleController = TextEditingController(text: data['title'] ?? '');
    _descController = TextEditingController(text: "¡Descuento especial por tiempo limitado!");
    
    _currentDiscount = double.tryParse(data['discount']?.toString() ?? '20') ?? 20.0;
    _activeDays = List<int>.from(data['activeDays'] ?? []);
    
    _productId = data['productId'] ?? '';
    _productName = data['productName'] ?? '';
    _originalPrice = double.tryParse(data['current_price']?.toString() ?? '0') ?? 0.0;
    _baseCost = double.tryParse(data['base_cost']?.toString() ?? '0') ?? 0.0;
    _limitPrice = double.tryParse(data['limit_price']?.toString() ?? '0') ?? 0.0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  double get _finalPrice => _originalPrice * (1 - (_currentDiscount / 100));
  double get _profit => _finalPrice - _baseCost;
  bool get _isSafe => _finalPrice >= _limitPrice;

  void _showProductPicker() {
    final user = context.read<UserModel>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('providerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
          final docs = snapshot.data!.docs;
          
          if (docs.isEmpty) {
            return const Center(child: Text("No tenés productos en inventario.", style: TextStyle(color: Colors.white54)));
          }

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("SELECCIONÁ UN PRODUCTO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final product = ProductModel.fromFirestore(docs[index]);
                    return ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.inventory_2_outlined, color: Color(0xFF00E5FF))),
                      title: Text(product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text("Precio: \$${NumberFormat("#,##0").format(product.price)}", style: const TextStyle(color: Colors.white54)),
                      trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF00E5FF)),
                      onTap: () {
                        setState(() {
                          _productId = docs[index].id;
                          _productName = product.name;
                          _originalPrice = product.price.toDouble();
                          _baseCost = (product.wholesalePrice ?? (product.price * 0.5)).toDouble();
                          _limitPrice = _baseCost * 1.1; 
                          _titleController.text = "Oferta en $_productName";
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _savePromo() async {
    if (!_isSafe) return;
    setState(() => _isSaving = true);

    try {
      final user = context.read<UserModel>();
      
      // ✅ RUTA RAÍZ: 'promotions' con providerId
      final promoData = {
        'providerId': user.uid, 
        'title': _titleController.text,
        'description': _descController.text,
        'productId': _productId,
        'discountPercentage': _currentDiscount,
        'promoPrice': _finalPrice,
        'minPriceAllowed': _limitPrice,
        'activeDays': _activeDays,
        'type': 'DISCOUNT', 
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'trigger': 'custom',
      };

      await FirebaseFirestore.instance
          .collection('promotions') // ✅ Colección raíz
          .add(promoData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🚀 Oferta Activada Exitosamente"), backgroundColor: Colors.green));
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al guardar"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_productId.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_offer_outlined, size: 80, color: Colors.white10),
            const SizedBox(height: 20),
            const Text("NUEVA OFERTA ESTRATÉGICA", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Text("Elegí un producto de tu inventario para aplicar un descuento que impulse tus ventas.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _showProductPicker,
              icon: const Icon(Icons.search, color: Colors.black),
              label: const Text("BUSCAR EN INVENTARIO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Producto: $_productName", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: _showProductPicker, child: const Text("Cambiar", style: TextStyle(color: Color(0xFF00E5FF)))),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF2D2D5A), borderRadius: BorderRadius.circular(16)),
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
                      value: _currentDiscount, min: 5, max: 50, divisions: 9,
                      activeColor: _isSafe ? Colors.cyan : Colors.red,
                      onChanged: (val) => setState(() => _currentDiscount = val),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
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

                    if (!_isSafe) const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text("⚠️ Estás perdiendo dinero.", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco("Título de la Oferta"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: _inputDeco("Condiciones / Descripción"),
              ),

              const SizedBox(height: 24),

              const Text("DÍAS VÁLIDOS", style: TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
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
                    selectedColor: Colors.cyan,
                    backgroundColor: const Color(0xFF1E1E2C),
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

              SizedBox(
                width: double.infinity, height: 55,
                child: FilledButton.icon(
                  onPressed: _isSafe && !_isSaving ? _savePromo : null,
                  icon: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
                      : const Icon(Icons.rocket_launch),
                  label: Text(_isSaving ? "PROCESANDO..." : "LANZAR OFERTA"),
                  style: FilledButton.styleFrom(backgroundColor: _isSafe ? Colors.cyan : Colors.grey),
                ),
              )
          ],
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
          style: TextStyle(color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 13)
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label, 
    filled: true, 
    fillColor: const Color(0xFF1E1E2C), 
    labelStyle: const TextStyle(color: Colors.white54), 
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
  );
}


// =========================================================
// 🎁 VISTA 2: CREADOR DE GIFT CARDS
// =========================================================
class _CreateGiftCardView extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const _CreateGiftCardView({this.initialData});

  @override
  State<_CreateGiftCardView> createState() => _CreateGiftCardViewState();
}

class _CreateGiftCardViewState extends State<_CreateGiftCardView> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  String _selectedTheme = 'Gold';
  bool _isSaving = false; 

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {};
    _titleController = TextEditingController(text: data['title'] ?? 'Gift Card Especial');
    _amountController = TextEditingController(text: data['suggested_amount']?.toString() ?? '20000');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveGiftCard() async {
    setState(() => _isSaving = true);
    
    try {
      final user = context.read<UserModel>();
      
      // ✅ ACTUALIZACIÓN CRÍTICA: Persistencia en raíz 'promotions' con providerId
      final promoData = {
        'providerId': user.uid, // <--- Vincular con el profesional
        'title': _titleController.text,
        'promoPrice': double.tryParse(_amountController.text) ?? 0,
        'type': 'GIFT_CARD',
        'style': _selectedTheme,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'trigger': 'seasonal',
      };

      await FirebaseFirestore.instance
          .collection('promotions') // ✅ Colección raíz
          .add(promoData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🎁 Gift Card Publicada con Éxito"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al guardar"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), 
      child: Column(
        children: [
          Container(
            height: 180, width: double.infinity,
            decoration: BoxDecoration(
              gradient: _getGradient(_selectedTheme),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: _getColor(_selectedTheme).withValues(alpha: 0.4), blurRadius: 20)],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    Text("GIFT CARD DIGITAL", style: TextStyle(color: Colors.white, letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)), 
                    Icon(Icons.nfc, color: Colors.white54)
                  ]
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_titleController.text, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("\$${NumberFormat("#,##0").format(double.tryParse(_amountController.text) ?? 0)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _titleController, 
            style: const TextStyle(color: Colors.white), 
            decoration: _inputDeco("Nombre de la Tarjeta"), 
            onChanged: (_) => setState((){})
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _amountController, 
            keyboardType: TextInputType.number, 
            style: const TextStyle(color: Colors.white), 
            decoration: _inputDeco("Monto a Cargar"), 
            onChanged: (_) => setState((){})
          ),
          const SizedBox(height: 25),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: ['Gold', 'Cyber', 'Love', 'Nature'].map((t) => GestureDetector(
              onTap: () => setState(() => _selectedTheme = t),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8), 
                width: 45, height: 45, 
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  gradient: _getGradient(t), 
                  border: _selectedTheme == t ? Border.all(color: Colors.white, width: 3) : null
                )
              ),
            )).toList()
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity, height: 55, 
            child: FilledButton(
              onPressed: _isSaving ? null : _saveGiftCard, 
              style: FilledButton.styleFrom(backgroundColor: _getColor(_selectedTheme)),
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("ACTIVAR TARJETA DE REGALO"),
            )
          )
        ],
      ),
    );
  }
  
  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label, 
    filled: true, 
    fillColor: const Color(0xFF1E1E2C), 
    labelStyle: const TextStyle(color: Colors.white54), 
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
  );
  
  LinearGradient _getGradient(String t) {
      if (t == 'Gold') return const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]);
      if (t == 'Cyber') return const LinearGradient(colors: [Color(0xFF00BFFF), Color(0xFF8A2BE2)]);
      if (t == 'Love') return const LinearGradient(colors: [Color(0xFFFF1493), Color(0xFFFF69B4)]);
      return const LinearGradient(colors: [Color(0xFF00FF7F), Color(0xFF008080)]);
  }
  
  Color _getColor(String t) {
      if (t == 'Gold') return Colors.orange;
      if (t == 'Cyber') return Colors.cyan;
      if (t == 'Love') return Colors.pink;
      return Colors.green;
  }
}

// =========================================================
// 📢 VISTA 3: CAMPAÑAS DE DIFUSIÓN
// =========================================================
class _CampaignDashboardView extends StatelessWidget {
  const _CampaignDashboardView();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("📢 Difundir mi Negocio", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Llegá a más clientes compartiendo tu catálogo profesional o tus promociones activas.", style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 25),
          
          _CampaignCard(
            title: "Mi Perfil Profesional",
            subtitle: "Tu vidriera digital completa.",
            icon: Icons.public,
            color: Colors.blueAccent,
            onShare: () {
                Share.share("¡Hola! Mirá mis trabajos y agenda tu turno online acá: https://servicly.app/p/${user.uid}");
            },
          ),
          
          const SizedBox(height: 15),
          
          _CampaignCard(
            title: "Compartir Ofertas",
            subtitle: "Enviar promociones por WhatsApp.",
            icon: Icons.local_offer,
            color: Colors.orangeAccent,
            onShare: () {
                Share.share("🔥 ¡Aprovechá mis ofertas exclusivas! Reservá ahora: https://servicly.app/p/${user.uid}");
            },
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onShare;

  const _CampaignCard({
    required this.title, 
    required this.subtitle, 
    required this.icon, 
    required this.color, 
    required this.onShare
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: color.withValues(alpha: 0.2))
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12), 
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), 
            child: Icon(icon, color: color, size: 24)
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)), 
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12))
              ]
            )
          ),
          IconButton(
            onPressed: onShare, 
            icon: const Icon(Icons.send_rounded, color: Colors.white70, size: 20)
          )
        ],
      ),
    );
  }
}