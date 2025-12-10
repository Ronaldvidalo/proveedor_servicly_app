import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proveedor_servicly_app/features/budget/models/quote_request_model.dart';

class QuoteRequestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _appId = 'default-app-id'; // O inyectarlo

  // Guardar la solicitud en la colección del PROVEEDOR (para que él la vea)
  // Ruta: artifacts/{appId}/users/{providerId}/leads/{requestId}
  // Nota: Usamos 'leads' porque técnicamente es un cliente potencial
  Future<void> sendRequest(QuoteRequestModel request) async {
    try {
      final docRef = _firestore
          .collection('artifacts')
          .doc(_appId)
          .collection('users')
          .doc(request.providerId)
          .collection('leads') // O 'quote_requests'
          .doc(request.id);

      await docRef.set(request.toMap());
    } catch (e) {
      throw Exception("Error enviando solicitud: $e");
    }
  }
}