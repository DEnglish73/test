import 'package:shared_preferences/shared_preferences.dart';

import 'sfx.dart';

/// Persisted player progress and settings, backed by shared_preferences.
abstract final class Progress {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // No persistence backend; progress lasts for the session only.
    }
    Sfx.muted = _prefs?.getBool('muted') ?? false;
  }

  static Set<int> get completed =>
      (_prefs?.getStringList('completed') ?? const [])
          .map(int.parse)
          .toSet();

  static bool isCompleted(int level) => completed.contains(level);

  /// A level is playable once the one before it has been beaten.
  static bool isUnlocked(int level) => level == 0 || isCompleted(level - 1);

  static Future<void> markCompleted(int level) async {
    final done = completed..add(level);
    final sorted = done.toList()..sort();
    await _prefs?.setStringList('completed', [for (final i in sorted) '$i']);
  }

  /// Best star rating (0-3) earned on a level.
  static int starsFor(int level) => _prefs?.getInt('stars_$level') ?? 0;

  static Future<void> setStars(int level, int stars) async {
    if (stars > starsFor(level)) {
      await _prefs?.setInt('stars_$level', stars);
    }
  }

  static Future<void> setMuted(bool value) async {
    Sfx.muted = value;
    await _prefs?.setBool('muted', value);
  }
}
