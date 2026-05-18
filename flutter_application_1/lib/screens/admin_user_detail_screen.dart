import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final String userId;
  const AdminUserDetailScreen({super.key, required this.userId});
  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.instance.getUserDetail(widget.userId);
    if (mounted) {
      setState(() {
        _loading = false;
        if (result['success']) _data = result['data'] as Map<String, dynamic>;
      });
    }
  }

  void _snack(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: isError ? kRed : cCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  Future<void> _suspend() async {
    final user = _data?['user'] as Map<String, dynamic>?;
    if (user == null) return;
    final isSuspended = user['suspended'] as bool? ?? false;
    String reason = '';
    if (!isSuspended) {
      final reasonCtrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: cCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Suspend user?', style: kTitle(16)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('They will be blocked from logging in.', style: kSub(12)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              style: TextStyle(color: cTitle),
              decoration: InputDecoration(
                labelText: 'Reason (optional)', labelStyle: TextStyle(color: cSub),
                filled: true, fillColor: cBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cBorder)))),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: cSub))),
            ElevatedButton(
              onPressed: () { reason = reasonCtrl.text.trim(); Navigator.pop(context, true); },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: const Text('Suspend')),
          ]),
      );
      if (ok != true || !mounted) return;
    } else {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: cCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Restore user?', style: kTitle(16)),
          content: Text('They will be able to log in again.', style: kSub(13)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: cSub))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black),
              child: const Text('Restore')),
          ]),
      );
      if (ok != true || !mounted) return;
    }
    final result = await ApiService.instance.suspendUser(widget.userId, reason: reason);
    if (mounted) {
      _snack(result['success']
          ? (result['data']?['suspended'] as bool? ?? false ? 'User suspended' : 'User restored')
          : (result['message'] ?? 'Error'),
        isError: !result['success']);
      if (result['success']) _load();
    }
  }

  Future<void> _resetPassword() async {
    final passCtrl = TextEditingController();
    bool obs = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset password', style: kTitle(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Set a new password. The user will be notified.', style: kSub(12)),
          const SizedBox(height: 12),
          TextField(
            controller: passCtrl,
            obscureText: obs,
            style: TextStyle(color: cTitle),
            decoration: InputDecoration(
              labelText: 'New password (min 6 chars)', labelStyle: TextStyle(color: cSub),
              suffixIcon: IconButton(
                icon: Icon(obs ? Icons.visibility_off : Icons.visibility, color: cSub2),
                onPressed: () => set(() => obs = !obs)),
              filled: true, fillColor: cBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cBorder)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: cSub))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black),
            child: const Text('Reset')),
        ])));
    if (ok != true || !mounted) return;
    if (passCtrl.text.length < 6) {
      _snack('Min 6 characters', isError: true);
      return;
    }
    final result = await ApiService.instance.adminResetUserPassword(widget.userId, passCtrl.text);
    if (mounted) {
      _snack(result['success'] ? 'Password reset ✅' : result['message'] ?? 'Error',
          isError: !result['success']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _data?['user'] as Map<String, dynamic>?;
    final bookings = (_data?['bookings'] as List?) ?? [];
    final transactions = (_data?['transactions'] as List?) ?? [];
    final completed = (_data?['completedSessions'] as int?) ?? 0;

    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(backgroundColor: cBg, elevation: 0,
          title: Text(user != null
              ? '${user['firstName']} ${user['lastName']}'
              : 'User Detail', style: kTitle(17))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : user == null
              ? Center(child: Text('Not found', style: kSub(14)))
              : RefreshIndicator(color: kGreen, onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.all(20), children: [

                    // Header card
                    Container(padding: const EdgeInsets.all(18), decoration: kCardDeco(),
                      child: Column(children: [
                        CircleAvatar(radius: 36,
                          backgroundColor: kGreen.withOpacity(0.18),
                          child: Text((user['firstName'] as String? ?? '?')[0].toUpperCase(),
                              style: const TextStyle(color: kGreen, fontSize: 28, fontWeight: FontWeight.w900))),
                        const SizedBox(height: 12),
                        Text('${user['firstName']} ${user['lastName']}', style: kTitle(18)),
                        const SizedBox(height: 4),
                        Text(user['email'] as String? ?? '', style: kSub(13)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
                          _chip(user['role'] as String? ?? 'driver',
                              user['role'] == 'host' ? Colors.blueAccent : kGreen),
                          if ((user['suspended'] as bool? ?? false))
                            _chip('Suspended', Colors.redAccent),
                          if (user['hostStatus'] != null && user['hostStatus'] != 'None')
                            _chip(user['hostStatus'] as String, Colors.amber),
                        ]),
                      ])),
                    const SizedBox(height: 16),

                    // Stats
                    Row(children: [
                      _stat('${user['balance'] ?? 0}', 'Balance', 'NIS'),
                      _stat('${user['points']  ?? 0}', 'Points',  ''),
                      _stat('$completed',              'Sessions',''),
                    ]),
                    const SizedBox(height: 16),

                    // Profile info
                    Container(padding: const EdgeInsets.all(14), decoration: kCardDeco(radius: 12),
                      child: Column(children: [
                        _info(Icons.phone_outlined,     'Phone',     user['phone']),
                        Divider(color: cBorder, height: 16),
                        _info(Icons.location_on_outlined, 'Region',  user['region']),
                        Divider(color: cBorder, height: 16),
                        _info(Icons.directions_car_outlined, 'Vehicle', user['vehicle']),
                        Divider(color: cBorder, height: 16),
                        _info(Icons.power,              'Connector', user['connector']),
                        if ((user['suspendedReason'] as String?)?.isNotEmpty ?? false) ...[
                          Divider(color: cBorder, height: 16),
                          _info(Icons.block, 'Reason', user['suspendedReason']),
                        ],
                      ])),
                    const SizedBox(height: 16),

                    // Actions
                    Row(children: [
                      Expanded(child: ElevatedButton.icon(
                        onPressed: _suspend,
                        icon: Icon(user['suspended'] == true ? Icons.lock_open : Icons.block, size: 16),
                        label: Text(user['suspended'] == true ? 'Restore' : 'Suspend',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: user['suspended'] == true ? kGreen : Colors.redAccent,
                          foregroundColor: user['suspended'] == true ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                      const SizedBox(width: 10),
                      Expanded(child: OutlinedButton.icon(
                        onPressed: _resetPassword,
                        icon: const Icon(Icons.lock_reset, size: 16, color: Colors.amber),
                        label: const Text('Reset Pass',
                            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.amber),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                    ]),
                    const SizedBox(height: 24),

                    // Recent bookings
                    Text('Recent Bookings (${bookings.length})', style: kTitle(14)),
                    const SizedBox(height: 10),
                    if (bookings.isEmpty)
                      Container(padding: const EdgeInsets.all(16), decoration: kCardDeco(radius: 12),
                        child: Center(child: Text('No bookings', style: kSub(12))))
                    else
                      ...bookings.take(10).map<Widget>((b) {
                        final st = (b['station'] as Map?) ?? {};
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: kCardDeco(radius: 10),
                          child: Row(children: [
                            const Icon(Icons.calendar_today, color: kGreen, size: 16),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(st['name'] as String? ?? 'Station', style: kTitle(12)),
                              Text(b['status'] as String? ?? '', style: kSub(10)),
                            ])),
                            Text('NIS ${((b['totalCost'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}',
                                style: TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                          ]));
                      }),
                    const SizedBox(height: 24),

                    // Recent transactions
                    Text('Recent Transactions (${transactions.length})', style: kTitle(14)),
                    const SizedBox(height: 10),
                    if (transactions.isEmpty)
                      Container(padding: const EdgeInsets.all(16), decoration: kCardDeco(radius: 12),
                        child: Center(child: Text('No transactions', style: kSub(12))))
                    else
                      ...transactions.take(10).map<Widget>((t) {
                        final amount = (t['amount'] as num?)?.toDouble() ?? 0;
                        final neg = amount < 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: kCardDeco(radius: 10),
                          child: Row(children: [
                            Icon(neg ? Icons.arrow_downward : Icons.arrow_upward,
                                color: neg ? Colors.redAccent : kGreen, size: 16),
                            const SizedBox(width: 10),
                            Expanded(child: Text(t['description'] as String? ?? '',
                                style: kSub(12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text('${neg ? '' : '+'}${amount.toStringAsFixed(1)}',
                                style: TextStyle(
                                    color: neg ? Colors.redAccent : kGreen,
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                          ]));
                      }),
                    const SizedBox(height: 30),
                  ])),
    );
  }

  Widget _chip(String text, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: c.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.3))),
        child: Text(text, style: TextStyle(
            color: c, fontSize: 11, fontWeight: FontWeight.w700)),
      );

  Widget _stat(String v, String l, String suffix) => Expanded(
        child: Container(margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: kCardDeco(radius: 12),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(v, style: TextStyle(color: cTitle, fontSize: 17, fontWeight: FontWeight.w900)),
              if (suffix.isNotEmpty)
                Padding(padding: const EdgeInsets.only(left: 3, bottom: 2),
                  child: Text(suffix, style: kSub(10))),
            ]),
            const SizedBox(height: 2),
            Text(l, style: kSub(10)),
          ])),
      );

  Widget _info(IconData icon, String label, dynamic val) {
    final v = val == null || val.toString().isEmpty ? 'Not set' : val.toString();
    return Row(children: [
      Icon(icon, color: cSub2, size: 16), const SizedBox(width: 10),
      Text(label, style: kSub(12)),
      const Spacer(),
      Expanded(child: Text(v, style: TextStyle(color: cTitle, fontSize: 12),
          textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
  }
}
