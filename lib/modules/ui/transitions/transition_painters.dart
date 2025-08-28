// FILE: lib/modules/ui/transitions/transition_painters.dart
// (English comments for code clarity)
// MODIFIED v2.0: CRITICAL FIX - Replaced the entire problematic FragmentShader
// implementation for the burn effect with a new, performant, and synchronous
// CustomClipper called BurnAwayClipper. This resolves all compilation errors.
// Also removed unused variables.

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

// --- 1. Watercolor Drip Transition ---

class WatercolorClipper extends CustomClipper<Path> {
  final double progress; // 0.0 to 1.0

  WatercolorClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    final waveHeight = 30.0;
    final dripLength = 80.0;

    for (double x = 0; x < size.width; x++) {
      final sine = sin((x / size.width) * 2 * pi * 3 + (progress * 2 * pi));
      final yPos = (size.height + waveHeight + dripLength) * progress -
          (waveHeight * sine * (1 - progress));

      // Add random drips
      final dripFactor = sin((x / size.width) * 2 * pi * 10 + (progress * pi));
      final currentDrip = max(0, dripFactor * dripLength * (1 - progress));

      if (x == 0) {
        path.moveTo(x, yPos + currentDrip);
      } else {
        path.lineTo(x, yPos + currentDrip);
      }
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

// --- 2. Burn Away Transition (NEW CLIPPER IMPLEMENTATION) ---

class BurnAwayClipper extends CustomClipper<Path> {
  final double progress;
  final Random random = Random();

  BurnAwayClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    if (progress <= 0) return path;
    if (progress >= 1) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }

    final revealY = size.height * progress;
    const burnHeight = 40.0;

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, max(0, revealY - burnHeight));

    // Create a jagged, random "burning" edge
    for (double x = size.width; x >= 0; x -= 10) {
      final noise =
          (random.nextDouble() - 0.5) * burnHeight * (1 - (progress * 0.5));
      path.lineTo(x, revealY + noise);
    }

    path.lineTo(0, max(0, revealY - burnHeight));
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

// --- 3. Glitch Transition ---

class GlitchClipper extends CustomClipper<Path> {
  final double progress;
  final Random random = Random();

  GlitchClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    if (progress == 0) {
      return path;
    }

    final revealY = size.height * progress;
    path.addRect(Rect.fromLTWH(0, 0, size.width, revealY));

    // Add random glitch blocks for effect
    final numBlocks = (20 * (1 - progress)).toInt();
    for (int i = 0; i < numBlocks; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final w = random.nextDouble() * 100 + 20;
      final h = random.nextDouble() * 5 + 2;
      path.addRect(Rect.fromLTWH(x, y, w, h));
    }
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

// --- 4. Pixelate Transition (Painter - for potential ShaderMask use) ---

class PixelatePainter extends CustomPainter {
  final double progress; // 0.0 (pixelated) to 1.0 (clear)

  PixelatePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // This painter is a placeholder. The actual effect would be achieved
    // with a ShaderMask in the rendering system, using this progress value.
    // The unused 'paint' variable has been removed.
    final pixelSize = (50 * (1.0 - progress)).clamp(1.0, 50.0);

    for (double y = 0; y < size.height; y += pixelSize) {
      for (double x = 0; x < size.width; x += pixelSize) {
        // In a real implementation, you would sample the color from an
        // underlying image/widget and draw a rect with that color.
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- 5. Ink Splash Transition ---

class InkSplashClipper extends CustomClipper<Path> {
  final double progress;
  final Random random = Random(1); // Seeded for consistency

  InkSplashClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width;
    final radius = maxRadius * progress;

    if (radius <= 0) return path;

    const points = 100;
    for (int i = 0; i < points; i++) {
      final angle = (i / points) * 2 * pi;
      final irregularity = (random.nextDouble() * 0.2 + 0.9) * radius;
      final x = center.dx + cos(angle) * irregularity;
      final y = center.dy + sin(angle) * irregularity;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
