import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import '../utils/app_settings.dart';
import 'login_screen.dart';

class HostSettingsScreen extends StatefulWidget {
  const HostSettingsScreen({super.key});
  @override
  State<HostSettingsScreen> createState() => _HostSettingsScreenState();
}

class _HostSettingsScreenState extends State<HostSettingsScreen> {
  final _businessCtrl = TextEditingController();
  final _bioCtrl      = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _bankCtrl     = TextEditingController();
  final _ibanCtrl     = TextEditingController();
  final _oldPassCtrl  = TextEditingController();
  final _newPassCtrl  = TextEditingController();
  final _confPassCtrl = TextEditingController();

  bool _loadingProfile = true;
  bool _savingProfile  = false;
  bool _savingBank     = false;
  bool _changingPass   = false;
  bool _savingNotif    = false;
  bool _notifBookings  = true;
  bool _notifPayouts   = true;
  bool _notifReviews   = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _businessCtrl.dispose(); _bioCtrl.dispose(); _phoneCtrl.dispose();
    _bankCtrl.dispose(); _ibanCtrl.dispose();
    _oldPassCtrl.dispose(); _newPassCtrl.dispose(); _confPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final result = await ApiService.instance.getHostProfile();
    if (mounted) {
      setState(() {
        _loadingProfile = false;
        if (result['success']) {
          final d = result['data'] as Map<String, dynamic>;
          _businessCtrl.text = d['businessName'] as String? ?? '';
          _bioCtrl.text      = d['bio']          as String? ?? '';
          _phoneCtrl.text    = d['phone']         as String? ?? '';
          _bankCtrl.text     = d['bankName']      as String? ?? '';
          _ibanCtrl.text     = d['iban']          as String? ?? '';
          _notifBookings     = d['notifBookings'] as bool? ?? true;
          _notifPayouts      = d['notifPayouts']  as bool? ?? true;
          _notifReviews      = d['notifReviews']  as bool? ?? true;
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    final result = await ApiService.instance.updateHostProfile({
      'businessName': _businessCtrl.text.trim(),
      'bio':          _bioCtrl.text.trim(),
      'phone':        _phoneCtrl.text.trim(),
    });
    if (mounted) {
      setState(() => _savingProfile = false);
      _snack(result['success'] ? 'Business info saved ✅' : result['message'] ?? 'Error',
          isError: !result['success']);
    }
  }

  Future<void> _saveBank() async {
    setState(() => _savingBank = true);
    final result = await ApiService.instance.updateHostProfile({
      'bankName': _bankCtrl.text.trim(),
      'iban':     _ibanCtrl.text.trim(),
    });
    if (mounted) {
      setState(() => _savingBank = false);
      _snack(result['success'] ? 'Banking info saved ✅' : result['message'] ?? 'Error',
          isError: !result['success']);
    }
  }

  Future<void> _saveNotifications() async {
    setState(() => _savingNotif = true);
    await ApiService.instance.updateHostProfile({
      'notifBookings': _notifBookings,
      'notifPayouts':  _notifPayouts,
      'notifReviews':  _notifReviews,
    });
    if (mounted) setState(() => _savingNotif = false);
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text != _confPassCtrl.text) {
      _snack('Passwords do not match', isError: true); return;
    }
    if (_newPassCtrl.text.length < 6) {
      _snack('Min 6 characters', isError: true); return;
    }
    setState(() => _changingPass = true);
    final result = await ApiService.instance.changePassword(
      oldPassword: _oldPassCtrl.text,
      newPassword: _newPassCtrl.text);
    if (mounted) {
      setState(() => _changingPass = false);
      _snack(result['success'] ? 'Password changed ✅' : result['message'] ?? 'Error',
          isError: !result['success']);
      if (result['success']) {
        _oldPassCtrl.clear(); _newPassCtrl.clear(); _confPassCtrl.clear();
      }
    }
  }

  void _logout() {
    ApiService.instance.logout();
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _snack(String msg, {bool isError = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? kRed : cCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  @override
  Widget build(BuildContext context) {
    final session = UserSession.instance;
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Settings', context),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Host Card
                Container(padding: const EdgeInsets.all(16), decoration: kCardDeco(),
                  child: Row(children: [
                    Container(width: 56, height: 56,
                      decoration: BoxDecoration(color: kGreen.withOpacity(0.12), shape: BoxShape.circle),
                      child: Center(child: Text(
                        session.firstName.isNotEmpty ? session.firstName[0].toUpperCase() : 'H',
                        style: const TextStyle(color: kGreen, fontSize: 24, fontWeight: FontWeight.w800)))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(session.fullName, style: kTitle(15)),
                      Text(session.email,    style: kSub(12)),
                      const SizedBox(height: 4),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: kGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text(_businessCtrl.text.isEmpty ? 'Independent' : _businessCtrl.text,
                            style: const TextStyle(color: kGreen, fontSize: 11, fontWeight: FontWeight.w700))),
                    ])),
                  ])),
                const SizedBox(height: 24),

                // Business Info
                _section('🏢 Business Information'),
                _field(_businessCtrl, 'Business Name', Icons.business,
                    hint: 'Your charging network name'),
                const SizedBox(height: 12),
                _field(_bioCtrl, 'Bio', Icons.description_outlined,
                    maxLines: 3, hint: 'Tell customers about your service'),
                const SizedBox(height: 12),
                _field(_phoneCtrl, 'Phone Number', Icons.phone,
                    type: TextInputType.phone),
                const SizedBox(height: 12),
                _saveBtn('Save Business Info', _savingProfile, _saveProfile),
                const SizedBox(height: 24),

                // Banking
                _section('🏦 Banking Information'),
                Text('Required to receive payouts', style: kSub(12)),
                const SizedBox(height: 12),
                _field(_bankCtrl, 'Bank Name', Icons.account_balance),
                const SizedBox(height: 12),
                _field(_ibanCtrl, 'IBAN Number', Icons.credit_card),
                const SizedBox(height: 12),
                _saveBtn('Save Banking Info', _savingBank, _saveBank),
                const SizedBox(height: 24),

                // Notifications
                _section('🔔 Notifications'),
                _toggle('New Bookings', 'Alert when a customer books your charger',
                    _notifBookings, (v) { setState(() => _notifBookings = v); _saveNotifications(); }),
                _toggle('Payout Updates', 'Alert on payout status changes',
                    _notifPayouts, (v) { setState(() => _notifPayouts = v); _saveNotifications(); }),
                _toggle('New Reviews', 'Alert when customers leave reviews',
                    _notifReviews, (v) { setState(() => _notifReviews = v); _saveNotifications(); }),
                const SizedBox(height: 24),

                // App Settings
                _section('⚙️ App'),
                ListenableBuilder(
                  listenable: AppSettings.instance,
                  builder: (_, __) => Column(children: [
                    _toggle('Dark Mode', 'Switch between dark and light theme',
                        AppSettings.instance.isDark,
                        (_) => AppSettings.instance.toggleTheme()),
                    _toggle('Arabic', 'Switch app language to Arabic',
                        AppSettings.instance.isArabic,
                        (_) => AppSettings.instance.toggleLanguage()),
                  ])),
                const SizedBox(height: 24),

                // Change Password
                _section('🔐 Change Password'),
                _passField(_oldPassCtrl, 'Current Password'),
                const SizedBox(height: 12),
                _passField(_newPassCtrl, 'New Password'),
                const SizedBox(height: 12),
                _passField(_confPassCtrl, 'Confirm New Password'),
                const SizedBox(height: 12),
                _saveBtn('Change Password', _changingPass, _changePassword,
                    color: Colors.blueAccent),
                const SizedBox(height: 24),

                // Logout
                _section('⚠️ Account'),
                Container(
                  decoration: BoxDecoration(color: kRed.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kRed.withOpacity(0.25))),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: kRed),
                    title: const Text('Log Out',
                        style: TextStyle(color: kRed, fontWeight: FontWeight.w700)),
                    subtitle: Text('You will need to sign in again', style: kSub(11)),
                    trailing: const Icon(Icons.chevron_right, color: kRed),
                    onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
                      backgroundColor: cCard,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('Log Out?', style: kTitle(16)),
                      content: Text('Are you sure?', style: kSub(13)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context),
                            child: Text('Cancel', style: TextStyle(color: cSub))),
                        ElevatedButton(
                          onPressed: () { Navigator.pop(context); _logout(); },
                          style: ElevatedButton.styleFrom(backgroundColor: kRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: const Text('Log Out')),
                      ])))),
                const SizedBox(height: 32),
              ])),
    );
  }

  Widget _section(String t) => Padding(padding: const EdgeInsets.only(bottom: 12),
    child: Text(t, style: kTitle(15)));

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? type, int maxLines = 1, String? hint}) =>
    TextField(controller: ctrl, keyboardType: type, maxLines: maxLines,
      style: TextStyle(color: cTitle, fontSize: 14),
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: cSub),
        hintText: hint, hintStyle: TextStyle(color: cSub2, fontSize: 12),
        prefixIcon: maxLines == 1 ? Icon(icon, color: cSub2, size: 20) : null,
        filled: true, fillColor: cCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kGreen, width: 1.5))));

  Widget _passField(TextEditingController ctrl, String label) =>
    StatefulBuilder(builder: (_, set) {
      bool obs = true;
      return TextField(controller: ctrl, obscureText: obs,
        style: TextStyle(color: cTitle, fontSize: 14),
        decoration: InputDecoration(
          labelText: label, labelStyle: TextStyle(color: cSub),
          prefixIcon: Icon(Icons.lock_outline, color: cSub2, size: 20),
          suffixIcon: IconButton(
            icon: Icon(obs ? Icons.visibility_off : Icons.visibility,
                color: cSub2, size: 18),
            onPressed: () => set(() => obs = !obs)),
          filled: true, fillColor: cCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: cBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: cBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kGreen, width: 1.5))));
    });

  Widget _saveBtn(String label, bool loading, VoidCallback onTap,
      {Color color = kGreen}) =>
    SizedBox(width: double.infinity, height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color, foregroundColor: Colors.black,
          disabledBackgroundColor: color.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: loading
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))));

  Widget _toggle(String title, String sub, bool val, ValueChanged<bool> onChange) =>
    Container(margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: kCardDeco(radius: 12),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: kTitle(13)),
          Text(sub,   style: kSub(11)),
        ])),
        Switch(value: val, onChanged: onChange, activeColor: kGreen),
      ]));
}
