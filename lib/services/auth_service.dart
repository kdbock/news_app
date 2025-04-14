import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Login with email and password - fixed to handle the type casting issue
  Future<User?> login(String email, String password) async {
    try {
      // Approach 1: Direct access with explicit type handling
      UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Return user directly without accessing properties that might trigger Pigeon
      return credential.user;
    } catch (e) {
      print('Login error: $e');

      // Approach 2: Check if login succeeded despite the error
      if (e.toString().contains('PigeonUserDetails')) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          // Login actually succeeded despite the error
          return currentUser;
        }
      }
      rethrow;
    }
  }

  // Register with email and password - same fix applied
  Future<User?> register(String email, String password) async {
    try {
      // Force direct access
      final authResult = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Explicitly access the user property
      final User? user = authResult.user;

      if (user != null) {
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
      print('Registration error: $e');
      rethrow;
    }
  }

  // Google sign-in - same fix applied
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Force direct access
      final authResult = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      // Explicitly access the user property
      final User? user = authResult.user;

      // Update or create user document in Firestore
      if (user != null) {
        await _updateUserDataAfterSocialLogin(user);
      }

      return user;
    } catch (e) {
      print('Google sign-in error: $e');
      return null;
    }
  }

  // Apple sign-in - same fix applied
  Future<User?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Force direct access
      final authResult = await FirebaseAuth.instance.signInWithCredential(
        oauthCredential,
      );

      // Explicitly access the user property
      final User? user = authResult.user;

      // Update or create user document in Firestore
      if (user != null) {
        await _updateUserDataAfterSocialLogin(
          user,
          firstName: appleCredential.givenName,
          lastName: appleCredential.familyName,
        );
      }

      return user;
    } catch (e) {
      print('Apple sign-in error: $e');
      return null;
    }
  }

  // Update user document after login
  Future<void> _updateUserLastLogin(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        await _firestore.collection('users').doc(userId).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // Create basic user document if it doesn't exist
        await _firestore.collection('users').doc(userId).set({
          'email': _auth.currentUser?.email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'isAdmin': false,
          'isContributor': false,
          'isInvestor': false,
          'isCustomer': true,
          'userType': 'customer',
        });
      }
    } catch (e) {
      print('Error updating user login timestamp: $e');
    }
  }

  // Update/create user data after social login
  Future<void> _updateUserDataAfterSocialLogin(
    User user, {
    String? firstName,
    String? lastName,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'firstName': firstName ?? '',
          'lastName': lastName ?? '',
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'isAdmin': false,
          'isContributor': false,
          'isInvestor': false,
          'isCustomer': true,
          'userType': 'customer',
        });
      } else {
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
          'email': user.email ?? userDoc.data()?['email'] ?? '',
          'displayName':
              user.displayName ?? userDoc.data()?['displayName'] ?? '',
          'photoURL': user.photoURL ?? userDoc.data()?['photoURL'],
        });
      }
    } catch (e) {
      print('Error updating user data after social login: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Logout error: $e');
      rethrow;
    }
  }
}
