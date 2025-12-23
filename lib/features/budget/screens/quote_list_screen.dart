// --- UX/UI Enhancement Comment ---
// File: quote_list_screen.dart
// UX/UI Redesigned: 2025-05-20 (Business Logic Update)
// Fixes:
// 1. Lógica de borrado seguro: Solo borradores, rechazadas, aceptadas o enviadas VENCIDAS.
// 2. Feedback visual en el menú de opciones si la cotización está bloqueada.
// 3. Conexión de menú de opciones (onLongPress).
// ---------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

// --- IMPORTS DEL PROYECTO ---
import 'package:proveedor_servicly_app/core/models/user_model.dart';
import 'package:proveedor_servicly_app/features/budget/models/quote_model.dart';
import 'package:proveedor_servicly_app/features/budget/models/quote_request_model.dart';
import 'package:proveedor_servicly_app/features/budget/providers/quote_provider.dart';

// --- WIDGETS PERSONALIZADOS ---
import 'package:proveedor_servicly_app/features/budget/widgets/quote_card.dart';
import 'package:proveedor_servicly_app/shared/theme/widgets/cyber_container.dart';

// --- PANTALLAS ---
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Centro de Ventas",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: theme.disabledColor,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "Cotizaciones"),
            Tab(text: "Solicitudes (Leads)"),
          ],
        ),
      ),

      // Botón Flotante para Crear
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QuoteEditorScreen(isNew: true),
            ),
          );
        },
        backgroundColor: colorScheme.primary,
        elevation: 10,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          "Nueva Cotización",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: const [
          _QuotesTab(),   // Pestaña 1
          _RequestsTab(), // Pestaña 2
        ],
      ),
    );
  }
}

// =============================================================================
// PESTAÑA 1: LISTA DE COTIZACIONES (Historial)
// =============================================================================
class _QuotesTab extends StatelessWidget {
  const _QuotesTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuoteProvider>();
    final quotes = provider.quotes;
    final isLoading = provider.isLoading;

