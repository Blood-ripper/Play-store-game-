import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/currency_bar.dart';
import '../widgets/player_avatar.dart';
import 'game_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';

/// Root shell with bottom navigation: Farm (hub) · Store · Leaderboard · You.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = <Widget>[
      const _FarmHub(),
      const ShopScreen(),
      const LeaderboardScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Text('🌾', style: TextStyle(fontSize: 20)), label: 'Farm'),
          NavigationDestination(icon: Text('🛒', style: TextStyle(fontSize: 20)), label: 'Store'),
          NavigationDestination(icon: Text('🏆', style: TextStyle(fontSize: 20)), label: 'Ranks'),
          NavigationDestination(icon: Text('🙂', style: TextStyle(fontSize: 20)), label: 'You'),
        ],
      ),
    );
  }
}

/// The farm hub: player card, equipped tractor, big PLAY button, and the
/// game-mode cards derived from the reference screenshots.
class _FarmHub extends StatelessWidget {
  const _FarmHub();

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final String handle = app.profile?.handle ?? 'Farmer';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[FarmColors.sky, Color(0xFFD9F0C2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: CurrencyBar(
                  onAddTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ShopScreen(initialTab: 2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: <Widget>[
                    PlayerAvatar(
                      frame: app.equippedFrame,
                      label: handle.isNotEmpty ? handle[0].toUpperCase() : '?',
                      size: 56,
                      vip: app.profile?.vip ?? false,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(handle,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900)),
                        Text('Level ${app.profile?.level ?? 1} • ${app.equippedFrame.name}',
                            style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                  children: <Widget>[
                    _bigPlayCard(context, app),
                    const SizedBox(height: 16),
                    const Text('More farm activities',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: const <Widget>[
                        _ModeCard(emoji: '🚚', title: 'Deliver Orders', ready: false),
                        _ModeCard(emoji: '🥕', title: 'Catch!', ready: false),
                        _ModeCard(emoji: '🛖', title: 'Repair Barn', ready: false),
                        _ModeCard(emoji: '🍅', title: 'Ketchup Factory', ready: false),
                        _ModeCard(emoji: '🏝️', title: 'Explore Island', ready: false),
                        _ModeCard(emoji: '🐄', title: 'Animal Pens', ready: false),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigPlayCard(BuildContext context, AppState app) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const GameScreen()),
      ),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: <Color>[FarmColors.sunflower, FarmColors.sunflowerDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
                color: FarmColors.sunflowerDeep.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('HARVEST!',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Drive ${app.equippedVehicle.name} • beat your high score',
                      style: const TextStyle(color: Colors.white, fontSize: 13)),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('▶  PLAY',
                        style: TextStyle(
                            color: FarmColors.sunflowerDeep,
                            fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
            const Text('🚜', style: TextStyle(fontSize: 64)),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.emoji, required this.title, this.ready = false});
  final String emoji;
  final String title;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(emoji, style: const TextStyle(fontSize: 38)),
                const SizedBox(height: 6),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
          ),
          if (!ready)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Soon',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}
