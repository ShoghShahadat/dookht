// FILE: lib/modules/visual_formula_editor/visual_formula_editor_module.dart
// (English comments for code clarity)

import 'package:nexus/nexus.dart';

/// A Nexus module that sets up the UI entity for the "Visual Formula Editor" page.
class VisualFormulaEditorModule extends NexusModule {
  @override
  void onLoad(NexusWorld world) {
    // Create the entity for the editor page itself.
    // This entity will hold the state of the canvas, nodes, and connections.
    final visualEditorPage = Entity()
      ..add(TagsComponent({'visual_formula_editor_page'}))
      ..add(LifecyclePolicyComponent(isPersistent: true));
    world.addEntity(visualEditorPage);
  }

  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [];
}
