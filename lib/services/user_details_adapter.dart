import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// This class serves as an adapter between Firebase's user data and our app's expected format
class UserDetailsAdapter {
  // Convert Firebase user to whatever format your app needs
  static Map<String, dynamic> fromFirebaseUser(User user) {
    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'phoneNumber': user.phoneNumber,
      'emailVerified': user.emailVerified,
    };
  }

  // Handle the PigeonUserDetails conversion
  static dynamic toPigeonFormat(User user) {
    try {
      // First convert to a standard map - this helps avoid direct casting issues
      final userMap = fromFirebaseUser(user);

      // Return the map format instead of trying to cast to PigeonUserDetails
      return userMap;
    } catch (e) {
      debugPrint('Error converting user to Pigeon format: $e');
      return null;
    }
  }
}
