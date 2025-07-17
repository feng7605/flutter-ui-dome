import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/localization/app_localization.dart';

/// Settings page for the application
class SettingsPage extends ConsumerWidget {
  /// Creates a new instance of [SettingsPage]
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeManager = ref.read(themeManagerProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final localization = ref.read(localizationProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings')),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(context.tr('dark_mode')),
            subtitle: Text(_getThemeModeName(context, currentThemeMode)),
            leading: const Icon(Icons.color_lens),
            onTap: () {
              _showThemeSelectionDialog(context, ref, currentThemeMode);
            },
          ),
          const Divider(),
          ListTile(
            title: Text(context.tr('language')),
            subtitle: Text(_getLanguageName(currentLocale)),
            leading: const Icon(Icons.language),
            onTap: () {
              _showLanguageSelectionDialog(context, ref, currentLocale);
            },
          ),
          const Divider(),
          ListTile(
            title: Text(context.tr('app_information')),
            leading: const SizedBox(width: 24),
          ),
          ListTile(
            title: Text(context.tr('version')),
            subtitle: const Text('1.0.0'),
            leading: const SizedBox(width: 24),
          ),
          ListTile(
            title: Text(context.tr('build_number')),
            subtitle: const Text('1'),
            leading: const SizedBox(width: 24),
          ),
          ListTile(
            title: Text(context.tr('copyright')),
            subtitle: const Text(' 2024 Flutter Frame'),
            leading: const SizedBox(width: 24),
          ),
        ],
      ),
    );
  }

  void _showThemeSelectionDialog(
      BuildContext context, WidgetRef ref, ThemeMode currentThemeMode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr('select_theme')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: Text(context.tr('system_theme')),
                value: ThemeMode.system,
                groupValue: currentThemeMode,
                onChanged: (value) {
                  ref.read(themeManagerProvider).setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(context.tr('light_mode')),
                value: ThemeMode.light,
                groupValue: currentThemeMode,
                onChanged: (value) {
                  ref.read(themeManagerProvider).setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(context.tr('dark_mode')),
                value: ThemeMode.dark,
                groupValue: currentThemeMode,
                onChanged: (value) {
                  ref.read(themeManagerProvider).setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(context.tr('cancel')),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageSelectionDialog(
      BuildContext context, WidgetRef ref, Locale currentLocale) {
    showDialog(
      context: context,
      builder: (context) {
        final localization = ref.read(localizationProvider);
        
        return AlertDialog(
          title: Text(context.tr('select_language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<Locale>(
                title: Text(context.tr('language_en')),
                value: const Locale('en', 'US'),
                groupValue: currentLocale,
                onChanged: (value) async {
                  await localization.setLocale(value!);
                  
                  // 强制更新 UI
                  ref.invalidate(localeProvider);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('language_changed')),
                      ),
                    );
                  }
                },
              ),
              RadioListTile<Locale>(
                title: Text(context.tr('language_zh')),
                value: const Locale('zh', 'CN'),
                groupValue: currentLocale,
                onChanged: (value) async {
                  await localization.setLocale(value!);
                  
                  // 强制更新 UI
                  ref.invalidate(localeProvider);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('language_changed')),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(context.tr('cancel')),
            ),
          ],
        );
      },
    );
  }

  String _getThemeModeName(BuildContext context, ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return context.tr('system_theme');
      case ThemeMode.light:
        return context.tr('light_mode');
      case ThemeMode.dark:
        return context.tr('dark_mode');
    }
  }

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      default:
        return 'English';
    }
  }
}
