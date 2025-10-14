import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game.dart';
import 'enemy.dart';
import 'door.dart';
import 'magazine.dart';
import 'melee_hitbox.dart';
import 'obstacle.dart';
import 'player_projectile.dart';
import 'sound_echo.dart';

/// This class represents the player in the game.
///
/// It extends `PositionComponent` to have a position, size, and angle.
/// It also mixes in `KeyboardHandler` to be able to react to keyboard events.
class Player extends PositionComponent
    with KeyboardHandler, CollisionCallbacks, HasGameReference {
  // The speed of the player, in pixels per second.
  final double _speed = 300;

  // The velocity of the player.
  final Vector2 _velocity = Vector2.zero();

  // --- Player State ---
  /// True if the player is currently performing the loading action.
  bool _isLoading = false;

  /// A timer to manage the delay between loading each round.
  late final Timer _loadTimer;

  /// A timer to manage the cooldown between melee pushes.
  final Timer _meleeCooldown = Timer(1.5, autoStart: false);

  /// The last known direction the player was moving. Defaults to facing down.
  final Vector2 _lastMoveDirection = Vector2(0, 1);

  /// The distance of the melee push.
  final double _meleeRange = 50.0;

  /// True if the player is holding down the load key.
  bool _isAttemptingToLoad = false;

  // --- Magazine and Ammo Management ---
  /// The magazine currently loaded in the weapon.
  Magazine? currentMagazine;

  /// The player's inventory of spare magazines.
  List<Magazine> magazines = [];

  /// The number of loose rounds the player is carrying.
  int looseRounds = 20;
  // ------------------------------------

  Player({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(35.0), // The player is a 35x35 square.
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Add a white rectangle to visually represent the player.
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.white,
    ));

    // Add a hitbox for collision detection.
    add(RectangleHitbox());

    // --- Reset Inventory State ---
    // This ensures that on restart, the player gets a fresh inventory.
    magazines.clear();
    looseRounds = 20;

    // Initialize player's starting magazines.
    // Start with one magazine loaded and two empty ones in inventory.
    currentMagazine = Magazine(capacity: 10, currentRounds: 10);
    // Two empty magazines.
    magazines.add(Magazine(capacity: 10));
    magazines.add(Magazine(capacity: 10));

    // Initialize the timer with a callback to reset the loading state.
    _loadTimer = Timer(0.5, onTick: () {
      _isLoading = false;
    }, autoStart: false);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _loadTimer.update(dt);
    _meleeCooldown.update(dt);

    // If the player is trying to load, and the load timer is not running, start loading.
    if (_isAttemptingToLoad && !_loadTimer.isRunning()) {
      _loadSingleRound();
    }

    // Player is vulnerable (cannot move) while loading.
    if (_isLoading) {
      _velocity.setZero();
    }

    // --- Move and Slide Collision ---
    final displacement = _velocity * dt;
    final movementBounds = toRect().translate(displacement.x, displacement.y);
    final colliders = parent?.children.whereType<Obstacle>() ?? [];

    // Check for collisions before moving.
    bool canMove = !colliders.any((c) => c.toRect().overlaps(movementBounds));
    // Also check for collisions with closed doors.
    final closedDoors = parent?.children.whereType<Door>().where((d) => !d.isOpen) ?? [];
    canMove &= !closedDoors.any((d) => d.toRect().overlaps(movementBounds));
    
    if (canMove) {
      position += displacement;
    }
    // --------------------------------
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Set loading intent based on key state.
    _isAttemptingToLoad = keysPressed.contains(LogicalKeyboardKey.keyE);

    // Movement is disabled if the player is loading.
    if (!_isLoading) {
      final newVelocity = Vector2.zero();
      newVelocity.x = (keysPressed.contains(LogicalKeyboardKey.keyA) ? -1 : 0) +
          (keysPressed.contains(LogicalKeyboardKey.keyD) ? 1 : 0);
      newVelocity.y = (keysPressed.contains(LogicalKeyboardKey.keyW) ? -1 : 0) +
          (keysPressed.contains(LogicalKeyboardKey.keyS) ? 1 : 0);
      _velocity.setFrom(newVelocity.normalized() * _speed);
    } else {
      _velocity.setZero();
    }

    // Update facing direction if moving.
    if (!_velocity.isZero()) {
      _lastMoveDirection.setFrom(_velocity.normalized());
    }

    if (keysPressed.contains(LogicalKeyboardKey.keyR)) {
      _reload();
    }

    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      _performMelee();
    }

    if (keysPressed.contains(LogicalKeyboardKey.keyF)) {
      _interactWithDoor();
    }

    return true;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Enemy) {
      // Pause the game and show the GameOver overlay.
      (game as MyGame).onGameOver();
    }
  }

  /// Attempts to fire a projectile towards the target position.
  /// Returns true if a shot was fired, false otherwise.
  bool fire(Vector2 targetPosition) {
    // Cannot fire while loading.
    if (_isLoading) return false;

    if (currentMagazine != null && !currentMagazine!.isEmpty) {
      // Decrement ammo and fire.
      currentMagazine!.currentRounds--;

      print(
          'Fired! Ammo: ${currentMagazine!.currentRounds}/${currentMagazine!.capacity}');
      return true;
    } else {
      // Out of ammo sound effect could go here.
      print('Click! Out of ammo.');
      return false;
    }
  }

  /// Reloads the weapon with the best available magazine.
  void _reload() {
    // Put the current magazine (if any) back into inventory.
    if (currentMagazine != null) {
      // Don't add a completely full magazine back if we are just starting.
      if (!currentMagazine!.isFull || magazines.isEmpty) {
        magazines.add(currentMagazine!);
      }
    }

    // Find the best magazine to load (fullest one).
    if (magazines.isNotEmpty) {
      // Sort magazines by round count, descending.
      magazines.sort((a, b) => b.currentRounds.compareTo(a.currentRounds));

      // Take the best magazine.
      currentMagazine = magazines.removeAt(0);
      print(
          'Reloaded! New Magazine: ${currentMagazine!.currentRounds}/${currentMagazine!.capacity}');
    } else {
      // No magazines left.
      currentMagazine = null;
      print('No magazines left!');
    }
  }

  /// Finds a non-full magazine and loads a single round into it.
  void _loadSingleRound() {
    if (looseRounds <= 0) {
      print('No loose rounds to load.');
      _isLoading = false;
      return;
    }

    // Find the first magazine in inventory that is not full.
    final magazineToLoad = magazines.firstWhere(
      (mag) => !mag.isFull,
      orElse: () => Magazine(capacity: -1), // Sentinel value if none found
    );

    if (magazineToLoad.capacity != -1) {
      _isLoading = true;
      _loadTimer.start(); // Start the timer for the loading delay.

      magazineToLoad.currentRounds++;
      looseRounds--;
      print(
          'Loading... Rounds left: $looseRounds. Magazine: ${magazineToLoad.currentRounds}/${magazineToLoad.capacity}');
    } else {
      print('All magazines are full.');
      _isLoading = false; // Ensure we are not stuck in a loading state.
    }
  }

  /// Performs a melee push if not on cooldown.
  void _performMelee() {
    if (_meleeCooldown.isRunning()) return;

    _meleeCooldown.start();

    // Create a hitbox in front of the player.
    final hitboxPosition = position + (_lastMoveDirection * _meleeRange * 0.5);
    game.add(MeleeHitbox(
      position: hitboxPosition,
      size: Vector2(_meleeRange, _meleeRange),
    ));

    // A melee push makes a small noise.
    game.add(SoundEcho(position: position.clone(), lifetime: 4.0, radius: 50.0));
  }

  /// Finds the nearest door and toggles its state.
  void _interactWithDoor() {
    final doors = game.children.whereType<Door>();
    if (doors.isEmpty) return;

    // Find the closest door.
    var closestDoor = doors.first;
    var closestDist = position.distanceTo(closestDoor.position);

    for (final door in doors.skip(1)) {
      final dist = position.distanceTo(door.position);
      if (dist < closestDist) {
        closestDoor = door;
        closestDist = dist;
      }
    }

    if (closestDist < 75) closestDoor.toggle();
  }
}