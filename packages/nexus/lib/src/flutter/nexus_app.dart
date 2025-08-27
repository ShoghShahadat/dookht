// This is a new file that seems to exist in your project based on the error.
// Please create it if it doesn't exist, or replace its content if it does.

import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

/// A helper widget that wraps a NexusWidget inside a MaterialApp.
class NexusApp extends StatelessWidget {
  final String title;
  final NexusWorld Function() worldProvider;
  final FlutterRenderingSystem renderingSystem;
  final ComponentTypeIdProvider componentTypeIdProvider;
  final Future<void> Function()? isolateInitializer;

  const NexusApp({
    super.key,
    this.title = 'Nexus App',
    required this.worldProvider,
    required this.renderingSystem,
    required this.componentTypeIdProvider, // Added the required provider
    this.isolateInitializer,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      home: NexusWidget(
        worldProvider: worldProvider,
        renderingSystem: renderingSystem,
        isolateInitializer: isolateInitializer,
        // Pass the provider down to the NexusWidget
        componentTypeIdProvider: componentTypeIdProvider,
      ),
    );
  }
}
