import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Chat.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Chat(
      id: doc.id,
      members: (data['members'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      memberUsernames: Map<String, String>.from(
        data['memberUsernames'] as Map<String, dynamic>? ?? const {},
      ),
      lastMessage: data['lastMessage'] as String? ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isGroup: data['isGroup'] as bool? ?? false,
      title: data['title'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'members': members,
      'memberUsernames': memberUsernames,
      'lastMessage': lastMessage,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isGroup': isGroup,
      'title': title,
    };
  }
}
