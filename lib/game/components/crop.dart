import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A single sunflower. Harvested when the tractor's blade overlaps it.
class Crop extends PositionComponent with CollisionCallbacks {
  Crop({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(44),
          anchor: Anchor.center,
        );

  bool harvested = false;
  double _pop = 0; // 0..1 harvest animation progress

  final Paint _petal = Paint()..color = const Color(0xFFFFC107);
  final Paint _petalEdge = Paint()..color = const Color(0xFFFF8F00);
  final Paint _center = Paint()..color = const Color(0xFF6D4C41);
  final Paint _stem = Paint()..color = const Color(0xFF558B2F);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: 18, anchor: Anchor.center)
      ..position = size / 2);
  }

  @override
  void update(double dt) {
    if (harvested) {
      _pop += dt * 4;
      scale = Vector2.all((1 - _pop).clamp(0, 1));
      if (_pop >= 1) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final Offset c = Offset(size.x / 2, size.y / 2);
    // stem
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(c.dx - 2, c.dy, 4, size.y / 2 - 4),
          const Radius.circular(2)),
      _stem,
    );
    // petals
    const int petals = 10;
    for (int i = 0; i < petals; i++) {
      final double a = (i / petals) * math.pi * 2;
      final Offset p = c + Offset(math.cos(a), math.sin(a)) * 13;
      canvas.drawCircle(p, 7, _petalEdge);
      canvas.drawCircle(p, 5.5, _petal);
    }
    // center
    canvas.drawCircle(c, 9, _center);
  }

  void harvest() => harvested = true;
}
