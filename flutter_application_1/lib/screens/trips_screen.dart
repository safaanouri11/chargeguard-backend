import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import 'trip_detail_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});
  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  bool _loading = true;
  List<dynamic> _trips = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.instance.getTrips();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _trips = res['success'] ? (res['data'] as List? ?? []) : [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('My Trips', context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : RefreshIndicator(
              color: kGreen, onRefresh: _load,
              child: _trips.isEmpty ? _emptyState() : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _trips.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) return _summaryHeader();
                  return _tripCard(_trips[i - 1] as Map<String, dynamic>);
                },
              ),
            ),
    );
  }

  Widget _emptyState() => ListView(children: [
        const SizedBox(height: 100),
        Center(child: Icon(Icons.route, color: cSub2, size: 64)),
        const SizedBox(height: 16),
        Center(child: Text('No trips yet', style: kTitle(16))),
        const SizedBox(height: 8),
        Center(child: Text('Start a charging session to record your first trip',
            style: kSub(12), textAlign: TextAlign.center)),
      ]);

  Widget _summaryHeader() {
    final total = _trips.length;
    final totalKwh = _trips.fold<double>(0,
        (s, t) => s + ((t['kwhCharged'] as num?)?.toDouble() ?? 0));
    final totalCost = _trips.fold<double>(0,
        (s, t) => s + ((t['cost'] as num?)?.toDouble() ?? 0));
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kGreen.withOpacity(0.18), Colors.blueAccent.withOpacity(0.05)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGreen.withOpacity(0.3)),
      ),
      child: Row(children: [
        _stat('$total', 'Trips'),
        _divider(),
        _stat(totalKwh.toStringAsFixed(1), 'kWh'),
        _divider(),
        _stat(totalCost.toStringAsFixed(2), 'NIS'),
      ]),
    );
  }

  Widget _stat(String value, String label) => Expanded(child: Column(children: [
        Text(value, style: kTitle(18).copyWith(color: kGreen)),
        const SizedBox(height: 2),
        Text(label, style: kSub(11)),
      ]));

  Widget _divider() => Container(width: 1, height: 32,
      color: cSub2.withOpacity(0.25));

  Widget _tripCard(Map<String, dynamic> t) {
    final station = t['station'] is Map ? t['station'] as Map : null;
    final stationName = station?['name'] as String? ?? 'Unknown station';
    final addr = station?['location']?['address'] as String? ?? '';
    final kwh = (t['kwhCharged'] as num?)?.toDouble() ?? 0;
    final cost = (t['cost'] as num?)?.toDouble() ?? 0;
    final duration = (t['durationMin'] as num?)?.toInt() ?? 0;
    final startPct = (t['startBatteryPct'] as num?)?.toInt() ?? 0;
    final endPct = (t['endBatteryPct'] as num?)?.toInt() ?? 0;
    final endedAt = DateTime.tryParse(t['endedAt'] as String? ?? '');
    final dateStr = endedAt != null
        ? '${endedAt.day}/${endedAt.month}/${endedAt.year} • ${endedAt.hour}:${endedAt.minute.toString().padLeft(2, '0')}'
        : '';
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => TripDetailScreen(trip: t))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: kCardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bolt, color: kGreen, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(stationName, style: kTitle(14)),
              if (addr.isNotEmpty) Text(addr,
                  style: kSub(11), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (dateStr.isNotEmpty) Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(dateStr, style: kSub(10)),
              ),
            ])),
            const Icon(Icons.chevron_right, color: kGreen, size: 18),
          ]),
          const SizedBox(height: 10),
          Container(height: 1, color: cSub2.withOpacity(0.15)),
          const SizedBox(height: 10),
          Row(children: [
            _mini(Icons.battery_charging_full, '${kwh.toStringAsFixed(1)} kWh', kGreen),
            _mini(Icons.attach_money, '${cost.toStringAsFixed(2)} NIS', kGreen),
            _mini(Icons.access_time, '$duration min', cSub2),
          ]),
          const SizedBox(height: 8),
          _batteryBar(startPct, endPct),
        ]),
      ),
    );
  }

  Widget _mini(IconData icon, String text, Color color) => Expanded(child: Row(children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Flexible(child: Text(text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis)),
      ]));

  Widget _batteryBar(int startPct, int endPct) {
    if (endPct <= startPct) return const SizedBox.shrink();
    return Row(children: [
      Text('$startPct%', style: kSub(10)),
      const SizedBox(width: 6),
      Expanded(child: Stack(children: [
        Container(height: 6, decoration: BoxDecoration(
            color: cSub2.withOpacity(0.15),
            borderRadius: BorderRadius.circular(3))),
        Positioned(left: 0, right: 0, top: 0, bottom: 0,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (endPct / 100).clamp(0.0, 1.0),
            child: Container(decoration: BoxDecoration(
                color: kGreen, borderRadius: BorderRadius.circular(3))),
          ),
        ),
      ])),
      const SizedBox(width: 6),
      Text('$endPct%', style: kSub(10).copyWith(color: kGreen)),
    ]);
  }
}
