import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/repositories/agenda_repository.dart';
import '../data/models/agenda_event_model.dart';
import '../data/repositories/availability_repository.dart';
import '../data/models/availability_model.dart';
import 'package:proveedor_servicly_app/features/inventory/services/inventory_intelligence_service.dart';

// 1. Repositorio
final agendaRepositoryProvider = Provider<AgendaRepository>((ref) {
  return AgendaRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

// 2. Stream de la Próxima Cita (Para el Dashboard)
final nextAppointmentProvider = StreamProvider<AgendaEvent?>((ref) {
  final repo = ref.watch(agendaRepositoryProvider);
  return repo.getNextAppointmentStream();
});

// 3. Stream de Eventos del Mes (Provider con parámetro de fecha)
final eventsForMonthProvider = StreamProvider.family<List<AgendaEvent>, DateTime>((ref, date) {
  final repo = ref.watch(agendaRepositoryProvider);
  final start = DateTime(date.year, date.month, 1);
  final end = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  return repo.getEventsStream(start: start, end: end);
});

// 4. Stream de Eventos Simplificado (Mes Actual)
final agendaEventsProvider = StreamProvider<List<AgendaEvent>>((ref) {
  final repo = ref.watch(agendaRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return repo.getEventsStream(start: start, end: end);
});

// ✅ NUEVO: MÉTRICAS DE CONVERSIÓN SEMANAL
/// Procesa los eventos de los últimos 7 días para calcular efectividad.
final weeklyConversionMetricsProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final eventsAsync = ref.watch(agendaEventsProvider);

  return eventsAsync.whenData((events) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // Filtramos eventos de la última semana
    final weeklyEvents = events.where((e) => e.startTime.isAfter(sevenDaysAgo)).toList();

    // Calculamos presupuestos totales recibidos
    final totalQuotes = weeklyEvents.where((e) => e.eventType == EventType.quoteNegotiation).length;
    
    // Calculamos cuántos de esos presupuestos fueron confirmados
    final confirmedQuotes = weeklyEvents.where((e) => 
      e.eventType == EventType.quoteNegotiation && e.eventStatus == EventStatus.confirmed
    ).length;

    // Calculamos citas directas (booking)
    final directBookings = weeklyEvents.where((e) => e.eventType == EventType.clientBooking).length;

    // Ratio de conversión de presupuestos
    final double conversionRate = totalQuotes > 0 ? (confirmedQuotes / totalQuotes) * 100 : 0.0;

    return {
      'totalQuotes': totalQuotes,
      'confirmedQuotes': confirmedQuotes,
      'directBookings': directBookings,
      'conversionRate': conversionRate,
      'totalClosed': confirmedQuotes + directBookings,
    };
  });
});

// --- PROVEEDORES DE DISPONIBILIDAD ---

final availabilityRepositoryProvider = Provider<AvailabilityRepository>((ref) {
  return AvailabilityRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

final availabilityStreamProvider = StreamProvider<List<DayAvailability>>((ref) {
  final repo = ref.watch(availabilityRepositoryProvider);
  return repo.getAvailabilityStream();
});

// --- SERVICIO DE INTELIGENCIA ---

final userIdProvider = Provider((ref) => FirebaseAuth.instance.currentUser?.uid ?? ''); 

final inventoryIntelligenceServiceProvider = Provider<InventoryIntelligenceService>((ref) {
  final agendaRepo = ref.watch(agendaRepositoryProvider);
  final userId = ref.watch(userIdProvider); 
  return InventoryIntelligenceService(agendaRepo, userId);
});