import 'story_sticker.dart';

class Story {
  final String id;
  final String authorId;
  final String authorUsername;
  final String? authorThemeKey;
  final int? authorThemeSeedColor;
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
  final List<StorySticker> stickers;

  Story({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    this.authorThemeKey,
    this.authorThemeSeedColor,
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
    this.stickers = const [],
  });

  factory Story.fromJson(Map<String, dynamic> data) {
    return Story(
      id: data['id'].toString(),
      authorId: data['authorId'].toString(),
      authorUsername: data['authorUsername'] as String? ?? '',
      authorThemeKey: data['authorThemeKey'] as String?,
      authorThemeSeedColor: (data['authorThemeSeedColor'] as num?)?.toInt(),
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String? ?? 'text',
      text: data['text'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? 0,
        isUtc: false,
      ),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        (data['expiresAt'] as num?)?.toInt() ?? 0,
        isUtc: false,
      ),
      seenBy: (data['seenBy'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      likedBy: (data['likedBy'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      musicTitle: data['musicTitle'] as String?,
      musicArtist: data['musicArtist'] as String?,
      musicUrl: data['musicUrl'] as String?,
      stickers: (data['stickers'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StorySticker.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorThemeKey': authorThemeKey,
      'authorThemeSeedColor': authorThemeSeedColor,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'text': text,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'seenBy': seenBy,
      'likedBy': likedBy,
      'musicTitle': musicTitle,
      'musicArtist': musicArtist,
      'musicUrl': musicUrl,
      'stickers': stickers.map((e) => e.toJson()).toList(),
    };
  }
}
