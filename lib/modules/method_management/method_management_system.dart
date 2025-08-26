import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'method_management_events.dart';

/// A system to handle the logic for creating, updating, and deleting pattern methods.
class MethodManagementSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<UpdatePatternMethodEvent>(_onUpdateMethod);
  }

  void _onUpdateMethod(UpdatePatternMethodEvent event) {
    final methodEntity = world.entities[event.methodId];
    if (methodEntity == null) {
      print(
          "Error: Could not find method with ID ${event.methodId} to update.");
      return;
    }

    final currentMethod = methodEntity.get<PatternMethodComponent>();
    if (currentMethod == null) return;

    // Create a new component with the updated data.
    final updatedMethod = PatternMethodComponent(
      methodId: currentMethod.methodId, // ID should not change
      name: event.newName,
      variables: event.newVariables,
      formulas: event.newFormulas,
    );

    // Replace the old component on the entity.
    methodEntity.add(updatedMethod);

    // Fire an event to save the changes to persistence.
    world.eventBus.fire(SaveDataEvent());

    print("Method '${event.newName}' updated successfully.");
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
