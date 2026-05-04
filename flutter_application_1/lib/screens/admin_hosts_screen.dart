import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import 'admin_host_detail_screen.dart';

class AdminHostsScreen extends StatefulWidget {
  const AdminHostsScreen({super.key});
  @override
  State<AdminHostsScreen> createState() => _AdminHostsScreenState();
}

class _AdminHostsScreenState extends State<AdminHostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _pending = [];
  List<dynamic> _all     = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.instance.getPendingHosts(),
      ApiService.instance.getAllHosts(),
    ]);
    if (mounted) {
      setState(() {
        _loading = false;
        _pending = results[0]['success'] ? (results[0]['data'] as List? ?? []) : [];
        _all     = results[1]['success'] ? (results[1]['data'] as List? ?? []) : [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg, elevation: 0,
        title: Text('Host Applications', style: kTitle(18)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: kGreen), onPressed: _load)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cBorder)),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black, unselectedLabelColor: cSub,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: '⏳ Pending (${_pending.length})'),
                Tab(text: '👥 All Hosts (${_all.length})'),
              ]))),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : TabBarView(controller: _tabCtrl, children: [
              _list(_pending, isPending: true),
              _list(_all, isPending: false),
            ]),
    );
  }

  Widget _list(List<dynamic> list, {required bool isPending}) {
    if (list.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(isPending ? Icons.inbox_outlined : Icons.people_outline, color: cSub2, size: 64),
        const SizedBox(height: 16),
        Text(isPending ? 'No pending applications' : 'No hosts yet', style: kTitle(16)),
      ]));
    }

    return RefreshIndicator(color: kGreen, onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final h      = list[i] as Map<String, dynamic>;
          final status = h['hostStatus'] as String? ?? 'None';
          final color  = status == 'Approved' ? kGreen
              : status == 'Pending' ? Colors.orange
              : status == 'Rejected' ? Colors.redAccent : cSub2;
          return GestureDetector(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AdminHostDetailScreen(hostId: h['_id'] as String)));
              _load();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
              decoration: kCardDeco(),
              child: Row(children: [
                Container(width: 46, height: 46,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                  child: Center(child: Text(
                    (h['firstName'] as String? ?? '?')[0].toUpperCase(),
                    style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${h['firstName']} ${h['lastName']}', style: kTitle(13)),
                  Text(h['email'] as String? ?? '', style: kSub(11)),
                  if ((h['businessName'] as String? ?? '').isNotEmpty)
                    Text(h['businessName'] as String, style: kSub(11)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))),
              ])));
        }));
  }
}
