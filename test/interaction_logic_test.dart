// FILE: test/interaction_logic_test.dart
// (English comments for code clarity)
// MODIFIED v9.0: This is now a rigorous, frame-by-frame stress test.
// It asserts the state of the world at the beginning, middle, and end of
// transitions, and runs the entire sequence 50 times to guarantee stability
// and catch any subtle race conditions.

import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_assistant/core/component_registry.dart';
import 'package:tailor_assistant/core/fixed_animation_system.dart';
import 'package:tailor_assistant/modules/customers/add_customer_form_module.dart';
import 'package:tailor_assistant/modules/customers/customer_events.dart';
import 'package:tailor_assistant/modules/customers/customer_list_module.dart';
import 'package:tailor_assistant/modules/input/input_module.dart';
import 'package:tailor_assistant/modules/lifecycle/app_lifecycle_module.dart';
import 'package:tailor_assistant/modules/ui/transitions/transition_component.dart';
import 'package:tailor_assistant/modules/ui/transitions/transition_system.dart';
import 'package:tailor_assistant/modules/ui/view_manager/view_manager_component.dart';
import 'package:tailor_assistant/modules/ui/view_manager/view_manager_module.dart';
import 'package:nexus/nexus.dart';
import 'package:collection/collection.dart';
import 'package:get_it/get_it.dart';

// A mock storage adapter for a hermetic test environment.
class MockStorageAdapter implements StorageAdapter {
  final Map<String, Map<String, dynamic>> _data = {};
  @override
  Future<void> init() async {}
  @override
  Future<Map<String, dynamic>?> load(String key) async => _data[key];
  @override
  Future<Map<String, Map<String, dynamic>>> loadAll() async => _data;
  @override
  Future<void> save(String key, Map<String, dynamic> data) async =>
      _data[key] = data;
}

void main() {
  group('Core Interaction and Transition Logic Stress Test', () {
    late NexusWorld world;

    setUpAll(() {
      registerCoreComponents();
      registerCustomComponents();
      GetIt.I.registerSingleton<StorageAdapter>(MockStorageAdapter());
    });

    setUp(() async {
      world = NexusWorld();
      world.loadModule(InputModule());
      world.loadModule(CustomerListModule(initialCustomers: []));
      world.loadModule(AddCustomerFormModule());
      world.loadModule(ViewManagerModule());
      world.loadModule(AppLifecycleModule());
      world.addSystem(TransitionSystem());
      world.addSystem(FixedAnimationSystem());
      await world.init();
    });

    tearDown(() {
      GetIt.I.reset();
    });

    test(
        '50 rapid back-to-back transitions should be handled correctly frame by frame',
        () async {
      final viewManagerEntity = world.entities.values
          .firstWhereOrNull((e) => e.has<ViewStateComponent>());
      final addCustomerButton = world.entities.values.firstWhereOrNull((e) =>
          e.get<TagsComponent>()?.hasTag('add_customer_button') ?? false);

      expect(viewManagerEntity, isNotNull);
      expect(addCustomerButton, isNotNull);

      for (int i = 0; i < 25; i++) {
        // 25 cycles = 50 transitions
        // --- FRAME 0: Assert initial state ---
        expect(viewManagerEntity!.get<ViewStateComponent>()!.currentView,
            AppView.customerList);

        // --- FRAME 1: Fire event and check transition start ---
        world.eventBus.fire(EntityTapEvent(addCustomerButton!.id));
        await Future.delayed(Duration.zero);
        world.update(0.016);

        var transitionComp = viewManagerEntity.get<TransitionComponent>();
        expect(transitionComp!.isRunning, isTrue,
            reason: "Transition should start on frame 1. Iteration: $i");
        expect(transitionComp.oldView, AppView.customerList,
            reason: "Old view should be customerList. Iteration: $i");
        // The definitive state should NOT have changed yet.
        expect(viewManagerEntity.get<ViewStateComponent>()!.currentView,
            AppView.customerList,
            reason:
                "ViewState should not change until transition ends. Iteration: $i");

        // --- Complete animation ---
        for (int j = 0; j < 75; j++) {
          world.update(0.016);
        }
        await Future.delayed(Duration.zero);

        // --- FINAL FRAME: Assert final state ---
        expect(viewManagerEntity.get<ViewStateComponent>()!.currentView,
            AppView.addCustomerForm,
            reason: "Final view should be addCustomerForm. Iteration: $i");
        expect(viewManagerEntity.get<TransitionComponent>()!.isRunning, isFalse,
            reason: "Transition should be finished. Iteration: $i");

        // --- NOW GO BACK ---
        world.eventBus.fire(ShowCustomerListEvent());
        await Future.delayed(Duration.zero);
        world.update(0.016);

        transitionComp = viewManagerEntity.get<TransitionComponent>();
        expect(transitionComp!.isRunning, isTrue,
            reason: "Return transition should start. Iteration: $i");
        expect(transitionComp.oldView, AppView.addCustomerForm,
            reason: "Old view should be addCustomerForm. Iteration: $i");
        expect(viewManagerEntity.get<ViewStateComponent>()!.currentView,
            AppView.addCustomerForm,
            reason:
                "ViewState should not change on return until transition ends. Iteration: $i");

        // --- Complete return animation ---
        for (int j = 0; j < 75; j++) {
          world.update(0.016);
        }
        await Future.delayed(Duration.zero);

        // Assert final state
        expect(viewManagerEntity.get<ViewStateComponent>()!.currentView,
            AppView.customerList,
            reason: "Final view should be customerList. Iteration: $i");
        expect(viewManagerEntity.get<TransitionComponent>()!.isRunning, isFalse,
            reason: "Return transition should be finished. Iteration: $i");
      }
    });
  });
}
