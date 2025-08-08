import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_gate.dart';

class AuthService extends ChangeNotifier {
  // instance of auth
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // sign in
  Future<UserCredential> signInWithEmailandPassword(
      String email, String password) async {
    try {
      final userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();

      final isActive = (doc.data()?['isActive'] ?? true) == true;
      if (!doc.exists || !isActive) {
        await _firebaseAuth.signOut();
        throw InactiveAccountException();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    } on InactiveAccountException {
      rethrow; // let UI show a nice message
    } catch (e) {
      throw Exception(e.toString());
    }
  }


  // sign up
  Future<UserCredential> signUpWithEmailandPassword(
      BuildContext context,
      String email,
      String password,
      ) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'role': 'user',
        'isActive': true, // ✅ مفعّل افتراضيًا
        'createdAt': FieldValue.serverTimestamp(),
      });

      // بعد التسجيل -> يذهب لملف التعريف لاستكمال البيانات
      Navigator.pushReplacementNamed(context, '/user_info');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // sign out
  Future<void> SignOut() async {
    return await _firebaseAuth.signOut();
  }

  // get user role
  Future<String?> getUserRole() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          return userDoc.get('role');
        }
      }
      return null;
    } catch (e) {
      print("Error getting user role: $e");
      return null;
    }
  }
}