    if (isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => const _CyberSkeleton(),
      );
    }

    if (quotes.isEmpty) {
      return _buildEmptyState(
        context,
        "Sin cotizaciones activas",
        "Crea propuestas profesionales para tus clientes y cierra más ventas.",
        Icons.dashboard_customize_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        final quote = quotes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: GestureDetector(
            onLongPress: () => _showOptionsSheet(context, quote, provider),
            child: QuoteCard(
              quote: quote,
              // Acción al tocar la tarjeta
              onTap: () => _navigateToPreview(context, quote),
              
              // Acción Botón Editar
              onEdit: () {
                context.read<QuoteProvider>().editQuote(quote);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuoteEditorScreen(isNew: false)),
                );
              },
              
              // Acción Botón Enviar
              onPreviewSend: () => _navigateToPreview(context, quote),
            ),
          ),
        );
      },
    );
  }

  // --- LÓGICA DE NEGOCIO PARA BORRADO ---
  bool _canDeleteQuote(Quote quote) {
    // 1. Estados que SIEMPRE se pueden borrar
    if (['draft', 'rejected', 'accepted'].contains(quote.status)) {
      return true;
    }
    
    // 2. Estado ENVIADO: Solo si ya venció
    if (quote.status == 'sent') {
      final now = DateTime.now();
      // Si la fecha actual es después de validUntil, ya venció -> Se puede borrar
      return now.isAfter(quote.validUntil);
    }

    // Por defecto seguridad
    return false;
  }

  void _showOptionsSheet(BuildContext context, Quote quote, QuoteProvider provider) {
    final theme = Theme.of(context);
    final canDelete = _canDeleteQuote(quote);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, 
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2))),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.disabledColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit, color: theme.colorScheme.primary),
                title: const Text('Editar Cotización'),
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
                title: const Text('Previsualizar y Compartir PDF'),
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToPreview(context, quote);
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Cambiar Estado'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showStatusDialog(context, provider, quote);
                },
              ),
              Divider(color: theme.dividerColor),
              
              // --- OPCIÓN ELIMINAR PROTEGIDA ---
              ListTile(
                leading: Icon(
                  Icons.delete_outline, 
                  color: canDelete ? theme.colorScheme.error : theme.disabledColor
                ),
                title: Text(
                  canDelete ? 'Eliminar' : 'Eliminar (Bloqueado)', 
                  style: TextStyle(
                    color: canDelete ? theme.colorScheme.error : theme.disabledColor,
                    fontWeight: canDelete ? FontWeight.bold : FontWeight.normal,
                  )
                ),
                subtitle: !canDelete 
                  ? const Text("No se puede borrar una cotización enviada y vigente.", style: TextStyle(fontSize: 12)) 
                  : null,
                onTap: () {
                  Navigator.pop(ctx);
                  if (canDelete) {
                    _confirmDelete(context, provider, quote.id);
                  } else {
                    // Feedback visual si intenta borrar lo bloqueado
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("⚠️ Solo puedes borrar cotizaciones enviadas si han vencido."),
                        backgroundColor: Colors.orange.shade800,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // UX: Diálogo personalizado estilo Cyber
  void _showStatusDialog(BuildContext context, QuoteProvider provider, Quote quote) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: CyberContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Actualizar Estado", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _buildStatusOption(ctx, provider, quote, 'draft', 'Borrador 📝', Colors.grey),
                _buildStatusOption(ctx, provider, quote, 'sent', 'Enviada 📤', Colors.blue),
                _buildStatusOption(ctx, provider, quote, 'accepted', 'Aceptada ✅', Colors.green),
                _buildStatusOption(ctx, provider, quote, 'rejected', 'Rechazada ❌', Colors.red),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(BuildContext ctx, QuoteProvider provider, Quote quote, String statusKey, String label, Color color) {
    final isSelected = statusKey == quote.status;
    return InkWell(
      onTap: () {
        provider.updateQuoteStatus(quote.id, statusKey);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color) : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(Icons.circle, color: color, size: 12),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: Theme.of(ctx).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, QuoteProvider provider, String quoteId) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: CyberContainer(
          borderGlow: true, // Resalta peligro
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text("¿Eliminar cotización?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Esta acción no se puede deshacer.", textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: () {
                      provider.deleteQuote(quoteId);
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                    child: const Text("Eliminar"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPreview(BuildContext context, Quote quote) {
    final user = context.read<UserModel?>();
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuotePreviewScreen(quote: quote, user: user),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No se pudo identificar al usuario.")),
      );
    }
  }
}

// =============================================================================
// PESTAÑA 2: SOLICITUDES / LEADS (Entrantes)
// =============================================================================
class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserModel?>();
    
    if (user == null) {
       return const Center(child: Text("Error: Usuario no autenticado"));
    }

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
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 6,
            itemBuilder: (_, __) => const _CyberSkeleton(),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error al cargar leads: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            context,
            "Bandeja de entrada vacía",
            "Aquí recibirás las solicitudes de potenciales clientes.",
            Icons.inbox_outlined,
          );
        }

        final leads = snapshot.data!.docs
            .map((doc) => QuoteRequestModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
          itemCount: leads.length,
          itemBuilder: (context, index) => _LeadCard(lead: leads[index]),
        );
      },
    );
  }
}

// =============================================================================
// WIDGET INTERNO: TARJETA DE LEAD
// =============================================================================
class _LeadCard extends StatelessWidget {
  final QuoteRequestModel lead;

  const _LeadCard({required this.lead});

  Future<void> _launchWhatsApp() async {
    final message = "Hola ${lead.clientName}, recibí tu solicitud para *${lead.serviceType}*. ¿Podemos conversar los detalles?";
    final url = "https://wa.me/${lead.clientPhone}?text=${Uri.encodeComponent(message)}";
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isNew = DateTime.now().difference(lead.createdAt).inHours < 24;

    return CyberContainer(
      borderGlow: isNew, 
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  lead.serviceType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                DateFormat('dd MMM • HH:mm').format(lead.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            lead.clientName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            lead.description,
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 20),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: OutlinedButton.icon(
                    onPressed: _launchWhatsApp,
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text("Chat"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: BorderSide(color: const Color(0xFF25D366).withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuoteEditorScreen(isNew: true, sourceRequest: lead),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bolt, size: 18),
                    label: const Text("Cotizar"),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: const Color(0xFF1A1A2E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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

// =============================================================================
// WIDGETS AUXILIARES
// =============================================================================

Widget _buildEmptyState(BuildContext context, String title, String subtitle, IconData icon) {
  final colorScheme = Theme.of(context).colorScheme;
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CyberContainer(
            borderRadius: 60,
            padding: const EdgeInsets.all(30),
            borderGlow: true,
            child: Icon(icon, size: 50, color: colorScheme.primary),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _CyberSkeleton extends StatefulWidget {
  const _CyberSkeleton();

  @override
  State<_CyberSkeleton> createState() => _CyberSkeletonState();
}

class _CyberSkeletonState extends State<_CyberSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 0.7).animate(_controller),
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
    );
  }
}