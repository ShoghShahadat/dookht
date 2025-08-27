// FILE: lib/main.dart
// (English comments for code clarity)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus/nexus.dart' hide ThemeProviderService;
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
import 'modules/persistence/persistence_module.dart';
import 'modules/theming/theming_module.dart';
import 'modules/theming/theme_provider.dart';
import 'modules/ui/main_screen_module.dart';
import 'modules/ui/rendering_system.dart';
import 'modules/ui/theme_selector/theme_selector_module.dart';
import 'modules/ui/view_manager/view_manager_module.dart';
import 'services/hive_storage_adapter.dart';

final GetIt services = GetIt.instance;

Future<void> _isolateInitializer() async {
  // --- FIX: Removed the problematic WidgetsFlutterBinding.ensureInitialized() ---
  // The Nexus framework handles the necessary plugin communication bindings internally.
  // We only need to initialize services that are safe to run in a background isolate.

  // Initialize Hive within the isolate as well, pointing to the same path.
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  await Hive.openBox(HiveStorageAdapter.boxName);

  registerCoreComponents();
  registerCustomComponents();

  // Register the HiveStorageAdapter for this isolate.
  services.registerSingleton<StorageAdapter>(HiveStorageAdapter());
  services.registerSingleton(ThemeProviderService());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for the main thread
  await Hive.initFlutter();
  await Hive.openBox(HiveStorageAdapter.boxName);

  registerCoreComponents();
  registerCustomComponents();

  // Register the HiveStorageAdapter for the main thread.
  services.registerSingleton<StorageAdapter>(HiveStorageAdapter());

  final rootIsolateToken = RootIsolateToken.instance;
  if (rootIsolateToken == null) {
    debugPrint("FATAL: Could not get RootIsolateToken.");
    return;
  }
  runApp(TailorAssistantApp(rootIsolateToken: rootIsolateToken));
}

class TailorAssistantApp extends StatelessWidget {
  final RootIsolateToken rootIsolateToken;
  const TailorAssistantApp({super.key, required this.rootIsolateToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دستیار تولیدی لباس',
      debugShowCheckedModeBanner: false,
      home: NexusWidget(
        renderingSystem: AppRenderingSystem(),
        isolateInitializer: _isolateInitializer,
        rootIsolateToken: rootIsolateToken,
        worldProvider: () {
          final world = NexusWorld();
          world.loadModule(InputModule());
          world.loadModule(PersistenceModule());
          world.loadModule(AppLifecycleModule());
          world.loadModule(ThemingModule());
          world.loadModule(MainScreenModule());
          world.loadModule(ThemeSelectorModule());
          world.loadModule(CustomerListModule());
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
