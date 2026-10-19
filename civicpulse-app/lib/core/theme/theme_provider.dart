import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemePreferenceKey = 'civicpulse_theme_mode';

/// State notifier provider for dynamic theme switching & persistence.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadPersistedTheme();
    return ThemeMode.system;
  }

  Future<void> _loadPersistedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_kThemePreferenceKey);
      if (savedMode != null) {
        switch (savedMode) {
          case 'dark':
            state = ThemeMode.dark;
            break;
          case 'light':
            state = ThemeMode.light;
            break;
          case 'system':
          default:
            state = ThemeMode.system;
            break;
        }
      }
    } catch (_) {
      // Default to system
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
      };
      await prefs.setString(_kThemePreferenceKey, modeString);
    } catch (_) {}
  }

  /// Auto-selects theme mode for user on/after login based on their preference or system
  Future<void> applyUserThemePreference({String? preferredMode}) async {
    if (preferredMode == 'dark') {
      await setThemeMode(ThemeMode.dark);
    } else if (preferredMode == 'light') {
      await setThemeMode(ThemeMode.light);
    } else {
      // If unspecified or auto, sync with saved or system
      await _loadPersistedTheme();
    }
  }
}
