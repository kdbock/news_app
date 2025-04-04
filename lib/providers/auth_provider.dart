import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  AuthProvider() {
    _initAuthListener();
  }

  // Getters
  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _userData?['isAdmin'] == true;
  bool get isContributor => _userData?['isContributor'] == true;
  bool get isInvestor => _userData?['isInvestor'] == true;
  bool get isAdvertiser => _userData?['isAdvertiser'] == true;

  // Initialize Firebase Auth listener
  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;

      if (user != null) {
        try {
          await _fetchUserData();
        } catch (e) {
          debugPrint('Error fetching user data: $e');
        }
      } else {
        _userData = null;
      }

      notifyListeners();
    });
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    if (_user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final snapshot =
          await _firestore.collection('users').doc(_user!.uid).get();

      if (snapshot.exists) {
        _userData = snapshot.data();
        debugPrint('User data fetched: $_userData');
      } else {
        debugPrint('User document does not exist in Firestore');
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      _userData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add refreshUserData method to fix errors
  Future<void> refreshUserData() async {
    try {
      await _fetchUserData();
      debugPrint('User data refreshed successfully');
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
    }
  }

  // Login method
  Future<User?> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Rename to signOut to match usage in app_drawer.dart
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signOut();
      _userData = null;
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
