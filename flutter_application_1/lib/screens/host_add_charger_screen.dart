import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/api_service.dart';
class HostAddChargerScreen extends StatefulWidget {
  const HostAddChargerScreen({super.key});
  @override
  State<HostAddChargerScreen> createState() => _HostAddChargerScreenState();
}

class _HostAddChargerScreenState extends State<HostAddChargerScreen> {
  final _nameCtrl  = TextEditingController();
  final _addrCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController(text: '2.5');

  String _power    = '22 kW';
  String _conn     = 'CCS2';
  String _status   = 'Active';
  int    _plugCount = 1;
  bool   _saving   = false;
  bool   _loadingAddr = false;

  Set<String> _amenities = {};
  Set<String> _parking   = {};
  Set<String> _vehicles  = {};

  LatLng _selected = const LatLng(32.221, 35.258);
  final MapController _mapCtrl = MapController();
  double _zoom = 13;

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
    _fetchAddress(_selected);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _addrCtrl.dispose(); _priceCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAddress(LatLng point) async {
    setState(() => _loadingAddr = true);
    try {
      final res = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json'
          '&lat=${point.latitude}&lon=${point.longitude}&zoom=18&accept-language=en'),
        headers: {'User-Agent': 'ChargeGuard/1.0'});
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() { _addrCtrl.text = data['display_name'] as String? ?? ''; });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingAddr = false);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) { _snack('Please enter station name', isError: true); return; }
    if (_addrCtrl.text.trim().isEmpty) { _snack('Please enter address', isError: true); return; }

    setState(() => _saving = true);
    final res = await ApiService.instance.addHostStation({
      'name':      _nameCtrl.text.trim(),
      'location':  { 'address': _addrCtrl.text.trim(), 'lat': _selected.latitude, 'lng': _selected.longitude },
      'power':     _power,
      'connector': _conn,
      'price':     double.tryParse(_priceCtrl.text) ?? 2.5,
      'status':    _status,
      'plugCount': _plugCount,
      'amenities': _amenities.toList(),
      'parking':   _parking.toList(),
      'vehicles':  _vehicles.toList(),
    });
    if (mounted) {
      setState(() => _saving = false);
      if (res['success']) { _snack('Charger added! ✅'); Navigator.pop(context, true); }
      else _snack(res['message'] ?? 'Error', isError: true);
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
      appBar: kAppBar('Add New Charger', context),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Map ──────────────────────────────────────────
        Row(children: [
          Text('📍 Location', style: kTitle(16)), const Spacer(),
          if (_loadingAddr) const SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(color: kGreen, strokeWidth: 2)),
        ]),
        const SizedBox(height: 4),
        Text('Tap the map to pin your charger location', style: kSub(12)),
        const SizedBox(height: 12),

        Container(height: 280,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: cBorder)),
          child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Stack(children: [
            FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: _selected, initialZoom: _zoom,
                minZoom: 3, maxZoom: 19,
                onTap: (_, ll) { setState(() => _selected = ll); _fetchAddress(ll); },
                onPositionChanged: (pos, hasGesture) { if (hasGesture) setState(() => _zoom = pos.zoom); }),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.chargeguard.app'),
                MarkerLayer(markers: [Marker(point: _selected, width: 50, height: 50,
                  child: Container(
                    decoration: BoxDecoration(color: kGreen, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: kGreen.withOpacity(0.5), blurRadius: 14)],
                        border: Border.all(color: Colors.white, width: 3)),
                    child: const Icon(Icons.ev_station, color: Colors.black, size: 24)))]),
              ]),
            // Zoom buttons
            Positioned(right: 12, top: 12, child: Column(children: [
              _mapBtn(Icons.add, () { _zoom = (_zoom + 1).clamp(3.0, 19.0); _mapCtrl.move(_mapCtrl.camera.center, _zoom); setState(() {}); }),
              const SizedBox(height: 6),
              _mapBtn(Icons.remove, () { _zoom = (_zoom - 1).clamp(3.0, 19.0); _mapCtrl.move(_mapCtrl.camera.center, _zoom); setState(() {}); }),
              const SizedBox(height: 6),
              _mapBtn(Icons.my_location, () { _mapCtrl.move(_selected, 15); setState(() => _zoom = 15); }),
            ])),
            // Coords
            Positioned(left: 12, bottom: 12,
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(8)),
                child: Text('${_selected.latitude.toStringAsFixed(4)}, ${_selected.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)))),
          ]))),
        const SizedBox(height: 24),

        // ── Charger Info ──────────────────────────────────
        Text('⚡ Charger Details', style: kTitle(16)),
        const SizedBox(height: 8),
        // Company notice
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: kGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kGreen.withOpacity(0.3))),
          child: Row(children: [
            const Icon(Icons.business, color: kGreen, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'This charger will be listed under: ${UserSession.instance.user?['businessName'] ?? 'Your Business'}',
              style: TextStyle(color: cTitle, fontSize: 12, fontWeight: FontWeight.w600))),
          ])),
        const SizedBox(height: 12),
        _field(_nameCtrl, 'Station Name', Icons.ev_station),
        const SizedBox(height: 12),

        // Address with spinner
        Stack(children: [
          _field(_addrCtrl, 'Address (auto-filled from map)', Icons.location_on_outlined, maxLines: 2),
          if (_loadingAddr)
            Positioned(right: 14, top: 14, child: SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(color: kGreen, strokeWidth: 2))),
        ]),
        const SizedBox(height: 12),

        Row(children: [
          Expanded(child: _dropdown('Power', _power, ['7 kW', '22 kW', '50 kW', 'AC'], (v) => setState(() => _power = v!))),
          const SizedBox(width: 12),
          Expanded(child: _dropdown('Connector', _conn, ['CCS2', 'Type 2', 'CHAdeMO', 'GB/T', 'NACS', 'AC'], (v) => setState(() => _conn = v!))),
        ]),
        const SizedBox(height: 12),

        _field(_priceCtrl, 'Price NIS/kWh', Icons.attach_money, type: TextInputType.number),
        const SizedBox(height: 12),

        // Status + Plug Count
        Row(children: [
          Expanded(child: _dropdown('Status', _status, ['Active', 'Coming Soon'], (v) => setState(() => _status = v!))),
          const SizedBox(width: 12),
          Expanded(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cBorder)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Plugs', style: kSub(11)),
                Text('$_plugCount', style: kTitle(16)),
              ])),
              Column(children: [
                _smallBtn(Icons.add, () => setState(() { if (_plugCount < 20) _plugCount++; })),
                _smallBtn(Icons.remove, () => setState(() { if (_plugCount > 1) _plugCount--; })),
              ]),
            ]))),
        ]),

        // Coming Soon notice
        if (_status == 'Coming Soon') ...[
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.schedule, color: Colors.grey, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text('This station will be visible to users as Coming Soon',
                  style: kSub(11))),
            ])),
        ],
        const SizedBox(height: 24),

        // ── Compatible Vehicles ───────────────────────────
        Text('🚗 Compatible Vehicles', style: kTitle(16)),
        const SizedBox(height: 4),
        Text('What vehicle types can use this charger?', style: kSub(12)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _vehicleList.map((v) {
          final sel = _vehicles.contains(v);
          return GestureDetector(
            onTap: () => setState(() => sel ? _vehicles.remove(v) : _vehicles.add(v)),
            child: _chip(Icons.directions_car, v, sel, Colors.blueAccent));
        }).toList()),
        const SizedBox(height: 24),

        // ── Amenities ─────────────────────────────────────
        Text('🏪 Amenities', style: kTitle(16)),
        const SizedBox(height: 4),
        Text('What services are available nearby?', style: kSub(12)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _amenList.map((a) {
          final sel = _amenities.contains(a);
          return GestureDetector(
            onTap: () => setState(() => sel ? _amenities.remove(a) : _amenities.add(a)),
            child: _chip(_amenIcons[a] ?? Icons.check, a, sel, Colors.purpleAccent));
        }).toList()),
        const SizedBox(height: 24),

        // ── Parking ───────────────────────────────────────
        Text('🅿️ Parking', style: kTitle(16)),
        const SizedBox(height: 4),
        Text('What type of parking is available?', style: kSub(12)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _parkList.map((p) {
          final sel = _parking.contains(p);
          return GestureDetector(
            onTap: () => setState(() => sel ? _parking.remove(p) : _parking.add(p)),
            child: _chip(_parkIcons[p] ?? Icons.local_parking, p, sel, Colors.orange));
        }).toList()),
        const SizedBox(height: 28),

        // ── Submit ────────────────────────────────────────
        SizedBox(width: double.infinity, height: 54,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Icon(Icons.add_location_alt),
            label: Text(_saving ? 'Adding...' : 'Add Charger',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                disabledBackgroundColor: kGreen.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
      ])),
    );
  }

  Widget _chip(IconData icon, String label, bool sel, Color color) =>
    AnimatedContainer(duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: sel ? color.withOpacity(0.15) : cCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sel ? color : cBorder)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: sel ? color : cSub2, size: 14),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: sel ? color : cSub, fontSize: 12, fontWeight: FontWeight.w700)),
      ]));

  Widget _mapBtn(IconData icon, VoidCallback onTap) => GestureDetector(onTap: onTap,
    child: Container(width: 36, height: 36,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)]),
      child: Icon(icon, color: Colors.black87, size: 18)));

  Widget _smallBtn(IconData icon, VoidCallback onTap) => GestureDetector(onTap: onTap,
    child: Container(width: 26, height: 26, margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(6)),
      child: Icon(icon, color: kGreen, size: 16)));

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? type, int maxLines = 1}) =>
    TextField(controller: ctrl, keyboardType: type, maxLines: maxLines,
      style: TextStyle(color: cTitle, fontSize: 14),
      decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: cSub),
        prefixIcon: maxLines == 1 ? Icon(icon, color: cSub2, size: 20) : null,
        filled: true, fillColor: cCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGreen, width: 1.5))));

  Widget _dropdown(String label, String value, List<String> opts, ValueChanged<String?> onChanged) =>
    DropdownButtonFormField<String>(value: value, dropdownColor: cCard,
      style: TextStyle(color: cTitle, fontSize: 14),
      decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: cSub),
        filled: true, fillColor: cCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGreen, width: 1.5))),
      items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged);
}
