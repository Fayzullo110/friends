import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String url;

  const VoiceMessagePlayer({super.key, required this.url});

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  late AudioPlayer _player;
  bool _loading = true;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setUrl(widget.url);
      await _player.setSpeed(_speed);
    } catch (_) {
      // ignore
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final playing = state?.playing ?? false;

        return StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, posSnap) {
            final position = posSnap.data ?? Duration.zero;
            final duration = _player.duration ?? Duration.zero;
            final maxMs = duration.inMilliseconds;
            final posMs = position.inMilliseconds.clamp(0, maxMs == 0 ? 0 : maxMs);

            String format(Duration d) {
              final totalSeconds = d.inSeconds;
              final minutes = (totalSeconds ~/ 60).toString().padLeft(1, '0');
              final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
              return '$minutes:$seconds';
            }

            final remaining = duration - position;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  color: theme.colorScheme.onPrimary,
                  onPressed: () async {
                    if (playing) {
                      await _player.pause();
                    } else {
                      await _player.play();
                    }
                  },
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        ),
                        child: Slider(
                          value: (maxMs == 0) ? 0 : (posMs / maxMs),
                          onChanged: (v) {
                            if (maxMs == 0) return;
                            final nextMs = (v * maxMs).round();
                            _player.seek(Duration(milliseconds: nextMs));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            Text(
                              format(position),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary.withOpacity(0.85),
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '-${format(remaining.isNegative ? Duration.zero : remaining)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary.withOpacity(0.7),
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () async {
                    final next = _speed == 1.0 ? 1.5 : (_speed == 1.5 ? 2.0 : 1.0);
                    setState(() {
                      _speed = next;
                    });
                    await _player.setSpeed(_speed);
                  },
                  child: Text('${_speed.toStringAsFixed(_speed == 1.0 ? 0 : 1)}x'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
