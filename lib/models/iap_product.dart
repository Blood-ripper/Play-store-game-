import 'package:flutter/material.dart';

/// Kinds of real-money products sold through Google Play Billing.
enum IapKind { gems, coins, vipPass, bundle }

/// A real-money in-app purchase product. The [storeId] MUST match the product
/// ID configured in the Google Play Console. These grant soft currency / VIP
/// which the player then spends on the 100 vehicles and 100 items in-game.
@immutable
class IapProduct {
  const IapProduct({
    required this.storeId,
    required this.title,
    required this.description,
    required this.kind,
    required this.grantGems,
    required this.grantCoins,
    required this.fallbackPrice,
    required this.emoji,
    required this.colorHex,
    this.bestValue = false,
    this.grantsVip = false,
  });

  final String storeId;
  final String title;
  final String description;
  final IapKind kind;
  final int grantGems;
  final int grantCoins;

  /// Shown only until the real localized price is fetched from the store.
  final String fallbackPrice;
  final String emoji;
  final int colorHex;
  final bool bestValue;
  final bool grantsVip;

  Color get color => Color(colorHex);
}

/// Mirror these IDs exactly in the Play Console (Monetize ▸ Products).
const List<IapProduct> kIapProducts = <IapProduct>[
  IapProduct(
    storeId: 'farmrush.gems.handful',
    title: 'Handful of Gems',
    description: '50 gems',
    kind: IapKind.gems,
    grantGems: 50,
    grantCoins: 0,
    fallbackPrice: r'$0.99',
    emoji: '💎',
    colorHex: 0xFF40C4FF,
  ),
  IapProduct(
    storeId: 'farmrush.gems.sack',
    title: 'Sack of Gems',
    description: '300 gems + 2,000 coins',
    kind: IapKind.gems,
    grantGems: 300,
    grantCoins: 2000,
    fallbackPrice: r'$4.99',
    emoji: '💎',
    colorHex: 0xFF7C4DFF,
    bestValue: true,
  ),
  IapProduct(
    storeId: 'farmrush.gems.wagon',
    title: 'Wagon of Gems',
    description: '800 gems + 6,000 coins',
    kind: IapKind.gems,
    grantGems: 800,
    grantCoins: 6000,
    fallbackPrice: r'$9.99',
    emoji: '💠',
    colorHex: 0xFF9C27B0,
  ),
  IapProduct(
    storeId: 'farmrush.coins.chest',
    title: 'Coin Chest',
    description: '10,000 coins',
    kind: IapKind.coins,
    grantGems: 0,
    grantCoins: 10000,
    fallbackPrice: r'$2.99',
    emoji: '🪙',
    colorHex: 0xFFFFB300,
  ),
  IapProduct(
    storeId: 'farmrush.vip.pass',
    title: 'VIP Farmer Pass',
    description: 'Legendary glow frame, +25% coins forever, 200 gems',
    kind: IapKind.vipPass,
    grantGems: 200,
    grantCoins: 0,
    fallbackPrice: r'$6.99',
    emoji: '👑',
    colorHex: 0xFFFF9800,
    grantsVip: true,
  ),
  IapProduct(
    storeId: 'farmrush.bundle.starter',
    title: 'Starter Tycoon Bundle',
    description: '150 gems + 5,000 coins + Gold frame unlock',
    kind: IapKind.bundle,
    grantGems: 150,
    grantCoins: 5000,
    fallbackPrice: r'$3.99',
    emoji: '🎁',
    colorHex: 0xFF4CAF50,
  ),
];
