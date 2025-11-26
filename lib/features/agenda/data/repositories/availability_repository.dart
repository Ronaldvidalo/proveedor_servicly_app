import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/availability_model.dart';

class AvailabilityRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AvailabilityRepository({required FirebaseFirestore firestore, required FirebaseAuth auth})
      : _firestore = firestore, _auth = auth;

  String? get _userId => _auth.currentUser?.uid;

  // Obtener la configuración completa (Stream para cambios en tiempo real)
  Stream<List<DayAvailability>> getAvailabilityStream() {
    if (_userId == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('availability')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => DayAvailability.fromFirestore(doc)).toList());
  }

  // Guardar la configuración de un día
  Future<void> updateDayAvailability(DayAvailability day) async {
    if (_userId == null) throw Exception("Usuario no autenticado");
    
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('availability')
        .doc(day.dayOfWeek) // ID del documento es el día (ej: 'monday')
        .set(day.toJson());
  }
  
  // Inicializar días vacíos si no existen
  Future<void> initializeDefaultAvailability() async {
    if (_userId == null) return;
    
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final collectionRef = _firestore.collection('users').doc(_userId).collection('availability');
    
    final snapshot = await collectionRef.get();
    if (snapshot.docs.isEmpty) {
      final batch = _firestore.batch();
      for (var day in days) {
        // Por defecto desactivados
        batch.set(collectionRef.doc(day), {'isEnabled': false, 'workSlots': []});
      }
      await batch.commit();
    }
  }
}