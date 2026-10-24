import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'crop.dart';

/// Player-controlled harvester. Movement speed and harvest reach come from the
/// equipped vehicle's stats. The red "blade" at the front harvests crops it
/// touches.
class Tractor extends PositionComponent with CollisionCallbacks {
  Tractor({
    required Vector2 position,
    required this.speed,
    required this.harvestPower,
    required this.color,
    required this.onHarvest,
  }) : super(
          position: position,
          size: Vector2(70, 48),
          anchor: Anchor.center,
        );

  final double speed;
  final double harvestPower;
  final Color color;
  final void Function(int value) onHarvest;

  Vector2 direction = Vector2.zero();

  final Paint _body = Paint();
  final Paint _cabin = Paint()..color = const Color(0xFF42A5F5);
  final Paint _wheel = Paint()..color = const Color(0xFF212121);
  final Paint _blade = Paint()..color = const Color(0xFFD32F2F);

  @override
  Future<void> onLoad() async {
    _body.color = color == const Color(0xFF9E9E9E)
        ? const Color(0xFFE53935) // make the default grey tractor red/fun
        : color;
    // Harvest reach scales a little with harvest power.
    final double reach = 26 + harvestPower * 0.2;
    add(RectangleHitbox(
      size: Vector2(reach, size.y * 0.8),
      position: Vector2(size.x, size.y * 0.1),
      anchor: Anchor.topLeft,
    ));
  }

  @override
  void update(double dt) {
    if (!direction.isZero()) {
      position += direction.normalized() * speed * 14 * dt;
      angle = math.atan2(direction.y, direction.x);
    }
    // Keep inside the field bounds set by the parent game.
    final Vector2? bounds = (parent as dynamic).fieldSize as Vector2?;
    if (bounds != null) {
      position.x = position.x.clamp(40, bounds.x - 40);
      position.y = position.y.clamp(40, bounds.y - 40);
    }
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    if (other is Crop && !other.harvested) {
      other.harvest();
      onHarvest((harvestPower).round().clamp(1, 999));
    }
    super.onCollisionStart(points, other);
  }

  @override
  void render(Canvas canvas) {
    // blade (front)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(size.x - 4, 4, 14, size.y - 8),
          const Radius.circular(4)),
      _blade,
    );
    // body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(6, 6, size.x - 18, size.y - 12),
          const Radius.circular(10)),
      _body,
    );
    // cabin
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(14, 10, 26, size.y - 20),
          const Radius.circular(8)),
      _cabin,
    );
    // wheels
    canvas.drawCircle(Offset(18, size.y - 6), 10, _wheel);
    canvas.drawCircle(Offset(size.x - 24, size.y - 6), 13, _wheel);
  }
}
