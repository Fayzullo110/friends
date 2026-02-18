class AppUser {
  final String id;
  final String email;
  final String username;
  final String? displayName;
  final String? photoUrl;
  final String? backgroundImageUrl;
  final String? bio;
  final int? followersCount;
  final int? followingCount;
  final String? firstName;
  final String? lastName;
  final int? age;
  final bool isOfficial;
  final String? badgeType; // e.g. 'owner', 'creator', 'brand'
  final bool isOnline;
  final DateTime? lastActiveAt;

  AppUser({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    this.photoUrl,
    this.backgroundImageUrl,
    this.bio,
    this.followersCount,
    this.followingCount,
    this.firstName,
    this.lastName,
    this.age,
    this.isOfficial = false,
    this.badgeType,
    this.isOnline = false,
    this.lastActiveAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      email: json['email'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      backgroundImageUrl: json['backgroundImageUrl'] as String?,
      bio: json['bio'] as String?,
      followersCount: (json['followersCount'] as num?)?.toInt(),
      followingCount: (json['followingCount'] as num?)?.toInt(),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      age: (json['age'] as num?)?.toInt(),
      isOfficial: json['isOfficial'] as bool? ?? false,
      badgeType: json['badgeType'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'backgroundImageUrl': backgroundImageUrl,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'isOfficial': isOfficial,
      'badgeType': badgeType,
      'isOnline': isOnline,
      'lastActiveAt': lastActiveAt?.toIso8601String(),
    };
  }
}
