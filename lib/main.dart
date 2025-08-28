// FILE: lib/main.dart
// (English comments for code clarity)
// MODIFIED v2.0: MAJOR REFACTOR - Simplified the main entry point.
// - Removed manual Hive data loading (_loadPersistedRawData).
// - Removed the concept of the 'bootstrap_data' entity.
// - Persistence is now fully and correctly handled by the AppLifecycleSystem.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus/nexus.dart' hide ThemeProviderService;
import 'package:tailor_assistant/modules/method_management/method_management_module.dart';
import 'package:tailor_assistant/modules/pattern_methods/pattern_methods_module.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/visual_formula_editor_module.dart';

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

/// This function is now the single source of truth for setting up the logic isolate.
/// It registers services and components, which is all that's needed before the world starts.
Future<void> _isolateInitializer(String dbPath) async {
  // Initialize Hive within the isolate for background access.
  Hive.init(dbPath);
  await Hive.openBox(HiveStorageAdapter.boxName);

  // Register all custom data components so they can be deserialized from storage.
  registerCoreComponents();
  registerCustomComponents();

  // Register global services.
  services.registerSingleton<StorageAdapter>(HiveStorageAdapter());
  services.registerSingleton(ThemeProviderService());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get the path for the database, which is needed by both the main thread and the isolate.
  final appDocumentDir = await getApplicationDocumentsDirectory();
  final dbPath = appDocumentDir.path;

  // Initialize Hive on the main thread for the UI.
  await Hive.initFlutter(dbPath);

  // Register components on the main thread as well for the rendering system.
  registerCoreComponents();
  registerCustomComponents();

  final rootIsolateToken = RootIsolateToken.instance;
  if (rootIsolateToken == null) {
    debugPrint("FATAL: Could not get RootIsolateToken.");
    return;
  }

  runApp(TailorAssistantApp(
    rootIsolateToken: rootIsolateToken,
    dbPath: dbPath,
  ));
}

class TailorAssistantApp extends StatelessWidget {
  final RootIsolateToken rootIsolateToken;
  final String dbPath;

  const TailorAssistantApp({
    super.key,
    required this.rootIsolateToken,
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
        worldProvider: () {
          final world = NexusWorld();

          // The world is now created clean. AppLifecycleSystem will handle loading data.
          world.loadModule(InputModule());
          world.loadModule(
              AppLifecycleModule()); // This module now handles persistence
          world.loadModule(ThemingModule());
          world.loadModule(MainScreenModule());
          world.loadModule(ThemeSelectorModule());
          // Initialize with an empty list. AppLifecycleSystem will populate it from storage.
          world.loadModule(CustomerListModule(initialCustomers: const []));
          world.loadModule(AddCustomerFormModule());
          world.loadModule(ViewManagerModule());
          world.loadModule(CalculationPageModule());
          world.loadModule(CalculationModule());
          world.loadModule(
              PatternMethodsModule()); // This creates the default method if no saved data exists
          world.loadModule(MethodManagementModule());
          world.loadModule(VisualFormulaEditorModule());

          return world;
        },
      ),
    );
  }
}
