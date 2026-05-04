import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import 'login_screen.dart';
import 'host_dashboard_screen.dart';

class HostPendingScreen extends StatefulWidget {
  const HostPendingScreen({super.key});
  @override
  State<HostPendingScreen> createState() => _HostPendingScreenState();
}

class _HostPendingScreenState extends State<HostPendingScreen> {
  String _status = 'Pending';
  String _rejectionReason = '';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    final result = await ApiService.instance.getHostStatus();
    if (mounted) {
      setState(() {
        _checking = false;
        if (result['success']) {
          final data = result['data'] as Map<String, dynamic>;
          _status = data['status'] as String? ?? 'Pending';
          _rejectionReason = data['rejectionReason'] as String? ?? '';
        }
      });

      // Auto-redirect if approved
      if (_status == 'Approved' && mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HostDashboardScreen()));
      }
    }
  }

  Future<void> _logout() async {
    ApiService.instance.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = _status == 'Rejected';
    final color = isRejected ? Colors.redAccent : Colors.orange;
    final icon  = isRejected ? Icons.cancel_outlined : Icons.pending_outlined;
    final title = isRejected ? 'Application Rejected' : 'Application Under Review';
    final sub   = isRejected
        ? 'Unfortunately your application was not approved.'
        : 'Your application is being reviewed by our team. This usually takes 24-48 hours.';

    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(32),
          child: Column(children: [
            const Spacer(),

            // Icon
            Container(width: 100, height: 100,
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.35), width: 3)),
              child: Icon(icon, color: color, size: 52)),
            const SizedBox(height: 28),

            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(_status.toUpperCase(),
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5))),
            const SizedBox(height: 18),

            Text(title, style: kTitle(22), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(sub, style: kSub(14), textAlign: TextAlign.center),
            const SizedBox(height: 20),

            if (isRejected && _rejectionReason.isNotEmpty)
              Container(padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Reason:', style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(_rejectionReason, style: kSub(13)),
                ])),

            if (!isRejected)
              Container(padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cBorder)),
                child: Column(children: [
                  _checkItem('Account created', true),
                  _checkItem('Documents submitted', true),
                  _checkItem('Admin review', _status == 'Approved'),
                  _checkItem('Account activation', _status == 'Approved'),
                ])),

            const Spacer(),

            SizedBox(width: double.infinity, height: 54,
              child: ElevatedButton.icon(
                onPressed: _checking ? null : _checkStatus,
                icon: _checking
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Icon(Icons.refresh),
                label: Text(_checking ? 'Checking...' : 'Check Status',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                    disabledBackgroundColor: kGreen.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
            const SizedBox(height: 12),

            TextButton.icon(
              onPressed: _logout,
              icon: Icon(Icons.logout, color: cSub, size: 16),
              label: Text('Log Out', style: TextStyle(color: cSub, fontSize: 13))),
          ])),
      ),
    );
  }

  Widget _checkItem(String text, bool done) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? kGreen : cSub2, size: 18),
      const SizedBox(width: 10),
      Text(text, style: TextStyle(color: done ? cTitle : cSub, fontSize: 13,
          fontWeight: done ? FontWeight.w600 : FontWeight.w400)),
    ]));
}
