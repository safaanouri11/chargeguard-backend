import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import '../utils/app_settings.dart';
import 'signup_screen.dart';
import 'host_signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _passFocus = FocusNode();

  late VideoPlayerController _videoCtrl;

  bool _obscure    = true;
  // Default to true — most apps remember by default, and the user has the
  // option to opt out by unchecking. Avoids surprising sign-outs.
  bool _rememberMe = true;
  bool _videoReady = false;
  bool _loading    = false;

  String? _emailError() {
    final v = _emailCtrl.text.trim();
    if (v.isEmpty) return null;
    final ok = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(v);
    return ok ? null : 'Enter a valid email address';
  }

  // ── Login ──────────────────────────────────────────────
  Future<void> _login() async {
    final email    = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _snack('Please enter email and password');
      return;
    }
    if (_emailError() != null) {
      _snack(_emailError()!);
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await ApiService.instance.login(
        email:    email,
        password: password,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (result['success'] == true) {
        final role = UserSession.instance.role;
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else if (role == 'host') {
          final status = UserSession.instance.hostStatus;
          if (status == 'Approved') {
            Navigator.pushReplacementNamed(context, '/host');
          } else {
            Navigator.pushReplacementNamed(context, '/host-pending');
          }
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
        rememberMe: _rememberMe,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (result['success'] == true) {
        // ignore: use_build_context_synchronously
        TextInput.finishAutofillContext();
        final user = result['data'] as Map<String, dynamic>;
        final role = user['role'] as String? ?? 'driver';

        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else if (role == 'host') {
          final status = user['hostStatus'] as String? ?? 'Approved';
          if (status == 'Approved') {
            Navigator.pushReplacementNamed(context, '/host');
          } else {
            Navigator.pushReplacementNamed(context, '/host-pending');
          }
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

  // ── Forgot Password ────────────────────────────────────
  Future<void> _forgotPassword() async {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);

    await showDialog(context: context, builder: (_) => _ForgotPasswordDialog(
      initialEmail: emailCtrl.text));
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
    _passFocus.dispose();
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
            child: AutofillGroup(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 48),

              // Logo + Language toggle
              Row(children: [
                Container(width: 52, height: 52,
                  decoration: BoxDecoration(color: kGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kGreen.withOpacity(0.3))),
                  child: const Icon(Icons.ev_station, color: kGreen, size: 28)),
                const SizedBox(width: 12),
                const Text('ChargeGuard',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const Spacer(),
                _LangToggle(),
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
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email, AutofillHints.username],
                onSubmitted: (_) => _passFocus.requestFocus(),
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: _deco(
                  hint: 'example@email.com',
                  icon: Icons.email_outlined,
                  errorText: _emailError(),
                )),
              const SizedBox(height: 16),

              // Password
              _lbl('Password'),
              TextField(
                controller: _passCtrl,
                focusNode: _passFocus,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _loading ? null : _login(),
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
                InkWell(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(children: [
                      AnimatedContainer(duration: const Duration(milliseconds: 200),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: _rememberMe ? kGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _rememberMe ? kGreen : Colors.white54, width: 1.8)),
                        child: _rememberMe
                            ? const Icon(Icons.check, size: 15, color: Colors.black) : null),
                      const SizedBox(width: 10),
                      Text('Remember me',
                          style: TextStyle(
                              color: _rememberMe ? Colors.white : Colors.white54,
                              fontSize: 13,
                              fontWeight: _rememberMe ? FontWeight.w600 : FontWeight.w500)),
                    ]),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _forgotPassword,
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
              const SizedBox(height: 12),

              // Become a Host link
              Center(child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HostSignupScreen())),
                child: const Text('Become a Host →',
                    style: TextStyle(color: kGreen, fontSize: 13, fontWeight: FontWeight.w700)))),
              const SizedBox(height: 24),

              // Version footer
              Center(child: Text('v1.0.0',
                  style: const TextStyle(color: Colors.white24, fontSize: 11))),
              const SizedBox(height: 16),
            ])),
          ),
        ),
      ]),
    );
  }

  Widget _lbl(String t) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(
        color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)));

  InputDecoration _deco({required String hint, required IconData icon, Widget? suffix, String? errorText}) =>
    InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Colors.white30),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      suffixIcon: suffix,
      filled: true, fillColor: kCard,
      errorText: errorText,
      errorStyle: const TextStyle(color: Color(0xFFFF8A80), fontSize: 11),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kGreen, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF8A80))),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.5)));
}

