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

  // Login with email and password
  Future<User?> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // This is crucial - update user document in Firestore if needed
      if (userCredential.user != null) {
        await _updateUserLastLogin(userCredential.user!.uid);
      }

      return userCredential.user;
    } catch (e) {
      print('Login error: $e');
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

      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
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

      return userCredential.user;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  // Sign in with Google
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

      final userCredential = await _auth.signInWithCredential(credential);

      // Update or create user document in Firestore
      if (userCredential.user != null) {
        await _updateUserDataAfterSocialLogin(userCredential.user!);
      }

      return userCredential.user;
    } catch (e) {
      print('Google sign-in error: $e');
      return null;
    }
  }

  // Sign in with Apple
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

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Update or create user document in Firestore
      if (userCredential.user != null) {
        await _updateUserDataAfterSocialLogin(
          userCredential.user!,
          firstName: appleCredential.givenName,
          lastName: appleCredential.familyName,
        );
      }

      return userCredential.user;
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
    await _googleSignIn.signOut();
    return _auth.signOut();
  }
}
