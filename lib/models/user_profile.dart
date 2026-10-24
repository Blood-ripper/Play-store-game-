import 'player_frame.dart';

/// A player's persisted profile. Stored in Firestore under /players/{uid}
/// and mirrored locally for offline play.
class UserProfile {
  UserProfile({
    required this.uid,
    required this.handle,
    required this.isGuest,
    this.coins = 500,
    this.gems = 10,
    this.xp = 0,
    this.highScore = 0,
    this.totalHarvested = 0,
    Set<String>? ownedVehicleIds,
    Set<String>? ownedItemIds,
    this.equippedVehicleId = 'veh_000',
    this.equippedFrameId = 'frame_default',
    this.vip = false,
    DateTime? createdAt,
  })  : ownedVehicleIds = ownedVehicleIds ?? <String>{'veh_000', 'veh_001'},
        ownedItemIds = ownedItemIds ?? <String>{'itm_000', 'itm_001'},
        createdAt = createdAt ?? DateTime.now();

  final String uid;
  String handle;
  final bool isGuest;

  int coins;
  int gems;
  int xp;
  int highScore;
  int totalHarvested;

  /// Guests begin already owning the 2 free vehicles + 2 free items so they
  /// can play without signing up or paying.
  final Set<String> ownedVehicleIds;
  final Set<String> ownedItemIds;

  String equippedVehicleId;
  String equippedFrameId;
  bool vip;
  final DateTime createdAt;

  int get level => 1 + (xp ~/ 1000);

  UserProfile copyWith({
    String? handle,
    int? coins,
    int? gems,
    int? xp,
    int? highScore,
    int? totalHarvested,
    String? equippedVehicleId,
    String? equippedFrameId,
    bool? vip,
  }) {
    return UserProfile(
      uid: uid,
      handle: handle ?? this.handle,
      isGuest: isGuest,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      xp: xp ?? this.xp,
      highScore: highScore ?? this.highScore,
      totalHarvested: totalHarvested ?? this.totalHarvested,
      ownedVehicleIds: ownedVehicleIds,
      ownedItemIds: ownedItemIds,
      equippedVehicleId: equippedVehicleId ?? this.equippedVehicleId,
      equippedFrameId: equippedFrameId ?? this.equippedFrameId,
      vip: vip ?? this.vip,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'handle': handle,
        'isGuest': isGuest,
        'coins': coins,
        'gems': gems,
        'xp': xp,
        'highScore': highScore,
        'totalHarvested': totalHarvested,
        'ownedVehicleIds': ownedVehicleIds.toList(),
        'ownedItemIds': ownedItemIds.toList(),
        'equippedVehicleId': equippedVehicleId,
        'equippedFrameId': equippedFrameId,
        'vip': vip,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        uid: j['uid'] as String,
        handle: j['handle'] as String,
        isGuest: (j['isGuest'] as bool?) ?? false,
        coins: (j['coins'] as num?)?.toInt() ?? 500,
        gems: (j['gems'] as num?)?.toInt() ?? 10,
        xp: (j['xp'] as num?)?.toInt() ?? 0,
        highScore: (j['highScore'] as num?)?.toInt() ?? 0,
        totalHarvested: (j['totalHarvested'] as num?)?.toInt() ?? 0,
        ownedVehicleIds: ((j['ownedVehicleIds'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic e) => e.toString())
            .toSet(),
        ownedItemIds: ((j['ownedItemIds'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic e) => e.toString())
            .toSet(),
        equippedVehicleId: (j['equippedVehicleId'] as String?) ?? 'veh_000',
        equippedFrameId: (j['equippedFrameId'] as String?) ?? 'frame_default',
        vip: (j['vip'] as bool?) ?? false,
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}
