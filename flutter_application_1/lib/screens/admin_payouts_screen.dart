import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class AdminPayoutsScreen extends StatefulWidget {
  const AdminPayoutsScreen({super.key});
  @override
  State<AdminPayoutsScreen> createState() => _AdminPayoutsScreenState();
}

class _AdminPayoutsScreenState extends State<AdminPayoutsScreen> {
  List<dynamic> _payouts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.instance.getAllPayouts();
    if (mounted) {
      setState(() {
        _loading = false;
        _payouts = result['success'] ? (result['data'] as List? ?? []) : [];
      });
    }
  }

  Future<void> _approve(String id) async {
    final result = await ApiService.instance.approvePayout(id);
    if (mounted) {
      _snack(result['success'] ? 'Payout approved ✅' : result['message'] ?? 'Error',
          isError: !result['success']);
      if (result['success']) _load();
    }
  }

  Future<void> _reject(String id) async {
    final result = await ApiService.instance.rejectPayout(id);
    if (mounted) {
      _snack(result['success'] ? 'Payout rejected' : result['message'] ?? 'Error',
          isError: !result['success']);
      if (result['success']) _load();
    }
  }

  void _snack(String msg, {bool isError = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: isError ? kRed : cCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  int get _pendingCount => _payouts.where((p) => p['status'] == 'Pending').length;
  int get _paidCount    => _payouts.where((p) => p['status'] == 'Paid').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(backgroundColor: cBg, elevation: 0,
          title: Text('Payout Requests', style: kTitle(18)),
          actions: [IconButton(icon: const Icon(Icons.refresh, color: kGreen), onPressed: _load)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : Column(children: [
              // Stats row
              Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(children: [
                  _stat('$_pendingCount', 'Pending', Colors.orange),
                  const SizedBox(width: 12),
                  _stat('$_paidCount', 'Paid Out', kGreen),
                ])),

              Expanded(child: _payouts.isEmpty
                ? Center(child: Text('No payout requests', style: kSub(14)))
                : RefreshIndicator(color: kGreen, onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _payouts.length,
                      itemBuilder: (_, i) {
                        final p = _payouts[i] as Map<String, dynamic>;
                        final status = p['status'] as String? ?? 'Pending';
                        final color = status == 'Paid' ? kGreen
                            : status == 'Rejected' ? Colors.redAccent : Colors.orange;
                        final host = p['host'];
                        final hostName = host is Map
                            ? '${host['firstName']} ${host['lastName']}'
                            : 'Host';
                        final businessName = host is Map
                            ? (host['businessName'] as String? ?? '') : '';
                        final amount = (p['amount'] as num?)?.toDouble() ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                          decoration: kCardDeco(),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(width: 44, height: 44,
                                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
                                child: Icon(Icons.payments_outlined, color: color, size: 22)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(businessName.isEmpty ? hostName : businessName, style: kTitle(13)),
                                Text(hostName, style: kSub(11)),
                              ])),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                                child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))),
                            ]),
                            const SizedBox(height: 12),
                            Container(padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(10)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Text('Amount:', style: kSub(11)), const Spacer(),
                                  Text('NIS ${amount.toStringAsFixed(2)}',
                                      style: const TextStyle(color: kGreen, fontSize: 16, fontWeight: FontWeight.w800)),
                                ]),
                                const SizedBox(height: 6),
                                Row(children: [
                                  Text('Bank:', style: kSub(11)), const Spacer(),
                                  Text(p['bankName'] as String? ?? '—', style: TextStyle(color: cTitle, fontSize: 12)),
                                ]),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Text('IBAN:', style: kSub(11)), const Spacer(),
                                  Flexible(child: Text(p['iban'] as String? ?? '—',
                                      style: TextStyle(color: cTitle, fontSize: 12),
                                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ]),
                              ])),
                            if (status == 'Pending') ...[
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(child: OutlinedButton.icon(
                                  onPressed: () => _reject(p['_id'] as String),
                                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                                  label: const Text('Reject',
                                      style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.redAccent),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
                                const SizedBox(width: 8),
                                Expanded(child: ElevatedButton.icon(
                                  onPressed: () => _approve(p['_id'] as String),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Approve',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kGreen, foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
                              ]),
                            ],
                          ]));
                      }))),
            ]),
    );
  }

  Widget _stat(String v, String l, Color color) => Expanded(
    child: Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(v, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
        Text(l, style: kSub(11)),
      ])));
}
