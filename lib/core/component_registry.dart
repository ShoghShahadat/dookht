import 'package:nexus/nexus.dart';

// Import all custom serializable components from the project.
import '../modules/customers/components/customer_component.dart';
import '../modules/ui/view_manager/view_manager_component.dart';

/// Registers all custom serializable components for this application.
/// This function must be called in both the main and the logic isolates.
void registerCustomComponents() {
  final registry = ComponentFactoryRegistry.I;

  // Register each custom component with its unique type name and a factory function.
  registry.register(
    'CustomerComponent',
    (json) => CustomerComponent.fromJson(json),
  );

  registry.register(
    'ViewStateComponent',
    (json) => ViewStateComponent.fromJson(json),
  );

  // Add any new serializable components here in the future.
}
