import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import '../utils/biometric.dart';
import '../utils/storage.dart';
import 'login_screen.dart';

// Shown when there's a `cg_last_user` in storage — even after a normal
// logout — so returning users see "Welcome back, Sara" with a one-tap
// sign-in (biometric if enabled, password otherwise). They can also pick
// "Use different account" to wipe and start fresh.

class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({super.key});
  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen> {
  Map<String, dynamic>? _lastUser;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _loading = true;
  bool _authing = false;
  String? _error;
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final raw = await Storage.get('cg_last_user');
    if (raw == null) {
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
      return;
    }
    final user = jsonDecode(raw) as Map<String, dynamic>;
    final available = await Biometric.available();
    final enabled = await Biometric.isEnabled();
    if (!mounted) return;
    setState(() {
      _lastUser = user;
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _loading = false;
    });
    // Auto-prompt biometric if it's enabled and a token still exists.
    if (enabled && available) {
      final hasToken = (await Storage.get('cg_token')) != null;
      if (hasToken) _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    if (_authing) return;
    setState(() { _authing = true; _error = null; });
    final ok = await Biometric.authenticate(
      reason: 'Sign in to ChargeGuard',
    );
    if (!mounted) return;
    if (!ok) {
      setState(() { _authing = false; _error = 'Biometric cancelled'; });
      return;
    }
    final autoOk = await ApiService.instance.tryAutoLogin();
    if (!mounted) return;
    if (autoOk) {
      _route();
    } else {
      setState(() {
        _authing = false;
        _error = 'Session expired — please enter your password';
      });
    }
  }

  Future<void> _signInWithPassword() async {
    final pwd = _passCtrl.text;
    if (pwd.isEmpty) {
      setState(() => _error = 'Please enter your password');
      return;
    }
    setState(() { _authing = true; _error = null; });
    final res = await ApiService.instance.login(
      email: _lastUser!['email'] as String,
      password: pwd,
      rememberMe: true,
    );
    if (!mounted) return;
    if (res['success'] != true) {
      setState(() {
        _authing = false;
        _error = res['message'] as String? ?? 'Invalid password';
      });
      return;
    }
    // Offer biometric if available and not yet enabled.
    if (_biometricAvailable && !_biometricEnabled) {
      await _offerBiometric();
    }
    if (mounted) _route();
  }

  Future<void> _offerBiometric() async {
    final accept = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cBg,
        title: const Text('Enable biometric login?'),
        content: const Text(
          'Use your fingerprint or face to sign in next time. '
          'You can disable this any time from Settings.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
    if (accept == true) {
      final ok = await Biometric.authenticate(reason: 'Confirm biometric setup');
      if (ok) await Biometric.setEnabled(true);
    }
  }

  void _route() {
    final role = UserSession.instance.role;
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin');
    } else if (role == 'host') {
      final status = UserSession.instance.hostStatus;
      Navigator.pushReplacementNamed(
          context, status == 'Approved' ? '/host' : '/host-pending');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _switchAccount() async {
    await ApiService.instance.forgetAccount();
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: kBg,
          body: Center(child: CircularProgressIndicator(color: kGreen)));
    }
    final firstName = _lastUser?['firstName'] as String? ?? 'there';
    final email = _lastUser?['email'] as String? ?? '';
    final avatar = _lastUser?['avatar'] as String? ?? '';
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const SizedBox(height: 40),

          // Logo
          Container(width: 52, height: 52,
            decoration: BoxDecoration(color: kGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kGreen.withOpacity(0.3))),
            child: const Icon(Icons.ev_station, color: kGreen, size: 28)),
          const SizedBox(height: 32),

          // Greeting
          const Text('Welcome back!',
              style: TextStyle(color: Colors.white,
                  fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 30),

          // Avatar + Name pill
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kCard, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kGreen.withOpacity(0.35), width: 1.5),
              boxShadow: [BoxShadow(color: kGreen.withOpacity(0.15), blurRadius: 16)],
            ),
            child: Column(children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: kGreen.withOpacity(0.2),
                backgroundImage: avatar.startsWith('data:image')
                    ? null : null, // avatar is a base64 data URL; left simple
                child: Text(initial,
                    style: const TextStyle(color: kGreen,
                        fontSize: 28, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 14),
              Text(firstName,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 18, fontWeight: FontWeight.w800)),
              if (email.isNotEmpty) Text(email,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 32),

          // Primary action
          if (_biometricEnabled && _biometricAvailable) ...[
            SizedBox(width: double.infinity, height: 54,
              child: ElevatedButton.icon(
                onPressed: _authing ? null : _tryBiometric,
                icon: _authing
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Icon(Icons.fingerprint, color: Colors.black),
                label: Text(_authing ? 'Authenticating...' : 'Sign in with biometric',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen, foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
            const SizedBox(height: 12),
            Text('or use your password',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 12),
          ],

          // Password field
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            autofocus: !(_biometricEnabled && _biometricAvailable),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _signInWithPassword(),
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: const Icon(Icons.lock_outline,
                  color: Colors.white38, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.white38, size: 20),
                onPressed: () => setState(() => _obscure = !_obscure)),
              filled: true, fillColor: kCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kGreen, width: 1.5)),
            )),
          const SizedBox(height: 12),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8A80).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF8A80).withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Color(0xFFFF8A80), size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!,
                    style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 12))),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: _authing ? null : _signInWithPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen, foregroundColor: Colors.black,
                disabledBackgroundColor: kGreen.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _authing
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                  : Text('Sign in as $firstName',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)))),
          const SizedBox(height: 16),

          TextButton.icon(
            onPressed: _switchAccount,
            icon: const Icon(Icons.swap_horiz, color: Colors.white54, size: 16),
            label: const Text('Use a different account',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ),
        ]),
      )),
    );
  }
}
