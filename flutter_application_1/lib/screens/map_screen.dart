import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../utils/api_service.dart';
import '../utils/constants.dart' show EVNetwork, kNetworks, networkInfo;
import '../utils/station_filters.dart';
import 'booking_form_screen.dart';
import 'map_filters_screen.dart';

const _kGreen  = Color(0xFF00E5A0);
const _kBg     = Color(0xFF0A0E1A);
const _kCard   = Color(0xFF131929);
const _kBorder = Color(0xFF1E2A3A);

// ── Connector Colors ───────────────────────────────────────
Color _connColor(String? c) {
  switch (c?.toUpperCase()) {
    case 'CCS2':    return const Color(0xFF00E5A0);
    case 'CCS1':    return const Color(0xFF00C9E0);
    case 'TYPE 2':  return const Color(0xFF4A90E2);
    case 'CHADEMO': return const Color(0xFFFF6B35);
    case 'GB/T':    return const Color(0xFFB44FE8);
    case 'NACS':    return const Color(0xFFE8334F);
    case 'J-1772':  return const Color(0xFF4A90E2);
    case 'AC':      return const Color(0xFFFFD93D);
    default:        return const Color(0xFF00E5A0);
  }
}

class RouteInfo {
  final List<LatLng> points;
  final double distanceMeters, durationSeconds;
  const RouteInfo({required this.points, required this.distanceMeters, required this.durationSeconds});
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapCtrl    = MapController();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _stations    = [];
  Set<String>                _bookmarkIds = {};
  bool _loadingStations = true;

  LatLng?    _userLocation;
  RouteInfo? _route;
  bool _loadingRoute = false;
  Map<String, dynamic>? _selected;

  // ── Filters ───────────────────────────────────────────────
  String     _filterAvail    = 'All';
  String     _filterConn     = 'All';
  String     _filterPower    = 'All';
  String     _filterComing   = 'Include'; // Include | Only | Hide
  Set<String> _filterAmen    = {};
  Set<String> _filterParking = {};
  Set<String> _filterVehicle = {};
  String _searchQuery = '';
  bool   _showFilters = false;

  static const _connectors = ['All', 'CCS2', 'Type 2', 'CHAdeMO', 'GB/T', 'NACS', 'AC'];
  static const _powers     = ['All', 'Fast (50kW+)', 'Medium (22kW)', 'Slow (7kW)'];
  static const _amenList   = ['WiFi', 'Dining', 'Restroom', 'Shopping', 'Lodging', 'Park',
                               'Grocery', 'Valet', 'Hiking', 'Camping', 'Free Charge'];
  static const _parkList   = ['Accessible', 'Covered', 'Garage', 'Illuminated',
                               'Pull In', 'Pull Through', 'Trailer Friendly'];
  static const _vehicleList = ['Car', 'Truck', 'Motorcycle', 'RV', 'Bicycle'];

  static const Map<String, IconData> _amenIcons = {
    'WiFi': Icons.wifi, 'Dining': Icons.restaurant, 'Restroom': Icons.wc,
    'Shopping': Icons.shopping_bag, 'Lodging': Icons.hotel, 'Park': Icons.park,
    'Grocery': Icons.shopping_cart, 'Valet': Icons.car_crash, 'Hiking': Icons.hiking,
    'Camping': Icons.cabin, 'Free Charge': Icons.money_off,
  };

  static const Map<String, IconData> _parkIcons = {
    'Accessible': Icons.accessible, 'Covered': Icons.roofing, 'Garage': Icons.garage,
    'Illuminated': Icons.lightbulb, 'Pull In': Icons.arrow_downward,
    'Pull Through': Icons.swap_vert, 'Trailer Friendly': Icons.rv_hookup,
  };

  @override
  void initState() {
    super.initState();
    _loadStations();
    _loadBookmarks();
    StationFilters.instance.addListener(_onFiltersChanged);
    // Wait for map to build before moving
    WidgetsBinding.instance.addPostFrameCallback((_) => _getLocation());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mapCtrl.dispose();
    StationFilters.instance.removeListener(_onFiltersChanged);
    super.dispose();
  }

  void _onFiltersChanged() => _loadStations();

