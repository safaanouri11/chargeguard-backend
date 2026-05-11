// Cross-platform key/value storage. Wraps shared_preferences so the rest of
// the app does not care whether it is running on web, Android, or iOS.
import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<String?> get(String key) async {
    final p = await _ensure();
    return p.getString(key);
  }

  static Future<void> set(String key, String value) async {
    final p = await _ensure();
    await p.setString(key, value);
  }

  static Future<void> remove(String key) async {
    final p = await _ensure();
    await p.remove(key);
  }
}
