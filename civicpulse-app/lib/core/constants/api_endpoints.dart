import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiEndpoints {
  static const String _prefKey = 'custom_backend_base_url';
  static String _customBaseUrl = '';

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _customBaseUrl = saved.trim();
      }
    } catch (_) {}
  }

  static final List<void Function(String)> _listeners = [];

  static void addListener(void Function(String) listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function(String) listener) {
    _listeners.remove(listener);
  }

  static void setCustomBaseUrl(String url) {
    var clean = url.trim();
    if (clean.endsWith('/')) clean = clean.substring(0, clean.length - 1);
    if (!clean.endsWith('/api/v1') && !clean.contains('/api')) {
      clean = '$clean/api/v1';
    }
    _customBaseUrl = clean;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefKey, clean);
    }).catchError((_) {});
    for (final listener in List.of(_listeners)) {
      try {
        listener(clean);
      } catch (_) {}
    }
  }

  // Configurable base URL
  // Checks runtime override, compile-time variable, or falls back to host IP
  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) return _customBaseUrl;
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Default to PC Wi-Fi LAN IP (10.209.125.178) so physical devices work automatically
      return 'http://10.209.125.178:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  // Base host origin for static media attachments (e.g. http://10.0.2.2:8080)
  static String get baseOrigin {
    try {
      final uri = Uri.parse(baseUrl);
      return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    } catch (_) {
      return 'http://localhost:8080';
    }
  }

  // Resolves full URL for evidentiary photo attachments
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseOrigin$cleanPath';
  }

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String googleLogin = '/auth/google';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/users/me';

  // Issues endpoints
  static const String issues = '/issues';
  static const String nearbyIssues = '/issues/nearby';
  static String issueDetails(String id) => '/issues/$id';
  static String updateStatus(String id) => '/issues/$id/status';
  static String issueComments(String id) => '/issues/$id/comments';
  static String issueAttachments(String id) => '/issues/$id/attachments';
  static String issueUpvote(String id) => '/issues/$id/upvote';
  static String issueTimeline(String id) => '/issues/$id/timeline';

  // Intelligence endpoints
  static const String suggestDraft = '/intelligence/suggest';
  static String issueIntelligence(String id) => '/issues/$id/intelligence';
  static String reviewIntelligence(String id) => '/issues/$id/intelligence/review';

  // Categories & Wards
  static const String categories = '/categories';
  static const String wards = '/wards';

  // Notifications
  static const String notifications = '/notifications';
  static const String unreadNotificationsCount = '/notifications/unread-count';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
}
