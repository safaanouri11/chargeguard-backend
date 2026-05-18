import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import 'admin_user_detail_screen.dart';

class AdminFraudScreen extends StatefulWidget {
  const AdminFraudScreen({super.key});
  @override
  State<AdminFraudScreen> createState() => _AdminFraudScreenState();
}

class _AdminFraudScreenState extends State<AdminFraudScreen> {
  List<dynamic> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.instance.getFraudAlerts();
    if (mounted) {
      setState(() {
        _loading = false;
        if (result['success']) {
          _alerts = (result['data']?['alerts'] as List?) ?? [];
        }
      });
    }
  }

  Color _sevColor(String sev) {
    if (sev == 'high')   return Colors.redAccent;
    if (sev == 'medium') return Colors.orange;
    return Colors.amber;
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'rapid_bookings':  return Icons.speed;
      case 'suspended_count': return Icons.block;
      case 'price_anomaly':   return Icons.trending_up;
      case 'stale_payout':    return Icons.hourglass_bottom;
      default:                return Icons.warning_amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(backgroundColor: cBg, elevation: 0,
          title: Text('Fraud Detection', style: kTitle(18)),
          actions: [IconButton(icon: const Icon(Icons.refresh, color: kGreen), onPressed: _load)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : RefreshIndicator(color: kGreen, onRefresh: _load,
              child: _alerts.isEmpty
                  ? ListView(physics: const AlwaysScrollableScrollPhysics(),
                      children: [const SizedBox(height: 80),
                        Center(child: Column(children: [
                          Container(width: 80, height: 80,
                              decoration: BoxDecoration(color: kGreen.withOpacity(0.12),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.shield, color: kGreen, size: 38)),
                          const SizedBox(height: 16),
                          Text('All clear ✅', style: kTitle(17)),
                          const SizedBox(height: 6),
                          Text('No suspicious activity detected', style: kSub(13)),
                        ])),
                      ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _alerts.length,
                      itemBuilder: (_, i) {
                        final a = _alerts[i] as Map<String, dynamic>;
                        final sev = a['severity'] as String? ?? 'low';
                        final color = _sevColor(sev);
                        final hasUser = (a['userId'] as String?)?.isNotEmpty ?? false;
                        return GestureDetector(
                          onTap: hasUser
                              ? () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => AdminUserDetailScreen(userId: a['userId'] as String)))
                              : null,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color.withOpacity(0.3))),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(width: 38, height: 38,
                                decoration: BoxDecoration(color: color.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Icon(_typeIcon(a['type'] as String? ?? ''),
                                    color: color, size: 20)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text(a['title'] as String? ?? '', style: kTitle(13))),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: color.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Text(sev.toUpperCase(),
                                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800))),
                                ]),
                                const SizedBox(height: 4),
                                Text(a['message'] as String? ?? '', style: kSub(12)),
                                if (hasUser) ...[
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    Icon(Icons.arrow_forward, color: color, size: 12),
                                    const SizedBox(width: 4),
                                    Text('Tap to view user',
                                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ]),
                                ],
                              ])),
                            ]),
                          ),
                        );
                      })),
    );
  }
}
