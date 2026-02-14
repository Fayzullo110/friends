import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class JitsiCallScreenImpl extends StatefulWidget {
  final String roomName;
  final String title;

  const JitsiCallScreenImpl({
    super.key,
    required this.roomName,
    required this.title,
  });

  @override
  State<JitsiCallScreenImpl> createState() => _JitsiCallScreenImplState();
}

class _JitsiCallScreenImplState extends State<JitsiCallScreenImpl> {
  late final WebViewController _controller;
  bool _loaded = false;
  bool _micMuted = false;
  bool _camMuted = false;
  bool _speakerOn = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..addJavaScriptChannel(
        'JitsiBridge',
        onMessageReceived: (message) {
          try {
            final decoded = jsonDecode(message.message);
            if (decoded is! Map) return;
            final event = decoded['event'];
            final muted = decoded['muted'];
            if (event is! String || muted is! bool) return;

            if (!mounted) return;
            setState(() {
              if (event == 'audio') {
                _micMuted = muted;
              } else if (event == 'video') {
                _camMuted = muted;
              }
            });
          } catch (_) {
            // ignore invalid messages
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _loaded = true;
            });

            _controller.runJavaScript('''
              (function() {
                if (!window.jitsiApi || !window.JitsiBridge) return;

                try {
                  window.jitsiApi.addListener('audioMuteStatusChanged', function(e) {
                    try { window.JitsiBridge.postMessage(JSON.stringify({event: 'audio', muted: !!e.muted})); } catch (_) {}
                  });
                  window.jitsiApi.addListener('videoMuteStatusChanged', function(e) {
                    try { window.JitsiBridge.postMessage(JSON.stringify({event: 'video', muted: !!e.muted})); } catch (_) {}
                  });
                } catch (_) {}
              })();
            ''');
          },
        ),
      )
      ..loadHtmlString(_buildHtml());
  }

  Future<void> _switchCamera() async {
    if (!_loaded) return;
    try {
      await _controller.runJavaScript(
        'window.jitsiApi && window.jitsiApi.executeCommand("toggleCamera");',
      );
    } catch (_) {
      // Fallback for some Jitsi builds.
      try {
        await _controller.runJavaScript(
          'window.jitsiApi && window.jitsiApi.executeCommand("switchCamera");',
        );
      } catch (_) {}
    }
  }

  Future<void> _hangup() async {
    if (_loaded) {
      try {
        await _controller.runJavaScript(
          'window.jitsiApi && window.jitsiApi.executeCommand("hangup");',
        );
      } catch (_) {}
    }

    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  String _buildHtml() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user?.email?.split('@').first ?? user?.displayName ?? 'user';
    final room = widget.roomName;

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0" />
  <style>
    html, body { height: 100%; margin: 0; background: #000; }
    #jitsi { width: 100%; height: 100%; }
  </style>
  <script src="https://meet.jit.si/external_api.js"></script>
</head>
<body>
  <div id="jitsi"></div>
  <script>
    const domain = "meet.jit.si";
    const options = {
      roomName: ${jsonEncode(room)},
      parentNode: document.querySelector('#jitsi'),
      userInfo: { displayName: ${jsonEncode(displayName)} },
      configOverwrite: {
        prejoinPageEnabled: false,
      },
      interfaceConfigOverwrite: {
        MOBILE_APP_PROMO: false,
      }
    };

    window.jitsiApi = new JitsiMeetExternalAPI(domain, options);

    window.startScreenShare = function() {
      try { window.jitsiApi.executeCommand('toggleShareScreen'); } catch (e) {}
    }

    window.startSharedVideo = function(url) {
      try { window.jitsiApi.executeCommand('startShareVideo', url); } catch (e) {}
    }

    window.stopSharedVideo = function() {
      try { window.jitsiApi.executeCommand('stopShareVideo'); } catch (e) {}
    }
  </script>
</body>
</html>
''';
  }

  Future<void> _shareScreen() async {
    if (!_loaded) return;
    try {
      await _controller.runJavaScript(
        'window.startScreenShare && window.startScreenShare();',
      );
    } catch (_) {}
  }

  Future<void> _toggleMic() async {
    if (!_loaded) return;
    try {
      await _controller.runJavaScript(
        'window.jitsiApi && window.jitsiApi.executeCommand("toggleAudio");',
      );
      if (!mounted) return;
      setState(() {
        _micMuted = !_micMuted;
      });
    } catch (_) {
      // Keep UI responsive.
    }
  }

  Future<void> _toggleCamera() async {
    if (!_loaded) return;
    try {
      await _controller.runJavaScript(
        'window.jitsiApi && window.jitsiApi.executeCommand("toggleVideo");',
      );
      if (!mounted) return;
      setState(() {
        _camMuted = !_camMuted;
      });
    } catch (_) {
      // Keep UI responsive.
    }
  }

  void _toggleSpeaker() {
    setState(() {
      _speakerOn = !_speakerOn;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Speaker routing depends on the device and Jitsi/WebView. Use device volume/route controls (speaker button, headphones, Bluetooth) or Jitsi audio settings.',
        ),
      ),
    );
  }

  Future<void> _watchTogether() async {
    if (!_loaded) return;

    final url = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Watch together'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Paste YouTube link (https://...)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Start'),
            ),
          ],
        );
      },
    );

    if (url == null || url.isEmpty) return;

    try {
      await _controller.runJavaScript(
        'window.startSharedVideo && window.startSharedVideo(${jsonEncode(url)});',
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final showDesktopHint = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _loaded ? _switchCamera : null,
            icon: const Icon(Icons.cameraswitch),
            tooltip: 'Switch camera',
          ),
          IconButton(
            onPressed: _loaded ? _toggleMic : null,
            icon: Icon(_micMuted ? Icons.mic_off : Icons.mic),
            tooltip: _micMuted ? 'Unmute mic' : 'Mute mic',
          ),
          IconButton(
            onPressed: _loaded ? _toggleCamera : null,
            icon: Icon(_camMuted ? Icons.videocam_off : Icons.videocam),
            tooltip: _camMuted ? 'Turn camera on' : 'Turn camera off',
          ),
          IconButton(
            onPressed: _toggleSpeaker,
            icon: Icon(_speakerOn ? Icons.volume_up : Icons.volume_off),
            tooltip: _speakerOn ? 'Speaker on' : 'Speaker off',
          ),
          IconButton(
            onPressed: _loaded ? _watchTogether : null,
            icon: const Icon(Icons.ondemand_video),
            tooltip: 'Watch together (YouTube)',
          ),
          IconButton(
            onPressed: _loaded ? _shareScreen : null,
            icon: const Icon(Icons.screen_share),
            tooltip: 'Share screen',
          ),
          IconButton(
            onPressed: _hangup,
            icon: const Icon(Icons.call_end),
            color: Colors.redAccent,
            tooltip: 'End call',
          ),
        ],
      ),
      body: Column(
        children: [
          if (showDesktopHint)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Text(
                'Tip: Screen sharing works best on desktop/web. Mobile WebViews may not support it.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
