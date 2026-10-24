import 'package:flutter/material.dart';
import 'vehicle.dart' show Glow;

export 'vehicle.dart' show Glow;

/// A cosmetic avatar frame. Non-purchasers always have the plain default
/// frame; buying premium content unlocks glowing/animated frames that are
/// visible to everyone on the leaderboard and in multiplayer lobbies.
@immutable
class PlayerFrame {
  const PlayerFrame({
    required this.id,
    required this.name,
    required this.glow,
    required this.ringColors,
    required this.animated,
    required this.unlockHint,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final Glow glow;
  final List<int> ringColors; // ARGB ints for the gradient ring
  final bool animated; // whether the glow pulses / rotates
  final String unlockHint; // how a player earns it
  final bool isDefault;

  List<Color> get colors => ringColors.map((int c) => Color(c)).toList();
}

/// Frame catalogue. The first entry is free & default so guests look fine;
/// the rest light up only for players who buy premium items/vehicles.
const List<PlayerFrame> kFrameCatalog = <PlayerFrame>[
  PlayerFrame(
    id: 'frame_default',
    name: 'Rookie',
    glow: Glow.none,
    ringColors: <int>[0xFFBDBDBD, 0xFF9E9E9E],
    animated: false,
    unlockHint: 'Everyone starts with this.',
    isDefault: true,
  ),
  PlayerFrame(
    id: 'frame_silver',
    name: 'Silver Harvester',
    glow: Glow.silver,
    ringColors: <int>[0xFFE0E0E0, 0xFF9E9E9E, 0xFFFFFFFF],
    animated: false,
    unlockHint: 'Own any Silver-tier item or vehicle.',
  ),
  PlayerFrame(
    id: 'frame_gold',
    name: 'Golden Farmer',
    glow: Glow.gold,
    ringColors: <int>[0xFFFFE082, 0xFFFFB300, 0xFFFFF59D],
    animated: true,
    unlockHint: 'Own any Gold / Platinum premium content.',
  ),
  PlayerFrame(
    id: 'frame_rainbow',
    name: 'Rainbow Elite',
    glow: Glow.rainbow,
    ringColors: <int>[
      0xFFFF5252, 0xFFFFD740, 0xFF69F0AE, 0xFF40C4FF, 0xFFE040FB
    ],
    animated: true,
    unlockHint: 'Own any Diamond-tier premium content.',
  ),
  PlayerFrame(
    id: 'frame_legendary',
    name: 'Legendary Tycoon',
    glow: Glow.legendary,
    ringColors: <int>[0xFFFF9800, 0xFFFFC107, 0xFFFF6F00, 0xFFFFE082],
    animated: true,
    unlockHint: 'Own any Legendary vehicle or the VIP pass.',
  ),
];

/// Resolves the best frame a player has earned from the glows they own.
PlayerFrame highestFrameForGlows(Set<Glow> ownedGlows) {
  const List<Glow> order = <Glow>[
    Glow.legendary,
    Glow.rainbow,
    Glow.gold,
    Glow.silver,
  ];
  for (final Glow g in order) {
    if (ownedGlows.contains(g)) {
      return kFrameCatalog.firstWhere((PlayerFrame f) => f.glow == g);
    }
  }
  return kFrameCatalog.first; // default
}
