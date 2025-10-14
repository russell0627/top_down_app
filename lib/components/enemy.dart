import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'obstacle.dart';
import 'door.dart';
import 'melee_hitbox.dart';
import 'player_projectile.dart';
import 'player.dart';
import 'sound_echo.dart';

/// This class represents an enemy in the game.
class Enemy extends PositionComponent with CollisionCallbacks {
  // --- Speed Properties ---
  final double _baseSpeed = 100;
  final double _boostedSpeed = 220; // Speed when inside a sound echo.
  late double _currentSpeed;
  // --------------------

  // A reference to the player, so the enemy knows what to chase.
  final Player playerToChase;

  // --- AI State ---
  /// If false, the enemy is idle. If true, it will hunt.
  bool isAlerted = false;

  /// The radius within which the enemy can "see" the player.
  final double _sightRadius = 120.0;

  final double _pushbackForce = 150.0;

  Enemy({required Vector2 position, required this.playerToChase})
      : super(
          position: position,
          size: Vector2.all(25.0), // The enemy is a 25x25 square.
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _currentSpeed = _baseSpeed;

    // Add a red rectangle to visually represent the enemy.
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.red,
    ));
    // Add a hitbox for collision detection.
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    final soundEchoes = parent?.children.whereType<SoundEcho>() ?? [];

    // --- Alert Logic ---
    if (!isAlerted) {
      // Become alerted if the player is too close.
      if (position.distanceTo(playerToChase.position) < _sightRadius) {
        isAlerted = true;
      }
    }

    // --- Speed Logic ---
    // Check if the enemy is inside any sound echo's radius.
    // The visual radius of the echo is half of its size property.
    final isInsideEcho = soundEchoes
        .any((echo) => position.distanceTo(echo.position) < echo.radius / 2);

    _currentSpeed = isInsideEcho ? _boostedSpeed : _baseSpeed;

    // --- Movement Logic ---
    if (isAlerted) {
      Vector2? targetPosition;

      // New AI Priority: Player > Sound
      // 1. If the player is in sight, target the player.
      if (position.distanceTo(playerToChase.position) < _sightRadius) {
        targetPosition = playerToChase.position;
      }
      // 2. If player is not in sight, check for sound echoes.
      else if (soundEchoes.isNotEmpty) {
        // Find the closest sound echo and target it.
        var closestEcho = soundEchoes.first;
        var closestDist = position.distanceTo(closestEcho.position);
        for (final echo in soundEchoes.skip(1)) {
          final dist = position.distanceTo(echo.position);
          if (dist < closestDist) {
            closestEcho = echo;
            closestDist = dist;
          }
        }
        targetPosition = closestEcho.position;
      }

      // Only move if there is a valid target.
      if (targetPosition != null) {
        // Calculate the desired movement vector.
        final direction =
            (targetPosition - position).normalized() * _currentSpeed * dt;
        final newPosition = position + direction;

        // Simple "move and slide" collision detection.
        final movementBounds = toRect().translate(direction.x, direction.y);
        final colliders = parent?.children.whereType<Obstacle>() ?? [];
        final closedDoors = parent?.children.whereType<Door>().where((d) => !d.isOpen) ?? [];

        bool canMove = !colliders.any((c) => c.toRect().overlaps(movementBounds)) &&
            !closedDoors.any((d) => d.toRect().overlaps(movementBounds));

        if (canMove) {
          position = newPosition;
        }
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    // Ignore collisions with projectiles.
    if (other is PlayerProjectile) {
      removeFromParent();
    } else if (other is MeleeHitbox) {
      // Get knocked back by the melee push.
      final pushDirection = (position - playerToChase.position).normalized();
      position.add(pushDirection * _pushbackForce);
    }
  }
}