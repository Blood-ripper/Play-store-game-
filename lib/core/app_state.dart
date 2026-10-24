import 'package:flutter/foundation.dart';

import '../data/farmer_items_catalog.dart';
import '../data/vehicles_catalog.dart';
import '../models/farmer_item.dart';
import '../models/iap_product.dart';
import '../models/leaderboard_entry.dart';
import '../models/player_frame.dart';
import '../models/user_profile.dart';
import '../models/vehicle.dart';
import '../services/auth_service.dart';
import '../services/iap_service.dart';
import '../services/leaderboard_service.dart';
import '../services/player_repository.dart';
import 'app_config.dart';

/// Outcome of a spend attempt, surfaced to the UI.
enum PurchaseOutcome { success, alreadyOwned, notEnoughFunds, error }

/// The single source of truth for the signed-in session. Backed by
/// ChangeNotifier so the whole UI reacts to currency / inventory changes.
class AppState extends ChangeNotifier {
  AppState({
    AuthService? auth,
    PlayerRepository? players,
    LeaderboardService? leaderboard,
    IapService? iap,
  })  : _auth = auth ?? AuthService(),
        _players = players ?? PlayerRepository(),
        _leaderboard = leaderboard ?? LeaderboardService(),
        _iap = iap ?? IapService() {
    _iap.purchaseResults.listen(_handleIapResult);
  }

  final AuthService _auth;
  final PlayerRepository _players;
  final LeaderboardService _leaderboard;
  final IapService _iap;

  UserProfile? _profile;
  bool _loading = false;

  UserProfile? get profile => _profile;
  bool get isLoading => _loading;
  bool get isSignedIn => _profile != null;
  AuthService get auth => _auth;
  IapService get iap => _iap;

  List<Vehicle> get vehicles => kVehicleCatalog;
  List<FarmerItem> get items => kFarmerItemCatalog;

  Future<void> bootstrap() async {
    _loading = true;
    notifyListeners();
    await _iap.init();
    final AuthUser? user = await _auth.currentUser();
    if (user != null) {
      await _loadOrCreateProfile(user);
    }
    _loading = false;
    notifyListeners();
  }

  // ---- Auth ----------------------------------------------------------------

  Future<void> signInAsGuest() async {
    final AuthUser user = await _auth.signInAsGuest();
    await _loadOrCreateProfile(user, defaultHandle: _randomGuestHandle());
    notifyListeners();
  }

  Future<void> signUp(String email, String password, String handle) async {
    final AuthUser user = await _auth.signUpWithEmail(email, password);
    await _loadOrCreateProfile(user, defaultHandle: handle);
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    final AuthUser user = await _auth.signInWithEmail(email, password);
    await _loadOrCreateProfile(user);
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    final AuthUser user = await _auth.signInWithGoogle();
    await _loadOrCreateProfile(user,
        defaultHandle: user.displayName ?? _randomGuestHandle());
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _profile = null;
    notifyListeners();
  }

  Future<void> _loadOrCreateProfile(AuthUser user,
      {String? defaultHandle}) async {
    UserProfile? p = await _players.load(user.uid);
    p ??= await _players.create(UserProfile(
      uid: user.uid,
      handle: defaultHandle ?? _randomGuestHandle(),
      isGuest: user.isGuest,
      coins: AppConfig.startingCoins,
      gems: AppConfig.startingGems,
    ));
    _profile = p;
  }

  // ---- Inventory / spending ------------------------------------------------

  bool ownsVehicle(String id) => _profile?.ownedVehicleIds.contains(id) ?? false;
  bool ownsItem(String id) => _profile?.ownedItemIds.contains(id) ?? false;

  Future<PurchaseOutcome> buyVehicle(Vehicle v) async {
    final UserProfile? p = _profile;
    if (p == null) return PurchaseOutcome.error;
    if (p.ownedVehicleIds.contains(v.id)) return PurchaseOutcome.alreadyOwned;
    final PurchaseOutcome spend = _spend(v.currency, v.price);
    if (spend != PurchaseOutcome.success) return spend;
    p.ownedVehicleIds.add(v.id);
    await _persist();
    notifyListeners();
    return PurchaseOutcome.success;
  }

  Future<PurchaseOutcome> buyItem(FarmerItem it) async {
    final UserProfile? p = _profile;
    if (p == null) return PurchaseOutcome.error;
    if (p.ownedItemIds.contains(it.id)) return PurchaseOutcome.alreadyOwned;
    final PurchaseOutcome spend = _spend(it.currency, it.price);
    if (spend != PurchaseOutcome.success) return spend;
    p.ownedItemIds.add(it.id);
    await _persist();
    notifyListeners();
    return PurchaseOutcome.success;
  }

