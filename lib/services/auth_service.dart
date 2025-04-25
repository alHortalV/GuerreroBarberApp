import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para iniciar sesión
  Future<UserCredential> signIn(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Guardar las credenciales localmente
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userCredential.user!.uid);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Método para cerrar sesión
  Future<void> signOut() async {
    try {
      // Limpiar las credenciales guardadas
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Método para verificar el rol del usuario
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['role'] as String?;
    } catch (e) {
      rethrow;
    }
  }

  // Método para obtener el usuario actual
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  static Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    // Forzar la actualización del token para obtener los últimos custom claims.
    IdTokenResult tokenResult = await user.getIdTokenResult(true);
    return tokenResult.claims != null && tokenResult.claims!['admin'] == true;
  }
}