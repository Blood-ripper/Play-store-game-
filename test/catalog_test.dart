import 'package:flutter_test/flutter_test.dart';

import 'package:farm_rush/data/farmer_items_catalog.dart';
import 'package:farm_rush/data/vehicles_catalog.dart';
import 'package:farm_rush/models/farmer_item.dart';
import 'package:farm_rush/models/player_frame.dart';
import 'package:farm_rush/models/vehicle.dart';

void main() {
  group('Catalog integrity', () {
    test('there are exactly 100 vehicles and 100 items', () {
      expect(kVehicleCatalog.length, 100);
      expect(kFarmerItemCatalog.length, 100);
    });

    test('exactly 2 free vehicles and 2 free items for new users', () {
      expect(kVehicleCatalog.where((Vehicle v) => v.freeUnlock).length, 2);
      expect(kFarmerItemCatalog.where((FarmerItem i) => i.freeUnlock).length, 2);
    });

    test('free entries cost nothing', () {
      for (final Vehicle v in kVehicleCatalog.where((Vehicle v) => v.freeUnlock)) {
        expect(v.price, 0);
        expect(v.currency, Currency.free);
      }
    });

    test('all ids are unique', () {
      final Set<String> vIds = kVehicleCatalog.map((Vehicle v) => v.id).toSet();
      final Set<String> iIds =
          kFarmerItemCatalog.map((FarmerItem i) => i.id).toSet();
      expect(vIds.length, kVehicleCatalog.length);
      expect(iIds.length, kFarmerItemCatalog.length);
    });

    test('premium (gem) entries carry a glow; free entries do not', () {
      for (final Vehicle v in kVehicleCatalog) {
        if (v.freeUnlock) expect(v.glow, Glow.none);
      }
    });

    test('json round-trips', () {
      final Vehicle v = kVehicleCatalog.first;
      expect(Vehicle.fromJson(v.toJson()).id, v.id);
      final FarmerItem i = kFarmerItemCatalog.last;
      expect(FarmerItem.fromJson(i.toJson()).name, i.name);
    });
  });

  group('Frame logic', () {
    test('no glows → default frame', () {
      expect(highestFrameForGlows(<Glow>{}).isDefault, isTrue);
    });

    test('legendary beats gold', () {
      final PlayerFrame f =
          highestFrameForGlows(<Glow>{Glow.gold, Glow.legendary});
      expect(f.glow, Glow.legendary);
    });

    test('silver resolves to the silver frame', () {
      expect(highestFrameForGlows(<Glow>{Glow.silver}).glow, Glow.silver);
    });
  });
}
