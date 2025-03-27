import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if user has admin access
  static Future<bool> hasAdminAccess() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    DocumentSnapshot doc =
        await _firestore.collection('users').doc(user.uid).get();
    return doc.exists &&
        (doc.data() as Map<String, dynamic>)['isAdmin'] == true;
  }

  // Check if user has contributor access
  static Future<bool> hasContributorAccess() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    DocumentSnapshot doc =
        await _firestore.collection('users').doc(user.uid).get();
    return doc.exists &&
        ((doc.data() as Map<String, dynamic>)['isContributor'] == true ||
            (doc.data() as Map<String, dynamic>)['isAdmin'] == true);
  }

  // Check if user has investor access
  static Future<bool> hasInvestorAccess() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    DocumentSnapshot doc =
        await _firestore.collection('users').doc(user.uid).get();
    return doc.exists &&
        ((doc.data() as Map<String, dynamic>)['isInvestor'] == true ||
            (doc.data() as Map<String, dynamic>)['isAdmin'] == true);
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
