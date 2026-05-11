import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/constants.dart';

class TripDetailScreen extends StatelessWidget {
  final Map<String, dynamic> trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final station = trip['station'] is Map ? trip['station'] as Map : null;
    final stationName = station?['name'] as String? ?? 'Unknown station';
    final addr = station?['location']?['address'] as String? ?? '';
    final lat = (station?['location']?['lat'] as num?)?.toDouble()
        ?? (trip['endLat'] as num?)?.toDouble() ?? 32.221;
    final lng = (station?['location']?['lng'] as num?)?.toDouble()
        ?? (trip['endLng'] as num?)?.toDouble() ?? 35.258;
    final kwh = (trip['kwhCharged'] as num?)?.toDouble() ?? 0;
    final cost = (trip['cost'] as num?)?.toDouble() ?? 0;
    final duration = (trip['durationMin'] as num?)?.toInt() ?? 0;
    final startPct = (trip['startBatteryPct'] as num?)?.toInt() ?? 0;
    final endPct = (trip['endBatteryPct'] as num?)?.toInt() ?? 0;
    final pctGained = endPct - startPct;
    final endedAt = DateTime.tryParse(trip['endedAt'] as String? ?? '');
    final power = station?['power'] as String? ?? '—';
    final connector = station?['connector'] as String? ?? '—';

    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Trip Details', context),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        // Map
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cSub2.withOpacity(0.2)),
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(lat, lng), initialZoom: 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.chargeguard.app',
              ),
              MarkerLayer(markers: [
                Marker(point: LatLng(lat, lng), width: 50, height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      color: kGreen, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: kGreen.withOpacity(0.5), blurRadius: 14)],
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.ev_station, color: Colors.black, size: 24),
                  ),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Station header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: kCardDeco(),
          child: Row(children: [
            Container(width: 50, height: 50,
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.ev_station, color: kGreen, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(stationName, style: kTitle(15)),
              if (addr.isNotEmpty) Text(addr, style: kSub(12)),
              const SizedBox(height: 4),
              Row(children: [
                _chip(Icons.flash_on, power, Colors.amber),
                const SizedBox(width: 6),
                _chip(Icons.power, connector, Colors.blueAccent),
              ]),
            ])),
          ]),
        ),
        const SizedBox(height: 16),

        // Stats grid
        Row(children: [
          _statCard(Icons.bolt, '${kwh.toStringAsFixed(1)} kWh', 'Energy Charged'),
          const SizedBox(width: 10),
          _statCard(Icons.attach_money, '${cost.toStringAsFixed(2)} NIS', 'Total Cost'),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _statCard(Icons.access_time, _fmtDuration(duration), 'Duration'),
          const SizedBox(width: 10),
          _statCard(Icons.battery_charging_full, '+$pctGained%', 'Battery Gained'),
        ]),
        const SizedBox(height: 20),

        // Battery start → end visualization
        Container(
          padding: const EdgeInsets.all(16),
          decoration: kCardDeco(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Battery Level', style: kTitle(14)),
            const SizedBox(height: 14),
            Row(children: [
              Column(children: [
                Text('$startPct%', style: kTitle(20)),
                Text('Start', style: kSub(11)),
              ]),
              const SizedBox(width: 14),
              Expanded(child: Stack(children: [
                Container(height: 10, decoration: BoxDecoration(
                    color: cSub2.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(5))),
                Positioned(left: 0, right: 0, top: 0, bottom: 0,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (endPct / 100).clamp(0.0, 1.0),
                    child: Container(decoration: BoxDecoration(
                        color: kGreen, borderRadius: BorderRadius.circular(5))),
                  ),
                ),
              ])),
              const SizedBox(width: 14),
              Column(children: [
                Text('$endPct%', style: kTitle(20).copyWith(color: kGreen)),
                Text('End', style: kSub(11)),
              ]),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        if (endedAt != null) Container(
          padding: const EdgeInsets.all(14),
          decoration: kCardDeco(),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined, color: kGreen, size: 18),
            const SizedBox(width: 10),
            Text(
              'Completed: ${endedAt.day}/${endedAt.month}/${endedAt.year} • '
              '${endedAt.hour}:${endedAt.minute.toString().padLeft(2, '0')}',
              style: kSub(12),
            ),
          ]),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _statCard(IconData icon, String value, String label) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(14),
        decoration: kCardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: kGreen, size: 18),
          const SizedBox(height: 8),
          Text(value, style: kTitle(16)),
          const SizedBox(height: 2),
          Text(label, style: kSub(11)),
        ]),
      ));

  Widget _chip(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 12), const SizedBox(width: 4),
      Text(text, style: TextStyle(color: color,
          fontSize: 10, fontWeight: FontWeight.w700)),
    ]),
  );

  String _fmtDuration(int min) {
    if (min < 60) return '$min min';
    final h = min ~/ 60; final m = min % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
