import 'player_frame.dart';

/// One row on the global leaderboard. Includes the player's equipped frame so
/// premium players render their glow to everyone.
class LeaderboardEntry {
  LeaderboardEntry({
    required this.uid,
    required this.handle,
    required this.score,
    required this.level,
    required this.frameId,
    required this.vip,
    this.rank = 0,
  });

  final String uid;
  final String handle;
  final int score;
  final int level;
  final String frameId;
  final bool vip;
  int rank;

  PlayerFrame get frame => kFrameCatalog.firstWhere(
        (PlayerFrame f) => f.id == frameId,
        orElse: () => kFrameCatalog.first,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'handle': handle,
        'score': score,
        'level': level,
        'frameId': frameId,
        'vip': vip,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        uid: j['uid'] as String,
        handle: (j['handle'] as String?) ?? 'Farmer',
        score: (j['score'] as num?)?.toInt() ?? 0,
        level: (j['level'] as num?)?.toInt() ?? 1,
        frameId: (j['frameId'] as String?) ?? 'frame_default',
        vip: (j['vip'] as bool?) ?? false,
      );
}
