import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kLocalePreferenceKey = 'civicpulse_locale';

/// Provides the current app locale, persisted to SharedPreferences.
/// `null` means "follow device locale" (system default).
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    _loadPersistedLocale();
    return null; // Start with system default
  }

  Future<void> _loadPersistedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_kLocalePreferenceKey);
      if (savedCode != null && savedCode.isNotEmpty) {
        state = Locale(savedCode);
      }
    } catch (_) {
      // Default to system
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_kLocalePreferenceKey);
      } else {
        await prefs.setString(_kLocalePreferenceKey, locale.languageCode);
      }
    } catch (_) {}
  }

  /// Convenience: set by language code string ('en', 'hi', or null for system)
  Future<void> setLocaleByCode(String? code) async {
    await setLocale(code != null ? Locale(code) : null);
  }
}
