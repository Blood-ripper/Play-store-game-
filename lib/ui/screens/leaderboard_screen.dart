import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/leaderboard_entry.dart';
import '../widgets/player_avatar.dart';

/// Global leaderboard. Each row renders the player's equipped frame, so
/// premium/VIP players visibly glow among free players.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<LeaderboardEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppState>().fetchLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    final String? myUid = context.read<AppState>().profile?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('🏆 Leaderboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _future = context.read<AppState>().fetchLeaderboard();
          });
          await _future;
        },
        child: FutureBuilder<List<LeaderboardEntry>>(
          future: _future,
          builder: (BuildContext context,
              AsyncSnapshot<List<LeaderboardEntry>> snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<LeaderboardEntry> rows = snap.data!;
            if (rows.isEmpty) {
              return const Center(child: Text('No scores yet — be the first!'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length,
              itemBuilder: (BuildContext context, int i) {
                final LeaderboardEntry e = rows[i];
                final bool me = e.uid == myUid;
                return Card(
                  color: me ? FarmColors.panel : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: me
                        ? const BorderSide(color: FarmColors.sunflowerDeep, width: 2)
                        : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 36,
                          child: Text(
                            _medal(e.rank),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ),
                        PlayerAvatar(
                          frame: e.frame,
                          label: e.handle.isNotEmpty
                              ? e.handle[0].toUpperCase()
                              : '?',
                          size: 44,
                          vip: e.vip,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                me ? '${e.handle} (you)' : e.handle,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              Text('Lvl ${e.level} • ${e.frame.name}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.black54)),
                            ],
                          ),
                        ),
                        Text('🌻 ${e.score}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 15)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _medal(int rank) => switch (rank) {
        1 => '🥇',
        2 => '🥈',
        3 => '🥉',
        _ => '#$rank',
      };
}
