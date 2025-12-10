// --- UX/UI Enhancement Comment ---
// Pantalla: QuoteListScreen (Dashboard Cotizaciones & Leads)
// Ubicación: lib/features/budget/screens/quote_list_screen.dart
// Responsabilidad: 
// 1. Tab 1: Mostrar historial de cotizaciones (Provider).
// 2. Tab 2: Mostrar nuevas solicitudes/leads de clientes (Firestore Stream).
// 3. Gestionar acciones: PDF, WhatsApp, Convertir Lead a Cotización.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

// --- IMPORTS DEL PROYECTO ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/budget/models/quote_model.dart';
import 'package:proveedor_servicly_app/features/budget/models/quote_request_model.dart'; // Modelo de Lead
import 'package:proveedor_servicly_app/features/budget/providers/quote_provider.dart';
import 'package:proveedor_servicly_app/features/budget/widgets/quote_card.dart';

// --- IMPORTS DE PANTALLAS (Rutas Absolutas para evitar errores) ---
import 'package:proveedor_servicly_app/features/budget/screens/quote_editor_screen.dart';
import 'package:proveedor_servicly_app/features/budget/screens/quote_preview_screen.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({super.key});

  @override
  State<QuoteListScreen> createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inicializamos el controlador para 2 pestañas
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Gestión de Ventas",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        // --- BARRA DE PESTAÑAS ---
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.disabledColor,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: "Cotizaciones"),
            Tab(text: "Solicitudes (Leads)"),
          ],
        ),
      ),
      
      // --- BOTÓN FLOTANTE (Solo crea cotización vacía) ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QuoteEditorScreen(isNew: true),
            ),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        icon: Icon(Icons.add, color: theme.colorScheme.onPrimary),
        label: Text(
          "Nueva", 
          style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)
        ),
      ),
      
      // --- CUERPO CON PESTAÑAS ---
      body: TabBarView(
        controller: _tabController,
        children: [
          const _QuotesTab(),   // Pestaña 1: Lista de PDFs
          const _RequestsTab(), // Pestaña 2: Lista de Formularios recibidos
        ],
      ),
    );
  }
}

// =============================================================================
// PESTAÑA 1: LISTA DE COTIZACIONES (Provider)
// =============================================================================
class _QuotesTab extends StatelessWidget {
  const _QuotesTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<QuoteProvider>(); 
    final quotes = provider.quotes;
    final isLoading = provider.isLoading;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (quotes.isEmpty) {
      return _buildEmptyState(
        theme, 
        "No hay cotizaciones aún", 
        "Crea tu primera propuesta profesional",
        Icons.description_outlined
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        final quote = quotes[index];
        return QuoteCard(
          quote: quote,
          onTap: () {
            // Editar
            context.read<QuoteProvider>().editQuote(quote);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuoteEditorScreen(isNew: false)),
            );
          },
          onMoreOptions: () => _showOptionsSheet(context, quote, provider),
        );
      },
    );
  }

  void _showOptionsSheet(BuildContext context, Quote quote, QuoteProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(ctx);
                provider.editQuote(quote);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuoteEditorScreen(isNew: false)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Compartir PDF'),
              onTap: () {
                Navigator.pop(ctx);
                final user = context.read<UserModel?>(); 
                if (user != null) {
                  // Navegamos a la pantalla de vista previa
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuotePreviewScreen(quote: quote, user: user),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error: No se pudo cargar usuario")),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.low_priority),
              title: const Text('Cambiar Estado'),
              onTap: () {
                Navigator.pop(ctx);
                _showStatusDialog(context, provider, quote);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, provider, quote.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context, QuoteProvider provider, Quote quote) {
    showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text("Seleccionar Estado"),
          children: [
            _buildStatusOption(ctx, provider, quote, 'draft', 'Borrador 📝', Colors.grey),
            _buildStatusOption(ctx, provider, quote, 'sent', 'Enviada 📤', Colors.blue),
            _buildStatusOption(ctx, provider, quote, 'accepted', 'Aceptada ✅', Colors.green),
            _buildStatusOption(ctx, provider, quote, 'rejected', 'Rechazada ❌', Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildStatusOption(BuildContext ctx, QuoteProvider provider, Quote quote, String statusKey, String label, Color color) {
    return SimpleDialogOption(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 12),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: statusKey == quote.status ? color : null)),
        ],
      ),
      onPressed: () {
        provider.updateQuoteStatus(quote.id, statusKey);
        Navigator.pop(ctx);
      },
    );
  }

  void _confirmDelete(BuildContext context, QuoteProvider provider, String quoteId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Eliminar cotización?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              provider.deleteQuote(quoteId);
              Navigator.pop(ctx);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PESTAÑA 2: SOLICITUDES / LEADS (Firestore Stream)
// =============================================================================
class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.read<UserModel?>();

    if (user == null) return const Center(child: Text("Error de usuario"));

    // Query directa a la colección 'leads' (donde guardamos desde el formulario)
    final leadsQuery = FirebaseFirestore.instance
        .collection('artifacts')
        .doc('default-app-id') 
        .collection('users')
        .doc(user.uid)
        .collection('leads')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: leadsQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            theme, 
            "Bandeja de entrada vacía", 
            "Aquí aparecerán las solicitudes de tus clientes",
            Icons.inbox
          );
        }

        // Mapeamos los documentos al modelo QuoteRequestModel
        final leads = snapshot.data!.docs
            .map((doc) => QuoteRequestModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: leads.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _LeadCard(lead: leads[index]),
        );
      },
    );
  }
}

// =============================================================================
// WIDGET AUXILIAR: TARJETA DE LEAD
// =============================================================================
class _LeadCard extends StatelessWidget {
  final QuoteRequestModel lead;

  const _LeadCard({required this.lead});

  Future<void> _launchWhatsApp() async {
    // Mensaje pre-escrito para seguimiento rápido
    final message = "Hola ${lead.clientName}, recibí tu solicitud de cotización para *${lead.serviceType}*. ¿Tienes algún detalle adicional antes de enviarte el presupuesto?";
    final url = "https://wa.me/${lead.clientPhone}?text=${Uri.encodeComponent(message)}";
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Lead
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: Text(lead.serviceType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: theme.colorScheme.primaryContainer,
                labelStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              Text(
                DateFormat('dd MMM - HH:mm').format(lead.createdAt),
                style: TextStyle(fontSize: 10, color: theme.disabledColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Text(lead.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            lead.description, 
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8)), 
            maxLines: 2, 
            overflow: TextOverflow.ellipsis
          ),
          
          const Divider(height: 24),
          
          // Acciones CRM
          Row(
            children: [
              // 1. Botón Seguimiento (WhatsApp)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _launchWhatsApp,
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text("Seguimiento"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // 2. Botón Cotizar (Convierte Lead -> Cotización)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Abrimos el editor y le pasamos la solicitud (lead) para que se llene solo
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuoteEditorScreen(isNew: true, sourceRequest: lead),
                      ),
                    );
                  },
                  icon: const Icon(Icons.request_quote, size: 18),
                  label: const Text("Cotizar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// Widget auxiliar común para estados vacíos
Widget _buildEmptyState(ThemeData theme, String title, String subtitle, IconData icon) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 64, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    ),
  );
}