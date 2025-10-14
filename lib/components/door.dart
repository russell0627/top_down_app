import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game.dart';
import 'sound_echo.dart';

/// A component representing a door that can be opened and closed.
class Door extends PositionComponent with HasGameReference<MyGame> {
  bool isOpen = false;
  late final RectangleComponent _visual;
  late final RectangleHitbox _hitbox;

  Door({required Vector2 position, required Vector2 size})
      : super(
          position: position,
          size: size,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _visual = RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF8B4513), // SaddleBrown
    );
    _hitbox = RectangleHitbox();

    add(_visual);
    add(_hitbox);
  }

  /// Toggles the door's state between open and closed.
  void toggle() {
    isOpen = !isOpen;

    if (isOpen) {
      // When open, make it visually smaller and disable collisions.
      _visual.size = Vector2(size.x, size.y * 0.2);
      _hitbox.collisionType = CollisionType.inactive;
    } else {
      // When closed, restore its visual size and enable collisions.
      _visual.size = size;
      _hitbox.collisionType = CollisionType.active;
    }

    // Interacting with a door makes a small noise.
    game.add(
      SoundEcho(
        position: position.clone(),
        lifetime: 3.0,
        radius: 80.0,
      ),
    );
  }
}