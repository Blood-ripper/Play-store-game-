import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';

/// Login / sign-up screen. Supports email, Google, and guest (anonymous) play.
/// Guests can play immediately with the free-unlocked vehicles & items.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _handle = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _handle.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = context.read<AppState>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[FarmColors.sky, Color(0xFFBEE6A0), FarmColors.grass],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('🚜', style: TextStyle(fontSize: 72)),
                  const Text('FARM RUSH', style: AppTheme.title),
                  const SizedBox(height: 4),
                  const Text('Harvest • Deliver • Build your tycoon',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: <Widget>[
                          if (_isSignUp)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextField(
                                controller: _handle,
                                decoration: const InputDecoration(
                                  labelText: 'Player handle',
                                  prefixIcon: Icon(Icons.badge),
                                ),
                              ),
                            ),
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _password,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                            ),
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(_error!,
                                  style: const TextStyle(color: FarmColors.tomato)),
                            ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _busy
                                  ? null
                                  : () => _run(() async {
                                        if (_isSignUp) {
                                          await app.signUp(_email.text,
                                              _password.text,
                                              _handle.text.trim().isEmpty
                                                  ? 'Farmer'
                                                  : _handle.text.trim());
                                        } else {
                                          await app.signIn(
                                              _email.text, _password.text);
                                        }
                                      }),
                              child: _busy
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : Text(_isSignUp ? 'Create account' : 'Log in'),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _isSignUp = !_isSignUp),
                            child: Text(_isSignUp
                                ? 'Have an account? Log in'
                                : 'New here? Create an account'),
                          ),
                          const Divider(),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _run(app.signInWithGoogle),
                              icon: const Text('🔵'),
                              label: const Text('Continue with Google'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed:
                                  _busy ? null : () => _run(app.signInAsGuest),
                              icon: const Icon(Icons.play_circle_fill),
                              label: const Text('Play as guest'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Guests start with 2 free tractors & 2 free items.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
