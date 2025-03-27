import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Use non-nullable Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Email/Password Login
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      // Update last login time and ensure roles are set
      if (user != null) {
        await updateUserRolesAfterLogin(user);
      }

      return user;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  // Register with Email/Password
  Future<User?> register(String email, String password) async {
    try {
      // Create the user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      // Create a basic user document in Firestore
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'isAdmin': false,
          'isContributor': false,
          'isInvestor': false,
          'isCustomer': true,
          'userType': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      print("Registration error: $e");
      rethrow;
    }
  }

  // Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return null;

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      // If user doesn't exist in Firestore yet, create their document
      if (user != null) {
        final docSnapshot =
            await _firestore.collection('users').doc(user.uid).get();

        if (!docSnapshot.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'displayName': user.displayName,
            'firstName': user.displayName?.split(' ').first ?? '',
            'lastName': user.displayName?.split(' ').last ?? '',
            'isAdmin': false,
            'isContributor': false,
            'isInvestor': false,
            'isCustomer': true,
            'userType': 'customer',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } else {
          await _firestore.collection('users').doc(user.uid).update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }
      }

      return user;
    } catch (e) {
      print("Google sign-in error: $e");
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
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

  // Add this method to update user roles when they log in
  Future<void> updateUserRolesAfterLogin(User user) async {
    try {
      // Get the user document
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      // If no document exists, create default one
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'displayName': user.displayName,
          'firstName': user.displayName?.split(' ').first ?? '',
          'lastName': user.displayName?.split(' ').last ?? '',
          'isAdmin': false,
          'isContributor': false,
          'isInvestor': false,
          'isCustomer': true,
          'userType': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // Just update last login
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating user roles: $e');
    }
  }
}
