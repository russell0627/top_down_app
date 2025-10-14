import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game.dart';
import 'enemy.dart';
import 'obstacle.dart';

/// This class represents a projectile fired by the player.
class PlayerProjectile extends PositionComponent
    with CollisionCallbacks, HasGameReference<MyGame> {
  final Vector2 velocity;
  final double _speed = 800;
  // The time in seconds before the projectile is removed.
  final double _lifetime = 2.0;
  double _timeLived = 0.0;

  PlayerProjectile({
    required Vector2 position,
    required Vector2 direction,
  })  : velocity = direction.normalized(),
        super(
          position: position,
          size: Vector2.all(10.0), // Projectile is a 10x10 square.
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.lightGreenAccent,
    ));
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * _speed * dt;
    _timeLived += dt;
    // Remove the projectile after its lifetime expires.
    if (_timeLived >= _lifetime) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    // When a projectile hits an enemy or an obstacle, it gets removed.
    if (other is Enemy || other is Obstacle) {
      removeFromParent();
    }
  }
}