import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class AdminLiveScreen extends StatefulWidget {
  const AdminLiveScreen({super.key});
  @override
  State<AdminLiveScreen> createState() => _AdminLiveScreenState();
}

class _AdminLiveScreenState extends State<AdminLiveScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    // Auto-refresh every 15s so the view feels truly "live".
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final result = await ApiService.instance.getLiveActivity();
    if (mounted) {
      setState(() {
        _loading = false;
        if (result['success']) _data = result['data'] as Map<String, dynamic>;
      });
    }
  }

  String _ago(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final d  = DateTime.now().difference(dt);
      if (d.inSeconds < 60) return '${d.inSeconds}s';
      if (d.inMinutes < 60) return '${d.inMinutes}m';
      return '${d.inHours}h';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = (_data?['activeSessions'] as List?) ?? [];
    final recent   = (_data?['recentTransactions'] as List?) ?? [];

    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(backgroundColor: cBg, elevation: 0,
          title: Row(children: [
            Container(width: 8, height: 8,
                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('Live Activity', style: kTitle(18)),
          ]),
          actions: [IconButton(icon: const Icon(Icons.refresh, color: kGreen),
              onPressed: () => _load())]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : RefreshIndicator(color: kGreen, onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                // Active sessions count
                Container(padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.redAccent.withOpacity(0.18), Colors.redAccent.withOpacity(0.05)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.bolt, color: Colors.redAccent, size: 36),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${sessions.length}',
                          style: TextStyle(color: cTitle, fontSize: 32, fontWeight: FontWeight.w900, height: 1)),
                      const SizedBox(height: 4),
                      Text('Active charging sessions', style: kSub(12)),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 6, height: 6,
                            decoration: const BoxDecoration(
                                color: Colors.redAccent, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        const Text('LIVE',
                            style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900)),
                      ])),
                  ])),
                const SizedBox(height: 24),

                Text('Active Sessions', style: kTitle(15)),
                const SizedBox(height: 10),
                if (sessions.isEmpty)
                  Container(padding: const EdgeInsets.all(20), decoration: kCardDeco(),
                    child: Center(child: Text('No active charging sessions', style: kSub(13))))
                else
                  ...sessions.map<Widget>((b) {
                    final u = (b['user'] as Map?) ?? {};
                    final s = (b['station'] as Map?) ?? {};
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: kCardDeco(radius: 12),
                      child: Row(children: [
                        CircleAvatar(radius: 18,
                          backgroundColor: kGreen.withOpacity(0.12),
                          child: Text((u['firstName'] as String? ?? '?')[0].toUpperCase(),
                              style: const TextStyle(color: kGreen, fontWeight: FontWeight.w800))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${u['firstName'] ?? ''} ${u['lastName'] ?? ''}', style: kTitle(13)),
                          Text(s['name'] as String? ?? 'Station', style: kSub(11),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: kGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(b['status'] as String? ?? 'Active',
                                style: const TextStyle(color: kGreen, fontSize: 10, fontWeight: FontWeight.w800))),
                          const SizedBox(height: 4),
                          Text(_ago(b['createdAt'] as String? ?? ''), style: kSub(10)),
                        ]),
                      ]));
                  }),
                const SizedBox(height: 24),

                Text('Recent Transactions', style: kTitle(15)),
                const SizedBox(height: 10),
                if (recent.isEmpty)
                  Container(padding: const EdgeInsets.all(20), decoration: kCardDeco(),
                    child: Center(child: Text('No recent transactions', style: kSub(13))))
                else
                  ...recent.map<Widget>((t) {
                    final amount = (t['amount'] as num?)?.toDouble() ?? 0;
                    final neg = amount < 0;
                    final u = (t['user'] as Map?) ?? {};
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: kCardDeco(radius: 10),
                      child: Row(children: [
                        Icon(neg ? Icons.arrow_downward : Icons.arrow_upward,
                            color: neg ? Colors.redAccent : kGreen, size: 14),
                        const SizedBox(width: 8),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim(),
                              style: TextStyle(color: cTitle, fontSize: 12, fontWeight: FontWeight.w700)),
                          Text(t['description'] as String? ?? '', style: kSub(10),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        Text('${neg ? '' : '+'}${amount.toStringAsFixed(1)}',
                            style: TextStyle(
                                color: neg ? Colors.redAccent : kGreen,
                                fontSize: 12, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 4),
                        Text(_ago(t['createdAt'] as String? ?? ''), style: kSub(9)),
                      ]));
                  }),
                const SizedBox(height: 20),
                Center(child: Text('Auto-refreshes every 15 seconds',
                    style: TextStyle(color: cSub2, fontSize: 11))),
                const SizedBox(height: 20),
              ])),
    );
  }
}
