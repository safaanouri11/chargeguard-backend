import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class AdminTicketsScreen extends StatefulWidget {
  const AdminTicketsScreen({super.key});
  @override
  State<AdminTicketsScreen> createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends State<AdminTicketsScreen> {
  List<dynamic> _tickets = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.instance.getAllTickets();
    if (mounted) {
      setState(() {
        _loading = false;
        _tickets = result['success'] ? (result['data'] as List? ?? []) : [];
      });
    }
  }

  Future<void> _resolve(String id) async {
    final result = await ApiService.instance.resolveTicket(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success'] ? 'Ticket resolved ✅' : result['message'] ?? 'Error'),
        backgroundColor: result['success'] ? cCard : kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      if (result['success']) _load();
    }
  }

  String _fmtDate(dynamic iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso.toString()).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${months[d.month - 1]}';
    } catch (_) { return ''; }
  }

  int get _openCount     => _tickets.where((t) => t['status'] == 'Open').length;
  int get _resolvedCount => _tickets.where((t) => t['status'] == 'Resolved').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(backgroundColor: cBg, elevation: 0,
          title: Text('Support Tickets', style: kTitle(18)),
          actions: [IconButton(icon: const Icon(Icons.refresh, color: kGreen), onPressed: _load)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : Column(children: [
              Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(children: [
                  _stat('$_openCount', 'Open', Colors.orange),
                  const SizedBox(width: 12),
                  _stat('$_resolvedCount', 'Resolved', kGreen),
                ])),

              Expanded(child: _tickets.isEmpty
                ? Center(child: Text('No tickets', style: kSub(14)))
                : RefreshIndicator(color: kGreen, onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _tickets.length,
                      itemBuilder: (_, i) {
                        final t = _tickets[i] as Map<String, dynamic>;
                        final status = t['status'] as String? ?? 'Open';
                        final color = status == 'Resolved' ? kGreen : Colors.orange;
                        final user = t['user'];
                        final userName = user is Map
                            ? '${user['firstName']} ${user['lastName']}' : 'User';
                        final userEmail = user is Map ? (user['email'] as String? ?? '') : '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                          decoration: kCardDeco(),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(width: 40, height: 40,
                                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.support_agent, color: color, size: 20)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(t['subject'] as String? ?? 'Issue', style: kTitle(13),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('$userName · ${_fmtDate(t['createdAt'])}', style: kSub(10)),
                              ])),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                                child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))),
                            ]),
                            const SizedBox(height: 12),
                            Container(padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(10)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(t['message'] as String? ?? '',
                                    style: TextStyle(color: cTitle, fontSize: 13, height: 1.4)),
                                if (userEmail.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Icon(Icons.email_outlined, color: cSub2, size: 12),
                                    const SizedBox(width: 6),
                                    Text(userEmail, style: kSub(11)),
                                  ]),
                                ],
                              ])),
                            if (status == 'Open') ...[
                              const SizedBox(height: 12),
                              SizedBox(width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _resolve(t['_id'] as String),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Mark as Resolved',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kGreen, foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
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
