import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  AuthProvider() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        // When user logs in, fetch their data from Firestore
        _fetchUserData();
      } else {
        // When user logs out, clear their data
        _userData = null;
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  // Add a method to get user roles
  bool get isAdmin => _userData?['isAdmin'] ?? false;
  bool get isContributor => _userData?['isContributor'] ?? false;
  bool get isInvestor => _userData?['isInvestor'] ?? false;
  String get userType => _userData?['userType'] ?? 'customer';

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final docSnapshot =
          await _firestore.collection('users').doc(_user!.uid).get();

      if (docSnapshot.exists) {
        _userData = docSnapshot.data();
        debugPrint('User data fetched: $_userData');
      } else {
        // Create a new user document if it doesn't exist
        final newUserData = {
          'email': _user!.email,
          'displayName': _user!.displayName ?? _user!.email?.split('@')[0],
          'firstName': _user!.displayName?.split(' ')[0] ?? '',
          'lastName': (_user!.displayName != null && _user!.displayName!.split(' ').length > 1)
              ? _user!.displayName!.split(' ')[1]
              : '',
          'photoURL': _user!.photoURL,
          'isAdmin': false,
          'isContributor': false,
          'isInvestor': false,
          'isCustomer': true,
          'userType': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('users').doc(_user!.uid).set(newUserData);
        _userData = newUserData;
        debugPrint('New user created: $_userData');
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Manual refresh of user data
  Future<void> refreshUserData() async {
    await _fetchUserData();
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Update last login
      if (_user != null) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signOut();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
