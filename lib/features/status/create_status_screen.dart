import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../services/user_status_service.dart';
import '../../services/auth_service.dart';
import '../../theme/ios_icons.dart';

class CreateStatusScreen extends StatefulWidget {
  const CreateStatusScreen({super.key});

  @override
  State<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends State<CreateStatusScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  String? _selectedEmoji;
  String? _musicTitle;
  String? _musicArtist;
  String? _musicUrl;
  bool _isSubmitting = false;

  final List<String> _quickEmojis = [
    '�','�','😄','😁','😆','😅','🤣','�','🙂','🙃','🫠','😉','😊','😇','🥰','😍','🤩','😘','😗','☺️','😚','😙','🥲','😋','😛','😜','🤪','😝','🤑','🤗','🤭','🫢','🫣','🤫','🤔','🫡','🤐','🤨','😐','😑','😶','🫥','😶‍🌫️','😏','😒','🙄','�','��','😌','😔','😪','🤤','😴','😷','🤒','🤕','🤢','🤮','🤧','🥵','🥶','🥴','😵','😵‍💫','🤯','🤠','🥳','🥸','😎','🤓','🧐','😕','🫤','😟','🙁','☹️','😮','😯','😲','😳','🥺','🥹','😦','😧','😨','😰','😥','😢','😭','😱','😖','😣','😞','😓','😩','😫','�','😤','😡','😠','🤬','😈','👿','💀','☠️','💩','🤡','👹','👺','👻','👽','👾','🤖','😺','😸','😹','😻','😼','😽','🙀','😿','😾','🙈','🙉','🙊','💋','💯','💢','💥','💫','💦','💨','🕳️','💣','💬','👁️‍🗨️','🗨️','🗯️','💭','💤',
    '👋','🤚','🖐️','✋','🖖','🫱','🫲','🫳','🫴','👌','🤌','🤏','✌️','🤞','🫰','🤟','🤘','🤙','👈','👉','👆','🖕','�','☝️','�','👎','✊','👊','🤛','🤜','👏','🙌','🫶','👐','🤲','🤝','🙏','✍️','💅','🤳','💪','🦾','🦿','🦵','🦶','👂','🦻','👃','🧠','🫀','🫁','🦷','🦴','👀','👁️','👅','👄','🫦','👶','🧒','👦','👧','🧑','👱','👨','🧔','🧔‍♂️','🧔‍♀️','👨‍🦰','👨‍🦱','👨‍🦳','👨‍🦲','👩','👩‍🦰','🧑‍🦰','👩‍🦱','🧑‍🦱','👩‍🦳','🧑‍🦳','👩‍🦲','🧑‍🦲','👱‍♀️','👱‍♂️','🧓','👴','👵',
    '❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❤️‍�','❤️‍�','💕','💞','💓','💗','💖','💘','💝','💟','☮️','✝️','☪️','🕉️','☸️','✡️','🔯','🕎','☯️','☦️','🛐','⛎','♈','♉','♊','♋','♌','♍','♎','♏','♐','♑','♒','♓','🆔','⚛️','🉑','☢️','☣️','📴','📳','🈶','🈚','🈸','🈺','🈷️','✴️','🆚','�','🉐','㊙️','㊗️','��','🈵','🈹','🈲','🅰️','🅱️','🆎','🆑','🅾️','🆘','❌','⭕','🛑','⛔','📛','🚫','💯','💢','♨️','🚷','🚯','🚳','🚱','🔞','📵','🚭','❗','❕','❓','❔','‼️','⁉️','🔅','🔆','〽️','⚠️','🚸','🔱','⚜️','🔰','♻️','✅','🈯','💹','❇️','✳️','❎','🌐','💠','Ⓜ️','🌀','💤','🏧','🚾','♿','🅿️','🈳','🈂','🛂','🛃','🛄','🛅','🛗','🧭','🧱','🧲','🧪','🧫','🧬','🧯','🧴','🧵','🧶','🧷','🧹','🧺','🧻','🧼','🧽','🧯','🛟','🛞','🪬','🪪','🟰',
    '💐','🌸','💮','🏵️','🌹','🥀','🌺','🌻','🌼','🌷','🪻','🪷','☘️','🍀','🍁','🍂','🍃','🪹','🪺','🪵','🌑','🌒','🌓','🌔','🌕','🌖','🌗','🌘','🌙','🌚','🌛','�','🌡️','☀️','🌝','🌞','🪐','⭐','🌟','🌠','🌌','☁️','⛅','⛈️','🌤️','🌥️','🌦️','🌧️','🌨️','❄️','🌬️','💨','🌪️','🌫️','🌈','☔','⚡','❄️','☃️','⛄','☄️','🔥','�','🌊',
    '🎄','✨','🎋','🎍','🎎','�','🎐','🎑','🧧','🎀','🎁','🎗️','🎟️','🎫','🎖️','🏆','🏅','🥇','🥈','🥉',
    '⚽','⚾','🥎','🏀','🏐','🏈','🏉','🎾','🥏','🎳','🏏','🏑','🏒','🥍','🏓','🏸','🥊','🥋','🥅','⛳','⛸️','🎣','🤿','🎽','🎿','🛷','🥌','🎯','🎱','🔮','🪄','🎮','🕹️','🎰','🎲','🧩','🧸','🪅','🪆','🪀','🪃','🪁','🎨','🧵','🪡','🧶','🪢','🛝','🛼','🛹','🤿','🎭','🖼️','🎨','🧵','🪡','🧶','🪢','👓','🕶️','🥽','🥼','🦺','👔','👕','👖','🧣','🧤','🧥','🧦','👗','👘','🥻','🩱','🩲','🩳','👙','👚','👛','👜','👝','🛍️','🎒','🩴','👞','👟','🥾','🥿','👠','👡','🩰','👢','👑','👒','🎩','🎓','🧢','🪖','⛑️','📿','💄','💍','💎','🔇','🔈','🔉','🔊','📢','📣','📯','🔔','🔕','�','🎵','🎶','🎙️','🎚️','🎛️','🎤','🎧','📻','🎷','🪗','�','🎹','🎺','🎻','🪕','🥁','🪘','📱','📲','☎️','📞','📟','📠','🔋','🔌','💻','🖥️','🖨️','⌨️','🖱️','🖲️','💽','💾','💿','📀','🧮','🎥','🎞️','📽️','🎬','📺','📷','📸','📹','📼','🔍','🔎','🕯️','💡','🔦','🏮','🪔','📔','📕','📖','📗','📘','📙','📚','📓','📒','📃','📜','📄','📰','🗞️','📑','🔖','🏷️','💰','🪙','💴','💵','💶','💷','💸','💳','🧾','💹','✉️','📧','📨','📩','📤','📥','📦','📫','📪','📬','📭','📮','🗳️','✏️','✒️','🖋️','🖊️','🖌️','🖍️','📝','💼','📁','📂','🗂️','📅','📆','🗒️','🗓️','📇','📈','📉','📊','📋','📌','📍','📎','🖇️','📏','📐','✂️','🗃️','🗄️','🗑️','🔒','🔓','🔏','🔐','🔑','🗝️','🔨','🪓','⛏️','⚒️','🛠️','🗡️','⚔️','🔫','🪃','🏹','🛡️','🪚','🔧','🪛','🔩','⚙️','🗜️','⚖️','🦯','🔗','⛓️','🪝','🧰','🧲','🪜','⚗️','🧪','🧫','🧬','🔬','🔭','📡','💉','🩸','💊','🩹','🩼','🩺','🌡️','🧹','🧺','🧻','🚽','🚰','🚿','🛁','🛀','🧼','🪥','🪒','🧽','🪣','🧴','🛒','🚬','⚰️','🪦','⚱️','🗿','🪧','🪦','🏧','🚮','🚰','♿','🚹','🚺','🚻','🚼','🚾','🛂','🛃','🛄','🛅','🛗','🧭','🚸','⛔','🚫','🚳','🚭','🚯','🚱','🚷','📵','🔞','☢️','☣️','⬆️','↗️','➡️','↘️','⬇️','↙️','⬅️','↖️','↕️','↔️','↩️','↪️','⤴️','⤵️','🔃','🔄','🔙','🔚','🔛','🔜','🔝','🛐','⚛️','🕉️','✡️','☸️','☯️','✝️','☦️','☪️','☮️','🕎','🔯','🪯','♈','♉','♊','♋','♌','♍','♎','♏','♐','♑','♒','♓','⛎','🔀','🔁','🔂','▶️','⏩','⏭️','⏯️','◀️','⏪','⏮️','🔼','⏫','🔽','⏬','⏸️','⏹️','⏺️','⏏️','🎦','🔅','🔆','📶','📳','📴','🛜','♀️','♂️','⚧️','✖️','➕','➖','➗','🟰','♾️','‼️','⁉️','❓','❔','❕','❗','〰️','💱','💲','⚕️','♻️','⚜️','🔱','📛','🔰','⭕','✅','☑️','✔️','❌','❎','➰','➿','〽️','✳️','✴️','❇️','©️','®️','™️','#️⃣','*️⃣','0️⃣','1️⃣','2️⃣','3️⃣','4️⃣','5️⃣','6️⃣','7️⃣','8️⃣','9️⃣','🔟','🔠','🔡','🔢','🔣','🔤','🅰️','🆎','🅱️','🆑','🆒','🆓','ℹ️','🆔','Ⓜ️','🆕','🆖','🅾️','🆗','🅿️','🆘','🆙','🆚','🈁','🈂️','🈷️','🈶','🈯','🉐','🈹','🈚','🈲','🉑','🈸','🈴','🈳','㊗️','㊙️','🈺','🈵',
    '🍏','🍎','🍐','🍊','🍋','🍌','🍉','🍇','🍓','🫐','🍈','🍒','🍑','🍍','🥝','🍅','🍆','🥑','🥦','🥬','🥒','🌶️','🫑','🌽','🥕','🫒','🧄','🧅','🥔','🍠','🥐','🥯','🍞','🥖','🥨','🧀','🥚','🍳','🧈','🥞','🧇','🥓','🍔','🍟','🍕','🌭','🥪','🌮','🌯','🫔','🥙','🧆','🥚','🍳','🥘','🍲','🫕','🥣','🥗','🍿','🧈','🧂','🥫','🍱','🍘','🍙','🍚','🍛','🍜','🍝','🍠','🍢','🍣','🍤','🍥','🍡','🥟','🥠','🥡','🦀','🦞','🦐','🦑','🦪','🍦','🍧','🍨','🍩','🍪','🎂','🍰','🧁','🥧','🍫','🍬','🍭','🍮','🍯','🍼','🥛','☕','🫖','🍵','🍶','🍾','🍷','🍸','🍹','🍺','🍻','🥂','🥃','🫗','🥤','🧋','🧃','🧉','🧊','🥢','🍽️','🍴','🥄','🔪','🫙','🏺',
    '🌍','🌎','🌏','🌐','🗺️','🧭','🏔️','⛰️','🌋','🗻','🏕️','🏖️','🏜️','🏝️','🏞️','🏟️','🏛️','🏗️','🧱','🪨','🪵','🛖','🏘️','🏚️','🏠','🏡','🏢','🏣','🏤','🏥','🏦','🏨','🏩','🏪','🏫','🏬','🏭','🏯','🏰','💒','🗼','🗽','⛪','🕌','🛕','🕍','⛩️','🕋','⛲','⛺','🌁','🌃','�️','🌄','🌅','🌆','🌇','🌉','♨️','🎠','🛝','🎡','🎢','💈','🎪','🚂','🚃','🚄','🚅','🚆','🚇','🚈','🚉','🚊','🚝','🚞','🚋','🚌','🚍','🚎','🚐','🚑','🚒','🚓','🚔','🚕','🚖','🚗','🚘','🚙','🛻','🚚','🚛','🚜','�️','🏍️','🛵','🦽','🦼','🛺','🚲','🛴','🛹','🛼','🚏','🛣️','🛤️','🛢️','⛽','🛞','🚨','🚥','🚦','🛑','🚧','⚓','🛟','⛵','🛶','🚤','🛳️','⛴️','🛥️','🚢','✈️','🛩️','🛫','🛬','🪂','💺','🚁','🚟','🚠','🚡','🛰️','🚀','🛸','🛎️','🧳','⌛','⏳','⌚','⏰','⏱️','⏲️','🕰️','🕛','🕧','🕐','🕜','🕑','🕝','🕒','🕞','🕓','🕟','🕔','🕠','🕕','🕡','🕖','🕢','🕗','🕣','🕘','🕤','🕙','🕥','🕚','🕦','🌑','🌒','🌓','🌔','🌕','🌖','🌗','🌘','🌙','🌚','🌛','🌜','🌡️','☀️','🌝','🌞','🪐','⭐','🌟','🌠','🌌','☁️','⛅','⛈️','🌤️','🌥️','🌦️','🌧️','🌨️','❄️','🌬️','💨','🌪️','🌫️','🌈','☔','⚡','❄️','☃️','⛄','☄️','🔥','💧','�',
  ];

