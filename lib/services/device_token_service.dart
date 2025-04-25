import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DeviceTokenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener el token del dispositivo actual
  Future<String?> getDeviceToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Error al obtener el token del dispositivo: $e');
      return null;
    }
  }

  // Registrar el token del dispositivo para el administrador
  Future<void> registerAdminDeviceToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Verificar si el usuario es admin
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists || userDoc.data()?['role'] != 'admin') return;

      final String? token = await getDeviceToken();
      if (token == null) return;

      // Guardar el token en la colección de admins
      await _firestore.collection('admins').doc(user.uid).set({
        'deviceToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'email': user.email,
      }, SetOptions(merge: true));

    } catch (e) {
      print('Error al registrar el token del dispositivo: $e');
    }
  }

  // Eliminar el token del dispositivo actual
  Future<void> removeAdminDeviceToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Verificar si existe el documento del admin
      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
      if (adminDoc.exists) {
        await _firestore.collection('admins').doc(user.uid).delete();
      }
    } catch (e) {
      print('Error al eliminar el token del dispositivo: $e');
    }
  }

  // Obtener el token del dispositivo del administrador específico
  Future<String?> getSpecificAdminDeviceToken(String adminId) async {
    try {
      final adminDoc = await _firestore.collection('admins').doc(adminId).get();
      if (!adminDoc.exists) return null;
      
      final data = adminDoc.data() as Map<String, dynamic>;
      return data['deviceToken'] as String?;
    } catch (e) {
      print('Error al obtener el token del administrador: $e');
      return null;
    }
  }

  // Obtener todos los tokens de dispositivo de los administradores
  Future<List<String>> getAllAdminDeviceTokens() async {
    try {
      final QuerySnapshot adminDocs = await _firestore
          .collection('admins')
          .get();

      List<String> allTokens = [];
      for (var adminDoc in adminDocs.docs) {
        final data = adminDoc.data() as Map<String, dynamic>;
        final String? token = data['deviceToken'] as String?;
        if (token != null) {
          allTokens.add(token);
        }
      }
      return allTokens;
    } catch (e) {
      print('Error al obtener los tokens de administrador: $e');
      return [];
    }
  }
} 