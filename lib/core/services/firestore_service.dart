// lib/core/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db;
  late final CollectionReference<Map<String, dynamic>> _usersCollection;

  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance {
    _usersCollection = _db.collection('users');
  }

  Future<void> createUser(UserModel user) async {
    try {
      print("--- FirestoreService: Creating user document with UID: ${user.uid} ---");
      await _usersCollection.doc(user.uid).set(user.toJson());
      print("--- FirestoreService: User document created successfully. ---");
    } catch (e) {
      print('Error al crear el usuario en Firestore: $e');
      rethrow;
    }
  }

  Stream<UserModel?> getUserStream(String uid) {
    print("--- FirestoreService: Getting user stream for UID: $uid ---");
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        print("--- FirestoreService: Snapshot received for UID: $uid. Document exists. ---");
        return UserModel.fromJson(snapshot.data()!);
      } else {
        print("--- FirestoreService: Snapshot received for UID: $uid. Document DOES NOT exist. ---");
        return null;
      }
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
    } catch (e) {
      print('Error al actualizar el usuario en Firestore: $e');
      rethrow;
    }
  }
}