import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';
import 'package:proveedor_servicly_app/features/crm/presentation/providers/client_list_viewmodel.dart'; 

// Widget auxiliar para mostrar un bloqueo de característica Pro
class ProFeatureLock extends StatelessWidget {
  final String featureName;

  const ProFeatureLock({required this.featureName, super.key});

  @override
  Widget build(BuildContext context) {
    // QA FIX: Adaptación visual para Dark/Light mode
    // En lugar de un fondo amarillo solido que brilla demasiado en dark mode,
    // usamos una transparencia.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = Colors.amber;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        // Fondo sutil en ambos modos
        color: baseColor.withValues(alpha: isDark ? 0.1 : 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock, color: baseColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'PRO Exclusivo: $featureName.',
              style: TextStyle(
                color: isDark ? Colors.amberAccent : Colors.amber.shade900, 
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: baseColor),
        ],
      ),
    );
  }
}

// Clase para manejar localmente el estado de las notas y etiquetas
class ClientDetailViewModel extends ChangeNotifier {
  final CrmRepository _repository;
  Cliente _cliente;
  String _currentNotes;
  bool _isSaving = false;

  ClientDetailViewModel(this._repository, this._cliente) : _currentNotes = _cliente.notasInternas;

  // Getters
  Cliente get cliente => _cliente;
  String get currentNotes => _currentNotes;
  bool get isSaving => _isSaving;

  // Setters
  void setNotes(String value) {
    _currentNotes = value;
  }

  // --- Lógica de Etiquetas (Tags) ---

  Future<void> addTag(String tag) async {
    tag = tag.trim().toLowerCase();
    if (tag.isNotEmpty && !_cliente.etiquetas.contains(tag)) {
      final newTags = List<String>.from(_cliente.etiquetas)..add(tag);
      await _updateTagsInRepository(newTags);
    }
  }

  Future<void> removeTag(String tag) async {
    final newTags = List<String>.from(_cliente.etiquetas)..remove(tag);
    await _updateTagsInRepository(newTags);
  }

  Future<void> _updateTagsInRepository(List<String> newTags) async {
    _setSaving(true);
    try {
      await _repository.updateClientTags(_cliente.id, newTags);
      _cliente = _cliente.copyWith(etiquetas: newTags);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al actualizar etiquetas: $e'); 
    } finally {
      _setSaving(false);
    }
  }

  // --- Lógica de Notas ---

