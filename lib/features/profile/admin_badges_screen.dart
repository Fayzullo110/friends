import 'package:flutter/material.dart';

import '../../services/admin_user_service.dart';

class AdminBadgesScreen extends StatefulWidget {
  const AdminBadgesScreen({super.key});

  @override
  State<AdminBadgesScreen> createState() => _AdminBadgesScreenState();
}

class _AdminBadgesScreenState extends State<AdminBadgesScreen> {
  final TextEditingController _userId = TextEditingController();
  bool _saving = false;

  bool _isOfficial = false;
  String _badgeType = 'none';

  @override
  void dispose() {
    _userId.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final id = _userId.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID is required')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await AdminUserService.instance.updateBadge(
        userId: id,
        isOfficial: _isOfficial,
        badgeType: _badgeType == 'none' ? '' : _badgeType,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: badges'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _userId,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Target user ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Official / Verified'),
            value: _isOfficial,
            onChanged: _saving
                ? null
                : (v) {
                    setState(() {
                      _isOfficial = v;
                    });
                  },
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Badge type'),
            subtitle: Text(_badgeType),
            trailing: const Icon(Icons.chevron_right),
            onTap: _saving
                ? null
                : () async {
                    final next = await showModalBottomSheet<String>(
                      context: context,
                      showDragHandle: true,
                      builder: (ctx) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: const Text('None'),
                                onTap: () => Navigator.of(ctx).pop('none'),
                              ),
                              ListTile(
                                title: const Text('Owner'),
                                onTap: () => Navigator.of(ctx).pop('owner'),
                              ),
                              ListTile(
                                title: const Text('Creator'),
                                onTap: () => Navigator.of(ctx).pop('creator'),
                              ),
                              ListTile(
                                title: const Text('Brand'),
                                onTap: () => Navigator.of(ctx).pop('brand'),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        );
                      },
                    );
                    if (next == null) return;
                    setState(() {
                      _badgeType = next;
                    });
                  },
          ),
          const SizedBox(height: 12),
          const Text(
            'Note: Access is controlled by server-side admin allowlist (app.admin.userIds).',
          ),
        ],
      ),
    );
  }
}
