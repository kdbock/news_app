import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? zipCode;
  final String? photoUrl;
  final String? birthday;
  final bool isAdmin;
  final bool isContributor;
  final bool isInvestor;
  final bool textAlerts;
  final bool dailyDigest;
  final bool sportsNewsletter;
  final bool politicalNewsletter;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.zipCode,
    this.photoUrl,
    this.birthday,
    this.isAdmin = false,
    this.isContributor = false,
    this.isInvestor = false,
    this.textAlerts = false,
    this.dailyDigest = false,
    this.sportsNewsletter = false,
    this.politicalNewsletter = false,
    this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phone: data['phone'],
      zipCode: data['zipCode'],
      photoUrl: data['photoUrl'],
      birthday: data['birthday'],
      isAdmin: data['isAdmin'] ?? false,
      isContributor: data['isContributor'] ?? false,
      isInvestor: data['isInvestor'] ?? false,
      textAlerts: data['textAlerts'] ?? false,
      dailyDigest: data['dailyDigest'] ?? false,
      sportsNewsletter: data['sportsNewsletter'] ?? false,
      politicalNewsletter: data['politicalNewsletter'] ?? false,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
      lastLogin: data['lastLogin'] != null 
          ? (data['lastLogin'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'zipCode': zipCode,
      'photoUrl': photoUrl,
      'birthday': birthday,
      'isAdmin': isAdmin,
      'isContributor': isContributor,
      'isInvestor': isInvestor,
      'textAlerts': textAlerts,
      'dailyDigest': dailyDigest,
      'sportsNewsletter': sportsNewsletter,
      'politicalNewsletter': politicalNewsletter,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? zipCode,
    String? photoUrl,
    String? birthday,
    bool? isAdmin,
    bool? isContributor,
    bool? isInvestor,
    bool? textAlerts,
    bool? dailyDigest,
    bool? sportsNewsletter,
    bool? politicalNewsletter,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      zipCode: zipCode ?? this.zipCode,
      photoUrl: photoUrl ?? this.photoUrl,
      birthday: birthday ?? this.birthday,
      isAdmin: isAdmin ?? this.isAdmin,
      isContributor: isContributor ?? this.isContributor,
      isInvestor: isInvestor ?? this.isInvestor,
      textAlerts: textAlerts ?? this.textAlerts,
      dailyDigest: dailyDigest ?? this.dailyDigest,
      sportsNewsletter: sportsNewsletter ?? this.sportsNewsletter,
      politicalNewsletter: politicalNewsletter ?? this.politicalNewsletter,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}