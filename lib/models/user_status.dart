import 'package:cloud_firestore/cloud_firestore.dart';

class UserStatus {
  final String id;
  final String userId;
  final String username;
  final String? photoUrl;
  final String text;
  final String? emoji;
  final String? musicTitle;
  final String? musicArtist;
  final String? musicUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> seenBy;

  UserStatus({
    required this.id,
    required this.userId,
    required this.username,
    this.photoUrl,
    required this.text,
    this.emoji,
    this.musicTitle,
    this.musicArtist,
    this.musicUrl,
    required this.createdAt,
    required this.expiresAt,
    this.seenBy = const [],
  });

  factory UserStatus.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserStatus(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      username: data['username'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      text: data['text'] as String? ?? '',
      emoji: data['emoji'] as String?,
      musicTitle: data['musicTitle'] as String?,
      musicArtist: data['musicArtist'] as String?,
      musicUrl: data['musicUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 24)),
      seenBy: (data['seenBy'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'photoUrl': photoUrl,
      'text': text,
      'emoji': emoji,
      'musicTitle': musicTitle,
      'musicArtist': musicArtist,
      'musicUrl': musicUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'seenBy': seenBy,
    };
  }

  bool get hasMusic => musicUrl != null && musicUrl!.isNotEmpty;
  bool get hasEmoji => emoji != null && emoji!.isNotEmpty;
}
