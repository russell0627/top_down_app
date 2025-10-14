import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'components/enemy.dart';
import 'components/door.dart';
import 'components/obstacle.dart';
import 'components/player.dart';
import 'components/player_projectile.dart';
import 'components/fog_of_war.dart';
import 'components/sound_echo.dart';

/// This class is the main entry point for the game.
///
/// A `FlameGame` is the base for all Flame games and provides a game loop,
/// component system, and other functionalities.
///
/// The camera is a built-in component of `FlameGame` and can be accessed
/// via the `camera` property. You can move, zoom, and rotate it to change
/// the viewport of your game world.
class MyGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection, TapCallbacks {
  /// A callback to be called when the game is over.
  final VoidCallback onGameOver;

  late Player player;
  // A random number generator for placing obstacles.
  final Random _random = Random();

  MyGame({required this.onGameOver});

  // Your game logic will go here.
  @override
  Future<void> onLoad() async {
    // The super.onLoad call is not strictly necessary here for now.
    // We will set up the game world in a separate method.
    await _buildWorld();

    final paint = Paint()
      ..color = const Color(0xFF0000FF) // Using const for Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Create a rectangle component that is the size of the game's viewport.
    // The `size` property is the dimensions of the game canvas.
    add(RectangleComponent(size: size, paint: paint));

    // Add the Fog of War component to the game.
    add(FogOfWar(player: player));

  }

  Future<void> _buildWorld() async {
    // Create and add the player to the game.
    player = Player(position: size / 2);
    add(player);

    // Add 10 random obstacles to the game.
    // For testing doors, let's create a small room structure instead.
    add(Obstacle(position: Vector2(300, 200))..size = Vector2(200, 20));
    add(Obstacle(position: Vector2(300, 400))..size = Vector2(200, 20));
    add(Obstacle(position: Vector2(200, 300))..size = Vector2(20, 200));

    // Add wall segments to close the gap around the door.
    add(Obstacle(position: Vector2(400, 230))..size = Vector2(20, 40)); // Above door
    add(Obstacle(position: Vector2(400, 370))..size = Vector2(20, 40)); // Below door

    // Add a door to the room.
    add(Door(position: Vector2(400, 300), size: Vector2(20, 100)));

    /*
    // Original random obstacle generation
    for (var i = 0; i < 10; i++) {
      add(
        Obstacle(
          position: Vector2(
            _random.nextDouble() * size.x,
            _random.nextDouble() * size.y,
          ),
        ),
      );
    }
    */

    // Add 5 random enemies to the game.
    for (var i = 0; i < 5; i++) {
      Vector2 spawnPosition;
      do {
        spawnPosition = Vector2(
          _random.nextDouble() * size.x,
          _random.nextDouble() * size.y,
        );
        // Ensure enemies don't spawn too close to the player's start position.
      } while ((spawnPosition - player.position).length < 150);

      add(
        Enemy(
          position: spawnPosition,
          playerToChase: player,
        ),
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Create and add the projectile directly from the game class.
    // This avoids the lifecycle race condition where the player's `game` ref might be null.
    if (player.fire(event.localPosition)) {
      // If the player successfully fired, create the projectile and sound.
      add(PlayerProjectile(
        position: player.position.clone(),
        direction: (event.localPosition - player.position),
      ));
      add(SoundEcho(position: player.position.clone(), radius: 700.0, lifetime: 3.0));

      // A gunshot alerts all enemies on the map.
      final enemies = children.whereType<Enemy>();
      for (final enemy in enemies) {
        enemy.isAlerted = true;
      }
    }
  }
}