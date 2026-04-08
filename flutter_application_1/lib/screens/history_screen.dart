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
    final res = await ApiService.instance.getTransactions();
    setState(() {
      _loading = false;
      if (res['success']) _transactions = res['data'] ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: kAppBar('Charging History', context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : _transactions.isEmpty
              ? const Center(child: Text('No history yet', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _transactions.length,
                  itemBuilder: (_, i) {
                    final t = _transactions[i];
                    final amount = (t['amount'] ?? 0).toDouble();
                    final isCredit = amount >= 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: kCardDeco(),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: (isCredit ? kGreen : Colors.red).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isCredit ? kGreen : Colors.red, size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t['label'] ?? '', style: kTitle(13)),
                          Text(t['type'] ?? '', style: kSub(11)),
                        ])),
                        Text(
                          '${isCredit ? "+" : ""}${amount.toStringAsFixed(0)} NIS',
                          style: TextStyle(
                            color: isCredit ? kGreen : Colors.red,
                            fontSize: 13, fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]),
                    );
                  },
                ),
    );
  }
}
