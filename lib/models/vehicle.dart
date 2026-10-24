import 'package:flutter/material.dart';

/// Rarity controls catalogue sorting and the cosmetic glow a player shows off
/// once they own the item.
enum Rarity { common, uncommon, rare, epic, legendary }

/// What a catalogue entry costs the player.
/// [free] entries are the default-unlocked ones every guest starts with.
enum Currency { free, coins, gems }

/// Visual aura applied to a player's avatar frame when a glowing item is
/// equipped. Non-purchasers render [Glow.none] (a plain frame); purchasers of
/// premium content light up so others can tell them apart.
enum Glow { none, silver, gold, rainbow, legendary }

@immutable
class Vehicle {
  const Vehicle({
    required this.id,
    required this.name,
    required this.family,
    required this.tier,
    required this.rarity,
    required this.currency,
    required this.price,
    required this.speed,
    required this.capacity,
    required this.harvestPower,
    required this.glow,
    required this.emoji,
    required this.freeUnlock,
    required this.colorHex,
  });

  final String id;
  final String name;
  final String family;
  final String tier;
  final Rarity rarity;
  final Currency currency;
  final int price;

  /// Gameplay stats – drive the Flame harvest game.
  final double speed;
  final int capacity;
  final double harvestPower;

  final Glow glow;
  final String emoji;
  final bool freeUnlock;
  final int colorHex;

  Color get color => Color(colorHex);

  bool get isPremium => currency == Currency.gems;

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as String,
        name: j['name'] as String,
        family: j['family'] as String,
        tier: j['tier'] as String,
        rarity: Rarity.values.byName(j['rarity'] as String),
        currency: Currency.values.byName(j['currency'] as String),
        price: (j['price'] as num).toInt(),
        speed: (j['speed'] as num).toDouble(),
        capacity: (j['capacity'] as num).toInt(),
        harvestPower: (j['harvestPower'] as num).toDouble(),
        glow: Glow.values.byName(j['glow'] as String),
        emoji: j['emoji'] as String,
        freeUnlock: j['freeUnlock'] as bool,
        colorHex: j['colorHex'] is int
            ? j['colorHex'] as int
            : int.parse(j['colorHex'].toString()),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'family': family,
        'tier': tier,
        'rarity': rarity.name,
        'currency': currency.name,
        'price': price,
        'speed': speed,
        'capacity': capacity,
        'harvestPower': harvestPower,
        'glow': glow.name,
        'emoji': emoji,
        'freeUnlock': freeUnlock,
        'colorHex': colorHex,
      };
}
