import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/repositories/agenda_repository.dart';
import '../data/models/agenda_event_model.dart';
import '../data/repositories/availability_repository.dart';
import '../data/models/availability_model.dart';

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
// Se usa 'family' para pasarle la fecha enfocada
final eventsForMonthProvider = StreamProvider.family<List<AgendaEvent>, DateTime>((ref, date) {
  final repo = ref.watch(agendaRepositoryProvider);
  
  // Calculamos primer y último día del mes para filtrar
  final start = DateTime(date.year, date.month, 1);
  final end = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  
  return repo.getEventsStream(start: start, end: end);
});

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