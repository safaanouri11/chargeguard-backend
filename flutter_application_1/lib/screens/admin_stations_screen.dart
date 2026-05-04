import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class AdminStationsScreen extends StatefulWidget {
  const AdminStationsScreen({super.key});
  @override
  State<AdminStationsScreen> createState() => _AdminStationsScreenState();
}

class _AdminStationsScreenState extends State<AdminStationsScreen> {
  List<dynamic> _stations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.instance.getAllStationsAdmin();
    if (mounted) {
      setState(() {
        _loading = false;
        _stations = result['success'] ? (result['data'] as List? ?? []) : [];
      });
    }
  }

  Future<void> _toggle(String id) async {
    final result = await ApiService.instance.toggleStationAdmin(id);
    if (mounted) {
      _snack(result['success'] ? 'Status updated' : result['message'] ?? 'Error',
          isError: !result['success']);
      if (result['success']) _load();
    }
  }

  Future<void> _delete(Map<String, dynamic> station) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Station?', style: kTitle(16)),
        content: Text('Delete "${station['name']}"?\nThis cannot be undone.', style: kSub(13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: cSub))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete')),
        ]));

    if (confirm != true || !mounted) return;
    final result = await ApiService.instance.deleteStation(station['_id'] as String);
    if (mounted) {
      _snack(result['success'] ? 'Station deleted' : result['message'] ?? 'Error',
          isError: !result['success']);
      if (result['success']) _load();
    }
  }

  void _snack(String msg, {bool isError = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: isError ? kRed : cCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(backgroundColor: cBg, elevation: 0,
          title: Text('All Stations (${_stations.length})', style: kTitle(18)),
          actions: [IconButton(icon: const Icon(Icons.refresh, color: kGreen), onPressed: _load)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : _stations.isEmpty
              ? Center(child: Text('No stations', style: kSub(14)))
              : RefreshIndicator(color: kGreen, onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _stations.length,
                    itemBuilder: (_, i) {
                      final s = _stations[i] as Map<String, dynamic>;
                      final active = s['available'] as bool? ?? true;
                      final host = s['host'];
                      final hostName = host is Map
                          ? '${host['firstName']} ${host['lastName']}'
                          : 'Unknown Host';
                      final location = s['location'];
                      final address = location is Map ? location['address'] as String? ?? '' : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                        decoration: kCardDeco(),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(width: 44, height: 44,
                              decoration: BoxDecoration(color: (active ? kGreen : Colors.redAccent).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(11)),
                              child: Icon(Icons.ev_station, color: active ? kGreen : Colors.redAccent, size: 22)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(s['name'] as String? ?? 'Station', style: kTitle(14),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(address, style: kSub(11),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ])),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (active ? kGreen : Colors.redAccent).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10)),
                              child: Text(active ? 'Active' : 'Disabled',
                                  style: TextStyle(color: active ? kGreen : Colors.redAccent,
                                      fontSize: 11, fontWeight: FontWeight.w700))),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            _tag(Icons.person_outline, hostName),
                            const SizedBox(width: 8),
                            _tag(Icons.bolt, s['power'] as String? ?? ''),
                            const SizedBox(width: 8),
                            _tag(Icons.attach_money, 'NIS ${s['price']}/kWh'),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: OutlinedButton.icon(
                              onPressed: () => _toggle(s['_id'] as String),
                              icon: Icon(active ? Icons.pause : Icons.play_arrow,
                                  color: active ? Colors.orange : kGreen, size: 16),
                              label: Text(active ? 'Disable' : 'Enable',
                                  style: TextStyle(color: active ? Colors.orange : kGreen,
                                      fontSize: 12, fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: active ? Colors.orange : kGreen),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
                            const SizedBox(width: 8),
                            Expanded(child: OutlinedButton.icon(
                              onPressed: () => _delete(s),
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                              label: const Text('Delete',
                                  style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
                          ]),
                        ]));
                    })),
    );
  }

  Widget _tag(IconData icon, String text) => Flexible(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: cSub2, size: 12), const SizedBox(width: 4),
      Flexible(child: Text(text, style: kSub(10),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
    ])));
}
