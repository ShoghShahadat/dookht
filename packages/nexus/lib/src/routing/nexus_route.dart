import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/nexus.dart';

/// A specialized [GoRoute] that handles the creation and rendering of a
/// self-contained Nexus scene running in a background isolate.
abstract class NexusRoute extends GoRoute {
  /// Creates a NexusRoute.
  NexusRoute({
    required String path,
    required NexusWorld Function() worldProvider,
    required FlutterRenderingSystem Function(BuildContext context)
        renderingSystemBuilder,
    // THE FIX: Add the provider as a required parameter for the route constructor.
    required ComponentTypeIdProvider componentTypeIdProvider,
    String? name,
    GlobalKey<NavigatorState>? parentNavigatorKey,
    GoRouterRedirect? redirect,
  }) : super(
          path: path,
          name: name,
          parentNavigatorKey: parentNavigatorKey,
          redirect: redirect,
          builder: (context, state) {
            final renderingSystem = renderingSystemBuilder(context);

            return NexusWidget(
              worldProvider: worldProvider,
              renderingSystem: renderingSystem,
              // THE FIX: Pass the provider down to the NexusWidget.
              componentTypeIdProvider: componentTypeIdProvider,
            );
          },
        );
}
