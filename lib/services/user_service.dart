import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user document
  Future<DocumentSnapshot?> getCurrentUserDocument() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await _firestore.collection('users').doc(user.uid).get();
    }
    return null;
  }

  // Check if user is admin
  Future<bool> isUserAdmin() async {
    DocumentSnapshot? doc = await getCurrentUserDocument();
    return doc != null &&
        doc.exists &&
        (doc.data() as Map<String, dynamic>)['isAdmin'] == true;
  }

  // Check if user is contributor
  Future<bool> isUserContributor() async {
    DocumentSnapshot? doc = await getCurrentUserDocument();
    return doc != null &&
        doc.exists &&
        (doc.data() as Map<String, dynamic>)['isContributor'] == true;
  }

  // Update user profile
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? zipCode,
    String? birthday,
    bool? textAlerts,
    bool? dailyDigest,
    bool? sportsNewsletter,
    bool? politicalNewsletter,
  }) async {
    User? user = _auth.currentUser;
    if (user != null) {
      Map<String, dynamic> updateData = {};

      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (phone != null) updateData['phone'] = phone;
      if (zipCode != null) updateData['zipCode'] = zipCode;
      if (birthday != null) updateData['birthday'] = birthday;
      if (textAlerts != null) updateData['textAlerts'] = textAlerts;
      if (dailyDigest != null) updateData['dailyDigest'] = dailyDigest;
      if (sportsNewsletter != null) {
        updateData['sportsNewsletter'] = sportsNewsletter;
      }
      if (politicalNewsletter != null) {
        updateData['politicalNewsletter'] = politicalNewsletter;
      }

      // Update display name if first or last name changed
      if (firstName != null || lastName != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();
        String currentFirstName =
            (doc.data() as Map<String, dynamic>)['firstName'] ?? '';
        String currentLastName =
            (doc.data() as Map<String, dynamic>)['lastName'] ?? '';

        String newFirstName = firstName ?? currentFirstName;
        String newLastName = lastName ?? currentLastName;

        await user.updateDisplayName('$newFirstName $newLastName');
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);
    }
  }

  // Make user an admin (use this in an admin panel)
  Future<void> makeUserAdmin(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isAdmin': true,
      'userType': 'administrator',
    });
  }

  // Make user a contributor
  Future<void> makeUserContributor(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isContributor': true,
      'userType': 'contributor',
    });
  }
}
