import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// This class represents a static obstacle in the game.
class Obstacle extends PositionComponent {
  Obstacle({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(50.0),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleComponent(size: size, paint: Paint()..color = Colors.grey));
    add(RectangleHitbox());
  }
}