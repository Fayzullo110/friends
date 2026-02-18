import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool _sending = false;

  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSend() async {
    final me = AuthService.instance.currentUser;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be signed in.'),
        ),
      );
      return;
    }

    final oldPassword = _oldController.text;
    final newPassword = _newController.text;
    final confirmPassword = _confirmController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Change password?'),
          content: const Text('Your password will be updated immediately.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Change'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await _changePassword(oldPassword: oldPassword, newPassword: newPassword);
  }

  Future<void> _changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    setState(() {
      _sending = true;
    });

    try {
      await AuthService.instance.api.postNoContent(
        '/api/users/me/change-password',
        body: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
      _oldController.clear();
      _newController.clear();
      _confirmController.clear();
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to change password. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = AuthService.instance.currentUser;
    final email = me?.email ?? 'Unknown email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your current password and a new password.',
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined),
              title: Text(email),
              subtitle: const Text('This account will be updated.'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _oldController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current password',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _sending ? null : _confirmAndSend,
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Change password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
