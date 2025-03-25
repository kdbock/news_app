import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static bool get isAvailable =>
      Firebase.apps.isNotEmpty && Firebase.apps[0] != null;

  static void checkFirebase() {
    if (!isAvailable) {
      print('Firebase not initialized. Some features will be unavailable.');
    }
  }
}
