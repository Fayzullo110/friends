class Chat {
  final String id;
  final List<String> members;
  final Map<String, String> memberUsernames;
  final String lastMessage;
  final DateTime updatedAt;
  final bool isGroup;
  final String? title;

  Chat({
    required this.id,
    required this.members,
    required this.memberUsernames,
    required this.lastMessage,
    required this.updatedAt,
    required this.isGroup,
    required this.title,
  });

  factory Chat.fromJson(Map<String, dynamic> data) {
    return Chat(
      id: data['id'].toString(),
      members: (data['members'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      memberUsernames: ((data['memberUsernames'] as Map?) ?? const {})
          .map((k, v) => MapEntry(k.toString(), v.toString()))
          .cast<String, String>(),
      lastMessage: data['lastMessage'] as String? ?? '',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (data['updatedAt'] as num?)?.toInt() ?? 0,
        isUtc: false,
      ),
      isGroup: data['isGroup'] as bool? ?? (data['group'] as bool? ?? false),
      title: data['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'members': members,
      'memberUsernames': memberUsernames,
      'lastMessage': lastMessage,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isGroup': isGroup,
      'title': title,
    };
  }
}
