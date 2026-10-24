import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_config.dart';
import '../models/user_profile.dart';

/// Persists [UserProfile]s. Firestore-backed when enabled, with a local
/// SharedPreferences cache that also serves as the offline store.
class PlayerRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String _localKey(String uid) => 'profile_$uid';

  Future<UserProfile?> load(String uid) async {
    if (AppConfig.firebaseEnabled) {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _db
          .collection(AppConfig.playersCollection)
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final UserProfile p = UserProfile.fromJson(doc.data()!);
        await _cacheLocal(p);
        return p;
      }
      return null;
    }
    return _loadLocal(uid);
  }

  Future<UserProfile> create(UserProfile profile) async {
    await save(profile);
    return profile;
  }

  Future<void> save(UserProfile profile) async {
    await _cacheLocal(profile);
    if (AppConfig.firebaseEnabled) {
      await _db
          .collection(AppConfig.playersCollection)
          .doc(profile.uid)
          .set(profile.toJson(), SetOptions(merge: true));
    }
  }

  Future<UserProfile?> _loadLocal(String uid) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_localKey(uid));
    if (raw == null) return null;
    return UserProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _cacheLocal(UserProfile profile) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKey(profile.uid), jsonEncode(profile.toJson()));
  }

  /// True if a handle is already taken (global uniqueness). Firestore uses a
  /// /handles/{handle} index doc; local mode always allows.
  Future<bool> isHandleAvailable(String handle) async {
    if (!AppConfig.firebaseEnabled) return true;
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection('handles').doc(handle.toLowerCase()).get();
    return !doc.exists;
  }

  Future<void> claimHandle(String handle, String uid) async {
    if (!AppConfig.firebaseEnabled) return;
    await _db
        .collection('handles')
        .doc(handle.toLowerCase())
        .set(<String, dynamic>{'uid': uid});
  }
}
