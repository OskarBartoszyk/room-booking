import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password, String firstName, String lastName) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Zapisz dane użytkownika do Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = getCurrentUser();
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}