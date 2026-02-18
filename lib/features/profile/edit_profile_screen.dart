import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';

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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _photoUrl = widget.user.photoUrl;
    _backgroundImageUrl = widget.user.backgroundImageUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final res = await AuthService.instance.api.uploadFile(
        path: '/api/uploads',
        bytes: bytes,
        filename: picked.name,
      );
      final url = (res['url'] as String?) ?? '';
      if (url.isEmpty) throw Exception('Upload failed');

      if (!mounted) return;
      setState(() {
        _photoUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update avatar: $e')),
      );
    }
  }

  Future<void> _pickBackground() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final res = await AuthService.instance.api.uploadFile(
        path: '/api/uploads',
        bytes: bytes,
        filename: picked.name,
      );
      final url = (res['url'] as String?) ?? '';
      if (url.isEmpty) throw Exception('Upload failed');

      if (!mounted) return;
      setState(() {
        _backgroundImageUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update background: $e')),
      );
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
                  backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                      ? NetworkImage(_photoUrl!)
                      : null,
                  child: _photoUrl == null || _photoUrl!.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: theme.colorScheme.onPrimaryContainer,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickAvatar,
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
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[200],
                image: _backgroundImageUrl != null && _backgroundImageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_backgroundImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _backgroundImageUrl == null || _backgroundImageUrl!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'Add background image',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickBackground,
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
