import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class AdminInsightsScreen extends StatefulWidget {
  const AdminInsightsScreen({super.key});
  @override
  State<AdminInsightsScreen> createState() => _AdminInsightsScreenState();
}

class _AdminInsightsScreenState extends State<AdminInsightsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.instance.getAdminInsights();
    if (mounted) {
      setState(() {
        _loading = false;
        if (result['success']) _data = result['data'] as Map<String, dynamic>;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats   = (_data?['stats']   as Map<String, dynamic>?) ?? {};
    final summary = _data?['summary']  as String? ?? '';
    final aiUsed  = _data?['aiUsed']   as bool? ?? false;
    final growthPct = (stats['bookingsGrowthPct'] as num?)?.toInt() ?? 0;
    final growthUp = growthPct >= 0;

    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(backgroundColor: cBg, elevation: 0,
          title: Text('AI Insights', style: kTitle(18)),
          actions: [IconButton(icon: const Icon(Icons.refresh, color: kGreen), onPressed: _load)]),
      body: _loading
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const CircularProgressIndicator(color: kGreen),
              const SizedBox(height: 16),
              Text('Analyzing the last 30 days...', style: kSub(13)),
            ]))
          : RefreshIndicator(color: kGreen, onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(20), children: [

                // AI Summary card
                Container(padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [kGreen.withOpacity(0.2), kGreen.withOpacity(0.05)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kGreen.withOpacity(0.3))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 36, height: 36,
                        decoration: BoxDecoration(color: kGreen.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.auto_awesome, color: kGreen, size: 20)),
                      const SizedBox(width: 10),
                      Text(aiUsed ? 'Claude AI Analysis' : 'Summary',
                          style: kTitle(15)),
                      const Spacer(),
                      if (aiUsed)
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: kGreen.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Text('AI',
                              style: TextStyle(color: kGreen, fontSize: 10, fontWeight: FontWeight.w800))),
                    ]),
                    const SizedBox(height: 14),
                    Text(summary,
                        style: TextStyle(color: cTitle, fontSize: 13, height: 1.5)),
                  ])),
                const SizedBox(height: 24),

                Text('Last 30 Days', style: kTitle(15)),
                const SizedBox(height: 12),

                Row(children: [
                  _stat(Icons.calendar_today,  '${stats['bookings30'] ?? 0}', 'Bookings',
                      growthPct == 0 ? null : '${growthUp ? '+' : ''}$growthPct%',
                      growthUp ? kGreen : Colors.redAccent),
                  const SizedBox(width: 10),
                  _stat(Icons.attach_money, 'NIS ${((stats['revenue30'] as num?)?.toInt() ?? 0)}',
                      'Revenue', null, kGreen),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _stat(Icons.person_add, '${stats['newUsers30'] ?? 0}', 'New Users',
                      null, Colors.blueAccent),
                  const SizedBox(width: 10),
                  _stat(Icons.home_work,  '${stats['newHosts30'] ?? 0}', 'New Hosts',
                      null, Colors.purpleAccent),
                ]),
                const SizedBox(height: 24),

                if ((stats['topStation'] as String? ?? '').isNotEmpty)
                  Container(padding: const EdgeInsets.all(14), decoration: kCardDeco(radius: 12),
                    child: Row(children: [
                      const Icon(Icons.emoji_events, color: Colors.amber, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Top Station', style: kSub(11)),
                        Text(stats['topStation'] as String, style: kTitle(13)),
                      ])),
                    ])),
                if ((stats['topStation'] as String? ?? '').isNotEmpty) const SizedBox(height: 10),

                if (stats['peakHour'] != null)
                  Container(padding: const EdgeInsets.all(14), decoration: kCardDeco(radius: 12),
                    child: Row(children: [
                      const Icon(Icons.access_time, color: Colors.purpleAccent, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Peak Hour', style: kSub(11)),
                        Text('${stats['peakHour']}:00 — ${(stats['peakHour'] as int) + 1}:00',
                            style: kTitle(13)),
                      ])),
                    ])),

                const SizedBox(height: 20),
                if (!aiUsed)
                  Container(padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.amber.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        'Claude AI is unavailable (no API key configured). '
                        'Showing a deterministic summary instead.',
                        style: TextStyle(color: cSub, fontSize: 11))),
                    ])),
              ])),
    );
  }

  Widget _stat(IconData icon, String v, String l, String? delta, Color color) => Expanded(
        child: Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.25))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
              if (delta != null)
                Text(delta, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 6),
            Text(v, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 3),
            Text(l, style: kSub(11)),
          ])),
      );
}
