# Nexus Framework

![Nexus Banner](https://placehold.co/1200x400/673AB7/FFFFFF?text=Nexus&font=raleway)

**A highly scalable, clean, and data-oriented framework for Flutter, inspired by the Entity Component System (ECS) architecture and powered by BLoC and GetIt.**

Nexus brings the performance and scalability of game development architecture to your Flutter applications. By separating data (Components) from logic (Systems), it enables you to build complex, high-performance apps that are easy to manage, test, and reason about.

---

## Core Concepts

Nexus is built upon three fundamental principles of the ECS pattern:

-   **Entity**: A general-purpose object, acting as a container for components. It has no data or logic of its own, only a unique ID.
-   **Component**: A container for pure data. Components define the properties of an entity but contain no logic. For example, `PositionComponent` stores coordinates, and `VelocityComponent` stores speed.
-   **System**: Contains all the application logic. Systems operate on entities that have a specific set of components. For instance, the `PhysicsSystem` only acts on entities that have both `PositionComponent` and `VelocityComponent`.

These concepts are orchestrated within a `NexusWorld`, which manages the entire application state and the main update loop.

## Features

✨ **Highly Scalable**: The decoupled nature of ECS allows you to add complex features by simply creating new components and systems without modifying existing code.

⚡ **Performant**: Designed for high-frequency updates. The UI is rendered reactively, ensuring only the necessary widgets are rebuilt, making it ideal for animations, simulations, and games.

🧪 **Extremely Testable**: With logic completely separated from data and UI, your systems become pure functions that are trivial to unit test.

🧩 **Modular & Reusable**: Components and systems are inherently modular, encouraging the creation of reusable building blocks for your applications.

🔗 **Integrates Seamlessly**: Built to work with the best of the Flutter ecosystem, with first-class support for `bloc` for state management and `get_it` for dependency injection.

## Getting Started

To start using Nexus, add the dependency to your `pubspec.yaml` file.

```yaml
dependencies:
  nexus: ^1.0.0-dev.2 # Or the latest version
```

## Usage

Here's a simple example of creating a world with a single entity that animates and then starts moving.

```dart
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';

// 1. Setup the World and Systems
NexusWorld setupWorld() {
  final world = NexusWorld();
  world.addSystem(FlutterRenderingSystem());
  world.addSystem(AnimationSystem());
  world.addSystem(PhysicsSystem());

  // 2. Create an Entity and add Components
  final myEntity = Entity();

  myEntity.add(PositionComponent(x: 100, y: 100, width: 150, height: 150, scale: 0));
  myEntity.add(WidgetComponent((context, entity) => Container(color: Colors.blueAccent)));
  myEntity.add(AnimationComponent(
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeOutBack,
    onUpdate: (entity, value) {
      final pos = entity.get<PositionComponent>()!;
      pos.scale = value;
      entity.add(pos); // Re-add to notify listeners
    },
    onComplete: (entity) {
      // Give it velocity after the animation
      entity.add(VelocityComponent(y: 100));
    },
  ));

  world.addEntity(myEntity);
  return world;
}

// 3. Run the World in a Flutter app
void main() {
  runApp(MyApp(world: setupWorld()));
}

class MyApp extends StatelessWidget {
  final NexusWorld world;
  const MyApp({super.key, required this.world});

  @override
  Widget build(BuildContext context) {
    final renderingSystem = world.systems.firstWhere((s) => s is FlutterRenderingSystem) as FlutterRenderingSystem;
    return MaterialApp(
      home: Scaffold(
        body: NexusWidget(
          world: world,
          child: renderingSystem.build(context),
        ),
      ),
    );
  }
}
```

## Contributing

Contributions are welcome! Whether it's filing an issue, improving documentation, or submitting a pull request, all contributions are appreciated.

1.  Fork the repository.
2.  Create your feature branch (`git checkout -b feature/amazing-feature`).
3.  Commit your changes (`git commit -m 'Add some amazing feature'`).
4.  Push to the branch (`git push origin feature/amazing-feature`).
5.  Open a pull request.

---
*This project is a work in progress. The API is subject to change.*
