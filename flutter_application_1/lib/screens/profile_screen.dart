// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/app_settings.dart';
import '../utils/api_service.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'offers_screen.dart';
import 'help_support_screen.dart';
import 'payment_methods_screen.dart';
import 'camera_screen.dart';
import 'referrals_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool    _loading    = true;
  String? _imageBase64;
  int     _avatarColorIdx = 0;

  final _avatarColors   = [kGreen, const Color(0xFF6C63FF), const Color(0xFFFF6B6B),
    const Color(0xFFFFD700), Colors.blueAccent, Colors.tealAccent];
  final _avatarInitials = ['A', 'M', 'S', 'Y', 'R', 'N'];

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_refresh);
    UserSession.instance.addListener(_refresh);
    _loadProfile();
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_refresh);
    UserSession.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  // ── Load Profile from Backend ─────────────────────────────
  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final result = await ApiService.instance.getProfile();
    if (mounted) setState(() => _loading = false);
    if (!result['success'] && mounted) {
      _snack('Could not load profile');
    }
  }

  // ── Pick Photo ────────────────────────────────────────────
  void _pickImage(String source) {
    final input = html.FileUploadInputElement();
    input.accept   = 'image/*';
    input.multiple = false;
    if (source == 'camera') input.setAttribute('capture', 'user');
    input.click();
    input.onChange.listen((event) {
      final file = input.files?.first;
      if (file == null) return;
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoad.listen((_) async {
        final base64 = reader.result as String;
        setState(() => _imageBase64 = base64);
        // Save to backend
        await ApiService.instance.updateProfile({'avatar': base64});
        if (mounted) Navigator.pop(context);
        _snack('Photo updated! ✅');
      });
    });
  }

  void _pickPhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: cBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Profile Photo', style: kTitle(18)),
          const SizedBox(height: 6),
          Text('Choose avatar color or upload a photo', style: kSub(13)),
          const SizedBox(height: 20),
          // Colors
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_avatarColors.length, (i) {
              final sel   = _avatarColorIdx == i && _imageBase64 == null;
              final color = _avatarColors[i];
              return GestureDetector(
                onTap: () {
                  setState(() { _avatarColorIdx = i; _imageBase64 = null; });
                  Navigator.pop(context);
                  _snack('Avatar updated! ✅');
                },
                child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                  width: sel ? 56 : 46, height: sel ? 56 : 46,
                  decoration: BoxDecoration(color: color.withOpacity(0.85), shape: BoxShape.circle,
                    border: sel ? Border.all(color: Colors.white, width: 3) : null,
                    boxShadow: sel ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 14)] : []),
                  child: Center(child: Text(_avatarInitials[i],
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20)))));
            }),
          ),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: _photoBtn(Icons.camera_alt_outlined, 'Camera', kGreen, () async {
              Navigator.pop(context);
              final result = await Navigator.push<String>(context,
                  MaterialPageRoute(builder: (_) => const CameraScreen()));
              if (result != null && mounted) {
                setState(() => _imageBase64 = result);
                // Upload to backend
                final res = await ApiService.instance.uploadAvatar(result);
                if (mounted) {
                  if (res['success']) {
                    // Update UserSession
                    UserSession.instance.setAvatar(result);
                    _snack('Photo updated! ✅');
                  } else {
                    _snack(res['message'] ?? 'Upload failed');
                  }
                }
              }
            })),
            const SizedBox(width: 12),
            Expanded(child: _photoBtn(Icons.photo_library_outlined, 'Gallery', Colors.blueAccent,
                () => _pickImage('gallery'))),
            const SizedBox(width: 12),
            Expanded(child: _photoBtn(Icons.delete_outline, 'Remove', Colors.redAccent, () {
              setState(() => _imageBase64 = null);
              ApiService.instance.updateProfile({'avatar': ''});
              Navigator.pop(context);
              _snack('Photo removed');
            })),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _photoBtn(IconData icon, String label, Color color, VoidCallback onTap) =>
    GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Column(children: [
          Icon(icon, color: color, size: 24), const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ])));

  // ── Edit Profile ──────────────────────────────────────────
  void _editProfile() {
    final user      = UserSession.instance;
    final firstCtrl = TextEditingController(text: user.firstName);
    final lastCtrl  = TextEditingController(text: user.lastName);
    final phoneCtrl = TextEditingController(text: user.phone);
    final emailCtrl = TextEditingController(text: user.email);

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: cCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: cBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(L.editProfile, style: kTitle(18)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _editField(firstCtrl, 'First Name', Icons.person_outline)),
            const SizedBox(width: 12),
            Expanded(child: _editField(lastCtrl, 'Last Name', Icons.person_outline)),
          ]),
          const SizedBox(height: 14),
          _editField(emailCtrl, 'Email', Icons.email_outlined, type: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _editField(phoneCtrl, 'Phone', Icons.phone_outlined, type: TextInputType.phone),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final result = await ApiService.instance.updateProfile({
                  'firstName': firstCtrl.text.trim(),
                  'lastName':  lastCtrl.text.trim(),
                  'email':     emailCtrl.text.trim(),
                  'phone':     phoneCtrl.text.trim(),
                });
                if (!mounted) return;
                Navigator.pop(context);
                _snack(result['success'] ? 'Profile updated! ✅' : result['message']);
              },
              style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text(L.saveChanges,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)))),
        ]),
      ),
    );
  }

  Widget _editField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) =>
    TextField(controller: ctrl, keyboardType: type,
      style: TextStyle(color: cTitle, fontSize: 15),
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: cSub),
        prefixIcon: Icon(icon, color: cSub2, size: 20),
        filled: true, fillColor: cBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kGreen, width: 1.5))));

  // ── Edit Vehicle ──────────────────────────────────────────
  void _editVehicle() {
    final user        = UserSession.instance;
    final vehicleCtrl = TextEditingController(text: user.vehicle);
    String connector  = user.connector;
    final connectors  = ['CCS2', 'Type 2', 'CHAdeMO', 'GB/T'];

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: cCard,
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
            Text('Edit Vehicle', style: kTitle(18)),
            const SizedBox(height: 20),
            _editField(vehicleCtrl, 'Vehicle Model', Icons.directions_car_outlined),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: Text('Connector Type', style: kSub(13))),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10,
              children: connectors.map((c) {
                final sel = connector == c;
                return GestureDetector(
                  onTap: () => set(() => connector = c),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? kGreen.withOpacity(0.12) : cBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? kGreen : cBorder, width: 1.5)),
                    child: Text(c, style: TextStyle(
                        color: sel ? kGreen : cSub, fontWeight: FontWeight.w700, fontSize: 13))));
              }).toList()),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await ApiService.instance.updateProfile({
                    'vehicle':   vehicleCtrl.text.trim(),
                    'connector': connector,
                  });
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  _snack(result['success'] ? 'Vehicle updated! ✅' : result['message']);
                },
                style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Save Vehicle',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)))),
          ]))));
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: cCard, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user  = UserSession.instance;
    final color = _avatarColors[_avatarColorIdx];
    final initial = user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'A';
    final avatar  = _imageBase64 ?? user.avatar;

    if (_loading) {
      return Scaffold(backgroundColor: cBg,
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: kGreen),
          const SizedBox(height: 16),
          Text('Loading profile...', style: kSub(14)),
        ])));
    }

    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(backgroundColor: cBg, elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(L.myProfile, style: kTitle(18)),
        actions: [
          IconButton(icon: Icon(Icons.settings_outlined, color: cSub),
              onPressed: () => goTo(context, const SettingsScreen())),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: cBorder))),
      body: RefreshIndicator(
        color: kGreen,
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(children: [

            // ── Avatar ─────────────────────────────────────
            GestureDetector(
              onTap: _pickPhoto,
              child: Stack(alignment: Alignment.bottomRight, children: [
                Container(width: 100, height: 100,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: color.withOpacity(0.15),
                    border: Border.all(color: color.withOpacity(0.7), width: 3),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 16)],
                    image: avatar.isNotEmpty
                        ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover)
                        : null),
                  child: avatar.isEmpty
                      ? Center(child: Text(initial,
                          style: TextStyle(color: color, fontSize: 44, fontWeight: FontWeight.w900)))
                      : null),
                Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                      border: Border.all(color: cBg, width: 2),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)]),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.black)),
              ]),
            ),
            const SizedBox(height: 12),

            // ── Name ────────────────────────────────────────
            Text(user.fullName.isNotEmpty ? user.fullName : 'Your Name', style: kTitle(22)),
            const SizedBox(height: 4),
            Text(user.email, style: kSub(14)),
            const SizedBox(height: 10),
            Row(mainAxisSize: MainAxisSize.min, children: [
              _badge(user.role == 'host' ? 'Charger Host' : 'EV Driver', kGreen),
              const SizedBox(width: 8),
              _badge('⭐ 4.8', Colors.amber),
            ]),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _editProfile,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cBorder)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit_outlined, color: cSub, size: 15), const SizedBox(width: 6),
                  Text(L.editProfile,
                      style: TextStyle(color: cSub, fontSize: 13, fontWeight: FontWeight.w600)),
                ]))),
            const SizedBox(height: 24),

            // ── Stats ───────────────────────────────────────
            Row(children: [
              _stat('12',     'Bookings'),
              _stat('340 kWh','Charged'),
              _stat('${user.points}', 'Points'),
            ]),
            const SizedBox(height: 24),

            // ── Balance Card ─────────────────────────────────
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF00E5A0), Color(0xFF00B37A)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
              child: Row(children: [
                const Icon(Icons.account_balance_wallet, color: Colors.black87, size: 28),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Wallet Balance',
                      style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('NIS ${user.balance.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w900)),
                ]),
                const Spacer(),
                GestureDetector(
                  onTap: () => goTo(context, const PaymentMethodsScreen()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('Manage',
                        style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w700)))),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Vehicle Card ─────────────────────────────────
            GestureDetector(
              onTap: _editVehicle,
              child: Container(width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: kCardDeco(),
                child: Row(children: [
                  Container(width: 46, height: 46,
                      decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.directions_car, color: kGreen, size: 24)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user.vehicle.isNotEmpty ? user.vehicle : 'Add your vehicle', style: kTitle(14)),
                    const SizedBox(height: 3),
                    Text('Connector: ${user.connector}', style: kSub(12)),
                  ])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Row(children: [
                      Icon(Icons.edit_outlined, color: kGreen, size: 13), SizedBox(width: 4),
                      Text('Edit', style: TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                    ])),
                ])),
            ),
            const SizedBox(height: 16),

            // ── Info Card ────────────────────────────────────
            Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: kCardDeco(),
              child: Column(children: [
                _infoRow(Icons.phone_outlined,       'Phone',  user.phone.isNotEmpty ? user.phone : 'Not set'),
                Divider(color: cBorder, height: 20),
                _infoRow(Icons.email_outlined,       'Email',  user.email),
                Divider(color: cBorder, height: 20),
                _infoRow(Icons.location_on_outlined, 'Region', user.region),
              ])),
            const SizedBox(height: 16),

            // ── Menu ─────────────────────────────────────────
            _menu(Icons.history_outlined,     'Charging History', 'View past sessions',
                onTap: () => goTo(context, const HistoryScreen())),
            _menu(Icons.local_offer_outlined, L.offers,           'Promos & rewards',
                onTap: () => goTo(context, OffersScreen())),
            _menu(Icons.card_giftcard_outlined, 'Invite Friends',  'Earn 10 NIS per referral',
                onTap: () => goTo(context, const ReferralsScreen())),
            _menu(Icons.credit_card_outlined, 'Payment Methods',  'Manage your cards',
                onTap: () => goTo(context, const PaymentMethodsScreen())),
            _menu(Icons.help_outline,         'Help & Support',   'FAQ & contact us',
                onTap: () => goTo(context, const HelpSupportScreen())),
            _menu(Icons.settings_outlined,    L.settings,         'Theme, language & more',
                onTap: () => goTo(context, const SettingsScreen())),
            _menu(Icons.lock_outlined,        'Change Password',  'Update your password',
                onTap: () => _showChangePassword(context)),
            const SizedBox(height: 12),

            // ── Logout ───────────────────────────────────────
            GestureDetector(
              onTap: () {
                ApiService.instance.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Container(width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.25))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.logout, color: Colors.redAccent, size: 20), const SizedBox(width: 10),
                  Text(L.logout,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w700)),
                ])),
            ),
            const SizedBox(height: 20),
            Text('ChargeGuard ©️ 2026', style: TextStyle(color: cSub2, fontSize: 12)),
            const SizedBox(height: 10),
          ]),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
    child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)));

  Widget _stat(String val, String label) => Expanded(
    child: Container(margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(vertical: 14), decoration: kCardDeco(radius: 14),
      child: Column(children: [
        Text(val, style: kTitle(15)), const SizedBox(height: 4), Text(label, style: kSub(10)),
      ])));

  Widget _infoRow(IconData icon, String label, String val) => Row(children: [
    Icon(icon, color: cSub2, size: 18), const SizedBox(width: 12),
    Text('$label  ', style: kSub(13)),
    Expanded(child: Text(val, style: TextStyle(color: cSub, fontSize: 13), textAlign: TextAlign.end)),
  ]);

  Widget _menu(IconData icon, String title, String sub, {required VoidCallback onTap}) =>
    GestureDetector(onTap: onTap,
      child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
        decoration: kCardDeco(radius: 14),
        child: Row(children: [
          Container(width: 38, height: 38,
              decoration: BoxDecoration(color: kGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: kGreen, size: 18)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: cTitle, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: cSub2, fontSize: 11)),
          ])),
          Icon(Icons.chevron_right, color: cSub2, size: 18),
        ])));
  void _showChangePassword(BuildContext context) {
    final oldCtrl  = TextEditingController();
    final newCtrl  = TextEditingController();
    final confCtrl = TextEditingController();
    bool loading   = false;
    bool obsOld = true, obsNew = true, obsConf = true;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: cCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, set) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: cBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Change Password', style: kTitle(18)),
          const SizedBox(height: 20),

          // Old password
          TextField(controller: oldCtrl, obscureText: obsOld,
            style: TextStyle(color: cTitle),
            decoration: InputDecoration(
              labelText: 'Current Password', labelStyle: TextStyle(color: cSub),
              prefixIcon: Icon(Icons.lock_outline, color: cSub2, size: 20),
              suffixIcon: IconButton(
                icon: Icon(obsOld ? Icons.visibility_off : Icons.visibility, color: cSub2, size: 18),
                onPressed: () => set(() => obsOld = !obsOld)),
              filled: true, fillColor: cBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGreen, width: 1.5)))),
          const SizedBox(height: 12),

          // New password
          TextField(controller: newCtrl, obscureText: obsNew,
            style: TextStyle(color: cTitle),
            decoration: InputDecoration(
              labelText: 'New Password', labelStyle: TextStyle(color: cSub),
              prefixIcon: Icon(Icons.lock_outline, color: cSub2, size: 20),
              suffixIcon: IconButton(
                icon: Icon(obsNew ? Icons.visibility_off : Icons.visibility, color: cSub2, size: 18),
                onPressed: () => set(() => obsNew = !obsNew)),
              filled: true, fillColor: cBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGreen, width: 1.5)))),
          const SizedBox(height: 12),

          // Confirm password
          TextField(controller: confCtrl, obscureText: obsConf,
            style: TextStyle(color: cTitle),
            decoration: InputDecoration(
              labelText: 'Confirm New Password', labelStyle: TextStyle(color: cSub),
              prefixIcon: Icon(Icons.lock_outline, color: cSub2, size: 20),
              suffixIcon: IconButton(
                icon: Icon(obsConf ? Icons.visibility_off : Icons.visibility, color: cSub2, size: 18),
                onPressed: () => set(() => obsConf = !obsConf)),
              filled: true, fillColor: cBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGreen, width: 1.5)))),
          const SizedBox(height: 20),

          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : () async {
                if (newCtrl.text != confCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Passwords do not match'), backgroundColor: kRed,
                    behavior: SnackBarBehavior.floating));
                  return;
                }
                if (newCtrl.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Min 6 characters'), backgroundColor: kRed,
                    behavior: SnackBarBehavior.floating));
                  return;
                }
                set(() => loading = true);
                final result = await ApiService.instance.changePassword(
                  oldPassword: oldCtrl.text,
                  newPassword: newCtrl.text);
                if (ctx.mounted) {
                  set(() => loading = false);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result['success'] ? 'Password changed ✅' : result['message'] ?? 'Error'),
                    backgroundColor: result['success'] ? cCard : kRed,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                  disabledBackgroundColor: kGreen.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Update Password',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)))),
        ]))));
  }

}