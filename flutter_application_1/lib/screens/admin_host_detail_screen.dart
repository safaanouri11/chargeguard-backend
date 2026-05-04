import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class AdminHostDetailScreen extends StatefulWidget {
  final String hostId;
  const AdminHostDetailScreen({super.key, required this.hostId});
  @override
  State<AdminHostDetailScreen> createState() => _AdminHostDetailScreenState();
}

class _AdminHostDetailScreenState extends State<AdminHostDetailScreen> {
  Map<String, dynamic>? _host;
  bool _loading = true;
  bool _acting  = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ApiService.instance.getHostDetails(widget.hostId);
    if (mounted) {
      setState(() {
        _loading = false;
        if (result['success']) _host = result['data'] as Map<String, dynamic>;
      });
    }
  }

  Future<void> _approve() async {
    setState(() => _acting = true);
    final result = await ApiService.instance.approveHost(widget.hostId);
    if (mounted) {
      setState(() => _acting = false);
      _snack(result['success'] ? 'Host approved ✅' : result['message'] ?? 'Error',
          isError: !result['success']);
      if (result['success']) _load();
    }
  }

  Future<void> _reject() async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Application', style: kTitle(16)),
        content: TextField(controller: ctrl, maxLines: 3,
          style: TextStyle(color: cTitle),
          decoration: InputDecoration(
            hintText: 'Reason for rejection', hintStyle: TextStyle(color: cSub),
            filled: true, fillColor: cBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cBorder)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: cSub))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Reject')),
        ]));

    if (reason == null || !mounted) return;

    setState(() => _acting = true);
    final result = await ApiService.instance.rejectHost(widget.hostId, reason);
    if (mounted) {
      setState(() => _acting = false);
      _snack(result['success'] ? 'Host rejected' : result['message'] ?? 'Error',
          isError: !result['success']);
      if (result['success']) _load();
    }
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
      appBar: kAppBar('Host Application', context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : _host == null
              ? Center(child: Text('Host not found', style: kSub(14)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    // Profile card
                    Container(padding: const EdgeInsets.all(20), decoration: kCardDeco(),
                      child: Column(children: [
                        Container(width: 70, height: 70,
                          decoration: BoxDecoration(color: kGreen.withOpacity(0.12), shape: BoxShape.circle),
                          child: Center(child: Text(
                            (_host!['firstName'] as String? ?? '?')[0].toUpperCase(),
                            style: const TextStyle(color: kGreen, fontSize: 28, fontWeight: FontWeight.w800)))),
                        const SizedBox(height: 12),
                        Text('${_host!['firstName']} ${_host!['lastName']}', style: kTitle(18)),
                        const SizedBox(height: 4),
                        Text(_host!['email'] as String, style: kSub(13)),
                        const SizedBox(height: 12),
                        _statusBadge(_host!['hostStatus'] as String? ?? 'None'),
                      ])),
                    const SizedBox(height: 20),

                    Text('Business Information', style: kTitle(15)),
                    const SizedBox(height: 10),
                    Container(padding: const EdgeInsets.all(16), decoration: kCardDeco(),
                      child: Column(children: [
                        _row(Icons.business, 'Business Name',
                            (_host!['businessName'] as String? ?? '').isEmpty ? '—' : _host!['businessName'] as String),
                        _row(Icons.phone, 'Phone',
                            (_host!['phone'] as String? ?? '').isEmpty ? '—' : _host!['phone'] as String),
                        _row(Icons.location_on, 'Region', _host!['region'] as String? ?? '—'),
                      ])),
                    const SizedBox(height: 20),

                    Text('Banking', style: kTitle(15)),
                    const SizedBox(height: 10),
                    Container(padding: const EdgeInsets.all(16), decoration: kCardDeco(),
                      child: Column(children: [
                        _row(Icons.account_balance, 'Bank',
                            (_host!['bankName'] as String? ?? '').isEmpty ? '—' : _host!['bankName'] as String),
                        _row(Icons.credit_card, 'IBAN',
                            (_host!['iban'] as String? ?? '').isEmpty ? '—' : _host!['iban'] as String),
                      ])),
                    const SizedBox(height: 20),

                    Text('Documents', style: kTitle(15)),
                    const SizedBox(height: 10),
                    _document('Government ID', _host!['idImage'] as String? ?? ''),
                    const SizedBox(height: 12),
                    _document('Business License', _host!['licenseImage'] as String? ?? ''),
                    const SizedBox(height: 24),

                    // Actions
                    if (_host!['hostStatus'] == 'Pending') ...[
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: _acting ? null : _reject,
                          icon: const Icon(Icons.close, color: Colors.redAccent),
                          label: const Text('Reject',
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
                        const SizedBox(width: 12),
                        Expanded(child: ElevatedButton.icon(
                          onPressed: _acting ? null : _approve,
                          icon: _acting
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Icon(Icons.check),
                          label: const Text('Approve',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                              disabledBackgroundColor: kGreen.withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
                      ]),
                    ],

                    if (_host!['hostStatus'] == 'Rejected' &&
                        (_host!['rejectionReason'] as String? ?? '').isNotEmpty)
                      Container(padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Rejection Reason:',
                              style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(_host!['rejectionReason'] as String, style: kSub(13)),
                        ])),
                  ])),
    );
  }

  Widget _statusBadge(String s) {
    final color = s == 'Approved' ? kGreen
        : s == 'Pending' ? Colors.orange
        : s == 'Rejected' ? Colors.redAccent : cSub2;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(s.toUpperCase(),
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)));
  }

  Widget _row(IconData icon, String label, String value) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, color: cSub2, size: 16), const SizedBox(width: 10),
        Text(label, style: kSub(12)), const Spacer(),
        Expanded(child: Text(value, textAlign: TextAlign.end,
            style: TextStyle(color: cTitle, fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]));

  Widget _document(String label, String image) => Container(
    padding: const EdgeInsets.all(14), decoration: kCardDeco(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: kTitle(13)),
      const SizedBox(height: 10),
      if (image.isNotEmpty)
        ClipRRect(borderRadius: BorderRadius.circular(10),
          child: Image.network(image, height: 180, width: double.infinity, fit: BoxFit.cover))
      else
        Container(height: 100, decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text('No image', style: kSub(12)))),
    ]));
}
