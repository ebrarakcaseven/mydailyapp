import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  User? get currentUser {
    return _auth.currentUser;
  }

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case "user-not-found":
          errorMessage = "Kullanıcı bulunamadı";
          break;
        case "wrong-password":
          errorMessage = "Yanlış şifre";
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz e-posta adresi';
          break;
        case 'user-disabled':
          errorMessage = 'Kullanıcı hesabı devre dışı bırakılmış';
          break;
        default:
          errorMessage = "Bir hata oluştu. Lütfen tekrar deneyin.";
      }
      throw AuthException(message: errorMessage);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> saveUserData(String data) async {
    if (_user != null) {
      await _firestore.collection('user_data').add({
        'uid': _user!.uid,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      throw AuthException(message: 'Kullanıcı oturumu açık değil');
    }
  }

  Stream<QuerySnapshot> getUserData() {
    if (_user != null) {
      return _firestore
          .collection('user_data')
          .where('uid', isEqualTo: _user!.uid)
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      return Stream.empty();
    }
  }

  Future<DocumentSnapshot> getUserInfo() async {
    if (_user != null) {
      return await _firestore.collection('users').doc(_user!.uid).get();
    } else {
      throw AuthException(message: 'Kullanıcı oturumu açık değil');
    }
  }
}

class AuthException implements Exception {
  final String? message;
  AuthException({this.message});
}
