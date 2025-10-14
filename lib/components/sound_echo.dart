import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// A component representing a lingering sound echo that attracts enemies.
class SoundEcho extends PositionComponent {
  final double lifetime;
  final double radius;

  SoundEcho({
    required Vector2 position,
    this.lifetime = 8.0,
    this.radius = 40.0,
  })
      : super(
          position: position,
          size: Vector2.all(radius),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add a visual representation that will fade out over the component's lifetime.
    add(
      CircleComponent(
        radius: radius / 2,
        paint: Paint()..color = Colors.lightBlueAccent.withOpacity(0.2),
      )..add(OpacityEffect.fadeOut(EffectController(duration: lifetime))),
    );

    // Add a timer to remove the entire component after its lifetime.
    add(TimerComponent(
      period: lifetime,
      onTick: () => removeFromParent(),
      removeOnFinish: true,
    ));
  }
}