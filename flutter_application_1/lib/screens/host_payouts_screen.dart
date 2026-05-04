import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import 'host_profile_screen.dart';

class HostPayoutsScreen extends StatefulWidget {
  const HostPayoutsScreen({super.key});
  @override
  State<HostPayoutsScreen> createState() => _HostPayoutsScreenState();
}

class _HostPayoutsScreenState extends State<HostPayoutsScreen> {
  List<dynamic> _payouts = [];
  double _available = 0;
  double _totalEarned = 0;
  double _totalPaid = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ApiService.instance.getHostPayouts();
    if (mounted) {
      setState(() {
        _loading = false;
        if (result['success']) {
          final d = result['data'] as Map<String, dynamic>;
          _payouts     = d['payouts'] as List? ?? [];
          _available   = (d['available'] as num?)?.toDouble() ?? 0;
          _totalEarned = (d['totalEarned'] as num?)?.toDouble() ?? 0;
          _totalPaid   = (d['totalPaid'] as num?)?.toDouble() ?? 0;
        }
      });
    }
  }

  Future<void> _requestPayout() async {
    if (_available < 1) {
      _snack('Nothing to withdraw', isError: true);
      return;
    }

    final ctrl = TextEditingController(text: _available.toStringAsFixed(0));

    final amount = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Request Payout', style: kTitle(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Available: NIS ${_available.toStringAsFixed(2)}', style: kSub(13)),
          const SizedBox(height: 16),
          TextField(controller: ctrl, keyboardType: TextInputType.number,
            style: TextStyle(color: cTitle),
            decoration: InputDecoration(
              labelText: 'Amount (NIS)', labelStyle: TextStyle(color: cSub),
              filled: true, fillColor: cBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kGreen)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: cSub))),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null) Navigator.pop(context, v);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Request')),
        ]));

    if (amount == null || !mounted) return;

    final result = await ApiService.instance.requestPayout(amount);
    if (mounted) {
      _snack(result['success'] ? 'Payout requested! ✅' : result['message'] ?? 'Error',
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
      appBar: kAppBar('Payouts', context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : RefreshIndicator(color: kGreen, onRefresh: _load,
              child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Available balance card
                  Container(width: double.infinity, padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00E5A0), Color(0xFF00B37A)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Available for Withdrawal',
                          style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('NIS ${_available.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.black, fontSize: 40, fontWeight: FontWeight.w900, height: 1)),
                      const SizedBox(height: 16),
                      SizedBox(width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _requestPayout,
                          icon: const Icon(Icons.arrow_downward),
                          label: const Text('Request Payout',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black, foregroundColor: kGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                    ])),
                  const SizedBox(height: 16),

                  // Stats row
                  Row(children: [
                    _stat('NIS ${_totalEarned.toStringAsFixed(0)}', 'Total Earned', kGreen),
                    const SizedBox(width: 12),
                    _stat('NIS ${_totalPaid.toStringAsFixed(0)}', 'Total Paid Out', Colors.blueAccent),
                  ]),
                  const SizedBox(height: 24),

                  // Banking notice
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const HostProfileScreen())),
                    child: Container(padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.blueAccent.withOpacity(0.3))),
                      child: Row(children: [
                        const Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Update your bank details in Host Profile',
                            style: TextStyle(color: cTitle, fontSize: 12))),
                        const Icon(Icons.chevron_right, color: Colors.blueAccent, size: 18),
                      ]))),
                  const SizedBox(height: 24),

                  Text('Payout History', style: kTitle(16)),
                  const SizedBox(height: 12),
                  if (_payouts.isEmpty)
                    Container(padding: const EdgeInsets.all(20), decoration: kCardDeco(),
                      child: Center(child: Text('No payouts yet', style: kSub(13))))
                  else
                    ..._payouts.map((p) {
                      final amount = (p['amount'] as num?)?.toDouble() ?? 0;
                      final status = p['status'] as String? ?? 'Pending';
                      final color  = status == 'Paid' ? kGreen
                          : status == 'Rejected' ? Colors.redAccent : Colors.orange;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                        decoration: kCardDeco(),
                        child: Row(children: [
                          Container(width: 40, height: 40,
                            decoration: BoxDecoration(color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.arrow_downward, color: color, size: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('NIS ${amount.toStringAsFixed(2)}', style: kTitle(14)),
                            Text(p['bankName'] as String? ?? '', style: kSub(11)),
                          ])),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10)),
                            child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))),
                        ]));
                    }),
                ]))),
    );
  }

  Widget _stat(String v, String l, Color color) => Expanded(
    child: Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(v, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(l, style: kSub(11)),
      ])));
}
