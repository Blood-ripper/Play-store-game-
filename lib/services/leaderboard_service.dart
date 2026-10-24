import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_config.dart';
import '../models/leaderboard_entry.dart';

/// Reads/writes the global leaderboard. Firestore-backed when enabled; in
/// local mode it keeps a seeded leaderboard on-device so the screen is never
/// empty during development.
class LeaderboardService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  static const String _localKey = 'local_leaderboard';

  Future<List<LeaderboardEntry>> topPlayers({int limit = 50}) async {
    if (AppConfig.firebaseEnabled) {
      final QuerySnapshot<Map<String, dynamic>> snap = await _db
          .collection(AppConfig.leaderboardCollection)
          .orderBy('score', descending: true)
          .limit(limit)
          .get();
      final List<LeaderboardEntry> rows = snap.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
              LeaderboardEntry.fromJson(d.data()))
          .toList();
      _rank(rows);
      return rows;
    }
    return _loadLocal(limit);
  }

  Future<void> submitScore(LeaderboardEntry entry) async {
    if (AppConfig.firebaseEnabled) {
      // Only overwrite if this score is higher (handled by a security rule +
      // a transaction for correctness).
      final DocumentReference<Map<String, dynamic>> ref = _db
          .collection(AppConfig.leaderboardCollection)
          .doc(entry.uid);
      await _db.runTransaction((Transaction txn) async {
        final DocumentSnapshot<Map<String, dynamic>> cur = await txn.get(ref);
        final int prev = (cur.data()?['score'] as num?)?.toInt() ?? 0;
        if (entry.score >= prev) {
          txn.set(ref, entry.toJson(), SetOptions(merge: true));
        }
      });
      return;
    }
    await _submitLocal(entry);
  }

  Future<List<LeaderboardEntry>> _loadLocal(int limit) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_localKey);
    List<LeaderboardEntry> rows;
    if (raw == null) {
      rows = _seed();
      await prefs.setString(
          _localKey,
          jsonEncode(rows
              .map((LeaderboardEntry e) => e.toJson())
              .toList()));
    } else {
      rows = (jsonDecode(raw) as List<dynamic>)
          .map((dynamic e) =>
              LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    rows.sort((LeaderboardEntry a, LeaderboardEntry b) =>
        b.score.compareTo(a.score));
    _rank(rows);
    return rows.take(limit).toList();
  }

  Future<void> _submitLocal(LeaderboardEntry entry) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<LeaderboardEntry> rows = await _loadLocal(1000);
    rows.removeWhere((LeaderboardEntry e) => e.uid == entry.uid);
    rows.add(entry);
    rows.sort((LeaderboardEntry a, LeaderboardEntry b) =>
        b.score.compareTo(a.score));
    await prefs.setString(
        _localKey,
        jsonEncode(
            rows.map((LeaderboardEntry e) => e.toJson()).toList()));
  }

  void _rank(List<LeaderboardEntry> rows) {
    for (int i = 0; i < rows.length; i++) {
      rows[i].rank = i + 1;
    }
  }

  List<LeaderboardEntry> _seed() {
    final List<Map<String, dynamic>> seed = <Map<String, dynamic>>[
      <String, dynamic>{'h': 'FarmKingArjun', 's': 98500, 'l': 42, 'f': 'frame_legendary', 'v': true},
      <String, dynamic>{'h': 'SunflowerSara', 's': 87200, 'l': 38, 'f': 'frame_rainbow', 'v': true},
      <String, dynamic>{'h': 'TractorTycoon', 's': 76100, 'l': 33, 'f': 'frame_gold', 'v': false},
      <String, dynamic>{'h': 'HarvestHero', 's': 65400, 'l': 29, 'f': 'frame_gold', 'v': false},
      <String, dynamic>{'h': 'CropDuster99', 's': 54300, 'l': 25, 'f': 'frame_silver', 'v': false},
      <String, dynamic>{'h': 'KetchupQueen', 's': 43200, 'l': 21, 'f': 'frame_silver', 'v': false},
      <String, dynamic>{'h': 'BarnBoss', 's': 32100, 'l': 17, 'f': 'frame_default', 'v': false},
      <String, dynamic>{'h': 'MangoMogul', 's': 21000, 'l': 12, 'f': 'frame_default', 'v': false},
      <String, dynamic>{'h': 'NewbieNate', 's': 9800, 'l': 6, 'f': 'frame_default', 'v': false},
    ];
    return <LeaderboardEntry>[
      for (int i = 0; i < seed.length; i++)
        LeaderboardEntry(
          uid: 'seed_$i',
          handle: seed[i]['h'] as String,
          score: seed[i]['s'] as int,
          level: seed[i]['l'] as int,
          frameId: seed[i]['f'] as String,
          vip: seed[i]['v'] as bool,
        ),
    ];
  }
}
