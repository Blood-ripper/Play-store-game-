import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_config.dart';
import 'core/app_state.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/splash_screen.dart';

class FarmRushApp extends StatelessWidget {
  const FarmRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (_) => AppState()..bootstrap(),
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    if (app.isLoading) return const SplashScreen();
    return app.isSignedIn ? const HomeScreen() : const LoginScreen();
  }
}
