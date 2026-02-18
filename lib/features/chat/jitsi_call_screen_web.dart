import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

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
  late final String _viewType;
  bool _initialized = false;
  bool _micMuted = false;
  bool _camMuted = false;
  bool _speakerOn = true;
  String? _initError;

  @override
  void initState() {
    super.initState();

    _viewType = 'jitsi-view-${widget.roomName}-${DateTime.now().millisecondsSinceEpoch}';

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final container = html.DivElement()
        ..id = 'jitsi-container-$viewId'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = '#000';

      final jitsiDiv = html.DivElement()
        ..id = 'jitsi-$viewId'
        ..style.width = '100%'
        ..style.height = '100%';

      container.append(jitsiDiv);

      _ensureExternalApiLoaded().then((_) {
        _initJitsi(jitsiDiv.id);
      });

      return container;
    });
  }

  Future<void> _switchCamera() async {
    try {
      js.context['jitsiApi']?.callMethod('executeCommand', ['toggleCamera']);
    } catch (_) {
      try {
        js.context['jitsiApi']?.callMethod('executeCommand', ['switchCamera']);
      } catch (_) {}
    }
  }

  Future<void> _hangup() async {
    try {
      js.context['jitsiApi']?.callMethod('executeCommand', ['hangup']);
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  void _toggleSpeaker() {
    setState(() {
      _speakerOn = !_speakerOn;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'On web, speaker/output device selection is handled by the browser and Jitsi settings.',
        ),
      ),
    );
  }

  Future<void> _ensureExternalApiLoaded() async {
    final existing = html.document.querySelector('script[data-jitsi-external-api="true"]');
    if (existing != null) return;

    final script = html.ScriptElement()
      ..src = 'https://meet.jit.si/external_api.js'
      ..type = 'text/javascript'
      ..setAttribute('data-jitsi-external-api', 'true');

    final completer = Completer<void>();
    script.onLoad.listen((_) => completer.complete());
    script.onError.listen((_) {
      _initError ??= 'Failed to load Jitsi external_api.js';
      completer.complete();
    });

    html.document.head?.append(script);
    await completer.future;
  }

  void _initJitsi(String parentId) {
    if (_initialized) return;
    _initialized = true;

    final me = AuthService.instance.currentUser;
    final displayName = me?.email.split('@').first ?? me?.username ?? 'user';

    final options = js.JsObject.jsify({
      'roomName': widget.roomName,
      'parentNode': html.document.getElementById(parentId),
      'userInfo': {'displayName': displayName},
      'configOverwrite': {'prejoinPageEnabled': false},
      'interfaceConfigOverwrite': {'MOBILE_APP_PROMO': false},
    });

    try {
      final api = js.context['JitsiMeetExternalAPI'] as js.JsFunction?;
      if (api == null) {
        _initError ??= 'JitsiMeetExternalAPI is not available (script blocked?)';
        if (mounted) setState(() {});
        return;
      }

      js.context['jitsiApi'] = js.JsObject(api, ['meet.jit.si', options]);

      final apiObj = js.context['jitsiApi'] as js.JsObject?;
      if (apiObj != null) {
        apiObj.callMethod('addListener', [
          'audioMuteStatusChanged',
          js.JsFunction.withThis((dynamic _, dynamic e) {
            try {
              final muted = (e is js.JsObject)
                  ? (e['muted'] as bool? ?? false)
                  : false;
              if (!mounted) return;
              setState(() {
                _micMuted = muted;
              });
            } catch (_) {}
          }),
        ]);

        apiObj.callMethod('addListener', [
          'videoMuteStatusChanged',
          js.JsFunction.withThis((dynamic _, dynamic e) {
            try {
              final muted = (e is js.JsObject)
                  ? (e['muted'] as bool? ?? false)
                  : false;
              if (!mounted) return;
              setState(() {
                _camMuted = muted;
              });
            } catch (_) {}
          }),
        ]);
      }
    } catch (_) {
      _initError ??= 'Failed to initialize Jitsi call';
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _openInNewTab() {
    final url = 'https://meet.jit.si/${widget.roomName}';
    html.window.open(url, '_blank');
  }

  Future<void> _shareScreen() async {
    try {
      js.context['jitsiApi']?.callMethod('executeCommand', ['toggleShareScreen']);
    } catch (_) {}
  }

  Future<void> _toggleMic() async {
    try {
      js.context['jitsiApi']?.callMethod('executeCommand', ['toggleAudio']);
      if (!mounted) return;
      setState(() {
        _micMuted = !_micMuted;
      });
    } catch (_) {}
  }

  Future<void> _toggleCamera() async {
    try {
      js.context['jitsiApi']?.callMethod('executeCommand', ['toggleVideo']);
      if (!mounted) return;
      setState(() {
        _camMuted = !_camMuted;
      });
    } catch (_) {}
  }

  Future<void> _watchTogether() async {
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
      js.context['jitsiApi']?.callMethod('executeCommand', ['startShareVideo', url]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.cameraswitch),
            tooltip: 'Switch camera',
          ),
          IconButton(
            onPressed: _toggleMic,
            icon: Icon(_micMuted ? Icons.mic_off : Icons.mic),
            tooltip: _micMuted ? 'Unmute mic' : 'Mute mic',
          ),
          IconButton(
            onPressed: _toggleCamera,
            icon: Icon(_camMuted ? Icons.videocam_off : Icons.videocam),
            tooltip: _camMuted ? 'Turn camera on' : 'Turn camera off',
          ),
          IconButton(
            onPressed: _toggleSpeaker,
            icon: Icon(_speakerOn ? Icons.volume_up : Icons.volume_off),
            tooltip: _speakerOn ? 'Speaker on' : 'Speaker off',
          ),
          IconButton(
            onPressed: _watchTogether,
            icon: const Icon(Icons.ondemand_video),
            tooltip: 'Watch together (YouTube)',
          ),
          IconButton(
            onPressed: _shareScreen,
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
      body: Stack(
        children: [
          HtmlElementView(viewType: _viewType),
          if (_initError != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.75),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _initError!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _openInNewTab,
                        child: const Text('Open in browser'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
