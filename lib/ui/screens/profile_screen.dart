import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/player_frame.dart';
import '../../models/user_profile.dart';
import '../widgets/player_avatar.dart';

/// Profile: avatar + frame picker, handle rename, stats, and sign-out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final UserProfile? p = app.profile;
    if (p == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => app.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: <Widget>[
          Center(
            child: PlayerAvatar(
              frame: app.equippedFrame,
              label: p.handle.isNotEmpty ? p.handle[0].toUpperCase() : '?',
              size: 96,
              vip: p.vip,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(p.handle,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900)),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _renameDialog(context, app),
                ),
              ],
            ),
          ),
          Center(
            child: Text(
              '${p.isGuest ? "Guest" : "Member"} • Level ${p.level} • ${app.equippedFrame.name}',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 20),
          _statsCard(app, p),
          const SizedBox(height: 20),
          const Text('Avatar frames',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'Unlock glowing frames by buying premium vehicles & items.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 10),
          _framePicker(context, app),
        ],
      ),
    );
  }

  Widget _statsCard(AppState app, UserProfile p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            _stat('🏆 High score', '${p.highScore}'),
            _stat('🌾 Total harvested', '${p.totalHarvested}'),
            _stat('🚜 Vehicles owned',
                '${p.ownedVehicleIds.length} / ${app.vehicles.length}'),
            _stat('👒 Items owned',
                '${p.ownedItemIds.length} / ${app.items.length}'),
            _stat('🪙 Coins', '${p.coins}'),
            _stat('💎 Gems', '${p.gems}'),
            if (p.vip) _stat('👑 VIP', 'Active (+25% coins)'),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(label),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _framePicker(BuildContext context, AppState app) {
    final List<PlayerFrame> unlocked = app.unlockedFrames;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: <Widget>[
        for (final PlayerFrame f in kFrameCatalog)
          _FrameOption(
            frame: f,
            unlocked: unlocked.any((PlayerFrame u) => u.id == f.id),
            equipped: app.equippedFrame.id == f.id,
            onTap: () => app.equipFrame(f.id),
          ),
      ],
    );
  }

  Future<void> _renameDialog(BuildContext context, AppState app) async {
    final TextEditingController ctrl =
        TextEditingController(text: app.profile?.handle);
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Change handle'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'New handle'),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await app.rename(result);
    }
  }
}

class _FrameOption extends StatelessWidget {
  const _FrameOption({
    required this.frame,
    required this.unlocked,
    required this.equipped,
    required this.onTap,
  });

  final PlayerFrame frame;
  final bool unlocked;
  final bool equipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: Column(
        children: <Widget>[
          Opacity(
            opacity: unlocked ? 1 : 0.4,
            child: PlayerAvatar(frame: frame, label: '🙂', size: 56),
          ),
          const SizedBox(height: 4),
          Text(frame.name,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: equipped ? FontWeight.w900 : FontWeight.w500,
                  color: equipped ? FarmColors.sunflowerDeep : Colors.black87)),
          if (!unlocked)
            const Icon(Icons.lock, size: 12, color: Colors.black38)
          else if (equipped)
            const Text('✓', style: TextStyle(color: FarmColors.grass)),
        ],
      ),
    );
  }
}
