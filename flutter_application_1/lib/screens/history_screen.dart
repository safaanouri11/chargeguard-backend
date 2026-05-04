import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final res = await ApiService.instance.getTransactions();
    if (mounted) {
      setState(() {
        _loading = false;
        _transactions = res['success'] ? (res['data'] as List? ?? []) : [];
      });
    }
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final d = DateTime.parse(createdAt.toString()).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      final h   = d.hour > 12 ? d.hour - 12 : d.hour == 0 ? 12 : d.hour;
      final m   = d.minute.toString().padLeft(2, '0');
      final ap  = d.hour >= 12 ? 'PM' : 'AM';
      return '${d.day} ${months[d.month - 1]} · $h:$m $ap';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Charging History', context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : RefreshIndicator(
              color: kGreen,
              onRefresh: _loadHistory,
              child: _transactions.isEmpty
                  ? ListView(children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.history, color: cSub2, size: 64),
                        const SizedBox(height: 16),
                        Text('No history yet', style: kTitle(18)),
                        const SizedBox(height: 8),
                        Text('Your transactions will appear here', style: kSub(13)),
                      ])),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _transactions.length,
                      itemBuilder: (_, i) {
                        final t      = _transactions[i];
                        final amount = (t['amount'] ?? 0).toDouble();
                        final isPlus = amount >= 0;
                        final type   = t['type'] as String? ?? 'charge';
                        final date   = _formatDate(t['createdAt']);

                        const iconMap = <String, IconData>{
                          'charge':   Icons.bolt,
                          'booking':  Icons.calendar_today_outlined,
                          'refund':   Icons.refresh,
                          'reward':   Icons.star_outline,
                          'topup':    Icons.add_circle_outline,
                          'transfer': Icons.send_outlined,
                        };
                        final colorMap = <String, Color>{
                          'charge':   Colors.blueAccent,
                          'booking':  Colors.orange,
                          'refund':   kGreen,
                          'reward':   kGreen,
                          'topup':    kGreen,
                          'transfer': Colors.blueAccent,
                        };
                        final icon  = iconMap[type]  ?? Icons.circle;
                        final color = colorMap[type] ?? cSub;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: kCardDeco(),
                          child: Row(children: [
                            Container(width: 44, height: 44,
                              decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(icon, color: color, size: 22)),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(t['label'] as String? ?? '', style: kTitle(13)),
                              if (date.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(date, style: kSub(11)),
                              ],
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(
                                '${isPlus ? "+" : ""}${amount.toStringAsFixed(2)} NIS',
                                style: TextStyle(
                                    color: isPlus ? kGreen : cTitle,
                                    fontSize: 13, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(type,
                                    style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700))),
                            ]),
                          ]));
                      }),
            ),
    );
  }
}