  Future<void> _loadStations() async {
    final filters = StationFilters.instance.toQuery();
    final result = await ApiService.instance.getStations(
        filters: filters.isEmpty ? null : filters);
    if (mounted) {
      setState(() {
        _loadingStations = false;
        _stations = result['success']
            ? (result['data'] as List).map((s) => Map<String, dynamic>.from(s)).toList()
            : [];
      });
    }
  }

  Future<void> _loadBookmarks() async {
    final result = await ApiService.instance.getBookmarkIds();
    if (mounted && result['success']) {
      setState(() {
        _bookmarkIds = Set<String>.from((result['data'] as List).map((e) => e.toString()));
      });
    }
  }

  Future<void> _toggleBookmark(String stationId) async {
    final isBm = _bookmarkIds.contains(stationId);
    setState(() { isBm ? _bookmarkIds.remove(stationId) : _bookmarkIds.add(stationId); });
    if (isBm) {
      await ApiService.instance.removeBookmark(stationId);
    } else {
      await ApiService.instance.addBookmark(stationId);
    }
    // Notify BookmarksScreen to refresh
    UserSession.instance.notifyBookmarkChange();
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _stations;

    // Coming soon
    if (_filterComing == 'Hide')    list = list.where((s) => (s['status'] ?? 'Active') != 'Coming Soon').toList();
    if (_filterComing == 'Only')    list = list.where((s) => (s['status'] ?? 'Active') == 'Coming Soon').toList();

    // Availability (only active stations)
    if (_filterAvail == 'Available') list = list.where((s) =>
        s['available'] == true && (s['status'] ?? 'Active') == 'Active').toList();
    if (_filterAvail == 'Busy')      list = list.where((s) =>
        s['available'] == false && (s['status'] ?? 'Active') == 'Active').toList();

    // Connector
    if (_filterConn != 'All') list = list.where((s) =>
        (s['connector'] as String? ?? '').toLowerCase() == _filterConn.toLowerCase()).toList();

    // Power
    if (_filterPower == 'Fast (50kW+)')  list = list.where((s) => (s['power'] as String? ?? '').contains('50')).toList();
    if (_filterPower == 'Medium (22kW)') list = list.where((s) => (s['power'] as String? ?? '').contains('22')).toList();
    if (_filterPower == 'Slow (7kW)')    list = list.where((s) => (s['power'] as String? ?? '').contains('7')).toList();

    // Amenities
    if (_filterAmen.isNotEmpty) {
      list = list.where((s) {
        final amen = (s['amenities'] as List? ?? []).map((e) => e.toString()).toSet();
        return _filterAmen.every((a) => amen.contains(a));
      }).toList();
    }

    // Parking
    if (_filterParking.isNotEmpty) {
      list = list.where((s) {
        final park = (s['parking'] as List? ?? []).map((e) => e.toString()).toSet();
        return _filterParking.every((p) => park.contains(p));
      }).toList();
    }

    // Vehicle
    if (_filterVehicle.isNotEmpty) {
      list = list.where((s) {
        final veh = (s['vehicles'] as List? ?? []).map((e) => e.toString()).toSet();
        return _filterVehicle.any((v) => veh.contains(v));
      }).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      list = list.where((s) {
        final name = (s['name'] as String? ?? '').toLowerCase();
        final conn = (s['connector'] as String? ?? '').toLowerCase();
        final addr = (s['location']?['address'] as String? ?? '').toLowerCase();
        return name.contains(_searchQuery) || conn.contains(_searchQuery) || addr.contains(_searchQuery);
      }).toList();
    }

    return list;
  }

  int get _activeFilters {
    int c = 0;
    if (_filterAvail    != 'All')     c++;
    if (_filterConn     != 'All')     c++;
    if (_filterPower    != 'All')     c++;
    if (_filterComing   != 'Include') c++;
    if (_filterAmen.isNotEmpty)       c++;
    if (_filterParking.isNotEmpty)    c++;
    if (_filterVehicle.isNotEmpty)    c++;
    return c;
  }

  void _resetFilters() => setState(() {
    _filterAvail = 'All'; _filterConn = 'All'; _filterPower = 'All';
    _filterComing = 'Include'; _filterAmen.clear();
    _filterParking.clear(); _filterVehicle.clear();
  });

