/// Global build-time configuration.
///
/// Set [firebaseEnabled] to true once you have run `flutterfire configure`
/// and generated a real `lib/firebase_options.dart`. Until then the app runs
/// in LOCAL mode: auth/profile/leaderboard are backed by on-device storage so
/// you can play and demo everything without a backend.
class AppConfig {
  AppConfig._();

  static const bool firebaseEnabled = bool.fromEnvironment(
    'FIREBASE_ENABLED',
    defaultValue: false,
  );

  /// When true, IAP uses the real Google Play Billing flow. Keep false on
  /// emulators / before store products exist; purchases then grant instantly
  /// in a sandboxed local flow for testing the UI.
  static const bool billingEnabled = bool.fromEnvironment(
    'BILLING_ENABLED',
    defaultValue: false,
  );

  static const String appName = 'Farm Rush';
  static const String leaderboardCollection = 'leaderboard';
  static const String playersCollection = 'players';

  // Starting economy for new / guest players.
  static const int startingCoins = 500;
  static const int startingGems = 10;
}
