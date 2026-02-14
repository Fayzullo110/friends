import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      backgroundImageUrl: data['backgroundImageUrl'],
      bio: data['bio'],
      followersCount: (data['followersCount'] as num?)?.toInt(),
      followingCount: (data['followingCount'] as num?)?.toInt(),
      firstName: data['firstName'],
      lastName: data['lastName'],
      age: (data['age'] as num?)?.toInt(),
      isOfficial: data['isOfficial'] as bool? ?? false,
      badgeType: data['badgeType'] as String?,
      isOnline: data['isOnline'] as bool? ?? false,
      lastActiveAt:
          (data['lastActiveAt'] as Timestamp?)?.toDate(),
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
      'lastActiveAt': lastActiveAt != null
          ? Timestamp.fromDate(lastActiveAt!)
          : null,
    };
  }
}