  Future<void> _getLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
      _mapCtrl.move(_userLocation!, 13);
    } catch (_) {}
  }

  Future<void> _fetchRoute(Map<String, dynamic> s) async {
    if (_userLocation == null) return;
    setState(() { _loadingRoute = true; _selected = s; });
    try {
      final lat = (s['location']?['lat'] as num?)?.toDouble() ?? 32.2211;
      final lng = (s['location']?['lng'] as num?)?.toDouble() ?? 35.2544;
      final res = await http.get(Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/'
          '${_userLocation!.longitude},${_userLocation!.latitude};$lng,$lat'
          '?overview=full&geometries=geojson'));
      if (res.statusCode == 200) {
        final data   = jsonDecode(res.body);
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        setState(() => _route = RouteInfo(
          points: coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList(),
          distanceMeters:  data['routes'][0]['distance'],
          durationSeconds: data['routes'][0]['duration'],
        ));
      }
    } catch (_) {}
    setState(() => _loadingRoute = false);
  }

  String _fmtDist(double m) => m > 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.toStringAsFixed(0)} m';
  String _fmtTime(double s)  => '${(s / 60).round()} min';

  void _showDetails(Map<String, dynamic> s) {
    final id        = s['_id'] as String? ?? '';
    final ok        = s['available'] as bool? ?? true;
    final name      = s['name']      as String? ?? 'Station';
    final power     = s['power']     as String? ?? '22 kW';
    final conn      = s['connector'] as String? ?? 'CCS2';
    final price     = s['price']?.toString() ?? '2.5';
    final addr      = s['location']?['address'] as String? ?? '';
    final status    = s['status']    as String? ?? 'Active';
    final networkName = s['network'] as String? ?? 'Independent';
    final plugCount = s['plugCount'] ?? 1;
    final amenities = (s['amenities'] as List? ?? []).map((e) => e.toString()).toList();
    final parking   = (s['parking']   as List? ?? []).map((e) => e.toString()).toList();
    final color     = status == 'Coming Soon' ? Colors.grey : _connColor(conn);
    final network   = networkInfo(networkName);

    showModalBottomSheet(
      context: context, backgroundColor: _kCard, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, set) {
        final bm = _bookmarkIds.contains(id);
        return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),

              // Header
              Row(children: [
                Container(width: 56, height: 56,
                  decoration: BoxDecoration(color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.4))),
                  child: Icon(Icons.ev_station, color: color, size: 28)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(addr, style: const TextStyle(color: Colors.white54, fontSize: 11),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ])),
                GestureDetector(
                  onTap: () { _toggleBookmark(id); set(() {}); },
                  child: Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: bm ? color.withOpacity(0.15) : Colors.white10,
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(bm ? Icons.bookmark : Icons.bookmark_outline,
                        color: bm ? color : Colors.white54, size: 22))),
              ]),
              const SizedBox(height: 14),

              // Network + Status badges
              Row(children: [
                // شعار الشركة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: network.color, borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 16, height: 16,
                      decoration: BoxDecoration(
                          color: network.textColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3)),
                      child: Center(child: Text(network.abbr.substring(0, 1),
                          style: TextStyle(color: network.textColor,
                              fontSize: 9, fontWeight: FontWeight.w900)))),
                    const SizedBox(width: 5),
                    Text(network.name, style: TextStyle(color: network.textColor,
                        fontSize: 11, fontWeight: FontWeight.w800)),
                  ])),
                const SizedBox(width: 8),
                Wrap(spacing: 6, children: [
                  _badge(conn, color),
                  _badge(status == 'Coming Soon' ? 'Coming Soon' : (ok ? 'Available' : 'Busy'),
                      status == 'Coming Soon' ? Colors.grey : (ok ? _kGreen : Colors.orange)),
                  _badge('$plugCount Plugs', Colors.blueAccent),
                ]),
              ]),
              const SizedBox(height: 16),

              // Stats
              Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  _stat(Icons.bolt,         power,           'Power'),
                  _div(),
                  _stat(Icons.attach_money, 'NIS $price/kWh','Price'),
                  _div(),
                  _stat(Icons.star,         s['rating']?.toString() ?? '5.0', 'Rating'),
                ])),
              const SizedBox(height: 16),

              // Amenities
              if (amenities.isNotEmpty) ...[
                const Text('Amenities', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6, children: amenities.map((a) =>
                  _iconChip(_amenIcons[a] ?? Icons.check, a, Colors.blueAccent)).toList()),
                const SizedBox(height: 14),
              ],

              // Parking
              if (parking.isNotEmpty) ...[
                const Text('Parking', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 6, children: parking.map((p) =>
                  _iconChip(_parkIcons[p] ?? Icons.local_parking, p, Colors.orange)).toList()),
                const SizedBox(height: 14),
              ],

              // Buttons
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _fetchRoute(s),
                  icon: const Icon(Icons.directions, color: _kGreen, size: 18),
                  label: const Text('Directions', style: TextStyle(color: _kGreen, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: _kGreen),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(
                  onPressed: (ok && status != 'Coming Soon') ? () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => BookingFormScreen(station: s)));
                  } : null,
                  icon: Icon(status == 'Coming Soon' ? Icons.schedule : Icons.calendar_today, size: 18),
                  label: Text(status == 'Coming Soon' ? 'Coming Soon' : (ok ? 'Book Now' : 'Busy'),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white12,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
              ]),
            ]),
        );
      }));
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)));

  Widget _stat(IconData icon, String val, String lbl) => Expanded(child: Column(children: [
    Icon(icon, color: _kGreen, size: 16), const SizedBox(height: 4),
    Text(val, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    Text(lbl, style: const TextStyle(color: Colors.white38, fontSize: 10)),
  ]));

  Widget _div() => Container(width: 1, height: 40, color: _kBorder);

  Widget _iconChip(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 12), const SizedBox(width: 5),
      Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    ]));

  @override
  Widget build(BuildContext context) {
    final filtered  = _filtered;
    final available = filtered.where((s) => s['available'] == true && (s['status'] ?? 'Active') == 'Active').length;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [

        // ── Map ───────────────────────────────────────────
        FlutterMap(
          mapController: _mapCtrl,
          options: const MapOptions(initialCenter: LatLng(32.221, 35.258), initialZoom: 13),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.chargeguard.app'),
            if (_route != null)
              PolylineLayer(polylines: [Polyline(points: _route!.points, color: _kGreen, strokeWidth: 4)]),
            MarkerLayer(markers: [
              ...filtered.map((s) {
                final ok     = s['available'] as bool? ?? true;
                final lat    = (s['location']?['lat'] as num?)?.toDouble() ?? 32.2211;
                final lng    = (s['location']?['lng'] as num?)?.toDouble() ?? 35.2544;
                final conn   = s['connector'] as String? ?? 'CCS2';
                final status = s['status'] as String? ?? 'Active';
                final color  = status == 'Coming Soon' ? Colors.grey : (ok ? _connColor(conn) : Colors.grey);
                final bm     = _bookmarkIds.contains(s['_id'] as String? ?? '');

                return Marker(point: LatLng(lat, lng), width: 52, height: 52,
                  child: GestureDetector(
                    onTap: () { _mapCtrl.move(LatLng(lat, lng), 15); _showDetails(s); },
                    child: Stack(children: [
                      Container(width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.18), shape: BoxShape.circle,
                          border: Border.all(color: color, width: status == 'Coming Soon' ? 2.0 : 2.5,
                              strokeAlign: BorderSide.strokeAlignInside),
                          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)]),
                        child: Icon(status == 'Coming Soon' ? Icons.schedule : Icons.ev_station,
                            color: color, size: 22)),
                      if (bm)
                        Positioned(top: 0, right: 0,
                          child: Container(width: 14, height: 14,
                            decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                            child: const Icon(Icons.bookmark, color: Colors.black, size: 9))),
                      if (status == 'Coming Soon')
                        Positioned(bottom: 0, left: 0,
                          child: Container(width: 14, height: 14,
                            decoration: BoxDecoration(color: Colors.grey[700], shape: BoxShape.circle),
                            child: const Icon(Icons.schedule, color: Colors.white, size: 9))),
                    ])));
              }),
              if (_userLocation != null)
                Marker(point: _userLocation!, width: 44, height: 44,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.15), shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent, width: 2.5),
                        boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 10)]),
                    child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 20))),
            ]),
          ]),

        // ── Top: Search + Filter Button ───────────────────
        SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(child: Container(height: 50,
                decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _searchQuery.isNotEmpty ? _kGreen : _kBorder),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)]),
                child: Row(children: [
                  const SizedBox(width: 16),
                  _loadingStations
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2))
                      : const Icon(Icons.search, color: Colors.white38, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(hintText: 'Search stations...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                        border: InputBorder.none, isDense: true))),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                        child: const Padding(padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.close, color: Colors.white38, size: 18))),
                ]))),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _showFilters = !_showFilters),
                child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: _activeFilters > 0 ? _kGreen : _kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _activeFilters > 0 ? _kGreen : _kBorder),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)]),
                  child: Stack(alignment: Alignment.center, children: [
                    Icon(Icons.tune, color: _activeFilters > 0 ? Colors.black : Colors.white54, size: 22),
                    if (_activeFilters > 0)
                      Positioned(top: 6, right: 6,
                        child: Container(width: 16, height: 16,
                          decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                          child: Center(child: Text('$_activeFilters',
                              style: const TextStyle(color: _kGreen, fontSize: 9, fontWeight: FontWeight.w900))))),
                  ]))),
            ])),
          const SizedBox(height: 8),

          // Filter Panel
          if (_showFilters) _filterPanel()
          else if (_searchQuery.isNotEmpty && _filtered.isNotEmpty)
            _searchDropdown()
          else
            _quickChips(),
        ])),

        // ── Route Banner ──────────────────────────────────
        if (_route != null && _selected != null)
          Positioned(top: 130, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.3), blurRadius: 12)]),
              child: Row(children: [
                const Icon(Icons.directions, color: Colors.black, size: 20), const SizedBox(width: 10),
                Expanded(child: Text(
                  '${_fmtDist(_route!.distanceMeters)} · ${_fmtTime(_route!.durationSeconds)} to ${_selected!['name']}',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13))),
                GestureDetector(onTap: () => setState(() { _route = null; _selected = null; }),
                    child: const Icon(Icons.close, color: Colors.black, size: 18)),
              ]))),

        // ── Legend ────────────────────────────────────────
        Positioned(left: 16, bottom: 80,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _kCard.withOpacity(0.95), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ...[
                ('CCS2', _connColor('CCS2')), ('Type 2', _connColor('Type 2')),
                ('CHAdeMO', _connColor('CHAdeMO')), ('GB/T', _connColor('GB/T')),
                ('NACS', _connColor('NACS')), ('AC', _connColor('AC')),
                ('Coming Soon', Colors.grey),
              ].map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: e.$2, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(e.$1, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600)),
                ]))),
            ]))),

        if (_loadingRoute) Container(color: Colors.black45,
            child: const Center(child: CircularProgressIndicator(color: _kGreen))),

        // ── Bottom Bar ────────────────────────────────────
        Positioned(bottom: 16, left: 16, right: 80,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder)),
            child: Row(children: [
              const Icon(Icons.ev_station, color: _kGreen, size: 18), const SizedBox(width: 8),
              Text('${filtered.length} stations', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('$available available', style: const TextStyle(color: _kGreen, fontSize: 12, fontWeight: FontWeight.w600)),
            ]))),

        Positioned(bottom: 16, right: 16,
          child: GestureDetector(onTap: _getLocation,
            child: Container(width: 52, height: 52,
              decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)]),
              child: const Icon(Icons.my_location, color: _kGreen, size: 22)))),

        // ── Advanced filters FAB ─────────────────────────
        Positioned(bottom: 80, right: 16,
          child: GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MapFiltersScreen())),
            child: Stack(clipBehavior: Clip.none, children: [
              Container(width: 52, height: 52,
                decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.3), blurRadius: 10)]),
                child: const Icon(Icons.tune, color: Colors.black, size: 22)),
              if (StationFilters.instance.activeCount > 0)
                Positioned(top: -4, right: -4, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBg, width: 2),
                  ),
                  child: Text('${StationFilters.instance.activeCount}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                )),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Filter Panel ──────────────────────────────────────────
  Widget _filterPanel() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)]),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title row
          Row(children: [
            const Text('Filters', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            const Spacer(),
            if (_activeFilters > 0)
              GestureDetector(onTap: _resetFilters,
                child: const Text('Reset All', style: TextStyle(color: _kGreen, fontSize: 12, fontWeight: FontWeight.w700))),
            const SizedBox(width: 12),
            GestureDetector(onTap: () => setState(() => _showFilters = false),
                child: const Icon(Icons.close, color: Colors.white38, size: 20)),
          ]),
          const SizedBox(height: 14),

          // Availability
          _sectionTitle('Availability'),
          _hChips(['All', 'Available', 'Busy'], _filterAvail,
              (v) => setState(() => _filterAvail = v)),
          const SizedBox(height: 14),

          // Coming Soon
          _sectionTitle('Coming Soon'),
          _hChips(['Include', 'Only', 'Hide'], _filterComing,
              (v) => setState(() => _filterComing = v)),
          const SizedBox(height: 14),

          // Connector
          _sectionTitle('Connector Type'),
          _connChips(),
          const SizedBox(height: 14),

          // Power
          _sectionTitle('Power Level'),
          _hChips(_powers, _filterPower, (v) => setState(() => _filterPower = v), small: true),
          const SizedBox(height: 14),

          // Vehicles
          _sectionTitle('Compatible Vehicles'),
          Wrap(spacing: 8, runSpacing: 6, children: _vehicleList.map((v) {
            final sel = _filterVehicle.contains(v);
            return GestureDetector(
              onTap: () => setState(() => sel ? _filterVehicle.remove(v) : _filterVehicle.add(v)),
              child: _filterChip(Icons.directions_car, v, sel, Colors.blueAccent));
          }).toList()),
          const SizedBox(height: 14),

          // Amenities
          _sectionTitle('Amenities'),
          Wrap(spacing: 8, runSpacing: 6, children: _amenList.map((a) {
            final sel = _filterAmen.contains(a);
            return GestureDetector(
              onTap: () => setState(() => sel ? _filterAmen.remove(a) : _filterAmen.add(a)),
              child: _filterChip(_amenIcons[a] ?? Icons.check, a, sel, Colors.purpleAccent));
          }).toList()),
          const SizedBox(height: 14),

          // Parking
          _sectionTitle('Parking'),
          Wrap(spacing: 8, runSpacing: 6, children: _parkList.map((p) {
            final sel = _filterParking.contains(p);
            return GestureDetector(
              onTap: () => setState(() => sel ? _filterParking.remove(p) : _filterParking.add(p)),
              child: _filterChip(_parkIcons[p] ?? Icons.local_parking, p, sel, Colors.orange));
          }).toList()),
          const SizedBox(height: 14),

          // Apply Button
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _showFilters = false),
              style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Show ${_filtered.length} Stations',
                  style: const TextStyle(fontWeight: FontWeight.w800)))),
        ]))));

  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700)));

  Widget _hChips(List<String> opts, String sel, ValueChanged<String> onTap, {bool small = false}) =>
    SingleChildScrollView(scrollDirection: Axis.horizontal,
      child: Row(children: opts.map((o) {
        final isSel = sel == o;
        return GestureDetector(onTap: () => onTap(o),
          child: AnimatedContainer(duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 8),
            padding: EdgeInsets.symmetric(horizontal: small ? 10 : 14, vertical: 7),
            decoration: BoxDecoration(color: isSel ? _kGreen : _kBg, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSel ? _kGreen : _kBorder)),
            child: Text(o, style: TextStyle(color: isSel ? Colors.black : Colors.white54,
                fontSize: small ? 10 : 12, fontWeight: FontWeight.w700))));
      }).toList()));

  Widget _connChips() => Wrap(spacing: 8, runSpacing: 6, children: _connectors.map((c) {
    final isSel = _filterConn == c;
    final color = c == 'All' ? _kGreen : _connColor(c);
    return GestureDetector(onTap: () => setState(() => _filterConn = c),
      child: AnimatedContainer(duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: isSel ? color : _kBg, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSel ? color : _kBorder)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (c != 'All')
            Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(color: isSel ? Colors.black.withOpacity(0.3) : color, shape: BoxShape.circle)),
          Text(c, style: TextStyle(color: isSel ? Colors.black : Colors.white54, fontSize: 12, fontWeight: FontWeight.w700)),
        ])));
  }).toList());

  Widget _filterChip(IconData icon, String label, bool sel, Color color) =>
    AnimatedContainer(duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: sel ? color.withOpacity(0.15) : _kBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sel ? color : _kBorder)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: sel ? color : Colors.white38, size: 12),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: sel ? color : Colors.white54, fontSize: 11, fontWeight: FontWeight.w700)),
      ]));

  Widget _searchDropdown() => Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder)),
      child: ListView.builder(shrinkWrap: true, padding: EdgeInsets.zero,
        itemCount: _filtered.length,
        itemBuilder: (_, i) {
          final s  = _filtered[i];
          final ok = s['available'] as bool? ?? true;
          final color = _connColor(s['connector'] as String?);
          return GestureDetector(
            onTap: () {
              _searchCtrl.clear(); setState(() => _searchQuery = '');
              final lat = (s['location']?['lat'] as num?)?.toDouble() ?? 32.2211;
              final lng = (s['location']?['lng'] as num?)?.toDouble() ?? 35.2544;
              _mapCtrl.move(LatLng(lat, lng), 16);
              _showDetails(s);
            },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(border: i < _filtered.length - 1
                  ? Border(bottom: BorderSide(color: _kBorder)) : null),
              child: Row(children: [
                Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.ev_station, color: color, size: 16)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s['name'] as String? ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(s['location']?['address'] as String? ?? '',
                      style: const TextStyle(color: Colors.white38, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: (ok ? _kGreen : Colors.orange).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Text(ok ? 'Available' : 'Busy', style: TextStyle(color: ok ? _kGreen : Colors.orange, fontSize: 10, fontWeight: FontWeight.w700))),
              ])));
        })));

  Widget _quickChips() => SingleChildScrollView(
    scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(children: [
      _qChip('All',          _filterAvail == 'All' && _filterConn == 'All' && _filterComing == 'Include', _kGreen,
          () { _filterAvail = 'All'; _filterConn = 'All'; _filterComing = 'Include'; _filterAmen.clear(); _filterParking.clear(); _filterVehicle.clear(); }),
      _qChip('Available',    _filterAvail == 'Available',    _kGreen,            () { _filterAvail = _filterAvail == 'Available' ? 'All' : 'Available'; }),
      _qChip('Coming Soon',  _filterComing == 'Only',        Colors.grey,        () { _filterComing = _filterComing == 'Only' ? 'Include' : 'Only'; }),
      _qChip('CCS2',         _filterConn == 'CCS2',          _connColor('CCS2'), () { _filterConn = _filterConn == 'CCS2' ? 'All' : 'CCS2'; }),
      _qChip('Type 2',       _filterConn == 'Type 2',        _connColor('Type 2'), () { _filterConn = _filterConn == 'Type 2' ? 'All' : 'Type 2'; }),
      _qChip('CHAdeMO',      _filterConn == 'CHAdeMO',       _connColor('CHAdeMO'), () { _filterConn = _filterConn == 'CHAdeMO' ? 'All' : 'CHAdeMO'; }),
      _qChip('GB/T',         _filterConn == 'GB/T',          _connColor('GB/T'), () { _filterConn = _filterConn == 'GB/T' ? 'All' : 'GB/T'; }),
      _qChip('NACS',         _filterConn == 'NACS',          _connColor('NACS'), () { _filterConn = _filterConn == 'NACS' ? 'All' : 'NACS'; }),
    ]));

  Widget _qChip(String label, bool sel, Color color, VoidCallback onTap) =>
    GestureDetector(onTap: () => setState(onTap),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: sel ? color : _kCard, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? color : _kBorder)),
        child: Text(label, style: TextStyle(color: sel ? Colors.black : Colors.white54,
            fontSize: 12, fontWeight: FontWeight.w700))));
}
