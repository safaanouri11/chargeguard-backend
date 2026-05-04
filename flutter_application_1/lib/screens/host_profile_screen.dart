import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class HostProfileScreen extends StatefulWidget {
  const HostProfileScreen({super.key});
  @override
  State<HostProfileScreen> createState() => _HostProfileScreenState();
}

class _HostProfileScreenState extends State<HostProfileScreen> {
  final _businessCtrl = TextEditingController();
  final _bioCtrl      = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _bankCtrl     = TextEditingController();
  final _ibanCtrl     = TextEditingController();

  bool _loading = true;
  bool _saving  = false;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _businessCtrl.dispose(); _bioCtrl.dispose(); _phoneCtrl.dispose();
    _bankCtrl.dispose(); _ibanCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final result = await ApiService.instance.getHostProfile();
    if (mounted) {
      setState(() {
        _loading = false;
        if (result['success']) {
          _profile = result['data'] as Map<String, dynamic>;
          _businessCtrl.text = _profile!['businessName'] as String? ?? '';
          _bioCtrl.text      = _profile!['bio']          as String? ?? '';
          _phoneCtrl.text    = _profile!['phone']        as String? ?? '';
          _bankCtrl.text     = _profile!['bankName']     as String? ?? '';
          _ibanCtrl.text     = _profile!['iban']         as String? ?? '';
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ApiService.instance.updateHostProfile({
      'businessName': _businessCtrl.text.trim(),
      'bio':          _bioCtrl.text.trim(),
      'phone':        _phoneCtrl.text.trim(),
      'bankName':     _bankCtrl.text.trim(),
      'iban':         _ibanCtrl.text.trim(),
    });
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success'] ? 'Profile updated! ✅' : result['message'] ?? 'Error'),
        backgroundColor: result['success'] ? cCard : kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Host Profile', context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Header card
                Container(padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00E5A0), Color(0xFF00B37A)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    Container(width: 60, height: 60,
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.15),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.business, color: Colors.black, size: 28)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_businessCtrl.text.isEmpty ? 'Host' : _businessCtrl.text,
                          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('${_profile?['firstName'] ?? ''} ${_profile?['lastName'] ?? ''}',
                          style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 13)),
                    ])),
                  ])),
                const SizedBox(height: 24),

                Text('Business Info', style: kTitle(16)),
                const SizedBox(height: 12),
                _field(_businessCtrl, 'Business Name',  Icons.business),
                const SizedBox(height: 12),
                _field(_bioCtrl,      'Bio',            Icons.description_outlined, maxLines: 3),
                const SizedBox(height: 12),
                _field(_phoneCtrl,    'Phone',          Icons.phone, type: TextInputType.phone),
                const SizedBox(height: 24),

                Text('Banking Information', style: kTitle(16)),
                const SizedBox(height: 4),
                Text('Required to receive payouts', style: kSub(12)),
                const SizedBox(height: 12),
                _field(_bankCtrl, 'Bank Name', Icons.account_balance),
                const SizedBox(height: 12),
                _field(_ibanCtrl, 'IBAN',      Icons.credit_card),
                const SizedBox(height: 28),

                SizedBox(width: double.infinity, height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                        disabledBackgroundColor: kGreen.withOpacity(0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
              ])),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? type, int maxLines = 1}) =>
    TextField(controller: ctrl, keyboardType: type, maxLines: maxLines,
      style: TextStyle(color: cTitle, fontSize: 14),
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: cSub),
        prefixIcon: maxLines == 1 ? Icon(icon, color: cSub2, size: 20) : null,
        filled: true, fillColor: cCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGreen, width: 1.5))));
}
