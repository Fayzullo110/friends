class AppUser {
  final String id;
  final String email;
  final String username;
  final String? displayName;
  final String? photoUrl;
  final String? backgroundImageUrl;
  final String? themeKey;
  final int? themeSeedColor;
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
    this.themeKey,
    this.themeSeedColor,
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

  AppUser copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? photoUrl,
    String? backgroundImageUrl,
    String? themeKey,
    int? themeSeedColor,
    String? bio,
    int? followersCount,
    int? followingCount,
    String? firstName,
    String? lastName,
    int? age,
    bool? isOfficial,
    String? badgeType,
    bool? isOnline,
    DateTime? lastActiveAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      themeKey: themeKey ?? this.themeKey,
      themeSeedColor: themeSeedColor ?? this.themeSeedColor,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      isOfficial: isOfficial ?? this.isOfficial,
      badgeType: badgeType ?? this.badgeType,
      isOnline: isOnline ?? this.isOnline,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      email: json['email'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      backgroundImageUrl: json['backgroundImageUrl'] as String?,
      themeKey: json['themeKey'] as String?,
      themeSeedColor: (json['themeSeedColor'] as num?)?.toInt(),
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
      'themeKey': themeKey,
      'themeSeedColor': themeSeedColor,
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
