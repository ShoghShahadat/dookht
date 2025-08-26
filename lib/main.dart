import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for RootIsolateToken
import 'package:get_it/get_it.dart';
// Hide the conflicting name from the nexus package to resolve ambiguity.
import 'package:nexus/nexus.dart' hide ThemeProviderService;
import 'package:shared_preferences/shared_preferences.dart';

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
import 'services/shared_prefs_storage_adapter.dart';

final GetIt services = GetIt.instance;

Future<void> _isolateInitializer() async {
  registerCoreComponents();
  registerCustomComponents();
  final prefs = await SharedPreferences.getInstance();
  services.registerSingleton<StorageAdapter>(SharedPrefsStorageAdapter(prefs));
  services.registerSingleton(ThemeProviderService());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerCoreComponents();
  registerCustomComponents();
  final prefs = await SharedPreferences.getInstance();
  services.registerSingleton<StorageAdapter>(SharedPrefsStorageAdapter(prefs));
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
          world.loadModule(AppLifecycleModule()); // Add the lifecycle module
          world.loadModule(ThemingModule());
          world.loadModule(MainScreenModule());
          world.loadModule(ThemeSelectorModule());
          world.loadModule(CustomerListModule());
          world.loadModule(AddCustomerFormModule());
          world.loadModule(ViewManagerModule());
          world.loadModule(CalculationPageModule());
          world.loadModule(CalculationModule());
          return world;
        },
      ),
    );
  }
}