  final List<(String, String, String)> _tracks = const [
    (
      "Chill wave",
      "Lo-Fi Collective",
      "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
    ),
    (
      "Sunset drive",
      "Indie Beats",
      "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
    ),
    (
      "Night city",
      "Synth Lines",
      "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
    ),
  ];

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickMusic() async {
    final theme = Theme.of(context);

    final previewPlayer = AudioPlayer();
    try {
      String query = '';
      String? playingUrl;
      bool isLoading = false;

      final result = await showModalBottomSheet<(String, String, String)?>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final q = query.trim().toLowerCase();
              final filtered = q.isEmpty
                  ? _tracks
                  : _tracks.where((t) {
                      return t.$1.toLowerCase().contains(q) ||
                          t.$2.toLowerCase().contains(q);
                    }).toList();

              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Add music',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: TextField(
                          onChanged: (v) => setSheetState(() => query = v),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(IOSIcons.search),
                            hintText: 'Search music',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Flexible(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('No results'),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final t = filtered[index];
                                  final isPlaying = playingUrl == t.$3;
                                  return ListTile(
                                    leading: IconButton(
                                      icon: isLoading && isPlaying
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(
                                              isPlaying
                                                  ? IOSIcons.pause
                                                  : IOSIcons.play,
                                            ),
                                      onPressed: () async {
                                        if (isLoading) return;
                                        try {
                                          if (isPlaying) {
                                            await previewPlayer.pause();
                                            setSheetState(() {
                                              playingUrl = null;
                                            });
                                            return;
                                          }

                                          setSheetState(() => isLoading = true);
                                          await previewPlayer.stop();
                                          await previewPlayer.setUrl(t.$3);
                                          await previewPlayer.play();
                                          setSheetState(() {
                                            playingUrl = t.$3;
                                          });
                                        } catch (_) {
                                          setSheetState(() {
                                            playingUrl = null;
                                          });
                                          ScaffoldMessenger.of(ctx)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Failed to preview this track.'),
                                            ),
                                          );
                                        } finally {
                                          setSheetState(() => isLoading = false);
                                        }
                                      },
                                    ),
                                    title: Text(t.$1),
                                    subtitle: Text(t.$2),
                                    onTap: () async {
                                      await previewPlayer.stop();
                                      if (ctx.mounted) {
                                        Navigator.of(ctx).pop(t);
                                      }
                                    },
                                  );
                                },
                              ),
                      ),
                      if (playingUrl != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                          child: Row(
                            children: [
                              const Icon(IOSIcons.musicNote, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Previewing...',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await previewPlayer.stop();
                                  setSheetState(() => playingUrl = null);
                                },
                                child: const Text('Stop'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (result == null) return;
      setState(() {
        _musicTitle = result.$1;
        _musicArtist = result.$2;
        _musicUrl = result.$3;
      });
    } finally {
      await previewPlayer.dispose();
    }
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedEmoji == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some text or an emoji')),
      );
      return;
    }

    final me = AuthService.instance.currentUser;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await UserStatusService.instance.createStatus(
        userId: me.id,
        username: me.username,
        photoUrl: me.photoUrl,
        text: text,
        emoji: _selectedEmoji,
        musicTitle: _musicTitle,
        musicArtist: _musicArtist,
        musicUrl: _musicUrl,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status shared!')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to share status: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? theme.appBarTheme.backgroundColor : Colors.white,
        foregroundColor: isDark ? theme.appBarTheme.foregroundColor : Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(IOSIcons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Share Status'),
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Share'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFE8BCD), Color(0xFF8D5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedEmoji != null)
                          Text(
                            _selectedEmoji!,
                            style: const TextStyle(fontSize: 48),
                          ),
                        if (_textController.text.isNotEmpty)
                          Text(
                            _textController.text,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        if (_musicTitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    IOSIcons.musicNote,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '$_musicTitle • $_musicArtist',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_selectedEmoji == null &&
                            _textController.text.isEmpty &&
                            _musicTitle == null)
                          Text(
                            'Your status will appear here',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Text input
                  TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    maxLines: 3,
                    maxLength: 140,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Full iOS emoji picker
                  Text(
                    'Add Emoji',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: GridView.builder(
                      scrollDirection: Axis.horizontal,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _quickEmojis.length,
                      itemBuilder: (context, index) {
                        final emoji = _quickEmojis[index];
                        final isSelected = _selectedEmoji == emoji;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedEmoji = isSelected ? null : emoji;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withOpacity(0.15)
                                  : theme.colorScheme.surface,
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.dividerColor,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Music selection
                  Text(
                    'Add Music',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_musicTitle != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              IOSIcons.musicNote,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _musicTitle!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_musicArtist != null)
                                  Text(
                                    _musicArtist!,
                                    style: theme.textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(IOSIcons.close),
                            onPressed: () {
                              setState(() {
                                _musicTitle = null;
                                _musicArtist = null;
                                _musicUrl = null;
                              });
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _pickMusic,
                      icon: const Icon(IOSIcons.musicNote),
                      label: const Text('Add music (optional)'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
