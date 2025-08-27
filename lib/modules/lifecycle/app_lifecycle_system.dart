// FILE: lib/modules/lifecycle/app_lifecycle_system.dart
// (English comments for code clarity)
// This system is now responsible for saving data.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:nexus/nexus.dart' hide AppLifecycleEvent;
import 'package:nexus/src/events/app_lifecycle_event.dart';
import 'package:tailor_assistant/services/hive_storage_adapter.dart';

/// A system that listens for application lifecycle changes and triggers
/// actions, such as saving data when the app goes into the background.
class AppLifecycleSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<AppLifecycleEvent>(_onLifecycleChange);
    // We also listen to the manual SaveDataEvent for immediate saves.
    listen<SaveDataEvent>((_) => _saveAllData());
  }

  void _onLifecycleChange(AppLifecycleEvent event) {
    final isLosingFocus = event.status == AppLifecycleStatus.paused ||
        event.status == AppLifecycleStatus.detached ||
        event.status == AppLifecycleStatus.hidden;

    if (isLosingFocus) {
      _saveAllData();
    }
  }

  Future<void> _saveAllData() async {
    debugPrint("💾 [Manual Save] ➡️ Initiating save...");

    // Since this system runs in the isolate, it can safely access Hive.
    final box = Hive.box(HiveStorageAdapter.boxName);

    final entitiesToSave =
        world.entities.values.where((e) => e.has<PersistenceComponent>());

    if (entitiesToSave.isEmpty) {
      debugPrint("💾 [Manual Save] 🧐 No persistent entities found to save.");
      return;
    }

    for (final entity in entitiesToSave) {
      final key = entity.get<PersistenceComponent>()!.storageKey;
      final entityJson = <String, dynamic>{};

      for (final component in entity.allComponents) {
        if (component is SerializableComponent) {
          entityJson[component.runtimeType.toString()] =
              (component as SerializableComponent).toJson();
        }
      }
      // Use the 'nexus_' prefix for consistency.
      await box.put('nexus_$key', jsonEncode(entityJson));
      debugPrint("💾 [Manual Save] ✅ Saved Entity with key '$key'.");
    }
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
