import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});
  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  List<dynamic> _logs = [];
  bool _loading = true;
  String _filter = 'all';

  static const _actions = {
    'approve_host':   ('Approve Host',   Icons.verified,         kGreen),
    'reject_host':    ('Reject Host',    Icons.cancel,           Colors.redAccent),
    'edit_balance':   ('Edit Balance',   Icons.account_balance_wallet, Colors.amber),
    'delete_user':    ('Delete User',    Icons.delete,           Colors.redAccent),
    'suspend_user':   ('Suspend User',   Icons.block,            Colors.orange),
    'unsuspend_user': ('Restore User',   Icons.check_circle,     kGreen),
    'reset_password': ('Reset Password', Icons.lock_reset,       Colors.amber),
    'toggle_station': ('Toggle Station', Icons.toggle_on,        Colors.blueAccent),
    'edit_station':   ('Edit Station',   Icons.edit_location,    Colors.blueAccent),
    'delete_station': ('Delete Station', Icons.delete,           Colors.redAccent),
    'approve_payout': ('Approve Payout', Icons.payments,         kGreen),
    'reject_payout':  ('Reject Payout',  Icons.money_off,        Colors.redAccent),
    'resolve_ticket': ('Resolve Ticket', Icons.support_agent,    kGreen),
    'create_promo':   ('Create Promo',   Icons.local_offer,      Colors.purpleAccent),
    'broadcast':      ('Broadcast',      Icons.campaign,         Colors.tealAccent),
    'update_config':  ('Update Config',  Icons.settings,         Colors.blueAccent),
    'export':         ('Export Data',    Icons.file_download,    Colors.amber),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.instance.getAuditLogs(limit: 200);
    if (mounted) {
      setState(() {
        _loading = false;
        _logs = result['success'] ? (result['data'] as List? ?? []) : [];
      });
    }
  }

  List<dynamic> get _filtered {
    if (_filter == 'all') return _logs;
    return _logs.where((l) => (l['action'] as String? ?? '').contains(_filter)).toList();
  }

  String _ago(String iso) {
    try {
      final dt   = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1)  return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours   < 24) return '${diff.inHours}h ago';
      if (diff.inDays    < 7)  return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(backgroundColor: cBg, elevation: 0,
          title: Text('Audit Log', style: kTitle(18)),
          actions: [IconButton(icon: const Icon(Icons.refresh, color: kGreen), onPressed: _load)]),
      body: Column(children: [
        SizedBox(height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _filterChip('all',     'All'),
              _filterChip('host',    'Hosts'),
              _filterChip('user',    'Users'),
              _filterChip('station', 'Stations'),
              _filterChip('payout',  'Payouts'),
              _filterChip('config',  'Config'),
              _filterChip('broadcast', 'Broadcasts'),
            ],
          )),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kGreen))
            : _filtered.isEmpty
                ? Center(child: Text('No audit entries', style: kSub(14)))
                : RefreshIndicator(color: kGreen, onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final l = _filtered[i] as Map<String, dynamic>;
                        final action = l['action'] as String? ?? '';
                        final tuple = _actions[action];
                        final label = tuple != null ? tuple.$1 : action;
                        final icon  = tuple != null ? tuple.$2 : Icons.history;
                        final color = tuple != null ? tuple.$3 : cSub2;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: kCardDeco(radius: 12),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(width: 36, height: 36,
                              decoration: BoxDecoration(color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(icon, color: color, size: 18)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(label, style: kTitle(13))),
                                Text(_ago(l['createdAt'] as String? ?? ''), style: kSub(10)),
                              ]),
                              const SizedBox(height: 3),
                              Text(l['detail'] as String? ?? '',
                                  style: kSub(11), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(children: [
                                Icon(Icons.person_outline, color: cSub2, size: 11),
                                const SizedBox(width: 4),
                                Text(l['adminEmail'] as String? ?? '',
                                    style: TextStyle(color: cSub2, fontSize: 10)),
                              ]),
                            ])),
                          ]),
                        );
                      }))),
      ]),
    );
  }

  Widget _filterChip(String value, String label) {
    final sel = _filter == value;
    return Padding(padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: sel ? kGreen : cCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? kGreen : cBorder)),
          child: Text(label, style: TextStyle(
              color: sel ? Colors.black : cSub,
              fontSize: 12, fontWeight: FontWeight.w700)),
        )));
  }
}
