# Monetization

Free-to-play with cosmetic + convenience IAP. No pay-to-win gates: every
gameplay-affecting item is also earnable with coins over time; gems mainly buy
time and prestige (glow frames, VIP).

## Currencies
- **Coins** 🪙 — soft currency, earned by playing. Buys most of the 100
  vehicles & 100 items.
- **Gems** 💎 — premium currency from real-money IAP (or small play rewards).
  Buys top-tier (epic/legendary) content and the VIP pass.

## New / guest player economy
- Start: 500 coins, 10 gems.
- Free-unlocked: 2 vehicles (`veh_000`, `veh_001`) + 2 items
  (`itm_000`, `itm_001`) so anyone can play instantly.

## Real-money products (`lib/models/iap_product.dart`)
| Product | Grants | Suggested price |
|---|---|---|
| Handful of Gems | 50 💎 | $0.99 |
| Sack of Gems ⭐ | 300 💎 + 2,000 🪙 | $4.99 |
| Wagon of Gems | 800 💎 + 6,000 🪙 | $9.99 |
| Coin Chest | 10,000 🪙 | $2.99 |
| **VIP Farmer Pass** | 200 💎 + **Legendary glow** + **+25% coins forever** | $6.99 |
| Starter Tycoon Bundle | 150 💎 + 5,000 🪙 + Gold frame | $3.99 |

Prices shown in-app are the real **localized** Play prices once products exist;
the table values are only fallbacks before the store responds.

## The glow-frame perk (prestige driver)
Buying any premium (gem) vehicle/item, or VIP, unlocks a **glowing avatar
frame** by tier:

| Tier owned | Frame | Look |
|---|---|---|
| (default) | Rookie | plain grey ring |
| Silver | Silver Harvester | soft silver ring |
| Gold / Platinum | Golden Farmer | animated gold pulse |
| Diamond | Rainbow Elite | animated rainbow sweep |
| Legendary / VIP | Legendary Tycoon | animated fiery glow + 👑 |

The frame is stored on the player's leaderboard row, so **everyone sees it** —
free players render a plain frame, purchasers visibly stand out. This is the
main non-coercive reason to spend.

## Fairness
- All grants are server-validated (`functions/verifyPurchase`); clients can't
  mint currency.
- Restore purchases supported (`IapService.restorePurchases`).
- No loot boxes / randomized paid rewards (simpler compliance, player trust).
