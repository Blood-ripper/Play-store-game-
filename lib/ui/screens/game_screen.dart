import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../game/farm_game.dart';

/// Hosts the Flame harvest mini-game with a HUD overlay and a results sheet.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  FarmGame? _game;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final AppState app = context.read<AppState>();
    _game ??= FarmGame(
      vehicle: app.equippedVehicle,
      onFinished: (int score, int harvested) async {
        if (_done) return;
        _done = true;
        await app.recordRun(score: score, harvested: harvested);
        if (mounted) _showResults(score, harvested);
      },
    );

    return Scaffold(
      body: Stack(
        children: <Widget>[
          GameWidget<FarmGame>(game: _game!),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  _hudButton(
                    icon: Icons.close,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  _ScoreHud(game: _game!),
                  const Spacer(),
                  _TimerHud(game: _game!),
                ],
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 24,
            child: _VehicleBadge(app: app),
          ),
        ],
      ),
    );
  }

  Widget _hudButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  void _showResults(int score, int harvested) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext ctx) {
        final AppState app = ctx.read<AppState>();
        final int coins = (score * app.coinMultiplier).round();
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('🌻 Harvest complete!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              _resultRow('Score', '$score'),
              _resultRow('Crops harvested', '$harvested'),
              _resultRow('Coins earned',
                  '+$coins ${app.coinMultiplier > 1 ? "(×${app.coinMultiplier.toStringAsFixed(2)})" : ""}'),
              _resultRow('High score', '${app.profile?.highScore ?? 0}'),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).maybePop();
                      },
                      child: const Text('Back home'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        setState(() {
                          _done = false;
                          _game = null; // restart with a fresh game
                        });
                      },
                      child: const Text('Play again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }
}

class _ScoreHud extends StatelessWidget {
  const _ScoreHud({required this.game});
  final FarmGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.scoreNotifier,
      builder: (BuildContext context, int score, _) => _chip('🌻 $score'),
    );
  }
}

class _TimerHud extends StatelessWidget {
  const _TimerHud({required this.game});
  final FarmGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: game.timeNotifier,
      builder: (BuildContext context, double t, _) =>
          _chip('⏱ ${t.ceil()}s', warn: t <= 10),
    );
  }
}

Widget _chip(String text, {bool warn = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: warn ? FarmColors.tomato : Colors.black45,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
    );

class _VehicleBadge extends StatelessWidget {
  const _VehicleBadge({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text('${app.equippedVehicle.emoji} ${app.equippedVehicle.name}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
