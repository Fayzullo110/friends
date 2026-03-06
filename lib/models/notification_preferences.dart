class NotificationPreferences {
  final bool notifyLikes;
  final bool notifyComments;
  final bool notifyFriendRequests;
  final bool notifyFriendAccepted;
  final bool notifyFollows;
  final bool digestEnabled;

  const NotificationPreferences({
    required this.notifyLikes,
    required this.notifyComments,
    required this.notifyFriendRequests,
    required this.notifyFriendAccepted,
    required this.notifyFollows,
    required this.digestEnabled,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      notifyLikes: json['notifyLikes'] as bool? ?? true,
      notifyComments: json['notifyComments'] as bool? ?? true,
      notifyFriendRequests: json['notifyFriendRequests'] as bool? ?? true,
      notifyFriendAccepted: json['notifyFriendAccepted'] as bool? ?? true,
      notifyFollows: json['notifyFollows'] as bool? ?? true,
      digestEnabled: json['digestEnabled'] as bool? ?? false,
    );
  }
}
