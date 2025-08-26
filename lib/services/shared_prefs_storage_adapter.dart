import 'dart:convert';
import 'package:nexus/nexus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A concrete implementation of the [StorageAdapter] interface that uses
/// the shared_preferences package for local data persistence.
///
/// This class handles the serialization of component data into JSON strings
/// for storage and deserialization upon loading.
class SharedPrefsStorageAdapter implements StorageAdapter {
  final SharedPreferences _prefs;

  SharedPrefsStorageAdapter(this._prefs);

  @override
  Future<void> init() async {
    // SharedPreferences is initialized in main.dart, so nothing to do here.
  }

  @override
  Future<Map<String, dynamic>?> load(String key) async {
    final jsonString = _prefs.getString(key);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<Map<String, Map<String, dynamic>>> loadAll() async {
    final allData = <String, Map<String, dynamic>>{};
    final keys = _prefs.getKeys();

    for (final key in keys) {
      // We only load keys that we know belong to our app's persistence system.
      if (key.startsWith('nexus_')) {
        final data = await load(key);
        if (data != null) {
          allData[key.replaceFirst('nexus_', '')] = data;
        }
      }
    }
    return allData;
  }

  @override
  Future<void> save(String key, Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    await _prefs.setString(key, jsonString);
  }
}
