import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import 'host_pending_screen.dart';

class HostSignupScreen extends StatefulWidget {
  const HostSignupScreen({super.key});
  @override
  State<HostSignupScreen> createState() => _HostSignupScreenState();
}

class _HostSignupScreenState extends State<HostSignupScreen> {
  final _firstCtrl    = TextEditingController();
  final _lastCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _bankCtrl     = TextEditingController();
  final _ibanCtrl     = TextEditingController();

  String? _idImage;
  String? _licenseImage;

  bool _loading = false;
  bool _obscure = true;
  int  _step    = 0;

  @override
  void dispose() {
    _firstCtrl.dispose(); _lastCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _businessCtrl.dispose(); _phoneCtrl.dispose();
    _bankCtrl.dispose(); _ibanCtrl.dispose();
    super.dispose();
  }

  // Upload image via HTML file input
  Future<void> _pickImage(bool isId) async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    input.onChange.listen((e) {
      final files = input.files;
      if (files == null || files.isEmpty) return;
      final reader = html.FileReader();
      reader.readAsDataUrl(files[0]);
      reader.onLoadEnd.listen((e) {
        final base64 = reader.result as String;
        setState(() {
          if (isId) {
            _idImage = base64;
          } else {
            _licenseImage = base64;
          }
        });
      });
    });
  }

  Future<void> _signup() async {
    if (_idImage == null || _licenseImage == null) {
      _snack('Please upload ID and Business License', isError: true);
      return;
    }

    setState(() => _loading = true);
    final result = await ApiService.instance.registerHost(
      firstName:    _firstCtrl.text.trim(),
      lastName:     _lastCtrl.text.trim(),
      email:        _emailCtrl.text.trim(),
      password:     _passCtrl.text,
      businessName: _businessCtrl.text.trim(),
      phone:        _phoneCtrl.text.trim(),
      bankName:     _bankCtrl.text.trim(),
      iban:         _ibanCtrl.text.trim(),
      idImage:      _idImage!,
      licenseImage: _licenseImage!,
    );
    if (mounted) {
      setState(() => _loading = false);
      if (result['success']) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HostPendingScreen()));
      } else {
        _snack(result['message'] ?? 'Signup failed', isError: true);
      }
    }
  }

  bool _canContinue() {
    if (_step == 0) {
      return _firstCtrl.text.trim().isNotEmpty &&
             _lastCtrl.text.trim().isNotEmpty &&
             _emailCtrl.text.trim().isNotEmpty &&
             _passCtrl.text.isNotEmpty;
    }
    if (_step == 3) {
      return _idImage != null && _licenseImage != null;
    }
    return true;
  }

  void _snack(String msg, {bool isError = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? kRed : cCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Become a Host', context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00E5A0), Color(0xFF00B37A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.business, color: Colors.black, size: 36),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Earn with ChargeGuard',
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Applications are reviewed by our team (24-48 hours)',
                    style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 12)),
              ])),
            ])),
          const SizedBox(height: 24),

          // Step indicator
          Row(children: [
            _stepDot(0, 'Account'),
            Expanded(child: Container(height: 2, color: _step >= 1 ? kGreen : cBorder)),
            _stepDot(1, 'Business'),
            Expanded(child: Container(height: 2, color: _step >= 2 ? kGreen : cBorder)),
            _stepDot(2, 'Banking'),
            Expanded(child: Container(height: 2, color: _step >= 3 ? kGreen : cBorder)),
            _stepDot(3, 'Verify'),
          ]),
          const SizedBox(height: 28),

          if (_step == 0) ..._accountStep(),
          if (_step == 1) ..._businessStep(),
          if (_step == 2) ..._bankingStep(),
          if (_step == 3) ..._verifyStep(),

          const SizedBox(height: 24),

          Row(children: [
            if (_step > 0)
              Expanded(child: OutlinedButton(
                onPressed: () => setState(() => _step--),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('Back', style: TextStyle(color: cTitle, fontWeight: FontWeight.w800)))),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: _loading || !_canContinue() ? null : () {
                if (_step < 3) {
                  setState(() => _step++);
                } else {
                  _signup();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                  disabledBackgroundColor: kGreen.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : Text(_step == 3 ? 'Submit Application' : 'Continue',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)))),
          ]),
        ]),
      ),
    );
  }

  Widget _stepDot(int idx, String label) => Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 28, height: 28,
      decoration: BoxDecoration(
        color: _step >= idx ? kGreen : cCard, shape: BoxShape.circle,
        border: Border.all(color: _step >= idx ? kGreen : cBorder, width: 2)),
      child: Center(child: _step > idx
          ? const Icon(Icons.check, color: Colors.black, size: 14)
          : Text('${idx + 1}',
              style: TextStyle(color: _step >= idx ? Colors.black : cSub,
                  fontSize: 11, fontWeight: FontWeight.w800)))),
    const SizedBox(height: 4),
    Text(label, style: TextStyle(color: _step >= idx ? kGreen : cSub, fontSize: 9, fontWeight: FontWeight.w700)),
  ]);

  List<Widget> _accountStep() => [
    Text('Account Details', style: kTitle(16)),
    const SizedBox(height: 16),
    Row(children: [
      Expanded(child: _field(_firstCtrl, 'First Name', Icons.person_outline)),
      const SizedBox(width: 12),
      Expanded(child: _field(_lastCtrl, 'Last Name', Icons.person_outline)),
    ]),
    const SizedBox(height: 12),
    _field(_emailCtrl, 'Email', Icons.email_outlined, type: TextInputType.emailAddress),
    const SizedBox(height: 12),
    TextField(controller: _passCtrl, obscureText: _obscure,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: cTitle, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Password', labelStyle: TextStyle(color: cSub),
        prefixIcon: Icon(Icons.lock_outline, color: cSub2, size: 20),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: cSub2, size: 20),
          onPressed: () => setState(() => _obscure = !_obscure)),
        filled: true, fillColor: cCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGreen, width: 1.5)))),
  ];

  List<Widget> _businessStep() => [
    Text('Business Information', style: kTitle(16)),
    const SizedBox(height: 4),
    Text('Optional — you can fill this later', style: kSub(12)),
    const SizedBox(height: 16),
    _field(_businessCtrl, 'Business Name', Icons.business),
    const SizedBox(height: 12),
    _field(_phoneCtrl, 'Phone', Icons.phone, type: TextInputType.phone),
  ];

  List<Widget> _bankingStep() => [
    Text('Banking Details', style: kTitle(16)),
    const SizedBox(height: 4),
    Text('Required to receive payouts', style: kSub(12)),
    const SizedBox(height: 16),
    _field(_bankCtrl, 'Bank Name', Icons.account_balance),
    const SizedBox(height: 12),
    _field(_ibanCtrl, 'IBAN', Icons.credit_card),
  ];

  List<Widget> _verifyStep() => [
    Text('ID Verification', style: kTitle(16)),
    const SizedBox(height: 4),
    Text('Required. Your documents are kept private.', style: kSub(12)),
    const SizedBox(height: 20),
    _uploadCard('Government ID', 'National ID or Passport', _idImage, () => _pickImage(true)),
    const SizedBox(height: 16),
    _uploadCard('Business License', 'Official business license or permit', _licenseImage, () => _pickImage(false)),
    const SizedBox(height: 16),
    Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3))),
      child: Row(children: [
        const Icon(Icons.schedule, color: Colors.orange, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text('Your application will be reviewed within 24-48 hours',
            style: kSub(11))),
      ])),
  ];

  Widget _uploadCard(String title, String sub, String? image, VoidCallback onTap) =>
    GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: image != null ? kGreen.withOpacity(0.08) : cCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: image != null ? kGreen : cBorder,
              width: image != null ? 2 : 1)),
        child: Row(children: [
          Container(width: 56, height: 56,
            decoration: BoxDecoration(
              color: image != null ? kGreen.withOpacity(0.15) : cBg,
              borderRadius: BorderRadius.circular(12)),
            child: image != null
                ? ClipRRect(borderRadius: BorderRadius.circular(12),
                    child: Image.network(image, fit: BoxFit.cover))
                : Icon(Icons.upload_file, color: cSub2, size: 28)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: kTitle(14)),
            const SizedBox(height: 4),
            Text(image != null ? 'Uploaded ✓ (tap to change)' : sub,
                style: TextStyle(color: image != null ? kGreen : cSub, fontSize: 11)),
          ])),
          Icon(image != null ? Icons.check_circle : Icons.arrow_forward_ios,
              color: image != null ? kGreen : cSub2, size: image != null ? 22 : 14),
        ])));

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType? type}) =>
    TextField(controller: ctrl, keyboardType: type,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: cTitle, fontSize: 14),
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: cSub),
        prefixIcon: Icon(icon, color: cSub2, size: 20),
        filled: true, fillColor: cCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGreen, width: 1.5))));
}
