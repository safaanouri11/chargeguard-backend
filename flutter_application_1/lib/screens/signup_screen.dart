import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import 'host_signup_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  int    _role      = 0;
  int    _step      = 1;
  bool   _obscure   = true;
  bool   _submitted = false;
  bool   _loading   = false;
  String _region    = 'Palestine';

  final _regions = ['Palestine', 'Jordan', 'UAE', 'Saudi Arabia', 'UK'];

  String? get _emailError {
    if (!_submitted) return null;
    final e = _emailCtrl.text.trim();
    if (e.isEmpty)        return 'Email is required';
    if (!e.contains('@')) return 'Email must contain @';
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$', caseSensitive: false).hasMatch(e))
      return 'Enter a valid email';
    return null;
  }

  String? get _passError {
    if (!_submitted) return null;
    final p = _passCtrl.text;
    if (p.isEmpty)                            return 'Password is required';
    if (p.length < 8)                         return 'At least 8 characters';
    if (!p.contains(RegExp(r'[A-Z]')))        return 'Must contain uppercase (A-Z)';
    if (!p.contains(RegExp(r'[0-9]')))        return 'Must contain a number';
    if (!p.contains(RegExp(r'[!@#\$%^&*]'))) return 'Must contain a symbol';
    return null;
  }

  bool get _step1Valid =>
      _firstCtrl.text.trim().isNotEmpty && _lastCtrl.text.trim().isNotEmpty;

  int _strength(String p) {
    int s = 0;
    if (p.length >= 8)                       s++;
    if (p.contains(RegExp(r'[A-Z]')))        s++;
    if (p.contains(RegExp(r'[0-9]')))        s++;
    if (p.contains(RegExp(r'[!@#\$%^&*]'))) s++;
    return s;
  }

  @override
  void dispose() {
    _firstCtrl.dispose(); _lastCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step == 1) {
      if (!_step1Valid) { _snack('Please fill your first and last name'); return; }
      setState(() { _step = 2; _submitted = false; });
    } else {
      setState(() => _submitted = true);
      if (_emailError != null) { _snack(_emailError!); return; }
      if (_passError  != null) { _snack(_passError!);  return; }

      setState(() => _loading = true);

      final result = await ApiService.instance.register(
        firstName: _firstCtrl.text.trim(),
        lastName:  _lastCtrl.text.trim(),
        email:     _emailCtrl.text.trim(),
        password:  _passCtrl.text,
        role:      'driver',
        region:    _region,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (result['success']) {
        _snack('Account created! Welcome 🎉');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        });
      } else {
        _snack(result['message'] ?? 'Registration failed');
      }
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: kCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(children: [
          _topBar(),
          _progressBar(),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: AnimatedSwitcher(duration: const Duration(milliseconds: 300),
              child: _step == 1 ? _step1Widget() : _step2Widget()),
          )),
          _bottomBtn(),
        ]),
      ),
    );
  }

  Widget _topBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Row(children: [
      GestureDetector(
        onTap: () => _step == 2
            ? setState(() { _step = 1; _submitted = false; })
            : Navigator.pop(context),
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder)),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16))),
      const Spacer(),
      const Icon(Icons.ev_station, color: kGreen, size: 22),
      const SizedBox(width: 8),
      const Text('ChargeGuard',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
      const Spacer(),
      const SizedBox(width: 40),
    ]));

  Widget _progressBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Step $_step of 2',
            style: const TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('${_step * 50}%', style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(value: _step / 2,
          backgroundColor: kCard, valueColor: const AlwaysStoppedAnimation(kGreen), minHeight: 6)),
      const SizedBox(height: 4),
    ]));

  Widget _step1Widget() => Column(key: const ValueKey(1),
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 10),
    const Text('Create Account',
        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
    const SizedBox(height: 6),
    const Text('Sign up as an EV Driver', style: TextStyle(color: Colors.white54, fontSize: 14)),
    const SizedBox(height: 28),
    _lbl('First Name'),
    _tf(_firstCtrl, 'Enter first name', Icons.person_outline),
    const SizedBox(height: 16),
    _lbl('Last Name'),
    _tf(_lastCtrl,  'Enter last name',  Icons.person_outline),
    const SizedBox(height: 16),
    _lbl('Region'),
    _dropdown(),
    const SizedBox(height: 16),
  ]);

  Widget _step2Widget() {
    final pw = _passCtrl.text;
    final st = _strength(pw);
    return Column(key: const ValueKey(2), crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 10),
      const Text('Almost There!',
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      const Text('Set your login credentials', style: TextStyle(color: Colors.white54, fontSize: 14)),
      const SizedBox(height: 24),
      // Summary
      Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kGreen.withOpacity(0.07), borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kGreen.withOpacity(0.25))),
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: kGreen.withOpacity(0.12), shape: BoxShape.circle),
            child: const Icon(Icons.directions_car, color: kGreen, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_firstCtrl.text} ${_lastCtrl.text}',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            Text('EV Driver · $_region',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ])),
          GestureDetector(onTap: () => setState(() { _step = 1; _submitted = false; }),
            child: const Text('Edit', style: TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w600))),
        ])),
      const SizedBox(height: 24),
      _lbl('Email Address'),
      TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
        onChanged: (_) => setState(() {}), style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: _deco(hint: 'example@email.com', icon: Icons.email_outlined, error: _emailError,
          suffix: _emailCtrl.text.isNotEmpty
              ? Icon(_emailError == null ? Icons.check_circle : Icons.cancel,
                  color: _emailError == null ? kGreen : kRed, size: 20) : null)),
      if (_emailError != null) _errMsg(_emailError!),
      const SizedBox(height: 16),
      _lbl('Password'),
      TextField(controller: _passCtrl, obscureText: _obscure,
        onChanged: (_) => setState(() {}), style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: _deco(hint: 'Create a strong password', icon: Icons.lock_outline, error: _passError,
          suffix: IconButton(
            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.white38, size: 20),
            onPressed: () => setState(() => _obscure = !_obscure)))),
      if (_passError != null) _errMsg(_passError!),
      if (pw.isNotEmpty) ...[
        const SizedBox(height: 10),
        _strengthBar(st),
      ],
      const SizedBox(height: 20),
    ]);
  }

  Widget _strengthBar(int st) {
    final colors = [kRed, Colors.orange, Colors.yellow, kGreen];
    final labels = ['Weak', 'Fair', 'Good', 'Strong'];
    final idx    = (st - 1).clamp(0, 3);
    return Row(children: [
      ...List.generate(4, (i) => Expanded(
        child: AnimatedContainer(duration: const Duration(milliseconds: 300),
          height: 5, margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(color: i < st ? colors[idx] : kBorder,
              borderRadius: BorderRadius.circular(3))))),
      const SizedBox(width: 8),
      Text(st > 0 ? labels[idx] : '',
          style: TextStyle(color: st > 0 ? colors[idx] : Colors.transparent,
              fontSize: 11, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _bottomBtn() {
    final enabled = _step == 1 ? _step1Valid : true;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(color: kBg, border: Border(top: BorderSide(color: kBorder))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: double.infinity, height: 54,
          child: ElevatedButton(
            onPressed: (enabled && !_loading) ? _next : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen, disabledBackgroundColor: kGreen.withOpacity(0.2),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: _loading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_step == 1 ? 'Next' : 'Create Account',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Icon(_step == 1 ? Icons.arrow_forward : Icons.check_circle_outline, size: 20),
                  ]))),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Already have an account? ', style: TextStyle(color: Colors.white54, fontSize: 13)),
          GestureDetector(onTap: () => Navigator.pop(context),
            child: const Text('Login', style: TextStyle(color: kGreen, fontSize: 13, fontWeight: FontWeight.w700))),
        ]),
      ]),
    );
  }

  Widget _roleCard(int val, IconData icon, String title, String sub) {
    final sel = _role == val;
    return Expanded(child: GestureDetector(onTap: () => setState(() => _role = val),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: sel ? kGreen.withOpacity(0.1) : kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sel ? kGreen.withOpacity(0.6) : kBorder, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: sel ? kGreen : Colors.white38, size: 28),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(color: sel ? kGreen : Colors.white,
              fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ]))));
  }

  Widget _lbl(String t) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)));

  Widget _errMsg(String msg) => Padding(padding: const EdgeInsets.only(top: 6, left: 4),
    child: Row(children: [
      const Icon(Icons.info_outline, color: kRed, size: 13), const SizedBox(width: 5),
      Expanded(child: Text(msg, style: const TextStyle(color: kRed, fontSize: 12))),
    ]));

  InputDecoration _deco({required String hint, required IconData icon, String? error, Widget? suffix}) =>
    InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Colors.white30),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20), suffixIcon: suffix,
      filled: true, fillColor: error != null ? kRed.withOpacity(0.06) : kCard,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: error != null ? kRed : kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: error != null ? kRed : kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: error != null ? kRed : kGreen, width: 1.5)));

  Widget _tf(TextEditingController ctrl, String hint, IconData icon) =>
    TextField(controller: ctrl, onChanged: (_) => setState(() {}),
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: _deco(hint: hint, icon: icon));

  Widget _dropdown() => DropdownButtonFormField<String>(
    value: _region, dropdownColor: kCard,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38),
    decoration: _deco(hint: '', icon: Icons.location_on_outlined),
    items: _regions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
    onChanged: (v) => setState(() => _region = v!));
}
