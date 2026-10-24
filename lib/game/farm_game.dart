import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import 'components/crop.dart';
import 'components/tractor.dart';

/// The playable "Harvest!" mini-game (reference screenshot 1).
///
/// Drive the tractor over the sunflower field with the on-screen joystick.
/// Each crop harvested adds to your score. The run lasts [runSeconds]; when it
/// ends [onFinished] fires with (score, harvested) so the app can award coins
/// and submit to the leaderboard.
class FarmGame extends FlameGame with HasCollisionDetection {
  FarmGame({
    required this.vehicle,
    required this.onFinished,
    this.runSeconds = 45,
  });

  final Vehicle vehicle;
  final void Function(int score, int harvested) onFinished;
  final int runSeconds;

  late Tractor tractor;
  late JoystickComponent joystick;
  Vector2 fieldSize = Vector2.all(1000);

  int score = 0;
  int harvested = 0;
  int _totalCrops = 0;
  double timeLeft = 0;
  bool _finished = false;

  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<double> timeNotifier = ValueNotifier<double>(0);

  @override
  Color backgroundColor() => const Color(0xFFBC8A5F); // soil

  @override
  Future<void> onLoad() async {
    fieldSize = size.clone();
    timeLeft = runSeconds.toDouble();
    timeNotifier.value = timeLeft;

    _plantField();
    _addTractor();
    _addJoystick();
  }

  void _plantField() {
    final math.Random rng = math.Random(42);
    const double margin = 70;
    const double step = 62;
    for (double y = margin; y < fieldSize.y - margin; y += step) {
      for (double x = margin; x < fieldSize.x - margin; x += step) {
        // leave a clear patch near the start position
        final bool nearStart =
            (Vector2(x, y) - fieldSize / 2).length < 90;
        if (nearStart) continue;
        const double jitter = 8;
        add(Crop(
          position: Vector2(
            x + rng.nextDouble() * jitter,
            y + rng.nextDouble() * jitter,
          ),
        ));
        _totalCrops++;
      }
    }
  }

  void _addTractor() {
    tractor = Tractor(
      position: fieldSize / 2,
      speed: vehicle.speed,
      harvestPower: vehicle.harvestPower,
      color: vehicle.color,
      onHarvest: (int value) {
        score += value;
        harvested += 1;
        scoreNotifier.value = score;
      },
    );
    add(tractor);
  }

  void _addJoystick() {
    final Paint knob = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final Paint bg = Paint()..color = Colors.white.withValues(alpha: 0.30);
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 26, paint: knob),
      background: CircleComponent(radius: 58, paint: bg),
      margin: const EdgeInsets.only(left: 36, bottom: 44),
    );
    // HUD elements don't move with the camera.
    camera.viewport.add(joystick);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_finished) return;

    tractor.direction = joystick.relativeDelta.clone();

    timeLeft -= dt;
    timeNotifier.value = timeLeft.clamp(0, runSeconds.toDouble());
    if (timeLeft <= 0) {
      _finish();
      return;
    }

    // Cleared the whole field before the timer? Award a clear-field bonus.
    if (_totalCrops > 0 && harvested >= _totalCrops) {
      score += 500;
      scoreNotifier.value = score;
      _finish();
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    onFinished(score, harvested);
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    fieldSize = newSize.clone();
  }
}
