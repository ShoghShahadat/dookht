// FILE: packages/nexus/lib/nexus.dart

/// The main library for the Nexus framework.
library nexus;

// --- Core ---
export 'src/core/archetype.dart';
export 'src/core/component.dart';
export 'src/core/entity.dart';
export 'src/core/event_bus.dart';
export 'src/core/nexus_module.dart';
export 'src/core/nexus_world.dart';
export 'src/core/system.dart';
export 'src/core/providers/entity_provider.dart';
export 'src/core/providers/system_provider.dart';
export 'src/core/assemblers/entity_assembler.dart';
export 'src/core/logic/logic_function.dart';
export 'src/core/utils/equatable_mixin.dart';
export 'src/core/storage/storage_adapter.dart';
export 'src/core/utils/frequency.dart';

// --- GPU Compute API ---
export 'src/compute/gpu_buffer.dart';
export 'src/compute/gpu_system.dart';

// --- Services ---
export 'src/services/network/http_method.dart';
export 'src/services/network/i_network_service.dart';
export 'src/services/network/i_web_socket_service.dart';

// --- Serialization ---
export 'src/core/serialization/serializable_component.dart';
export 'src/core/serialization/component_factory.dart';
export 'src/core/serialization/world_serializer.dart';
export 'src/core/render_packet.dart';
export 'src/core/serialization/binary_component.dart';
export 'src/core/serialization/binary_component_factory.dart';
export 'src/core/serialization/binary_reader_writer.dart';
export 'src/core/serialization/binary_world_serializer.dart';

// --- Events ---
export 'src/events/app_lifecycle_event.dart';
export 'src/events/gameplay_events.dart';
export 'src/events/hardware_input_events.dart';
export 'src/events/list_events.dart';
export 'src/events/shape_events.dart';
export 'src/events/input_events.dart';
export 'src/events/pointer_events.dart';
export 'src/events/history_events.dart';
export 'src/events/theme_events.dart';
export 'src/events/responsive_events.dart';
export 'src/events/ui_events.dart';
// --- FINAL FIX: Export core persistence events so they are accessible to the app ---
export 'src/systems/persistence_system.dart'
    show DataLoadedEvent, SaveDataEvent;

// --- Components ---
export 'src/components/animation_component.dart';
export 'src/components/animation_progress_component.dart';
export 'src/components/api_request_component.dart';
export 'src/components/api_status_component.dart';
export 'src/components/app_lifecycle_component.dart';
export 'src/components/archetype_component.dart';
export 'src/components/attractor_component.dart';
export 'src/components/blackboard_component.dart';
export 'src/components/bloc_component.dart';
export 'src/components/category_component.dart';
export 'src/components/children_component.dart';
export 'src/components/clickable_component.dart';
export 'src/components/counter_state_component.dart';
export 'src/components/custom_widget_component.dart';
export 'src/components/decoration_components.dart';
export 'src/components/effect_component.dart';
export 'src/components/gameplay_components.dart';
export 'src/components/input_focus_component.dart';
export 'src/components/keyboard_input_component.dart';
export 'src/components/link_component.dart';
export 'src/components/list_components.dart';
export 'src/components/lifecycle_component.dart';
export 'src/components/lifecycle_policy_component.dart';
export 'src/components/morphing_component.dart';
export 'src/components/parent_component.dart';
export 'src/components/particle_component.dart';
export 'src/components/particle_spawner_component.dart';
export 'src/components/persistence_component.dart';
export 'src/components/position_component.dart';
export 'src/components/render_strategy_component.dart';
export 'src/components/responsive_component.dart';
export 'src/components/rule_component.dart';
export 'src/components/screen_info_component.dart';
export 'src/components/shape_path_component.dart';
export 'src/components/spawner_link_component.dart';
export 'src/components/styleable_component.dart';
export 'src/components/tags_component.dart';
export 'src/components/theme_component.dart';
export 'src/components/timer_component.dart';
export 'src/components/velocity_component.dart';
export 'src/components/web_socket_components.dart';
export 'src/components/widget_component.dart';
export 'src/components/history_component.dart';

// --- Systems ---
export 'src/systems/advanced_input_system.dart';
export 'src/systems/animation_system.dart';
export 'src/systems/api_system.dart';
export 'src/systems/app_lifecycle_system.dart';
export 'src/systems/archetype_system.dart';
export 'src/systems/attraction_system.dart';
export 'src/systems/bloc_system.dart';
export 'src/systems/collision_system.dart';
export 'src/systems/damage_system.dart';
export 'src/systems/decoration_animation_system.dart';
export 'src/systems/effect_system.dart';
export 'src/systems/flutter_rendering_system.dart';
export 'src/systems/garbage_collector_system.dart';
export 'src/systems/hardware_input_system.dart';
export 'src/systems/history_system.dart';
export 'src/systems/input_system.dart';
export 'src/systems/list_item_animation_system.dart';
export 'src/systems/list_item_interaction_system.dart';
export 'src/systems/list_state_system.dart';
export 'src/systems/lifecycle_system.dart';
export 'src/systems/morphing_system.dart';
export 'src/systems/particle_lifecycle_system.dart';
export 'src/systems/persistence_system.dart'
    show PersistenceSystem; // Hide events here to avoid ambiguity
export 'src/systems/physics_system.dart';
export 'src/systems/pointer_system.dart';
export 'src/systems/pulsing_warning_system.dart';
export 'src/systems/responsiveness_system.dart';
export 'src/systems/rule_system.dart';
export 'src/systems/shape_selection_system.dart';
export 'src/systems/spawner_system.dart';
export 'src/systems/targeting_system.dart';
export 'src/systems/particle_spawning_system.dart';
export 'src/systems/theming_system.dart';
export 'src/systems/timer_system.dart';
export 'src/systems/transform_system.dart';
export 'src/systems/web_socket_system.dart';

// --- Flutter Bridge ---
export 'src/flutter/entity_widget_builder.dart';
export 'src/flutter/nexus_widget.dart';
export 'src/flutter/nexus_manager.dart';
export 'src/flutter/nexus_isolate_manager.dart';
export 'src/flutter/nexus_single_thread_manager.dart';
export 'src/flutter/builder_tags.dart';
export 'src/flutter/widget_builder.dart';
