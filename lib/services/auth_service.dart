import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseAuth? _auth =
      FirebaseService.isAvailable ? FirebaseAuth.instance : null;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Email/Password Login
  Future<User?> login(String email, String password) async {
    if (_auth == null) {
      print('Firebase Auth not available');
      return null;
    }

    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Register with Email/Password
  Future<User?> register(String email, String password) async {
    if (_auth == null) {
      print('Firebase Auth not available');
      return null;
    }

    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  // Google Sign-In
  Future<User?> signInWithGoogle() async {
    if (_auth == null) {
      print('Firebase Auth not available');
      return null;
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      print('Google sign-in error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (_auth == null) {
      print('Firebase Auth not available');
      return;
    }

    await _googleSignIn.signOut();
    return await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    if (_auth == null) {
      print('Firebase Auth not available');
      return null;
    }

    return _auth.currentUser;
  }

  // Stream of authentication state changes
  Stream<User?> get userStream {
    if (_auth == null) {
      print('Firebase Auth not available');
      return Stream.value(null);
    }

    return _auth.authStateChanges();
  }
}
