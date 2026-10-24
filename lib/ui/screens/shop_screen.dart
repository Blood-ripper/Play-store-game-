import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/farmer_item.dart';
import '../../models/iap_product.dart';
import '../../models/vehicle.dart';
import '../widgets/currency_bar.dart';

/// Three-tab store: Vehicles (100), Farmer Items (100), and Gems (real money).
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Farm Store'),
          bottom: const TabBar(
            labelColor: Colors.white,
            indicatorColor: FarmColors.sunflower,
            tabs: <Widget>[
              Tab(text: '🚜 Vehicles'),
              Tab(text: '👒 Items'),
              Tab(text: '💎 Gems'),
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: const CurrencyBar(),
            ),
            const Expanded(
              child: TabBarView(
                children: <Widget>[
                  _VehicleGrid(),
                  _ItemGrid(),
                  _GemStore(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _rarityColor(Rarity r) => <Rarity, Color>{
      Rarity.common: const Color(0xFF9E9E9E),
      Rarity.uncommon: const Color(0xFF4CAF50),
      Rarity.rare: const Color(0xFF2196F3),
      Rarity.epic: const Color(0xFF9C27B0),
      Rarity.legendary: const Color(0xFFFF9800),
    }[r]!;

Future<void> _handleOutcome(BuildContext context, PurchaseOutcome o,
    String name) async {
  final ScaffoldMessengerState m = ScaffoldMessenger.of(context);
  final String msg = switch (o) {
    PurchaseOutcome.success => '🎉 Unlocked $name!',
    PurchaseOutcome.alreadyOwned => 'You already own $name.',
    PurchaseOutcome.notEnoughFunds =>
      'Not enough funds — buy gems in the 💎 tab.',
    PurchaseOutcome.error => 'Something went wrong.',
  };
  m.showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
}

class _VehicleGrid extends StatelessWidget {
  const _VehicleGrid();

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final List<Vehicle> vehicles = app.vehicles;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: 210,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: vehicles.length,
      itemBuilder: (BuildContext context, int i) {
        final Vehicle v = vehicles[i];
        final bool owned = app.ownsVehicle(v.id);
        final bool equipped = app.profile?.equippedVehicleId == v.id;
        return _CatalogCard(
          emoji: v.emoji,
          name: v.name,
          subtitle: '${v.tier} • ${v.family}',
          stats: '⚡${v.speed.toStringAsFixed(0)}  📦${v.capacity}  🌾${v.harvestPower.toStringAsFixed(0)}',
          rarityColor: _rarityColor(v.rarity),
          glow: v.glow,
          currency: v.currency,
          price: v.price,
          freeUnlock: v.freeUnlock,
          owned: owned,
          equipped: equipped,
          onBuy: () async {
            final PurchaseOutcome o = await app.buyVehicle(v);
            if (context.mounted) await _handleOutcome(context, o, v.name);
          },
          onEquip: () => app.equipVehicle(v.id),
        );
      },
    );
  }
}

class _ItemGrid extends StatelessWidget {
  const _ItemGrid();

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final List<FarmerItem> items = app.items;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisExtent: 200,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int i) {
        final FarmerItem it = items[i];
        final bool owned = app.ownsItem(it.id);
        return _CatalogCard(
          emoji: it.emoji,
          name: it.name,
          subtitle: '${it.tier} • ${it.category}',
          stats: '✨ ${it.boostStat} ×${it.boostValue.toStringAsFixed(2)}',
          rarityColor: _rarityColor(it.rarity),
          glow: it.glow,
          currency: it.currency,
          price: it.price,
          freeUnlock: it.freeUnlock,
          owned: owned,
          equipped: false,
          onBuy: () async {
            final PurchaseOutcome o = await app.buyItem(it);
            if (context.mounted) await _handleOutcome(context, o, it.name);
          },
          onEquip: null,
        );
      },
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.emoji,
    required this.name,
    required this.subtitle,
    required this.stats,
    required this.rarityColor,
    required this.glow,
    required this.currency,
    required this.price,
    required this.freeUnlock,
    required this.owned,
    required this.equipped,
    required this.onBuy,
    required this.onEquip,
  });

  final String emoji;
  final String name;
  final String subtitle;
  final String stats;
  final Color rarityColor;
  final Glow glow;
  final Currency currency;
  final int price;
  final bool freeUnlock;
  final bool owned;
  final bool equipped;
  final VoidCallback onBuy;
  final VoidCallback? onEquip;

  @override
  Widget build(BuildContext context) {
    final bool premium = glow != Glow.none;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: rarityColor, width: 2),
        boxShadow: premium
            ? <BoxShadow>[
                BoxShadow(
                    color: rarityColor.withValues(alpha: 0.45),
                    blurRadius: 12,
                    spreadRadius: 1),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: rarityColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(subtitle.split(' • ').first,
                    style: TextStyle(
                        color: rarityColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10)),
              ),
              const Spacer(),
              if (premium)
                const Text('✨', style: TextStyle(fontSize: 14)),
            ],
          ),
          Expanded(
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 44)),
            ),
          ),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13)),
          Text(stats,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.black54)),
          const SizedBox(height: 6),
          _buildButton(),
        ],
      ),
    );
  }

  Widget _buildButton() {
    if (equipped) {
      return OutlinedButton(
        onPressed: null,
        child: const Text('Equipped'),
      );
    }
    if (owned) {
      return ElevatedButton(
        onPressed: onEquip,
        style: ElevatedButton.styleFrom(
            backgroundColor: FarmColors.grass,
            padding: const EdgeInsets.symmetric(vertical: 8)),
        child: Text(onEquip == null ? 'Owned' : 'Equip',
            style: const TextStyle(fontSize: 13)),
      );
    }
    final String label = freeUnlock
        ? 'FREE'
        : currency == Currency.gems
            ? '💎 $price'
            : '🪙 $price';
    return ElevatedButton(
      onPressed: onBuy,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            currency == Currency.gems ? FarmColors.gem : FarmColors.sunflowerDeep,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _GemStore extends StatelessWidget {
  const _GemStore();

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(14),
      children: <Widget>[
        const Text(
          'Buy gems & coins with real money. Spend them on vehicles & items.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        for (final IapProduct p in kIapProducts)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Text(p.emoji, style: const TextStyle(fontSize: 34)),
              title: Row(
                children: <Widget>[
                  Flexible(child: Text(p.title,
                      style: const TextStyle(fontWeight: FontWeight.w800))),
                  if (p.bestValue)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: FarmColors.tomato,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('BEST',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
              subtitle: Text(p.description),
              trailing: ElevatedButton(
                onPressed: () async {
                  await app.buyIap(p);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Processing ${p.title}…')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: p.color),
                child: Text(app.iap.priceFor(p)),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => app.iap.restorePurchases(),
            child: const Text('Restore purchases'),
          ),
        ),
      ],
    );
  }
}
