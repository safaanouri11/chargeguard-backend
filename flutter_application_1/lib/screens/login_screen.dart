import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  late VideoPlayerController _videoCtrl;

  bool _obscure    = true;
  bool _rememberMe = false;
  bool _videoReady = false;
  bool _loading    = false;

  // ── Login ──────────────────────────────────────────────
  Future<void> _login() async {
    final email    = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _snack('Please enter email and password');
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await ApiService.instance.login(
        email:    email,
        password: password,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (result['success'] == true) {
        final role = UserSession.instance.role;
        if (role == 'host') {
          Navigator.pushReplacementNamed(context, '/host');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _snack(result['message'] ?? 'Invalid email or password');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('Connection error: $e');
      }
    }
  }

  // ── Host Login ─────────────────────────────────────────
  Future<void> _goHost() async {
    final email    = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _snack('Please enter email and password');
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await ApiService.instance.login(
        email:    email,
        password: password,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (result['success'] == true) {
        Navigator.pushReplacementNamed(context, '/host');
      } else {
        _snack(result['message'] ?? 'Invalid email or password');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('Connection error: $e');
      }
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
      ]),
      backgroundColor: kCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 4),
    ),
  );

  @override
  void initState() {
    super.initState();
    _videoCtrl = VideoPlayerController.asset('assets/videos/bg.mp4')
      ..initialize().then((_) {
        _videoCtrl.setLooping(true);
        _videoCtrl.setVolume(0);
        _videoCtrl.play();
        if (mounted) setState(() => _videoReady = true);
      }).catchError((e) => debugPrint('Video: $e'));
  }

  @override
  void dispose() {
    _videoCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(children: [
        // Video BG
        if (_videoReady)
          Positioned.fill(child: Opacity(opacity: 0.12,
            child: FittedBox(fit: BoxFit.cover,
              child: SizedBox(width: _videoCtrl.value.size.width,
                  height: _videoCtrl.value.size.height,
                  child: VideoPlayer(_videoCtrl))))),
        // Glow
        Positioned(top: -80, left: -60,
          child: Container(width: 260, height: 260,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: kGreen.withOpacity(0.07)))),
        // Content
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 48),

              // Logo
              Row(children: [
                Container(width: 52, height: 52,
                  decoration: BoxDecoration(color: kGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kGreen.withOpacity(0.3))),
                  child: const Icon(Icons.ev_station, color: kGreen, size: 28)),
                const SizedBox(width: 12),
                const Text('ChargeGuard',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 48),

              const Text('Welcome Back!',
                  style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Login to continue charging',
                  style: TextStyle(color: Colors.white54, fontSize: 15)),
              const SizedBox(height: 36),

              // Email
              _lbl('Email Address'),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: _deco(hint: 'example@email.com', icon: Icons.email_outlined)),
              const SizedBox(height: 16),

              // Password
              _lbl('Password'),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: _deco(
                  hint: 'Enter your password',
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.white38, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure)))),
              const SizedBox(height: 14),

              // Remember + Forgot
              Row(children: [
                GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Row(children: [
                    AnimatedContainer(duration: const Duration(milliseconds: 200),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: _rememberMe ? kGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _rememberMe ? kGreen : kBorder, width: 1.5)),
                      child: _rememberMe
                          ? const Icon(Icons.check, size: 13, color: Colors.black) : null),
                    const SizedBox(width: 8),
                    const Text('Remember me',
                        style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ]),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _snack('Coming soon...'),
                  child: const Text('Forgot password?',
                      style: TextStyle(color: kGreen, fontSize: 13, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 32),

              // Login Button
              SizedBox(width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen, foregroundColor: Colors.black,
                    disabledBackgroundColor: kGreen.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                      : const Text('Login',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)))),
              const SizedBox(height: 14),

              // Host Button
              SizedBox(width: double.infinity, height: 54,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _goHost,
                  icon: const Icon(Icons.home_outlined, color: kGreen, size: 20),
                  label: const Text("I'm a Charger Host",
                      style: TextStyle(color: kGreen, fontSize: 15, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kGreen, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
              const SizedBox(height: 32),

              // Sign Up
              Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text("Don't have an account? ",
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SignupScreen())),
                  child: const Text('Sign Up',
                      style: TextStyle(color: kGreen, fontSize: 14, fontWeight: FontWeight.w700))),
              ])),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _lbl(String t) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(
        color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)));

  InputDecoration _deco({required String hint, required IconData icon, Widget? suffix}) =>
    InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Colors.white30),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      suffixIcon: suffix,
      filled: true, fillColor: kCard,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kGreen, width: 1.5)));
}
