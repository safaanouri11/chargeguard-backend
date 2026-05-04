import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import 'charger_detail_screen.dart';

// Predefined Palestinian cities — quick origin/destination selection.
class _City {
  final String name;
  final double lat;
  final double lng;
  const _City(this.name, this.lat, this.lng);
}

const List<_City> _kCities = [
  _City('Nablus',     32.221, 35.258),
  _City('Ramallah',   31.901, 35.204),
  _City('Jerusalem',  31.781, 35.215),
  _City('Hebron',     31.532, 35.099),
  _City('Bethlehem',  31.705, 35.207),
  _City('Jenin',      32.461, 35.296),
  _City('Tulkarm',    32.314, 35.028),
  _City('Jericho',    31.857, 35.461),
];

const List<String> _kConnectors = ['CCS2', 'CCS1', 'Type 2', 'CHAdeMO', 'GB/T'];

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});
  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  _City?  _from;
  _City?  _to;
  Map<String, double>? _currentLocation;
  bool _useCurrentLocation = false;

  double _vehicleRange = 300;
  int    _battery      = 65;
  String _connector    = 'CCS2';

  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _battery   = UserSession.instance.batteryPct;
    _connector = UserSession.instance.connector.isNotEmpty
        ? UserSession.instance.connector : 'CCS2';
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _useCurrentLocation = false);
    final pos = await ApiService.instance.getCurrentPosition();
    if (!mounted) return;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not get your location. Please allow access.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    setState(() {
      _currentLocation = pos;
      _useCurrentLocation = true;
      _from = null;
    });
  }

  Future<void> _planTrip() async {
    final startLat = _useCurrentLocation ? _currentLocation?['lat'] : _from?.lat;
    final startLng = _useCurrentLocation ? _currentLocation?['lng'] : _from?.lng;
    if (startLat == null || startLng == null) {
      setState(() => _error = 'Pick a starting point');
      return;
    }
    if (_to == null) {
      setState(() => _error = 'Pick a destination');
      return;
    }
    if (_useCurrentLocation == false && _from?.name == _to?.name) {
      setState(() => _error = 'Origin and destination cannot be the same');
      return;
    }
    setState(() { _loading = true; _error = null; _result = null; });
    final res = await ApiService.instance.planRoute(
      startLat: startLat, startLng: startLng,
      endLat:   _to!.lat,  endLng:   _to!.lng,
      vehicleRangeKm: _vehicleRange,
      currentBatteryPct: _battery,
      connector: _connector,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success']) {
        _result = res['data'] as Map<String, dynamic>;
      } else {
        _error = res['message'] as String? ?? 'Failed to plan trip';
      }
    });
  }

  void _resetForm() => setState(() { _result = null; _error = null; });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('AI Trip Planner', context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _result == null ? _buildForm() : _buildResults(),
        ),
      ),
    );
  }

  // ─────────── FORM ───────────
  Widget _buildForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _hero(),
      const SizedBox(height: 20),
      _sectionTitle('From', Icons.my_location),
      const SizedBox(height: 8),
      _currentLocationButton(),
      const SizedBox(height: 8),
      _cityChips(
        selected: _useCurrentLocation ? null : _from,
        onTap: (c) => setState(() {
          _from = c; _useCurrentLocation = false;
        }),
      ),
      const SizedBox(height: 22),
      _sectionTitle('To', Icons.flag),
      const SizedBox(height: 8),
      _cityChips(selected: _to, onTap: (c) => setState(() => _to = c)),
      const SizedBox(height: 22),
      _vehicleCard(),
      if (_error != null) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
          ]),
        ),
      ],
      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton.icon(
          onPressed: _loading ? null : _planTrip,
          icon: _loading
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Icon(Icons.bolt, color: Colors.black),
          label: Text(_loading ? 'Planning...' : 'Plan My Trip',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      const SizedBox(height: 16),
    ]);
  }

  Widget _hero() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kGreen.withOpacity(0.18), kGreen.withOpacity(0.04)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kGreen.withOpacity(0.35)),
        ),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.route, color: kGreen, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Smart Trip Planning', style: kTitle(16)),
              const SizedBox(height: 4),
              Text('Find optimal charging stops along your route',
                  style: kSub(12)),
            ]),
          ),
        ]),
      );

  Widget _sectionTitle(String text, IconData icon) =>
      Row(children: [
        Icon(icon, color: kGreen, size: 18),
        const SizedBox(width: 8),
        Text(text, style: kTitle(15)),
      ]);

  Widget _currentLocationButton() {
    final selected = _useCurrentLocation;
    return GestureDetector(
      onTap: _detectCurrentLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? kGreen.withOpacity(0.15) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kGreen : cSub2.withOpacity(0.4),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(Icons.gps_fixed, color: selected ? kGreen : cSub2, size: 18),
          const SizedBox(width: 10),
          Text('Use my current location',
              style: TextStyle(
                color: selected ? kGreen : null,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
          if (selected) ...[
            const Spacer(),
            const Icon(Icons.check_circle, color: kGreen, size: 18),
          ],
        ]),
      ),
    );
  }

  Widget _cityChips({_City? selected, required void Function(_City) onTap}) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _kCities.map((c) {
        final isSel = selected?.name == c.name;
        return GestureDetector(
          onTap: () => onTap(c),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSel ? kGreen.withOpacity(0.15) : null,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSel ? kGreen : cSub2.withOpacity(0.3),
                width: isSel ? 1.5 : 1,
              ),
            ),
            child: Text(c.name, style: TextStyle(
              fontSize: 12,
              color: isSel ? kGreen : null,
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
            )),
          ),
        );
      }).toList(),
    );
  }

  Widget _vehicleCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: kCardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('Vehicle', Icons.directions_car_filled_outlined),
          const SizedBox(height: 14),
          // Connector
          Text('Connector', style: kSub(12)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: _kConnectors.map((c) {
            final isSel = _connector == c;
            return GestureDetector(
              onTap: () => setState(() => _connector = c),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSel ? kGreen.withOpacity(0.15) : null,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSel ? kGreen : cSub2.withOpacity(0.3),
                  ),
                ),
                child: Text(c, style: TextStyle(
                  fontSize: 11,
                  color: isSel ? kGreen : null,
                  fontWeight: FontWeight.w600,
                )),
              ),
            );
          }).toList()),
          const SizedBox(height: 18),
          // Range
          Row(children: [
            Text('Vehicle Range', style: kSub(12)),
            const Spacer(),
            Text('${_vehicleRange.round()} km',
                style: kTitle(13).copyWith(color: kGreen)),
          ]),
          Slider(
            value: _vehicleRange, min: 100, max: 600, divisions: 25,
            activeColor: kGreen,
            onChanged: (v) => setState(() => _vehicleRange = v),
          ),
          // Battery
          Row(children: [
            Text('Current Battery', style: kSub(12)),
            const Spacer(),
            Text('$_battery%', style: kTitle(13).copyWith(color: kGreen)),
          ]),
          Slider(
            value: _battery.toDouble(), min: 5, max: 100, divisions: 19,
            activeColor: kGreen,
            onChanged: (v) => setState(() => _battery = v.round()),
          ),
        ]),
      );

  // ─────────── RESULTS ───────────
  Widget _buildResults() {
    final r = _result!;
    final stops    = (r['stops'] as List?) ?? [];
    final feasible = r['feasible'] as bool? ?? true;
    final summary  = r['summary'] as String? ?? '';
    final dist     = (r['totalDistanceKm'] as num?)?.toDouble() ?? 0;
    final totalMin = (r['totalMinutes'] as num?)?.toInt() ?? 0;
    final cost     = (r['totalCost'] as num?)?.toDouble() ?? 0;
    final kwh      = (r['totalKwh'] as num?)?.toDouble() ?? 0;
    final driveMin = (r['drivingMinutes'] as num?)?.toInt() ?? 0;
    final chargeMin = (r['chargingMinutes'] as num?)?.toInt() ?? 0;
    final endPct   = (r['finalArrivalPct'] as num?)?.toInt() ?? 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // AI summary card
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kGreen.withOpacity(0.2), Colors.blueAccent.withOpacity(0.08)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kGreen.withOpacity(0.4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: kGreen, size: 18),
            ),
            const SizedBox(width: 10),
            Text('AI Trip Summary', style: kTitle(14)),
          ]),
          const SizedBox(height: 12),
          Text(summary, style: kSub(13).copyWith(height: 1.5)),
        ]),
      ),
      const SizedBox(height: 16),
      // Stats grid
      Row(children: [
        _statCard(Icons.straighten,  '${dist.toStringAsFixed(1)} km',  'Distance'),
        const SizedBox(width: 10),
        _statCard(Icons.access_time, _fmtMinutes(totalMin),            'Total Time'),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _statCard(Icons.bolt,        '${kwh.toStringAsFixed(1)} kWh',  'Energy'),
        const SizedBox(width: 10),
        _statCard(Icons.attach_money,'${cost.toStringAsFixed(2)} NIS', 'Total Cost'),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _statCard(Icons.directions_car, _fmtMinutes(driveMin), 'Driving'),
        const SizedBox(width: 10),
        _statCard(Icons.battery_charging_full, _fmtMinutes(chargeMin), 'Charging'),
      ]),
      const SizedBox(height: 22),
      if (!feasible)
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.4)),
          ),
          child: Row(children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(child: Text(
              'Route may not be feasible — not enough stations along the path. '
              'Consider charging more before departure.',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            )),
          ]),
        ),
      Text('Route Timeline', style: kTitle(15)),
      const SizedBox(height: 12),
      _timeline(stops, endPct),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: _resetForm,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Trip'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 50),
            foregroundColor: kGreen,
            side: const BorderSide(color: kGreen),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        )),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton.icon(
          onPressed: _planTrip,
          icon: const Icon(Icons.refresh, color: Colors.black),
          label: const Text('Replan',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 50),
            backgroundColor: kGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        )),
      ]),
      const SizedBox(height: 16),
    ]);
  }

  Widget _statCard(IconData icon, String value, String label) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(14),
        decoration: kCardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: kGreen, size: 18),
          const SizedBox(height: 8),
          Text(value, style: kTitle(15)),
          const SizedBox(height: 2),
          Text(label, style: kSub(11)),
        ]),
      ));

  Widget _timeline(List stops, int endPct) {
    final fromName = _useCurrentLocation
        ? 'My Location'
        : (_from?.name ?? 'Origin');
    final toName = _to?.name ?? 'Destination';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: kCardDeco(),
      child: Column(children: [
        _node(true, fromName, 'Starting at $_battery%', isStart: true),
        for (int i = 0; i < stops.length; i++) ...[
          _connector_(stops[i]['legKm'] as num, ' drive'),
          _stopNode(stops[i] as Map<String, dynamic>, i + 1),
        ],
        _connector_(_finalLegKm(stops), ' drive to destination'),
        _node(false, toName, 'Arriving at $endPct%', isStart: false),
      ]),
    );
  }

  num _finalLegKm(List stops) {
    final r = _result!;
    return (r['finalLegKm'] as num?) ?? 0;
  }

  Widget _node(bool isOrigin, String name, String detail, {required bool isStart}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: kGreen.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: kGreen, width: 2),
        ),
        child: Icon(isStart ? Icons.trip_origin : Icons.flag,
            color: kGreen, size: 14),
      ),
      const SizedBox(width: 12),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: kTitle(13)),
          Text(detail, style: kSub(11)),
        ]),
      )),
    ]);
  }

  Widget _connector_(num km, String suffix) =>
      Padding(padding: const EdgeInsets.only(left: 13),
        child: Row(children: [
          Container(width: 2, height: 24, color: kGreen.withOpacity(0.4)),
          const SizedBox(width: 21),
          Text('${km.toStringAsFixed(1)} km$suffix', style: kSub(11)),
        ]),
      );

  Widget _stopNode(Map<String, dynamic> stop, int index) {
    final name      = stop['name']      as String? ?? 'Station';
    final addr      = stop['address']   as String? ?? '';
    final power     = stop['power']     as String? ?? '';
    final price     = stop['price']?.toString() ?? '';
    final arrivePct = (stop['arrivalBatteryPct'] as num?)?.toInt() ?? 0;
    final toPct     = (stop['chargeToPct']       as num?)?.toInt() ?? 80;
    final minutes   = (stop['estimatedChargeMinutes'] as num?)?.toInt() ?? 0;
    final cost      = (stop['estimatedCost'] as num?)?.toDouble() ?? 0;
    final kwh       = (stop['kwhCharged']    as num?)?.toDouble() ?? 0;
    final stationLike = {
      ...stop,
      'location': {
        'address': stop['address'],
        'lat':     stop['lat'],
        'lng':     stop['lng'],
      },
    };
    return GestureDetector(
      onTap: () => goTo(context, ChargerDetailScreen(stationLike)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: kGreen, shape: BoxShape.circle,
          ),
          child: Center(child: Text('$index',
              style: const TextStyle(color: Colors.black,
                  fontSize: 11, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kGreen.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kGreen.withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.ev_station, color: kGreen, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(name, style: kTitle(13))),
            ]),
            if (addr.isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(addr, style: kSub(11)),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 12, runSpacing: 4, children: [
              _miniStat(Icons.battery_alert, 'Arrive $arrivePct%'),
              _miniStat(Icons.bolt, 'Charge to $toPct%'),
              _miniStat(Icons.access_time, '$minutes min'),
              _miniStat(Icons.electric_bolt_outlined, '${kwh.toStringAsFixed(1)} kWh'),
              _miniStat(Icons.attach_money, '${cost.toStringAsFixed(2)} NIS'),
              if (power.isNotEmpty) _miniStat(Icons.flash_on, power),
              if (price.isNotEmpty) _miniStat(Icons.tag, '$price/kWh'),
            ]),
          ]),
        )),
      ]),
    );
  }

  Widget _miniStat(IconData icon, String text) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: cSub2),
        const SizedBox(width: 3),
        Text(text, style: kSub(11)),
      ]);

  String _fmtMinutes(int m) {
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}h' : '${h}h ${r}m';
  }
}
