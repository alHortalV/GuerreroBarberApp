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

  // Registrar token para cualquier usuario (admin o cliente)
  Future<void> registerDeviceToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token == null) return;

      // Primero verificamos si es admin
      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
      if (adminDoc.exists) {
        // Es un admin, guardar en la colección de admins
        await _firestore
            .collection('admins')
            .doc(user.uid)
            .collection('tokens')
            .doc(token)
            .set({
          'token': token,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Es un cliente, guardar en la colección de users
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('tokens')
            .doc(token)
            .set({
          'token': token,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
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

  // Obtener tokens de administradores
  Future<List<String>> getAllAdminDeviceTokens() async {
    try {
      final adminTokens = await _firestore
          .collection('admins')
          .get();
      
      List<String> tokens = [];
      
      for (var admin in adminTokens.docs) {
        final tokenDocs = await admin.reference.collection('tokens').get();
        tokens.addAll(tokenDocs.docs.map((doc) => doc.data()['token'] as String));
      }
      
      return tokens;
    } catch (e) {
      print('Error al obtener tokens de administradores: $e');
      return [];
    }
  }

  // Obtener tokens de un cliente específico
  Future<List<String>> getUserDeviceTokens(String userId) async {
    try {
      final tokenDocs = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .get();
      
      return tokenDocs.docs
          .map((doc) => doc.data()['token'] as String)
          .toList();
    } catch (e) {
      print('Error al obtener tokens del usuario: $e');
      return [];
    }
  }
} 