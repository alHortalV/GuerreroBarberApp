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

      // Verificar si el email corresponde a un admin
      final adminQuery = await _firestore
          .collection('admins')
          .where('email', isEqualTo: user.email)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        // Es un admin, guardar el token en su documento
        final adminDoc = adminQuery.docs.first;
        await _firestore
            .collection('admins')
            .doc(adminDoc.id) // Este es el UID del admin
            .update({
          'deviceTokens': FieldValue.arrayUnion([token]), // Agregar el token al array
          'lastDeviceToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('Token registrado para admin ${adminDoc.id} (${user.email}): $token');
      } else {
        // Es un cliente, guardar en la colección de users
        await Future.wait([
          _firestore
              .collection('users')
              .doc(user.uid)
              .collection('tokens')
              .doc(token)
              .set({
            'token': token,
            'createdAt': FieldValue.serverTimestamp(),
          }),
          _firestore
              .collection('users')
              .doc(user.uid)
              .update({
            'lastDeviceToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          })
        ]);
        print('Token registrado para usuario ${user.uid}: $token');
      }
    } catch (e) {
      print('Error al registrar el token del dispositivo: $e');
    }
  }

  // Eliminar el token del dispositivo actual
  Future<void> removeDeviceToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token == null) return;

      // Verificar si es admin
      final adminQuery = await _firestore
          .collection('admins')
          .where('email', isEqualTo: user.email)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        // Es un admin, eliminar el token del array
        final adminDoc = adminQuery.docs.first;
        await _firestore
            .collection('admins')
            .doc(adminDoc.id)
            .update({
          'deviceTokens': FieldValue.arrayRemove([token]),
        });
        
        // Si era el último token activo, también limpiarlo
        final currentData = await _firestore
            .collection('admins')
            .doc(adminDoc.id)
            .get();
            
        if (currentData.data()?['lastDeviceToken'] == token) {
          await _firestore
              .collection('admins')
              .doc(adminDoc.id)
              .update({
            'lastDeviceToken': null,
            'lastTokenUpdate': null,
          });
        }
      } else {
        // Es un cliente, eliminar el token
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('tokens')
            .doc(token)
            .delete();

        // También limpiar el último token si coincide
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (userDoc.data()?['lastDeviceToken'] == token) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .update({
            'lastDeviceToken': null,
            'lastTokenUpdate': null,
          });
        }
      }
    } catch (e) {
      print('Error al eliminar el token del dispositivo: $e');
    }
  }

  // Limpiar tokens antiguos (más de 30 días)
  Future<void> cleanupOldTokens() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      // Limpiar tokens antiguos de administradores
      final adminDocs = await _firestore.collection('admins').get();
      for (var adminDoc in adminDocs.docs) {
        final tokenDocs = await adminDoc.reference
            .collection('tokens')
            .where('createdAt', isLessThan: thirtyDaysAgo)
            .get();
        
        for (var tokenDoc in tokenDocs.docs) {
          await tokenDoc.reference.delete();
        }
      }

      // Limpiar tokens antiguos de usuarios
      final userDocs = await _firestore.collection('users').get();
      for (var userDoc in userDocs.docs) {
        final tokenDocs = await userDoc.reference
            .collection('tokens')
            .where('createdAt', isLessThan: thirtyDaysAgo)
            .get();
        
        for (var tokenDoc in tokenDocs.docs) {
          await tokenDoc.reference.delete();
        }
      }
    } catch (e) {
      print('Error al limpiar tokens antiguos: $e');
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
      final adminDocs = await _firestore.collection('admins').get();
      List<String> tokens = [];
      
      for (var adminDoc in adminDocs.docs) {
        final adminData = adminDoc.data();
        
        // Obtener todos los tokens del array deviceTokens
        if (adminData.containsKey('deviceTokens')) {
          final deviceTokens = List<String>.from(adminData['deviceTokens'] ?? []);
          tokens.addAll(deviceTokens);
        }
        
        // Obtener el último token si existe y no está en el array
        if (adminData.containsKey('lastDeviceToken')) {
          final lastToken = adminData['lastDeviceToken'] as String;
          if (!tokens.contains(lastToken)) {
            tokens.add(lastToken);
          }
        }
      }
      
      print('Tokens de administradores encontrados: ${tokens.length}');
      return tokens.toSet().toList(); // Eliminar duplicados
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

  // Obtener el último token de un usuario específico
  Future<String?> getUserLastDeviceToken(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;
      
      final data = userDoc.data() as Map<String, dynamic>;
      return data['lastDeviceToken'] as String?;
    } catch (e) {
      print('Error al obtener el último token del usuario: $e');
      return null;
    }
  }

  // Eliminar un token de todos los administradores
  Future<void> removeTokenFromAllAdmins(String token) async {
    final adminDocs = await _firestore.collection('admins').get();
    for (var adminDoc in adminDocs.docs) {
      await _firestore.collection('admins').doc(adminDoc.id).update({
        'deviceTokens': FieldValue.arrayRemove([token]),
      });
      final data = adminDoc.data();
      if (data['lastDeviceToken'] == token) {
        await _firestore.collection('admins').doc(adminDoc.id).update({
          'lastDeviceToken': null,
          'lastTokenUpdate': null,
        });
      }
    }
  }

  // Eliminar un token de todos los usuarios
  Future<void> removeTokenFromAllUsers(String token) async {
    final userDocs = await _firestore.collection('users').get();
    for (var userDoc in userDocs.docs) {
      // Eliminar de la subcolección tokens
      final tokensCol = await _firestore.collection('users').doc(userDoc.id).collection('tokens').where('token', isEqualTo: token).get();
      for (var tokenDoc in tokensCol.docs) {
        await tokenDoc.reference.delete();
      }
      // Limpiar lastDeviceToken si coincide
      final data = userDoc.data();
      if (data['lastDeviceToken'] == token) {
        await _firestore.collection('users').doc(userDoc.id).update({
          'lastDeviceToken': null,
          'lastTokenUpdate': null,
        });
      }
    }
  }

  // Obtener solo el último token de cada administrador
  Future<List<String>> getAllAdminsLastDeviceTokens() async {
    try {
      final adminDocs = await _firestore.collection('admins').get();
      List<String> tokens = [];
      for (var adminDoc in adminDocs.docs) {
        final adminData = adminDoc.data();
        if (adminData.containsKey('lastDeviceToken') && adminData['lastDeviceToken'] != null && (adminData['lastDeviceToken'] as String).isNotEmpty) {
          tokens.add(adminData['lastDeviceToken'] as String);
        }
      }
      print('Últimos tokens de administradores encontrados: \\${tokens.length}');
      return tokens;
    } catch (e) {
      print('Error al obtener los últimos tokens de administradores: $e');
      return [];
    }
  }
} 