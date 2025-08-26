// FILE: lib/modules/method_management/method_management_system.dart
// (English comments for code clarity)
// REVERTED to its original, clean state.

import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'method_management_events.dart';

/// A system to handle the logic for creating, updating, and deleting pattern methods.
class MethodManagementSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<UpdatePatternMethodEvent>(_onUpdateMethod);
    listen<CreatePatternMethodEvent>(_onCreateMethod);
    listen<DeletePatternMethodEvent>(_onDeleteMethod);
  }

  void _onUpdateMethod(UpdatePatternMethodEvent event) {
    final methodEntity = world.entities[event.methodId];
    if (methodEntity == null) return;

    final currentMethod = methodEntity.get<PatternMethodComponent>();
    if (currentMethod == null) return;

    final updatedMethod = PatternMethodComponent(
      methodId: currentMethod.methodId,
      name: event.newName,
      variables: event.newVariables,
      formulas: event.newFormulas,
    );
    methodEntity.add(updatedMethod);
    world.eventBus.fire(SaveDataEvent());
  }

  void _onCreateMethod(CreatePatternMethodEvent event) {
    final newMethodId = 'method_${DateTime.now().millisecondsSinceEpoch}';
    final newMethodEntity = Entity()
      ..add(TagsComponent({'pattern_method'}))
      ..add(LifecyclePolicyComponent(isPersistent: true))
      ..add(PatternMethodComponent(
        methodId: newMethodId,
        name: 'متد جدید',
        variables: [
          DynamicVariable(key: 'ease', label: 'میزان آزادی', defaultValue: 1.0)
        ],
        formulas: [],
      ))
      ..add(PersistenceComponent('method_$newMethodId'));

    world.addEntity(newMethodEntity);
    world.eventBus.fire(SaveDataEvent());

    // Immediately navigate to the edit page for the new method.
    world.eventBus.fire(ShowEditMethodEvent(newMethodEntity.id));
  }

  void _onDeleteMethod(DeletePatternMethodEvent event) {
    final methodEntity = world.entities[event.methodId];
    if (methodEntity == null) return;

    world.removeEntity(event.methodId);
    world.eventBus.fire(SaveDataEvent());
    print("Method with ID ${event.methodId} deleted.");
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
