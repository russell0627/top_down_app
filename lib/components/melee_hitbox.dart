import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

/// A short-lived component representing the area of a player's melee push.
class MeleeHitbox extends PositionComponent {
  MeleeHitbox({required Vector2 position, required Vector2 size})
      : super(
          position: position,
          size: size,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());

    // The hitbox only exists for a fraction of a second.
    add(TimerComponent(period: 0.1, onTick: removeFromParent, removeOnFinish: true));
  }
}