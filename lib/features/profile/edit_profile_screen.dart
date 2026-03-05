import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../theme/ios_icons.dart';
import '../../theme/app_themes.dart';
import '../../widgets/safe_network_image.dart';
import '../chat/gif_picker_sheet.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  String? _photoUrl;
  String? _backgroundImageUrl;
  String? _themeKey;
  int? _themeSeedColor;
  bool _isSaving = false;
  bool _uploadingAvatar = false;
  bool _uploadingBackground = false;

  bool _isVideoUrl(String url) {
    final u = url.trim().toLowerCase();
    return u.endsWith('.mp4') ||
        u.endsWith('.mov') ||
        u.endsWith('.m4v') ||
        u.endsWith('.webm');
  }

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _photoUrl = widget.user.photoUrl;
    _backgroundImageUrl = widget.user.backgroundImageUrl;
    _themeKey = widget.user.themeKey;
    _themeSeedColor = widget.user.themeSeedColor;
  }

  Future<void> _setTheme({required String? key, required int? seedColor}) async {
    setState(() {
      _themeKey = key;
      _themeSeedColor = seedColor;
    });
    if (_isSaving || _uploadingAvatar || _uploadingBackground) return;
    try {
      setState(() {
        _isSaving = true;
      });

      await AuthService.instance.updateTheme(
        themeKey: key,
        themeSeedColor: seedColor,
      );

      if (!mounted) return;
      setState(() {
        _themeKey = key;
        _themeSeedColor = seedColor;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update theme: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickCustomThemeColor() async {
    if (_isSaving || _uploadingAvatar || _uploadingBackground) return;

    final initial = (_themeKey == AppThemes.customKey && _themeSeedColor != null)
        ? Color(_themeSeedColor!)
        : AppThemes.seedFor(
            themeKey: _themeKey,
            themeSeedColor: _themeSeedColor,
          );

    Color selected = initial;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a theme color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selected,
              onColorChanged: (c) {
                selected = c;
              },
              enableAlpha: false,
              labelTypes: const <ColorLabelType>[],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Use'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;
    await _setTheme(key: AppThemes.customKey, seedColor: selected.value);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (_isSaving || _uploadingAvatar || _uploadingBackground) return;
    try {
      setState(() {
        _uploadingAvatar = true;
      });
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        if (mounted) {
          setState(() {
            _uploadingAvatar = false;
          });
        }
        return;
      }

      final bytes = await picked.readAsBytes();
      final res = await AuthService.instance.api.uploadFile(
        path: '/api/uploads',
        bytes: bytes,
        filename: picked.name,
      );
      final url = (res['url'] as String?) ?? '';
      if (url.isEmpty) throw Exception('Upload failed');

      await AuthService.instance.api.patchNoContent(
        '/api/users/me',
        body: {'photoUrl': url},
      );

      if (!mounted) return;
      setState(() {
        _photoUrl = url;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update avatar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _pickBackground() async {
    if (_isSaving || _uploadingAvatar || _uploadingBackground) return;
    try {
      setState(() {
        _uploadingBackground = true;
      });
      final choice = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_outlined),
                  title: const Text('Image'),
                  onTap: () => Navigator.of(ctx).pop('image'),
                ),
                ListTile(
                  leading: const Icon(Icons.gif_box_outlined),
                  title: const Text('GIF'),
                  onTap: () => Navigator.of(ctx).pop('gif'),
                ),
                ListTile(
                  leading: const Icon(Icons.videocam_outlined),
                  title: const Text('Short video (max 5s)'),
                  onTap: () => Navigator.of(ctx).pop('video'),
                ),
                ListTile(
                  leading: const Icon(IOSIcons.close),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          );
        },
      );

      if (choice == null) return;

      if (choice == 'gif') {
        final selectedUrl = await showModalBottomSheet<String?>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (ctx) {
            return SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.7,
              child: GifPickerSheet(
                onSelected: (gif) {
                  Navigator.of(ctx).pop(gif.originalUrl);
                },
              ),
            );
          },
        );

        if (selectedUrl == null || selectedUrl.trim().isEmpty) return;

        await AuthService.instance.api.patchNoContent(
          '/api/users/me',
          body: {'backgroundImageUrl': selectedUrl.trim()},
        );

        if (!mounted) return;
        setState(() {
          _backgroundImageUrl = selectedUrl.trim();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Background updated.')),
        );
        return;
      }

      final picker = ImagePicker();
      XFile? picked;
      if (choice == 'image') {
        picked = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          maxHeight: 800,
          imageQuality: 85,
        );
      } else if (choice == 'video') {
        picked = await picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(seconds: 5),
        );
      }

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final res = await AuthService.instance.api.uploadFile(
        path: '/api/uploads',
        bytes: bytes,
        filename: picked.name,
      );
      final url = (res['url'] as String?) ?? '';
      if (url.isEmpty) throw Exception('Upload failed');

      await AuthService.instance.api.patchNoContent(
        '/api/users/me',
        body: {'backgroundImageUrl': url},
      );

      if (!mounted) return;
      setState(() {
        _backgroundImageUrl = url;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            choice == 'video'
                ? 'Background video updated.'
                : 'Background image updated.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update background: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingBackground = false;
        });
      }
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty.')),
      );
      return;
    }

    final isChanged = username != widget.user.username ||
        bio != (widget.user.bio ?? '') ||
        _photoUrl != widget.user.photoUrl ||
        _backgroundImageUrl != widget.user.backgroundImageUrl;

    if (!isChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await AuthService.instance.api.patchJson(
        '/api/users/me',
        {
          'username': username,
          'bio': bio,
          'photoUrl': _photoUrl,
          'backgroundImageUrl': _backgroundImageUrl,
        },
        (json) => AppUser.fromJson(json),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Avatar with edit button
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: ClipOval(
                    child: (_photoUrl != null && _photoUrl!.trim().isNotEmpty)
                        ? SafeNetworkImage(
                            url: _photoUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Icon(
                              IOSIcons.person,
                              size: 40,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: (_isSaving || _uploadingAvatar || _uploadingBackground)
                        ? null
                        : _pickAvatar,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Change profile photo',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            // Background image preview
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: (_backgroundImageUrl != null &&
                        _backgroundImageUrl!.trim().isNotEmpty)
                    ? _EditProfileBackgroundPreview(
                        url: _backgroundImageUrl!,
                        isVideo: _isVideoUrl(_backgroundImageUrl!),
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              IOSIcons.image,
                              color: Colors.grey[600],
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add background image',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: (_isSaving || _uploadingAvatar || _uploadingBackground)
                  ? null
                  : _pickBackground,
              child: Text(
                _backgroundImageUrl != null && _backgroundImageUrl!.isNotEmpty
                    ? 'Change background image'
                    : 'Add background image',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Theme
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Theme',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final p in AppThemes.presets)
                  ChoiceChip(
                    label: Text(p.label),
                    selected: (_themeKey ?? AppThemes.defaultKey) == p.key,
                    onSelected: (_isSaving || _uploadingAvatar || _uploadingBackground)
                        ? null
                        : (_) {
                            _setTheme(
                              key: p.key,
                              seedColor: null,
                            );
                          },
                    avatar: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: p.seedColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Custom',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: (_isSaving || _uploadingAvatar || _uploadingBackground)
                    ? null
                    : _pickCustomThemeColor,
                icon: const Icon(Icons.color_lens_outlined, size: 18),
                label: const Text('Pick custom color'),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in const <Color>[
                  Color(0xFF8D5CF6),
                  Color(0xFFFE8BCD),
                  Color(0xFFD4943A),
                  Color(0xFF22C55E),
                  Color(0xFF06B6D4),
                  Color(0xFF111827),
                ])
                  GestureDetector(
                    onTap: (_isSaving || _uploadingAvatar || _uploadingBackground)
                        ? null
                        : () {
                            _setTheme(
                              key: AppThemes.customKey,
                              seedColor: c.value,
                            );
                          },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ((_themeKey == AppThemes.customKey) && _themeSeedColor == c.value)
                              ? theme.colorScheme.onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ((_themeKey == AppThemes.customKey) && _themeSeedColor == c.value)
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            // Form fields
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 40),
            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _EditProfileBackgroundPreview extends StatefulWidget {
  final String url;
  final bool isVideo;

  const _EditProfileBackgroundPreview({
    required this.url,
    required this.isVideo,
  });

  @override
  State<_EditProfileBackgroundPreview> createState() =>
      _EditProfileBackgroundPreviewState();
}

class _EditProfileBackgroundPreviewState
    extends State<_EditProfileBackgroundPreview> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _controller = c;
      c.setLooping(true);
      c.setVolume(0);
      c.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        c.play();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _EditProfileBackgroundPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url == widget.url && oldWidget.isVideo == widget.isVideo) {
      return;
    }

    _controller?.dispose();
    _controller = null;

    if (widget.isVideo) {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _controller = c;
      c.setLooping(true);
      c.setVolume(0);
      c.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        c.play();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVideo) {
      return SafeNetworkImage(
        url: widget.url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 120,
      );
    }

    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return Container(color: Colors.black12);
    }

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      ),
    );
  }
}
