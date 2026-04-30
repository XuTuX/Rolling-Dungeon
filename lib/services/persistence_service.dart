import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:circle_war/game/auto_battle/models/meta_data.dart';

/// Handles persistent save/load of meta-progression data.
class PersistenceService {
  static const String _metaKey = 'meta_progress';

  /// Load meta progress from SharedPreferences.
  static Future<MetaProgressData> loadMeta() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_metaKey);
    if (raw == null) return MetaProgressData();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return MetaProgressData.fromJson(json);
    } catch (_) {
      return MetaProgressData();
    }
  }

  /// Save meta progress to SharedPreferences.
  static Future<void> saveMeta(MetaProgressData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_metaKey, jsonEncode(data.toJson()));
  }

  /// Reset all meta data (for testing/debug).
  static Future<void> resetMeta() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_metaKey);
  }
}
