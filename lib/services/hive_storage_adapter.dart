// FILE: lib/services/hive_storage_adapter.dart
// (English comments for code clarity)

import 'dart:convert';
import 'package:nexus/nexus.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// A concrete implementation of the [StorageAdapter] interface that uses
/// the Hive package for fast and reliable local data persistence.
class HiveStorageAdapter implements StorageAdapter {
  // The name of the Hive box where all Nexus data will be stored.
  static const String boxName = 'nexus_storage';
  late final Box _box;

  HiveStorageAdapter() {
    _box = Hive.box(boxName);
  }

  @override
  Future<void> init() async {
    // Hive is initialized in main.dart before this adapter is created.
  }

  @override
  Future<Map<String, dynamic>?> load(String key) async {
    final data = _box.get(key);
    if (data != null) {
      // Data in Hive can be complex, but we expect a Map for our components.
      // We decode from JSON string to ensure type safety.
      return jsonDecode(data as String) as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<Map<String, Map<String, dynamic>>> loadAll() async {
    final allData = <String, Map<String, dynamic>>{};
    final keys = _box.keys;

    for (final key in keys) {
      if (key is String && key.startsWith('nexus_')) {
        final jsonString = _box.get(key) as String?;
        if (jsonString != null) {
          try {
            final dataMap = jsonDecode(jsonString) as Map<String, dynamic>;
            allData[key.replaceFirst('nexus_', '')] = dataMap;
          } catch (e) {
            print('[HiveStorageAdapter] Error decoding JSON for key $key: $e');
          }
        }
      }
    }
    return allData;
  }

  @override
  Future<void> save(String key, Map<String, dynamic> data) async {
    // We store the data as a JSON string to maintain compatibility
    // and ensure complex nested maps are handled correctly by Hive.
    final jsonString = jsonEncode(data);
    await _box.put(key, jsonString);
  }
}
