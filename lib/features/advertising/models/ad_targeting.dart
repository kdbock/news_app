// Define enums for targeting options
enum UserInterestLevel {
  low,
  medium,
  high
}

enum UserType {
  anonymous,
  registered,
  subscriber,
  premium
}

class AdTargeting {
  final List<String> categories;
  final List<String>? regions;
  final UserInterestLevel? interestLevel;
  final UserType? userType;
  
  // Constructor to initialize final variables
  const AdTargeting({
    required this.categories,
    this.regions,
    this.interestLevel,
    this.userType,
  });

  // Factory constructor from JSON
  factory AdTargeting.fromJson(Map<String, dynamic> json) {
    return AdTargeting(
      categories: List<String>.from(json['categories'] ?? []),
      regions: json['regions'] != null ? List<String>.from(json['regions']) : null,
      interestLevel: json['interestLevel'] != null 
          ? UserInterestLevel.values[json['interestLevel']] 
          : null,
      userType: json['userType'] != null 
          ? UserType.values[json['userType']] 
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'categories': categories,
      'regions': regions,
      'interestLevel': interestLevel?.index,
      'userType': userType?.index,
    };
  }

  // Methods for matching ads to user profiles
  bool matchesUserProfile(Map<String, dynamic> userProfile) {
    // Match categories if user has interests in these categories
    final userInterests = userProfile['interests'] as List<String>? ?? [];
    if (categories.isNotEmpty && 
        !categories.any((category) => userInterests.contains(category))) {
      return false;
    }
    
    // Match regions if specified
    final userRegion = userProfile['region'] as String?;
    if (regions != null && regions!.isNotEmpty && 
        userRegion != null && !regions!.contains(userRegion)) {
      return false;
    }
    
    // Match user type if specified
    final profileUserType = userProfile['userType'] as int?;
    if (userType != null && profileUserType != null && 
        userType!.index != profileUserType) {
      return false;
    }
    
    // Match interest level if specified
    final profileInterestLevel = userProfile['interestLevel'] as int?;
    if (interestLevel != null && profileInterestLevel != null && 
        interestLevel!.index > profileInterestLevel) {
      return false;
    }
    
    return true;
  }
  
  // Create an empty targeting (show to everyone)
  static AdTargeting get universal => const AdTargeting(categories: []);
  
  // Copy with method for modifying targeting
  AdTargeting copyWith({
    List<String>? categories,
    List<String>? regions,
    UserInterestLevel? interestLevel,
    UserType? userType,
  }) {
    return AdTargeting(
      categories: categories ?? this.categories,
      regions: regions ?? this.regions,
      interestLevel: interestLevel ?? this.interestLevel,
      userType: userType ?? this.userType,
    );
  }
}