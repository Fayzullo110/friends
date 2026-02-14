import 'package:flutter/material.dart';

import 'jitsi_call_screen_io.dart'
    if (dart.library.html) 'jitsi_call_screen_web.dart';

class JitsiCallScreen extends StatelessWidget {
  final String roomName;
  final String title;

  const JitsiCallScreen({
    super.key,
    required this.roomName,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return JitsiCallScreenImpl(
      roomName: roomName,
      title: title,
    );
  }
}