// ─────────────────────────────────────────────────────────
//  Language toggle (English ↔ Arabic) — top-right of login
// ─────────────────────────────────────────────────────────
class _LangToggle extends StatefulWidget {
  @override
  State<_LangToggle> createState() => _LangToggleState();
}

class _LangToggleState extends State<_LangToggle> {
  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    return GestureDetector(
      onTap: () {
        s.toggleLanguage();
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.language, color: Colors.white70, size: 14),
          const SizedBox(width: 5),
          Text(s.isArabic ? 'EN' : 'AR',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Forgot Password Dialog — 2 steps
// ─────────────────────────────────────────────────────────
class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  const _ForgotPasswordDialog({this.initialEmail = ''});
  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailCtrl   = TextEditingController();
  final _codeCtrl    = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confCtrl    = TextEditingController();

  int  _step    = 0; // 0=email, 1=code+password
  bool _loading = false;
  bool _obscure = true;
  String _resetCode = ''; // demo only

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); _codeCtrl.dispose();
    _passCtrl.dispose(); _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final result = await ApiService.instance.forgotPassword(_emailCtrl.text.trim());
    setState(() => _loading = false);
    if (result['success']) {
      _resetCode = result['data']?['code'] as String? ?? '';
      setState(() => _step = 1);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Code: $_resetCode (Demo — check terminal)'),
        backgroundColor: const Color(0xFF131929),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Error'),
        backgroundColor: kRed, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  Future<void> _resetPassword() async {
    if (_codeCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) return;
    if (_passCtrl.text != _confCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Passwords do not match'), backgroundColor: kRed,
        behavior: SnackBarBehavior.floating));
      return;
    }
    if (_passCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Min 6 characters'), backgroundColor: kRed,
        behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _loading = true);
    final result = await ApiService.instance.resetPassword(
      _emailCtrl.text.trim(), _codeCtrl.text.trim(), _passCtrl.text);
    setState(() => _loading = false);
    if (result['success']) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password reset! Please login ✅'),
        backgroundColor: Color(0xFF131929),
        behavior: SnackBarBehavior.floating));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Error'),
        backgroundColor: kRed, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF131929),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lock_reset, color: kGreen, size: 24),
            const SizedBox(width: 10),
            Text('Reset Password', style: const TextStyle(color: Colors.white,
                fontSize: 17, fontWeight: FontWeight.w800)),
            const Spacer(),
            GestureDetector(onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.white38, size: 20)),
          ]),
          const SizedBox(height: 20),

          if (_step == 0) ...[
            const Text('Enter your email address and we\'ll send you a reset code.',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Email Address', labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.white38, size: 20),
                filled: true, fillColor: const Color(0xFF0A0E1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E2A3A))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E2A3A))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kGreen, width: 1.5)))),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendCode,
                style: ElevatedButton.styleFrom(backgroundColor: kGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('Send Reset Code',
                        style: TextStyle(fontWeight: FontWeight.w800)))),
          ],

          if (_step == 1) ...[
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kGreen.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.info_outline, color: kGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Code sent to ${_emailCtrl.text}',
                    style: const TextStyle(color: kGreen, fontSize: 12))),
              ])),
            const SizedBox(height: 14),
            _dialogField(_codeCtrl, 'Reset Code', Icons.pin),
            const SizedBox(height: 12),
            _dialogField(_passCtrl, 'New Password', Icons.lock_outline, obscure: true),
            const SizedBox(height: 12),
            _dialogField(_confCtrl, 'Confirm Password', Icons.lock_outline, obscure: true),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => setState(() => _step = 0),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF1E2A3A)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Back', style: TextStyle(color: Colors.white54)))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                onPressed: _loading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(backgroundColor: kGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _loading
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('Reset', style: TextStyle(fontWeight: FontWeight.w800)))),
            ]),
          ],
        ])));
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon,
      {bool obscure = false}) =>
    StatefulBuilder(builder: (_, set) => TextField(
      controller: ctrl, obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true, fillColor: const Color(0xFF0A0E1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E2A3A))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E2A3A))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kGreen, width: 1.5)))));
}
