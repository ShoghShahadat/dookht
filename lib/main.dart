// FILE: lib/main.dart
// (English comments for code clarity)
// FINAL, DEFINITIVE FIX v12: The root cause was a race condition where the
// GarbageCollectorSystem was deleting the bootstrapEntity before the
// LifecycleSystem could read from it. Adding a persistent LifecyclePolicyComponent
// to the bootstrapEntity solves this permanently.

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus/nexus.dart' hide ThemeProviderService;
import 'package:tailor_assistant/core/type_id_provider.dart';
import 'package:tailor_assistant/modules/method_management/method_management_module.dart';
import 'package:tailor_assistant/modules/pattern_methods/pattern_methods_module.dart';
import 'package:path_provider/path_provider.dart';

import 'core/component_registry.dart';
import 'modules/calculations/calculation_module.dart';
import 'modules/calculations/calculation_page_module.dart';
import 'modules/customers/add_customer_form_module.dart';
import 'modules/customers/customer_list_module.dart';
import 'modules/input/input_module.dart';
import 'modules/lifecycle/app_lifecycle_module.dart';
import 'modules/theming/theming_module.dart';
import 'modules/theming/theme_provider.dart';
import 'modules/ui/main_screen_module.dart';
import 'modules/ui/rendering_system.dart';
import 'modules/ui/theme_selector/theme_selector_module.dart';
import 'modules/ui/view_manager/view_manager_module.dart';
import 'services/hive_storage_adapter.dart';

final GetIt services = GetIt.instance;

Future<Map<String, Map<String, dynamic>>> _loadPersistedRawData() async {
  final Map<String, Map<String, dynamic>> loadedData = {};
  final box = await Hive.openBox(HiveStorageAdapter.boxName);

  if (box.isEmpty) {
    debugPrint("📦 [Manual Load] Hive box is empty.");
    await box.close();
    return loadedData;
  }

  debugPrint(
      "📦 [Manual Load] Found ${box.keys.length} items in Hive. Reading raw data...");

  for (var key in box.keys) {
    if (key is! String || !key.startsWith('nexus_')) continue;

    final jsonString = box.get(key) as String?;
    if (jsonString == null) continue;

    final storageKey = key.replaceFirst('nexus_', '');
    loadedData[storageKey] = jsonDecode(jsonString);
  }

  await box.close();
  debugPrint("📦 [Manual Load] ✅ Raw data reading complete. Box closed.");
  return loadedData;
}

Future<void> _isolateInitializer(String dbPath) async {
  Hive.init(dbPath);
  await Hive.openBox(HiveStorageAdapter.boxName);

  registerCoreComponents();
  registerCustomComponents();
  services.registerSingleton<StorageAdapter>(HiveStorageAdapter());
  services.registerSingleton(ThemeProviderService());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocumentDir = await getApplicationDocumentsDirectory();
  final dbPath = appDocumentDir.path;

  await Hive.initFlutter(dbPath);

  registerCoreComponents();
  registerCustomComponents();

  final persistedRawData = await _loadPersistedRawData();

  final rootIsolateToken = RootIsolateToken.instance;
  if (rootIsolateToken == null) {
    debugPrint("FATAL: Could not get RootIsolateToken.");
    return;
  }

  runApp(TailorAssistantApp(
    rootIsolateToken: rootIsolateToken,
    persistedRawData: persistedRawData,
    dbPath: dbPath,
  ));
}

class TailorAssistantApp extends StatelessWidget {
  final RootIsolateToken rootIsolateToken;
  final Map<String, Map<String, dynamic>> persistedRawData;
  final String dbPath;

  const TailorAssistantApp({
    super.key,
    required this.rootIsolateToken,
    required this.persistedRawData,
    required this.dbPath,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دستیار تولیدی لباس',
      debugShowCheckedModeBanner: false,
      home: NexusWidget(
        renderingSystem: AppRenderingSystem(),
        isolateInitializer: () => _isolateInitializer(dbPath),
        rootIsolateToken: rootIsolateToken,
        componentTypeIdProvider: appComponentTypeIdProvider,
        worldProvider: () {
          final world = NexusWorld();

          final bootstrapEntity = Entity()
            ..add(TagsComponent({'bootstrap_data'}))
            // THE FIX: Make the data carrier persistent to prevent garbage collection.
            ..add(LifecyclePolicyComponent(isPersistent: true))
            ..add(BlackboardComponent({'persistedRawData': persistedRawData}));
          world.addEntity(bootstrapEntity);

          world.loadModule(InputModule());
          world.loadModule(AppLifecycleModule());
          world.loadModule(ThemingModule());
          world.loadModule(MainScreenModule());
          world.loadModule(ThemeSelectorModule());
          world.loadModule(CustomerListModule(initialCustomers: const []));
          world.loadModule(AddCustomerFormModule());
          world.loadModule(ViewManagerModule());
          world.loadModule(CalculationPageModule());
          world.loadModule(CalculationModule());
          world.loadModule(PatternMethodsModule());
          world.loadModule(MethodManagementModule());
          return world;
        },
      ),
    );
  }
}
