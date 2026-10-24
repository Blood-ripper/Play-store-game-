import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_config.dart';

/// Represents the signed-in identity regardless of backend.
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.isGuest,
    this.email,
    this.displayName,
  });

  final String uid;
  final bool isGuest;
  final String? email;
  final String? displayName;
}

/// Authentication facade. Uses Firebase Auth when enabled, otherwise a local
/// identity stored in SharedPreferences so guests can play offline.
class AuthService {
  AuthService() {
    if (AppConfig.firebaseEnabled) {
      _firebaseAuth = FirebaseAuth.instance;
      _firebaseAuth!.authStateChanges().listen((User? user) {
        _controller.add(user == null ? null : _mapFirebase(user));
      });
    }
  }

  FirebaseAuth? _firebaseAuth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  static const String _localUidKey = 'local_uid';
  static const String _localGuestKey = 'local_is_guest';
  static const String _localEmailKey = 'local_email';

  Stream<AuthUser?> get authState => _controller.stream;

  AuthUser _mapFirebase(User u) => AuthUser(
        uid: u.uid,
        isGuest: u.isAnonymous,
        email: u.email,
        displayName: u.displayName,
      );

  /// Returns the currently signed-in user, restoring a local session if any.
  Future<AuthUser?> currentUser() async {
    if (AppConfig.firebaseEnabled) {
      final User? u = _firebaseAuth!.currentUser;
      return u == null ? null : _mapFirebase(u);
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? uid = prefs.getString(_localUidKey);
    if (uid == null) return null;
    return AuthUser(
      uid: uid,
      isGuest: prefs.getBool(_localGuestKey) ?? true,
      email: prefs.getString(_localEmailKey),
    );
  }

  Future<AuthUser> signInAsGuest() async {
    if (AppConfig.firebaseEnabled) {
      final UserCredential cred = await _firebaseAuth!.signInAnonymously();
      return _mapFirebase(cred.user!);
    }
    return _persistLocal(
      'guest_${DateTime.now().millisecondsSinceEpoch}',
      isGuest: true,
    );
  }

  Future<AuthUser> signUpWithEmail(String email, String password) async {
    if (AppConfig.firebaseEnabled) {
      final UserCredential cred =
          await _firebaseAuth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _controller.add(_mapFirebase(cred.user!));
      return _mapFirebase(cred.user!);
    }
    return _persistLocal('local_${email.hashCode.toUnsigned(32)}',
        isGuest: false, email: email);
  }

  Future<AuthUser> signInWithEmail(String email, String password) async {
    if (AppConfig.firebaseEnabled) {
      final UserCredential cred = await _firebaseAuth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _controller.add(_mapFirebase(cred.user!));
      return _mapFirebase(cred.user!);
    }
    return _persistLocal('local_${email.hashCode.toUnsigned(32)}',
        isGuest: false, email: email);
  }

  Future<AuthUser> signInWithGoogle() async {
    if (!AppConfig.firebaseEnabled) {
      return _persistLocal('google_local', isGuest: false,
          email: 'player@google.local');
    }
    final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
    if (gUser == null) {
      throw AuthException('Google sign-in cancelled.');
    }
    final GoogleSignInAuthentication gAuth = await gUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );
    final UserCredential cred =
        await _firebaseAuth!.signInWithCredential(credential);
    _controller.add(_mapFirebase(cred.user!));
    return _mapFirebase(cred.user!);
  }

  Future<void> signOut() async {
    if (AppConfig.firebaseEnabled) {
      await _googleSignIn.signOut();
      await _firebaseAuth!.signOut();
    } else {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localUidKey);
      await prefs.remove(_localGuestKey);
      await prefs.remove(_localEmailKey);
      _controller.add(null);
    }
  }

  Future<AuthUser> _persistLocal(String uid,
      {required bool isGuest, String? email}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localUidKey, uid);
    await prefs.setBool(_localGuestKey, isGuest);
    if (email != null) await prefs.setString(_localEmailKey, email);
    final AuthUser user = AuthUser(uid: uid, isGuest: isGuest, email: email);
    _controller.add(user);
    return user;
  }

  void dispose() => _controller.close();
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
