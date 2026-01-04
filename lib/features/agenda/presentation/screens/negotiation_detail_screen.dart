import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Modelos y Providers
import 'package:proveedor_servicly_app/features/agenda/data/models/agenda_event_model.dart';
import 'package:proveedor_servicly_app/features/agenda/providers/agenda_providers.dart';

class NegotiationDetailScreen extends ConsumerStatefulWidget {
  final AgendaEvent event;

  const NegotiationDetailScreen({super.key, required this.event});

  @override
  ConsumerState<NegotiationDetailScreen> createState() => _NegotiationDetailScreenState();
}

class _NegotiationDetailScreenState extends ConsumerState<NegotiationDetailScreen> {
  bool _isProcessing = false;
  late DateTime _currentProposedDate;

  @override
  void initState() {
    super.initState();
    _currentProposedDate = widget.event.startTime;
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00B2B2);
    final metadata = widget.event.metadata ?? {};
    final List services = metadata['services'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text("Detalle de Negociación", style: TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TARJETA DE ESTADO
            _buildStatusHeader(accentColor),

            const SizedBox(height: 24),

            // 2. INFORMACIÓN DEL CLIENTE
            _buildSectionTitle("CLIENTE"),
            _buildInfoTile(Icons.person_outline, metadata['clientName'] ?? "No especificado"),
            _buildInfoTile(Icons.phone_android, metadata['clientPhone'] ?? "No especificado"),

            const SizedBox(height: 24),

            // 3. DETALLE DE SERVICIOS
            _buildSectionTitle("SERVICIOS SOLICITADOS"),
            ...services.map((s) => _buildServiceItem(s, accentColor)).toList(),

            const SizedBox(height: 24),

            // 4. FECHA Y HORA ACTUAL
            _buildSectionTitle("FECHA PROPUESTA"),
            _buildInfoTile(
              Icons.calendar_today, 
              DateFormat('EEEE d MMMM, HH:mm', 'es_ES').format(_currentProposedDate),
              isHighlight: true
            ),

            const SizedBox(height: 40),

            // 5. ACCIONES DE NEGOCIACIÓN
            if (!_isProcessing) _buildActionButtons(accentColor),
            if (_isProcessing) const Center(child: CircularProgressIndicator(color: accentColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Color accentColor) {
    final bool isPending = widget.event.eventStatus == EventStatus.pendingApproval;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPending ? Colors.orangeAccent.withValues(alpha: 0.1) : accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPending ? Colors.orangeAccent.withValues(alpha: 0.3) : accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(isPending ? Icons.pending_actions : Icons.check_circle, color: isPending ? Colors.orangeAccent : accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isPending 
                ? "Esta solicitud requiere tu respuesta para confirmarse." 
                : "Esta cita ya ha sido confirmada.",
              style: TextStyle(color: isPending ? Colors.orangeAccent : accentColor, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Color accentColor) {
    return Column(
      children: [
        // BOTÓN ACEPTAR
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: () => _updateStatus(EventStatus.confirmed),
            style: FilledButton.styleFrom(backgroundColor: accentColor),
            icon: const Icon(Icons.check),
            label: const Text("ACEPTAR CITA", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),

        // BOTÓN CONTRAOFERTA (Cambiar hora)
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: _showDateTimePicker,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.edit_calendar),
            label: const Text("ENVIAR CONTRAOFERTA"),
          ),
        ),
        const SizedBox(height: 12),

        // BOTÓN RECHAZAR
        TextButton(
          onPressed: () => _updateStatus(EventStatus.cancelled),
          child: const Text("RECHAZAR SOLICITUD", style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }

  // --- LÓGICA TÉCNICA ---

  Future<void> _updateStatus(EventStatus newStatus, {DateTime? newDate}) async {
    setState(() => _isProcessing = true);
    final repo = ref.read(agendaRepositoryProvider);

    try {
      // Actualizamos el evento con el nuevo estado y/o fecha
      final updatedEvent = widget.event.copyWith(
        eventStatus: newStatus,
        startTime: newDate ?? widget.event.startTime,
        endTime: newDate != null 
            ? newDate.add(const Duration(minutes: 60)) 
            : widget.event.endTime,
      );

      await repo.updateEvent(updatedEvent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Acción realizada: ${newStatus.name}"), backgroundColor: const Color(0xFF1A1A2E)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _showDateTimePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _currentProposedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_currentProposedDate),
      );

      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute,
        );
        
        // Ejecutamos la contraoferta
        _updateStatus(EventStatus.pendingApproval, newDate: finalDateTime);
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _buildInfoTile(IconData icon, String value, {bool isHighlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isHighlight ? const Color(0xFF00B2B2) : Colors.white38),
          const SizedBox(width: 12),
          Text(value, style: TextStyle(color: isHighlight ? const Color(0xFF00B2B2) : Colors.white, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(service['name'] ?? "Servicio", style: const TextStyle(color: Colors.white)),
          Text("\$${service['price']}", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}