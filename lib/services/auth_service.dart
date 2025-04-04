import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Login with email and password - Fixed to handle type casting errors
  Future<User?> login(String email, String password) async {
    try {
      debugPrint("Attempting login with: $email");

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        try {
          // Update lastLogin timestamp
          await _firestore.collection('users').doc(user.uid).update({
            'lastLogin': FieldValue.serverTimestamp(),
          });

          await updateUserRolesAfterLogin(user);
        } catch (e) {
          // Log error but don't fail the login
          debugPrint("Error updating user data after login: $e");
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth login error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Generic login error: $e");

      // Handle the specific type casting error
      if (e.toString().contains('PigeonUserDetails')) {
        debugPrint("Handling PigeonUserDetails casting error");
        // The login actually succeeded but the post-processing failed
        // Return the current user instead of throwing
        return FirebaseAuth.instance.currentUser;
      }

      rethrow;
    }
  }

  // Register with email and password
  Future<User?> register(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        // Create user document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'isAdmin': false,
          'isContributor': false,
          'isInvestor': false,
          'isCustomer': true,
          'userType': 'customer',
        });
      }

      return user;
    } catch (e) {
      debugPrint("Registration error: $e");
      rethrow;
    }
  }

  // Update user roles after login
  Future<void> updateUserRolesAfterLogin(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        // If user document doesn't exist, create it
        await userDoc.set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'isAdmin': false,
          'isContributor': false,
          'isInvestor': false,
          'isCustomer': true,
          'userType': 'customer',
        });
      } else {
        // Update last login timestamp
        await userDoc.update({'lastLogin': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      debugPrint("Error updating user roles: $e");
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // User canceled the sign-in
      }

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await updateUserRolesAfterLogin(user);
      }

      return user;
    } catch (e) {
      debugPrint("Google sign in error: $e");
      rethrow;
    }
  }

  // Sign in with Apple
  Future<User?> signInWithApple() async {
    try {
      // Generate random string to secure the request
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request credentials for the sign-in
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create OAuthCredential
      final oauthCredential = OAuthProvider(
        "apple.com",
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user != null) {
        await updateUserRolesAfterLogin(user);
      }

      return user;
    } catch (e) {
      debugPrint("Apple sign in error: $e");
      rethrow;
    }
  }

  // Helper for Apple Sign In
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    return await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Stream of authentication state changes
  Stream<User?> get userStream {
    return _auth.authStateChanges();
  }

  // Registration method
  Future<User?> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String? zipCode,
    String? birthday,
    String userType = 'customer', // Default type
  }) async {
    try {
      // Create the user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      // Set display name
      await user?.updateDisplayName('$firstName $lastName');

      // Create a user document in Firestore
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': phone ?? '',
          'zipCode': zipCode ?? '',
          'birthday': birthday ?? '',
          'userType': userType,
          'isAdmin': userType == 'administrator',
          'isContributor': userType == 'contributor',
          'isInvestor': userType == 'investor',
          'isCustomer': userType == 'customer',
          'textAlerts': false,
          'dailyDigest': false,
          'sportsNewsletter': false,
          'politicalNewsletter': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      rethrow; // Pass the error up to be handled by UI
    }
  }

  // Sign in method
  Future<User?> signInUser(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      // Update last login time
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Check if user is admin
  Future<bool> isUserAdmin() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      return doc.exists &&
          (doc.data() as Map<String, dynamic>)['isAdmin'] == true;
    }
    return false;
  }

  // Get user type
  Future<String> getUserType() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      return doc.exists
          ? (doc.data() as Map<String, dynamic>)['userType'] ?? 'customer'
          : 'customer';
    }
    return 'customer';
  }
}
