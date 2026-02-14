import 'package:url_launcher/url_launcher.dart';

/// Simple video call service using Jitsi Meet via URL launcher.
///
/// For now we create one Jitsi room per chat using the chatId.
class VideoCallService {
  VideoCallService._();

  static final VideoCallService instance = VideoCallService._();

  Future<void> joinChatCall({
    required String chatId,
    required String title,
  }) async {
    final roomName = 'friends_chat_$chatId';

    final uri = Uri.parse('https://meet.jit.si/$roomName');

    if (!await canLaunchUrl(uri)) {
      throw Exception('Could not launch video call');
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }
}
