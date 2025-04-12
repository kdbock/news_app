import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if current user has admin access
  static Future<bool> hasAdminAccess() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        return false;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return userData['isAdmin'] == true;
    } catch (e) {
      print('Error checking admin role: $e');
      return false;
    }
  }

  // Check if current user has investor access
  static Future<bool> hasInvestorAccess() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        return false;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return userData['isInvestor'] == true;
    } catch (e) {
      print('Error checking investor role: $e');
      return false;
    }
  }

  // Check if current user has contributor access
  static Future<bool> hasContributorAccess() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        return false;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return userData['isContributor'] == true;
    } catch (e) {
      print('Error checking contributor role: $e');
      return false;
    }
  }

  // Grant role to user
  static Future<bool> grantRole(String userId, String role, bool value) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        role: value,
      });
      return true;
    } catch (e) {
      print('Error granting role: $e');
      return false;
    }
  }

  // Get all users with specific role
  static Future<List<Map<String, dynamic>>> getUsersWithRole(String role) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where(role, isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error getting users with role: $e');
      return [];
    }
  }

  // Get user role information
  static Future<Map<String, bool>> getUserRoles() async {
    User? user = _auth.currentUser;
    if (user == null) {
      return {
        'isAdmin': false,
        'isContributor': false,
        'isInvestor': false,
        'isCustomer': false,
      };
    }

    DocumentSnapshot doc =
        await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      return {
        'isAdmin': false,
        'isContributor': false,
        'isInvestor': false,
        'isCustomer': true,
      };
    }

    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return {
      'isAdmin': data['isAdmin'] ?? false,
      'isContributor': data['isContributor'] ?? false,
      'isInvestor': data['isInvestor'] ?? false,
      'isCustomer': data['isCustomer'] ?? true,
    };
  }
}
