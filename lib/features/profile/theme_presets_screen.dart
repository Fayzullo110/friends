import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_themes.dart';

class ThemePresetsScreen extends StatefulWidget {
  const ThemePresetsScreen({super.key});

  @override
  State<ThemePresetsScreen> createState() => _ThemePresetsScreenState();
}

class _ThemePresetsScreenState extends State<ThemePresetsScreen> {
  bool _saving = false;

  Future<void> _applyPreset(AppThemePreset preset) async {
    if (_saving) return;
    setState(() {
      _saving = true;
    });
    try {
      await AuthService.instance.updateTheme(
        themeKey: preset.key,
        themeSeedColor: null,
      );
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
    final theme = Theme.of(context);
    final me = AuthService.instance.currentUser;
    final currentKey = (me?.themeKey ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme presets'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: me == null
          ? const Center(child: Text('Please log in to customize your theme.'))
          : ListView.separated(
              itemCount: AppThemes.presets.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: theme.colorScheme.onSurface.withOpacity(0.08),
              ),
              itemBuilder: (context, index) {
                final p = AppThemes.presets[index];
                final selected = p.key == currentKey ||
                    (currentKey.isEmpty && p.key == AppThemes.defaultKey);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: p.seedColor,
                  ),
                  title: Text(p.label),
                  trailing: selected
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  onTap: _saving ? null : () => _applyPreset(p),
                );
              },
            ),
    );
  }
}
