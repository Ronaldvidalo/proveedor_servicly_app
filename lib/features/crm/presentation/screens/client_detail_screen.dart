import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:proveedor_servicly_app/features/crm/data/models/cliente_model.dart';
import 'package:proveedor_servicly_app/features/crm/data/repositories/crm_repository.dart';
import 'package:proveedor_servicly_app/features/crm/presentation/providers/client_list_viewmodel.dart'; 
// Asumimos que el ViewModel de la lista es accesible para refrescar la UI

// Widget auxiliar para mostrar un bloqueo de característica Pro
class ProFeatureLock extends StatelessWidget {
  final String featureName;

  const ProFeatureLock({required this.featureName, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.lock, color: Colors.amber.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'PRO Exclusivo: $featureName.',
              style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.amber),
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
    // No notificamos aquí para evitar reconstrucciones excesivas mientras el usuario escribe
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
      // Actualizar el modelo local para reflejar el cambio inmediatamente
      _cliente = _cliente.copyWith(etiquetas: newTags);
      notifyListeners();
    } catch (e) {
      // Manejar error de guardado
      print('Error al actualizar etiquetas: $e'); 
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notas guardadas exitosamente'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar notas: $e'), backgroundColor: Colors.red),
      );
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
    // Determinar si el usuario es Pro (leemos del ClientListViewModel)
    final isProUser = Provider.of<ClientListViewModel>(context, listen: false).isProUser;
    final currencyFormat = NumberFormat.currency(locale: 'es_ES', symbol: '\$');

    // Inyectamos el ViewModel de Detalle de forma local para esta pantalla
    return ChangeNotifierProvider(
      create: (context) => ClientDetailViewModel(context.read<CrmRepository>(), cliente),
      child: Consumer<ClientDetailViewModel>(
        builder: (context, viewModel, child) {
          final currentClient = viewModel.cliente;

          return Scaffold(
            appBar: AppBar(
              title: Text(currentClient.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECCIÓN 1: Información Básica y de Contacto ---
                  _buildSectionTitle('Información de Contacto'),
                  _buildDetailRow(Icons.email, 'Email:', currentClient.email),
                  _buildDetailRow(Icons.phone, 'Teléfono:', currentClient.telefono),
                  _buildDetailRow(Icons.calendar_today, 'Alta desde:', DateFormat('dd/MM/yyyy').format(currentClient.fechaAlta)),
                  
                  const Divider(height: 30),

                  // --- SECCIÓN 2: KPIs y Estadísticas (Diferenciación Pro) ---
                  _buildSectionTitle('Estadísticas y Valor'),
                  
                  if (isProUser) ...[
                    // KPI Pro: LTV
                    _buildDetailRow(
                      Icons.star, 
                      'Valor de por vida (LTV):', 
                      currencyFormat.format(currentClient.montoTotalFacturado), 
                      color: Colors.green.shade700
                    ),
                    // KPI Pro: Última Interacción
                    _buildDetailRow(
                      Icons.access_time, 
                      'Última Interacción:', 
                      DateFormat('dd/MM/yyyy HH:mm').format(currentClient.ultimaInteraccion)
                    ),
                  ] else ...[
                    // Vista Free
                    _buildDetailRow(Icons.shopping_cart, 'Total de Pedidos:', 'Ver en módulo de Finanzas'),
                    const ProFeatureLock(featureName: 'Estadísticas de Valor (LTV)'),
                  ],

                  const Divider(height: 30),

                  // --- SECCIÓN 3: Etiquetas Personalizadas (Pro Exclusivo) ---
                  _buildSectionTitle('Etiquetas de Segmentación'),
                  _buildTagsSection(context, viewModel, isProUser),

                  const Divider(height: 30),

                  // --- SECCIÓN 4: Notas Privadas (Pro Exclusivo) ---
                  _buildSectionTitle('Notas Privadas (Historial de Interacciones)'),
                  _buildNotesSection(context, viewModel, isProUser),

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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: TextStyle(color: color ?? Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context, ClientDetailViewModel viewModel, bool isProUser) {
    if (!isProUser) {
      return const ProFeatureLock(featureName: 'Etiquetas para Segmentación');
    }

    // Campo de entrada para nuevas etiquetas
    final tagController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: viewModel.cliente.etiquetas.map((tag) {
            return Chip(
              label: Text(tag, style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.blueGrey,
              deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white70),
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
                decoration: const InputDecoration(
                  labelText: 'Nueva Etiqueta',
                  hintText: 'Ej: VIP, Diseño',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (value) {
                  viewModel.addTag(value);
                  tagController.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.add, color: Colors.green.shade700),
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

  Widget _buildNotesSection(BuildContext context, ClientDetailViewModel viewModel, bool isProUser) {
    if (!isProUser) {
      return const ProFeatureLock(featureName: 'Notas Privadas e Historial');
    }

    // Usamos un TextFormField para la nota editable
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextFormField(
          initialValue: viewModel.currentNotes,
          onChanged: viewModel.setNotes, // Actualiza el estado local del ViewModel
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Escribe notas privadas sobre este cliente...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: viewModel.isSaving ? null : () => viewModel.saveNotes(context),
          icon: viewModel.isSaving
              ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save),
          label: Text(viewModel.isSaving ? 'Guardando...' : 'Guardar Notas'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ],
    );
  }
}