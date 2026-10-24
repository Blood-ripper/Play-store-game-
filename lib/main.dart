import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  if (AppConfig.firebaseEnabled) {
    // Enabled once you have run `flutterfire configure`.
    // The generated firebase_options.dart provides DefaultFirebaseOptions.
    // import 'package:firebase_core/firebase_core.dart';
    // import 'firebase_options.dart';
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    await _initFirebase();
  }

  runApp(const FarmRushApp());
}

/// Kept in a separate function so the Firebase imports only exist once you
/// enable them (see docs/SETUP.md). In LOCAL mode this is a no-op.
Future<void> _initFirebase() async {
  // Uncomment after running `flutterfire configure`:
  //
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
}