  Future<void> saveNotes(BuildContext context) async {
    _setSaving(true);
    try {
      if (_currentNotes != _cliente.notasInternas) {
        await _repository.updateClientNotes(_cliente.id, _currentNotes);
        _cliente = _cliente.copyWith(notasInternas: _currentNotes);
        if(context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notas guardadas exitosamente'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar notas: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _setSaving(false);
    }
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }
}

// PANTALLA PRINCIPAL
class ClientDetailScreen extends StatelessWidget {
  final Cliente cliente;

  const ClientDetailScreen({required this.cliente, super.key});

  @override
  Widget build(BuildContext context) {
    final isProUser = Provider.of<ClientListViewModel>(context, listen: false).isProUser;
    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '\$');
    
    // QA FIX: Obtener tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChangeNotifierProvider(
      create: (context) => ClientDetailViewModel(context.read<CrmRepository>(), cliente),
      child: Consumer<ClientDetailViewModel>(
        builder: (context, viewModel, child) {
          final currentClient = viewModel.cliente;

          return Scaffold(
            // Fondo dinámico
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: Text(currentClient.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600)),
              // AppBar dinámica
              backgroundColor: theme.scaffoldBackgroundColor,
              foregroundColor: colorScheme.onSurface,
              elevation: 0,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECCIÓN 1: Información Básica y de Contacto ---
                  _buildSectionTitle('Información de Contacto', theme),
                  _buildDetailRow(Icons.email, 'Email:', currentClient.email, theme),
                  _buildDetailRow(Icons.phone, 'Teléfono:', currentClient.telefono, theme),
                  _buildDetailRow(Icons.calendar_today, 'Alta desde:', DateFormat('dd/MM/yyyy').format(currentClient.fechaAlta), theme),
                  
                  Divider(height: 30, color: theme.dividerColor),

                  // --- SECCIÓN 2: KPIs y Estadísticas ---
                  _buildSectionTitle('Estadísticas y Valor', theme),
                  
                  if (isProUser) ...[
                    _buildDetailRow(
                      Icons.star, 
                      'Valor de por vida (LTV):', 
                      currencyFormat.format(currentClient.montoTotalFacturado), 
                      theme,
                      color: Colors.green.shade600 // Verde siempre visible
                    ),
                    _buildDetailRow(
                      Icons.access_time, 
                      'Última Interacción:', 
                      DateFormat('dd/MM/yyyy HH:mm').format(currentClient.ultimaInteraccion),
                      theme
                    ),
                  ] else ...[
                    _buildDetailRow(Icons.shopping_cart, 'Total de Pedidos:', 'Ver en módulo de Finanzas', theme),
                    const ProFeatureLock(featureName: 'Estadísticas de Valor (LTV)'),
                  ],

                  Divider(height: 30, color: theme.dividerColor),

                  // --- SECCIÓN 3: Etiquetas ---
                  _buildSectionTitle('Etiquetas de Segmentación', theme),
                  _buildTagsSection(context, viewModel, isProUser, theme),

                  Divider(height: 30, color: theme.dividerColor),

                  // --- SECCIÓN 4: Notas Privadas ---
                  _buildSectionTitle('Notas Privadas (Historial de Interacciones)', theme),
                  _buildNotesSection(context, viewModel, isProUser, theme),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS AUXILIARES DE LA PANTALLA ---

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          // QA FIX: Color primario (Neón) para títulos
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, ThemeData theme, {Color? color}) {
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600, 
                // QA FIX: Texto etiqueta adaptable
                color: colorScheme.onSurface
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: TextStyle(
                // QA FIX: Texto valor adaptable o color específico
                color: color ?? colorScheme.onSurface.withValues(alpha: 0.7)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context, ClientDetailViewModel viewModel, bool isProUser, ThemeData theme) {
    if (!isProUser) {
      return const ProFeatureLock(featureName: 'Etiquetas para Segmentación');
    }

    final tagController = TextEditingController();
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: viewModel.cliente.etiquetas.map((tag) {
            return Chip(
              label: Text(tag, style: TextStyle(color: colorScheme.onSurface)),
              // QA FIX: Fondo chip dinámico (Tarjeta)
              backgroundColor: theme.cardTheme.color,
              side: BorderSide(color: theme.dividerColor),
              deleteIcon: Icon(Icons.close, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.5)),
              onDeleted: () => viewModel.removeTag(tag),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: tagController,
                // QA FIX: Estilo de input dinámico
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Nueva Etiqueta',
                  hintText: 'Ej: VIP, Diseño',
                  // Usamos el input decoration del theme si es posible, o override
                  labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.dividerColor)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.primary)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (value) {
                  viewModel.addTag(value);
                  tagController.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.add_circle, color: colorScheme.primary, size: 32),
              onPressed: () {
                viewModel.addTag(tagController.text);
                tagController.clear();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context, ClientDetailViewModel viewModel, bool isProUser, ThemeData theme) {
    if (!isProUser) {
      return const ProFeatureLock(featureName: 'Notas Privadas e Historial');
    }
    
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextFormField(
          initialValue: viewModel.currentNotes,
          onChanged: viewModel.setNotes, 
          maxLines: 6,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Escribe notas privadas sobre este cliente...',
            hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.dividerColor)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colorScheme.primary)),
            filled: true,
            fillColor: theme.cardTheme.color,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: viewModel.isSaving ? null : () => viewModel.saveNotes(context),
          icon: viewModel.isSaving
              ? SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary))
              : const Icon(Icons.save),
          label: Text(viewModel.isSaving ? 'Guardando...' : 'Guardar Notas'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ],
    );
  }
}