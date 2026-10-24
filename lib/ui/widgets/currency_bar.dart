import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';

/// Top bar showing the player's coins and gems with a "+" to open the store.
class CurrencyBar extends StatelessWidget {
  const CurrencyBar({super.key, this.onAddTap});
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final int coins = app.profile?.coins ?? 0;
    final int gems = app.profile?.gems ?? 0;
    return Row(
      children: <Widget>[
        _pill('🪙', coins, FarmColors.coin),
        const SizedBox(width: 8),
        _pill('💎', gems, FarmColors.gem),
        const Spacer(),
        if (onAddTap != null)
          InkWell(
            onTap: onAddTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: FarmColors.sunflowerDeep,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
      ],
    );
  }

  Widget _pill(String icon, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            _format(value),
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: FarmColors.ink),
          ),
        ],
      ),
    );
  }

  static String _format(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }
}