  PurchaseOutcome _spend(Currency currency, int price) {
    final UserProfile p = _profile!;
    switch (currency) {
      case Currency.free:
        return PurchaseOutcome.success;
      case Currency.coins:
        if (p.coins < price) return PurchaseOutcome.notEnoughFunds;
        p.coins -= price;
        return PurchaseOutcome.success;
      case Currency.gems:
        if (p.gems < price) return PurchaseOutcome.notEnoughFunds;
        p.gems -= price;
        return PurchaseOutcome.success;
    }
  }

  Future<void> equipVehicle(String id) async {
    if (_profile == null || !ownsVehicle(id)) return;
    _profile = _profile!.copyWith(equippedVehicleId: id);
    _refreshFrame();
    await _persist();
    notifyListeners();
  }

  Future<void> equipFrame(String frameId) async {
    if (_profile == null) return;
    if (!unlockedFrames.any((PlayerFrame f) => f.id == frameId)) return;
    _profile = _profile!.copyWith(equippedFrameId: frameId);
    await _persist();
    notifyListeners();
  }

  Vehicle get equippedVehicle => kVehicleCatalog.firstWhere(
        (Vehicle v) => v.id == _profile?.equippedVehicleId,
        orElse: () => kVehicleCatalog.first,
      );

  // ---- Frames (the glow system) -------------------------------------------

  /// Every glow the player has earned by owning premium content (or VIP).
  Set<Glow> get ownedGlows {
    final Set<Glow> glows = <Glow>{};
    final UserProfile? p = _profile;
    if (p == null) return glows;
    for (final Vehicle v in kVehicleCatalog) {
      if (p.ownedVehicleIds.contains(v.id) && v.glow != Glow.none) {
        glows.add(v.glow);
      }
    }
    for (final FarmerItem it in kFarmerItemCatalog) {
      if (p.ownedItemIds.contains(it.id) && it.glow != Glow.none) {
        glows.add(it.glow);
      }
    }
    if (p.vip) glows.add(Glow.legendary);
    return glows;
  }

  List<PlayerFrame> get unlockedFrames {
    final Set<Glow> owned = ownedGlows;
    return kFrameCatalog
        .where((PlayerFrame f) => f.isDefault || owned.contains(f.glow))
        .toList();
  }

  PlayerFrame get equippedFrame => kFrameCatalog.firstWhere(
        (PlayerFrame f) => f.id == _profile?.equippedFrameId,
        orElse: () => kFrameCatalog.first,
      );

  void _refreshFrame() {
    final UserProfile? p = _profile;
    if (p == null) return;
    // Auto-equip the best frame the player just unlocked, if still on default.
    if (p.equippedFrameId == 'frame_default') {
      final PlayerFrame best = highestFrameForGlows(ownedGlows);
      if (!best.isDefault) {
        _profile = p.copyWith(equippedFrameId: best.id);
      }
    }
  }

  // ---- Real-money IAP ------------------------------------------------------

  Future<void> buyIap(IapProduct product) => _iap.buy(product);

  void _handleIapResult(PurchaseResult result) {
    if (!result.success || _profile == null) {
      notifyListeners();
      return;
    }
    final IapProduct p = result.product;
    _profile!.gems += p.grantGems;
    _profile!.coins += p.grantCoins;
    if (p.grantsVip) {
      _profile = _profile!.copyWith(vip: true);
    }
    _refreshFrame();
    _persist();
    notifyListeners();
  }

  // ---- Gameplay rewards ----------------------------------------------------

  /// Multiplier applied to coins from equipped items + VIP.
  double get coinMultiplier {
    double mult = 1.0;
    final UserProfile? p = _profile;
    if (p == null) return mult;
    for (final FarmerItem it in kFarmerItemCatalog) {
      if (p.ownedItemIds.contains(it.id) &&
          (it.boostStat == 'coinBonus' || it.boostStat == 'allRound')) {
        mult += (it.boostValue - 1.0);
      }
    }
    if (p.vip) mult += 0.25;
    return mult;
  }

  Future<void> recordRun({required int score, required int harvested}) async {
    final UserProfile? p = _profile;
    if (p == null) return;
    final int coinsEarned = (score * coinMultiplier).round();
    p.coins += coinsEarned;
    p.xp += score;
    p.totalHarvested += harvested;
    if (score > p.highScore) p.highScore = score;
    _refreshFrame();
    await _persist();
    await _submitLeaderboard();
    notifyListeners();
  }

  Future<void> _submitLeaderboard() async {
    final UserProfile? p = _profile;
    if (p == null) return;
    await _leaderboard.submitScore(LeaderboardEntry(
      uid: p.uid,
      handle: p.handle,
      score: p.highScore,
      level: p.level,
      frameId: p.equippedFrameId,
      vip: p.vip,
    ));
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard() =>
      _leaderboard.topPlayers();

  Future<void> rename(String handle) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(handle: handle);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_profile != null) await _players.save(_profile!);
  }

  String _randomGuestHandle() {
    final int n = DateTime.now().millisecondsSinceEpoch % 10000;
    return 'Farmer$n';
  }

  @override
  void dispose() {
    _auth.dispose();
    _iap.dispose();
    super.dispose();
  }
}
