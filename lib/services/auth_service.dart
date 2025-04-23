import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    // Forzar la actualización del token para obtener los últimos custom claims.
    IdTokenResult tokenResult = await user.getIdTokenResult(true);
    return tokenResult.claims != null && tokenResult.claims!['admin'] == true;
  }
}