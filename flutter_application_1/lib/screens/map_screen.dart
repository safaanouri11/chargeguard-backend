import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

const _kGreen  = Color(0xFF00E5A0);
const _kBg     = Color(0xFF0A0E1A);
const _kCard   = Color(0xFF131929);
const _kBorder = Color(0xFF1E2A3A);

// ── Data Models ───────────────────────────────────────────
class ChargingStation {
  final String name, status, chargerType, connectorType, price, waitingTime;
  final double lat, lng, reliabilityScore;
  const ChargingStation({
    required this.name, required this.lat, required this.lng,
    required this.status, required this.chargerType,
    required this.connectorType, required this.price,
    required this.waitingTime, required this.reliabilityScore,
  });
}

class RouteInfo {
  final List<LatLng> points;
  final double distanceMeters, durationSeconds;
  const RouteInfo({required this.points, required this.distanceMeters, required this.durationSeconds});
}

// ── Screen ────────────────────────────────────────────────
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapCtrl = MapController();

  static const stations = [
    ChargingStation(name: 'An-Najah EV Station', lat: 32.2211, lng: 35.2544,
        status: 'Available', chargerType: 'DC Fast', connectorType: 'CCS2',
        price: '2.5 NIS/kWh', waitingTime: '0 min', reliabilityScore: 4.8),
    ChargingStation(name: 'City Mall Charger', lat: 32.2300, lng: 35.2600,
        status: 'Occupied', chargerType: 'AC', connectorType: 'Type 2',
        price: '1.8 NIS/kWh', waitingTime: '12 min', reliabilityScore: 4.2),
    ChargingStation(name: 'Downtown Fast Charger', lat: 32.2250, lng: 35.2400,
        status: 'Out of Service', chargerType: 'DC Fast', connectorType: 'CCS2',
        price: '3.0 NIS/kWh', waitingTime: 'N/A', reliabilityScore: 2.9),
    ChargingStation(name: 'Campus Green Charger', lat: 32.2180, lng: 35.2500,
        status: 'Available', chargerType: 'AC', connectorType: 'Type 2',
        price: '1.5 NIS/kWh', waitingTime: '3 min', reliabilityScore: 4.6),
  ];

  LatLng? _userLocation;
  String  _filter       = 'All';
  RouteInfo? _route;
  bool _loadingRoute    = false;
  ChargingStation? _selected;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  // ── Status color
  Color _statusColor(String s) {
    switch (s) {
      case 'Available':     return _kGreen;
      case 'Occupied':      return Colors.orange;
      case 'Out of Service':return Colors.redAccent;
      default:              return Colors.blueAccent;
    }
  }

  List<ChargingStation> get _filtered =>
      stations.where((s) => _filter == 'All' || s.status == _filter).toList();

  // ── Location
  Future<void> _getLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied) return;
    final pos = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
    _mapCtrl.move(_userLocation!, 14);
  }

  // ── Route
  Future<void> _fetchRoute(ChargingStation s) async {
    if (_userLocation == null) return;
    setState(() { _loadingRoute = true; _selected = s; });

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${_userLocation!.longitude},${_userLocation!.latitude};'
        '${s.lng},${s.lat}?overview=full&geometries=geojson',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        setState(() {
          _route = RouteInfo(
            points: coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList(),
            distanceMeters: data['routes'][0]['distance'],
            durationSeconds: data['routes'][0]['duration'],
          );
        });
      }
    } catch (_) {}

    setState(() => _loadingRoute = false);
  }

  String _fmtDist(double m) =>
      m > 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.toStringAsFixed(0)} m';
  String _fmtTime(double s) => '${(s / 60).round()} min';

  // ── Show station bottom sheet
  void _showDetails(ChargingStation s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                  color: _statusColor(s.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.ev_station, color: _statusColor(s.status), size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(s.chargerType, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: _statusColor(s.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(s.status,
                  style: TextStyle(color: _statusColor(s.status), fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            _infoChip(Icons.bolt, s.connectorType),
            const SizedBox(width: 10),
            _infoChip(Icons.attach_money, s.price),
            const SizedBox(width: 10),
            _infoChip(Icons.access_time, s.waitingTime),
            const SizedBox(width: 10),
            _infoChip(Icons.star, '${s.reliabilityScore}'),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () { Navigator.pop(context); _fetchRoute(s); },
                icon: const Icon(Icons.directions, color: _kGreen, size: 18),
                label: const Text('Get Route', style: TextStyle(color: _kGreen, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: s.status == 'Available' ? () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Booking ${s.name}...'),
                      backgroundColor: _kCard,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                } : null,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white10,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Icon(icon, color: _kGreen, size: 16),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final center = _userLocation ?? const LatLng(32.2211, 35.2544);

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [

        // ── Map
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(initialCenter: center, initialZoom: 13),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              additionalOptions: const {'User-Agent': 'ChargeGuard/1.0'},
            ),
            if (_route != null)
              PolylineLayer(polylines: [
                Polyline(
                  points: _route!.points,
                  color: _kGreen,
                  strokeWidth: 4,
                ),
              ]),
            MarkerLayer(markers: [
              ..._filtered.map((s) => Marker(
                point: LatLng(s.lat, s.lng),
                width: 48, height: 48,
                child: GestureDetector(
                  onTap: () => _showDetails(s),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _statusColor(s.status).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: _statusColor(s.status), width: 2),
                    ),
                    child: Icon(Icons.ev_station, color: _statusColor(s.status), size: 22),
                  ),
                ),
              )),
              if (_userLocation != null)
                Marker(
                  point: _userLocation!,
                  width: 44, height: 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent, width: 2),
                    ),
                    child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 20),
                  ),
                ),
            ]),
          ],
        ),

        // ── Top: Search + Filters
        SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
                ),
                child: const Row(children: [
                  Icon(Icons.search, color: Colors.white38, size: 20),
                  SizedBox(width: 10),
                  Text('Search chargers...', style: TextStyle(color: Colors.white38, fontSize: 14)),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: ['All', 'Available', 'Occupied', 'Out of Service'].map((f) {
                final sel = _filter == f;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? _kGreen : _kCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? _kGreen : _kBorder),
                    ),
                    child: Text(f,
                        style: TextStyle(
                            color: sel ? Colors.black : Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                );
              }).toList()),
            ),
          ]),
        ),

        // ── Route info banner
        if (_route != null && _selected != null)
          Positioned(
            top: 130, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.3), blurRadius: 12)],
              ),
              child: Row(children: [
                const Icon(Icons.directions, color: Colors.black, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_fmtDist(_route!.distanceMeters)} · ${_fmtTime(_route!.durationSeconds)} to ${_selected!.name}',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() { _route = null; _selected = null; }),
                  child: const Icon(Icons.close, color: Colors.black, size: 18),
                ),
              ]),
            ),
          ),

        // ── Loading
        if (_loadingRoute)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(color: _kGreen),
            ),
          ),

        // ── Bottom: Station count
        Positioned(
          bottom: 16, left: 16, right: 80,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Row(children: [
              const Icon(Icons.ev_station, color: _kGreen, size: 18),
              const SizedBox(width: 8),
              Text('${_filtered.length} stations found',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${stations.where((s) => s.status == 'Available').length} available',
                  style: const TextStyle(color: _kGreen, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),

      // ── FAB: My Location
      floatingActionButton: FloatingActionButton(
        onPressed: _getLocation,
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: _kBorder)),
        child: const Icon(Icons.my_location, color: _kGreen),
      ),
    );
  }
}
