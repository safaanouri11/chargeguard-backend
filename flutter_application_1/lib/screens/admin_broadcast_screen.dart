import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});
  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  String _target = 'all';
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Title required', isError: true);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Send broadcast?', style: kTitle(16)),
        content: Text(
          'This will notify all ${_target == 'all' ? 'users' : _target}. '
          'Are you sure?',
          style: kSub(13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: cSub))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black),
            child: const Text('Send')),
        ]),
    );
    if (confirm != true) return;

    setState(() => _sending = true);
    final result = await ApiService.instance.broadcastNotification(
      title:  _titleCtrl.text.trim(),
      body:   _bodyCtrl.text.trim(),
      target: _target,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (result['success']) {
      final count = (result['data']?['count'] as int?) ?? 0;
      _snack('Sent to $count users ✅');
      _titleCtrl.clear();
      _bodyCtrl.clear();
    } else {
      _snack(result['message'] ?? 'Failed', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? kRed : cCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(backgroundColor: cBg, elevation: 0,
          title: Text('Broadcast', style: kTitle(18))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kGreen.withOpacity(0.25))),
            child: Row(children: [
              const Icon(Icons.campaign, color: kGreen, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Send a notification to all users, drivers only, or hosts only. '
                'Use sparingly — too many broadcasts annoy users.',
                style: TextStyle(color: cSub, fontSize: 12))),
            ])),
          const SizedBox(height: 24),

          Text('Audience', style: kTitle(14)),
          const SizedBox(height: 10),
          Row(children: [
            _audChip('all',     'All Users',  Icons.people),
            const SizedBox(width: 8),
            _audChip('drivers', 'Drivers',    Icons.directions_car),
            const SizedBox(width: 8),
            _audChip('hosts',   'Hosts',      Icons.home_work),
          ]),
          const SizedBox(height: 24),

          Text('Title', style: kTitle(14)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            style: TextStyle(color: cTitle, fontSize: 15),
            maxLength: 60,
            decoration: _inputDeco('e.g. New promo: 20% off this week'),
          ),

          Text('Message', style: kTitle(14)),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyCtrl,
            style: TextStyle(color: cTitle, fontSize: 14),
            maxLines: 5,
            maxLength: 280,
            decoration: _inputDeco('Details (optional)'),
          ),
          const SizedBox(height: 16),

          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.send, size: 18),
              label: Text(_sending ? 'Sending...' : 'Send Broadcast',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen, foregroundColor: Colors.black,
                disabledBackgroundColor: kGreen.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
        ]),
      ),
    );
  }

  Widget _audChip(String value, String label, IconData icon) {
    final sel = _target == value;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _target = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? kGreen.withOpacity(0.12) : cCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? kGreen : cBorder, width: 1.5)),
        child: Column(children: [
          Icon(icon, color: sel ? kGreen : cSub2, size: 22),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(
              color: sel ? kGreen : cSub,
              fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    ));
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: cSub2),
        filled: true, fillColor: cCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGreen, width: 1.5)),
      );
}
