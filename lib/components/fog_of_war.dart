import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'player.dart';

/// A component that renders a "fog of war" effect, obscuring the game world
/// except for a clear radius around the player.
class FogOfWar extends Component with HasGameReference {
  final Player player;
  final double visionRadius;
  final Color fogColor;

  FogOfWar({
    required this.player,
    this.visionRadius = 250.0,
    this.fogColor = const Color(0xEE000000), // Mostly opaque black
  });

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // The canvas is saved and restored to ensure the blend mode is only
    // applied to the fog of war effect.
    canvas.saveLayer(null, Paint());

    // Draw the dark fog over the entire screen.
    canvas.drawColor(fogColor, BlendMode.src);

    // "Cut out" a circle of visibility around the player.
    // BlendMode.clear erases the pixels in the circle, revealing the game world underneath.
    canvas.drawCircle(
      player.absolutePosition.toOffset(),
      visionRadius,
      Paint()..blendMode = BlendMode.clear,
    );

    canvas.restore();
  }

  // By setting a high priority, we ensure the fog renders on top of all other components.
  @override
  int get priority => 100;
}