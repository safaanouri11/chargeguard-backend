import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/app_settings.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _s = AppSettings.instance;
  bool _biometric = false;

  @override
  void initState() {
    super.initState();
    _s.addListener(_refresh);
  }

  @override
  void dispose() {
    _s.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  // ── Change Password ───────────────────────────────────────
  void _changePassword() {
    final oldCtrl  = TextEditingController();
    final newCtrl  = TextEditingController();
    final confCtrl = TextEditingController();
    bool obscOld = true, obscNew = true, obscConf = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: cBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(L.changePass, style: kTitle(18)),
            const SizedBox(height: 6),
            Text('Enter your current password and choose a new one', style: kSub(13)),
            const SizedBox(height: 20),
            _passField(oldCtrl,  'Current Password', obscOld,  () => set(() => obscOld  = !obscOld)),
            const SizedBox(height: 12),
            _passField(newCtrl,  'New Password',     obscNew,  () => set(() => obscNew  = !obscNew)),
            const SizedBox(height: 12),
            _passField(confCtrl, 'Confirm New Password', obscConf, () => set(() => obscConf = !obscConf)),
            const SizedBox(height: 8),
            // Password rules hint
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Password must contain:', style: kSub(11)),
                const SizedBox(height: 6),
                _rule('At least 8 characters'),
                _rule('Uppercase letter (A-Z)'),
                _rule('Number (0-9)'),
                _rule('Symbol (!@#\$%^&*)'),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (oldCtrl.text.trim().isEmpty) {
                    _snack('Enter your current password'); return;
                  }
                  if (newCtrl.text.length < 8) {
                    _snack('Password must be at least 8 characters'); return;
                  }
                  if (newCtrl.text != confCtrl.text) {
                    _snack('Passwords do not match!'); return;
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Row(children: [
                      Icon(Icons.check_circle, color: kGreen, size: 18),
                      SizedBox(width: 8),
                      Text('Password changed successfully! ✅'),
                    ]),
                    backgroundColor: cCard, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                },
                style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Update Password',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)))),
          ]),
        ),
      ),
    );
  }

  Widget _rule(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(children: [
      const Icon(Icons.circle, size: 5, color: kGreen),
      const SizedBox(width: 6),
      Text(t, style: TextStyle(color: cSub, fontSize: 11)),
    ]),
  );

  Widget _passField(TextEditingController ctrl, String label, bool obscure, VoidCallback toggle) =>
      TextField(controller: ctrl, obscureText: obscure,
        style: TextStyle(color: cTitle, fontSize: 15),
        decoration: InputDecoration(
          labelText: label, labelStyle: TextStyle(color: cSub),
          prefixIcon: Icon(Icons.lock_outline, color: cSub2, size: 20),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: cSub2, size: 20), onPressed: toggle),
          filled: true, fillColor: cBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: cBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: cBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kGreen, width: 1.5))));

  // ── Biometric Login ───────────────────────────────────────
  void _toggleBiometric(bool val) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.fingerprint, color: Color(0xFF6C63FF), size: 28),
          const SizedBox(width: 10),
          Text(val ? 'Enable Biometric' : 'Disable Biometric',
              style: TextStyle(color: cTitle, fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        content: Text(
          val
              ? 'Use Face ID or Fingerprint to log in quickly and securely. Your biometric data is stored only on your device.'
              : 'Are you sure you want to disable biometric login? You will need to enter your password each time.',
          style: kSub(13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: cSub))),
          ElevatedButton(
            onPressed: () {
              setState(() => _biometric = val);
              Navigator.pop(context);
              _snack(val ? '🔐 Biometric login enabled!' : 'Biometric login disabled');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: val ? const Color(0xFF6C63FF) : Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text(val ? 'Enable' : 'Disable',
                style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  // ── Delete Account ────────────────────────────────────────
  void _deleteAccount() {
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          backgroundColor: cCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text('Delete Account',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('This action is permanent and cannot be undone. All your data, bookings, and points will be deleted.',
                style: kSub(13)),
            const SizedBox(height: 16),
            Text('Type "DELETE" to confirm:', style: kSub(12)),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              onChanged: (_) => set(() {}),
              style: TextStyle(color: cTitle, fontSize: 15, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'DELETE',
                hintStyle: TextStyle(color: cSub2),
                filled: true, fillColor: cBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5))),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: cSub))),
            ElevatedButton(
              onPressed: confirmCtrl.text == 'DELETE'
                  ? () {
                      Navigator.pop(ctx);
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  disabledBackgroundColor: Colors.red.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Delete Forever',
                  style: TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: cCard, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar(L.settings, context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── APPEARANCE
          _sTitle(L.appearance),
          const SizedBox(height: 12),
          _card(icon: _s.isDark ? Icons.dark_mode : Icons.light_mode_outlined,
              iconColor: _s.isDark ? const Color(0xFF6C63FF) : Colors.amber,
              title: L.theme, sub: _s.isDark ? L.darkMode : L.lightMode,
              trailing: _sw(_s.isDark, (_) {
                _s.toggleTheme();
                _snack(_s.isDark ? '🌙 ${L.darkMode}' : '☀️ ${L.lightMode}');
              })),
          const SizedBox(height: 10),
          _card(icon: Icons.language_outlined, iconColor: kGreen,
              title: L.language, sub: _s.isArabic ? 'العربية 🇸🇦' : 'English 🇬🇧',
              trailing: GestureDetector(
                onTap: () {
                  _s.toggleLanguage();
                  _snack(_s.isArabic ? '🇸🇦 تم التغيير للعربية' : '🇬🇧 Changed to English');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: kGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kGreen.withOpacity(0.3))),
                  child: Text(_s.isArabic ? 'AR  🇸🇦' : 'EN  🇬🇧',
                      style: const TextStyle(color: kGreen, fontSize: 13, fontWeight: FontWeight.w700))))),
          const SizedBox(height: 24),

          // ── NOTIFICATIONS
          _sTitle(L.notifications),
          const SizedBox(height: 12),
          _card(icon: Icons.bolt, iconColor: kGreen,
              title: 'Charging Done', sub: 'Alert when car is fully charged',
              trailing: _sw(_s.chargingDone, (_) => _s.toggleChargingDone())),
          const SizedBox(height: 10),
          _card(icon: Icons.calendar_today_outlined, iconColor: Colors.blueAccent,
              title: 'Booking Reminder', sub: '15 min before your booking',
              trailing: _sw(_s.bookingReminder, (_) => _s.toggleBookingReminder())),
          const SizedBox(height: 10),
          _card(icon: Icons.local_offer_outlined, iconColor: const Color(0xFFFF6B6B),
              title: 'Offers & Promos', sub: 'New deals and discounts',
              trailing: _sw(_s.offers, (_) => _s.toggleOffers())),
          const SizedBox(height: 10),
          _card(icon: Icons.battery_alert_outlined, iconColor: Colors.orange,
              title: 'Low Battery', sub: 'Notify when battery below 20%',
              trailing: _sw(_s.lowBattery, (_) => _s.toggleLowBattery())),
          const SizedBox(height: 24),

          // ── SECURITY
          _sTitle(L.security),
          const SizedBox(height: 12),
          _card(icon: Icons.lock_outline, iconColor: Colors.orange,
              title: L.changePass, sub: 'Update your login password',
              trailing: Icon(Icons.chevron_right, color: cSub2, size: 20),
              onTap: _changePassword),
          const SizedBox(height: 10),
          _card(icon: Icons.fingerprint, iconColor: const Color(0xFF6C63FF),
              title: 'Biometric Login', sub: 'Face ID / Fingerprint',
              trailing: _sw(_biometric, _toggleBiometric)),
          const SizedBox(height: 24),

          // ── ABOUT
          _sTitle(L.about),
          const SizedBox(height: 12),
          _card(icon: Icons.info_outline, iconColor: cSub,
              title: 'App Version', sub: 'ChargeGuard v1.0.0',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Text('Latest',
                    style: TextStyle(color: kGreen, fontSize: 11, fontWeight: FontWeight.w700)))),
          const SizedBox(height: 10),
          _card(icon: Icons.privacy_tip_outlined, iconColor: Colors.blueAccent,
              title: 'Privacy Policy', sub: 'How we handle your data',
              trailing: Icon(Icons.chevron_right, color: cSub2, size: 20),
              onTap: () => goTo(context, const PrivacyPolicyScreen())),
          const SizedBox(height: 10),
          _card(icon: Icons.description_outlined, iconColor: Colors.blueAccent,
              title: 'Terms of Use', sub: 'Read our terms and conditions',
              trailing: Icon(Icons.chevron_right, color: cSub2, size: 20),
              onTap: () => goTo(context, const TermsScreen())),
          const SizedBox(height: 24),

          // ── Delete Account
          GestureDetector(
            onTap: _deleteAccount,
            child: Container(width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.2))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.delete_forever_outlined, color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                Text(L.deleteAccount,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w700)),
              ])),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _sTitle(String t) => Text(t.toUpperCase(),
      style: TextStyle(color: cSub2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1));

  Widget _sw(bool val, ValueChanged<bool> onChange) => Switch(
    value: val, onChanged: onChange,
    activeColor: kGreen, activeTrackColor: kGreen.withOpacity(0.3),
    inactiveThumbColor: Colors.grey, inactiveTrackColor: Colors.grey.withOpacity(0.3));

  Widget _card({required IconData icon, required Color iconColor,
    required String title, required String sub,
    required Widget trailing, VoidCallback? onTap}) =>
    GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: kCardDeco(radius: 14),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: cTitle, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: cSub2, fontSize: 11)),
          ])),
          trailing,
        ])));
}
