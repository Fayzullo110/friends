import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String authorId;
  final String authorUsername;
  final String? mediaUrl; // image / video / gif URL
  final String mediaType; // 'text', 'image', 'video', 'gif'
  final String? text;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> seenBy;
  final List<String> likedBy;
  final String? musicTitle;
  final String? musicArtist;
  final String? musicUrl;

  Story({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    this.mediaUrl,
    required this.mediaType,
    this.text,
    required this.createdAt,
    required this.expiresAt,
    this.seenBy = const [],
    this.likedBy = const [],
    this.musicTitle,
    this.musicArtist,
    this.musicUrl,
  });

  factory Story.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Story(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorUsername: data['authorUsername'] as String? ?? '',
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String? ?? 'text',
      text: data['text'] as String?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt:
          (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seenBy: (data['seenBy'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      likedBy: (data['likedBy'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      musicTitle: data['musicTitle'] as String?,
      musicArtist: data['musicArtist'] as String?,
      musicUrl: data['musicUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorUsername': authorUsername,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'seenBy': seenBy,
      'likedBy': likedBy,
      'musicTitle': musicTitle,
      'musicArtist': musicArtist,
      'musicUrl': musicUrl,
    };
  }
}
