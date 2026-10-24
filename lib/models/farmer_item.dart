import 'package:flutter/material.dart';
import 'vehicle.dart' show Rarity, Currency, Glow;

export 'vehicle.dart' show Rarity, Currency, Glow;

/// A cosmetic / booster item the farmer can buy and equip (hats, outfits,
/// tools, pets, boosters). Boosters modify gameplay stats; cosmetics change
/// the avatar and can grant a glowing frame.
@immutable
class FarmerItem {
  const FarmerItem({
    required this.id,
    required this.name,
    required this.category,
    required this.tier,
    required this.rarity,
    required this.currency,
    required this.price,
    required this.boostStat,
    required this.boostValue,
    required this.glow,
    required this.emoji,
    required this.freeUnlock,
    required this.colorHex,
  });

  final String id;
  final String name;
  final String category; // Hat, Outfit, Tool, Pet, Booster
  final String tier;
  final Rarity rarity;
  final Currency currency;
  final int price;

  /// Which stat this item multiplies, and by how much.
  final String boostStat;
  final double boostValue;

  final Glow glow;
  final String emoji;
  final bool freeUnlock;
  final int colorHex;

  Color get color => Color(colorHex);

  bool get isPremium => currency == Currency.gems;

  factory FarmerItem.fromJson(Map<String, dynamic> j) => FarmerItem(
        id: j['id'] as String,
        name: j['name'] as String,
        category: j['category'] as String,
        tier: j['tier'] as String,
        rarity: Rarity.values.byName(j['rarity'] as String),
        currency: Currency.values.byName(j['currency'] as String),
        price: (j['price'] as num).toInt(),
        boostStat: j['boostStat'] as String,
        boostValue: (j['boostValue'] as num).toDouble(),
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
        'category': category,
        'tier': tier,
        'rarity': rarity.name,
        'currency': currency.name,
        'price': price,
        'boostStat': boostStat,
        'boostValue': boostValue,
        'glow': glow.name,
        'emoji': emoji,
        'freeUnlock': freeUnlock,
        'colorHex': colorHex,
      };
}
