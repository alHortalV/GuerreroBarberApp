import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> isUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
      return adminDoc.exists;
    } catch (e) {
      print('Error verificando si el usuario es admin: $e');
      return false;
    }
  }

  Stream<bool> adminStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return false;
      
      try {
        final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
        return adminDoc.exists;
      } catch (e) {
        print('Error verificando estado de admin: $e');
        return false;
      }
    });
  }
} 