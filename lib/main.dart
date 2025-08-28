// FILE: lib/main.dart
// (English comments for code clarity)
// MODIFIED v4.0: Replaced the default AnimationSystem with the new, robust
// FixedAnimationSystem to ensure smooth and correct transition animations.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus/nexus.dart' hide ThemeProviderService;
import 'package:tailor_assistant/core/fixed_animation_system.dart';
import 'package:tailor_assistant/modules/method_management/method_management_module.dart';
import 'package:tailor_assistant/modules/pattern_methods/pattern_methods_module.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tailor_assistant/modules/ui/transitions/transition_system.dart';
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
          world.loadModule(VisualFormulaEditorModule());

          // Add the core systems for transitions and animations
          world.addSystem(TransitionSystem());
          world.addSystem(FixedAnimationSystem()); // CRITICAL FIX

          return world;
        },
      ),
    );
  }
}
