import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/player_frame.dart';

/// Renders a player's avatar inside their equipped [PlayerFrame].
///
/// Free / non-purchasing players show the plain default ring. Players who own
/// premium content get a glowing (and, for higher tiers, animated rotating +
/// pulsing) ring that everyone sees on the leaderboard and in lobbies.
class PlayerAvatar extends StatefulWidget {
  const PlayerAvatar({
    super.key,
    required this.frame,
    required this.label,
    this.size = 64,
    this.vip = false,
  });

  final PlayerFrame frame;
  final String label; // e.g. first letter of handle or emoji
  final double size;
  final bool vip;

  @override
  State<PlayerAvatar> createState() => _PlayerAvatarState();
}

class _PlayerAvatarState extends State<PlayerAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PlayerFrame f = widget.frame;
    final List<Color> colors = f.colors;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (BuildContext context, Widget? child) {
        final double t = _ctrl.value;
        final double pulse = f.animated ? 0.6 + 0.4 * (0.5 + 0.5 * math.sin(t * 2 * math.pi)) : 0.0;
        final double rotation = f.animated ? t * 2 * math.pi : 0.0;
        final double glowRadius = f.glow == Glow.none ? 0 : 10 + pulse * 10;

        return Container(
          width: widget.size + 12,
          height: widget.size + 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: f.glow == Glow.none
                ? null
                : <BoxShadow>[
                    BoxShadow(
                      color: colors.last.withValues(alpha: 0.6),
                      blurRadius: glowRadius,
                      spreadRadius: 1 + pulse * 2,
                    ),
                  ],
          ),
          child: CustomPaint(
            painter: _RingPainter(colors: colors, rotation: rotation, width: 5),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFFFE0B2), Color(0xFFFFCC80)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.size * 0.42,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF5D4037),
              ),
            ),
            if (widget.vip)
              Positioned(
                bottom: 0,
                child: Text('👑', style: TextStyle(fontSize: widget.size * 0.3)),
              ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.colors, required this.rotation, this.width = 5});
  final List<Color> colors;
  final double rotation;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2 - width / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: <Color>[...colors, colors.first],
        transform: GradientRotation(rotation),
      ).createShader(rect);
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.rotation != rotation || old.colors != colors;
}
