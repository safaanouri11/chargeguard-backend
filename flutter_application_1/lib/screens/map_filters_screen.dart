import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import '../utils/station_filters.dart';

// Static option lists. We render every option even if no station has it yet —
// the backend `/api/stations/filters` is used to merge in any extra values
// the DB knows about, but never to *remove* the canonical set.
const _kConnectors = [
  'CCS2', 'CCS1', 'CHAdeMO', 'Type 2', 'NACS', 'GB/T', 'AC', 'J-1772',
];
const _kAmenities = [
  'Dining', 'Restroom', 'Shopping', 'Lodging', 'Park', 'Grocery',
  'WiFi', 'Valet', 'Hiking', 'Camping', 'Free Charge',
];
const _kParking = [
  'Accessible', 'Covered', 'Garage', 'Illuminated',
  'Pull In', 'Pull Through', 'Trailer Friendly',
];

class MapFiltersScreen extends StatefulWidget {
  const MapFiltersScreen({super.key});
  @override
  State<MapFiltersScreen> createState() => _MapFiltersScreenState();
}

class _MapFiltersScreenState extends State<MapFiltersScreen> {
  final _f = StationFilters.instance;
  int _resultCount = 0;
  bool _counting = false;
  List<String> _backendConnectors = [];
  List<String> _backendAmenities  = [];
  List<String> _backendParking    = [];
  List<String> _backendNetworks   = [];

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _refreshCount();
  }

  Future<void> _loadFilterOptions() async {
    final res = await ApiService.instance.getStationFilters();
    if (!mounted || !res['success']) return;
    final d = res['data'] as Map<String, dynamic>;
    setState(() {
      _backendConnectors = (d['connectors'] as List?)?.cast<String>() ?? const [];
      _backendAmenities  = (d['amenities']  as List?)?.cast<String>() ?? const [];
      _backendParking    = (d['parking']    as List?)?.cast<String>() ?? const [];
      _backendNetworks   = (d['networks']   as List?)?.cast<String>() ?? const [];
    });
  }

  Future<void> _refreshCount() async {
    setState(() => _counting = true);
    final res = await ApiService.instance.getStations(filters: _f.toQuery());
    if (!mounted) return;
    setState(() {
      _counting = false;
      _resultCount = res['success'] ? (res['data'] as List).length : 0;
    });
  }

  void _change(VoidCallback fn) {
    setState(fn);
    _refreshCount();
  }

  List<String> _merge(List<String> canonical, List<String> backend) {
    final s = {...canonical, ...backend};
    return s.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: kGreen, foregroundColor: Colors.black,
        elevation: 0,
        title: Text('Map Filters', style: kTitle(17).copyWith(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () { _f.reset(); _refreshCount(); setState(() {}); },
            child: const Text('Reset',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _section('Kilowatt Range'),
        const SizedBox(height: 6),
        Center(child: Text(
          (_f.minPower == null && _f.maxPower == null)
              ? 'Any power'
              : '${_f.minPower?.toStringAsFixed(0) ?? '0'} kW – '
                '${_f.maxPower != null ? "${_f.maxPower!.toStringAsFixed(0)} kW" : "350+ kW"}',
          style: kTitle(14).copyWith(color: kGreen),
        )),
        RangeSlider(
          values: RangeValues(_f.minPower ?? 0, _f.maxPower ?? 350),
          min: 0, max: 350, divisions: 35,
          activeColor: kGreen, inactiveColor: kGreen.withOpacity(0.2),
          labels: RangeLabels(
            '${(_f.minPower ?? 0).toStringAsFixed(0)} kW',
            (_f.maxPower ?? 350) >= 350 ? '350+ kW' : '${_f.maxPower!.toStringAsFixed(0)} kW',
          ),
          onChanged: (v) => _change(() {
            _f.minPower = v.start <= 0 ? null : v.start;
            _f.maxPower = v.end >= 350 ? null : v.end;
          }),
        ),
        const SizedBox(height: 8),

        _section('Connectors'),
        const SizedBox(height: 8),
        _chipGroup(_merge(_kConnectors, _backendConnectors), _f.connectors),
        const SizedBox(height: 22),

        _section('Station Count'),
        const SizedBox(height: 8),
        Row(children: [
          _segment('Any', _f.minPlugCount == 0, () => _change(() => _f.minPlugCount = 0)),
          const SizedBox(width: 6),
          _segment('2+',  _f.minPlugCount == 2, () => _change(() => _f.minPlugCount = 2)),
          const SizedBox(width: 6),
          _segment('4+',  _f.minPlugCount == 4, () => _change(() => _f.minPlugCount = 4)),
          const SizedBox(width: 6),
          _segment('6+',  _f.minPlugCount == 6, () => _change(() => _f.minPlugCount = 6)),
        ]),
        const SizedBox(height: 22),

        _section('Min Rating'),
        const SizedBox(height: 6),
        Center(child: Text(
          _f.minRating == 0 ? 'Any rating'
              : '${_f.minRating.toStringAsFixed(1)}+ ★',
          style: kTitle(14).copyWith(color: kGreen),
        )),
        Slider(
          value: _f.minRating, min: 0, max: 5, divisions: 10,
          activeColor: kGreen,
          onChanged: (v) => _change(() => _f.minRating = v),
        ),

        _section('Amenities'),
        const SizedBox(height: 8),
        _chipGroup(_merge(_kAmenities, _backendAmenities), _f.amenities),
        const SizedBox(height: 22),

        _section('Parking'),
        const SizedBox(height: 8),
        _chipGroup(_merge(_kParking, _backendParking), _f.parking),
        const SizedBox(height: 22),

        if (_backendNetworks.isNotEmpty) ...[
          _section('Networks'),
          const SizedBox(height: 8),
          _chipGroup(_backendNetworks, _f.networks),
          const SizedBox(height: 22),
        ],

        _section('Additional Filters'),
        const SizedBox(height: 8),
        _toggleChip('Available Now', _f.onlyAvailable,
            () => _change(() => _f.onlyAvailable = !_f.onlyAvailable)),
        const SizedBox(height: 22),

        _section('Coming Soon'),
        const SizedBox(height: 8),
        Column(children: [
          _radio('Include Coming Soon', _f.comingSoon == 'include',
              () => _change(() => _f.comingSoon = 'include')),
          _radio('Show Only Coming Soon', _f.comingSoon == 'only',
              () => _change(() => _f.comingSoon = 'only')),
          _radio('Hide Coming Soon', _f.comingSoon == 'hide',
              () => _change(() => _f.comingSoon = 'hide')),
        ]),
        const SizedBox(height: 80),
      ]),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: cBg,
          border: Border(top: BorderSide(color: cSub2.withOpacity(0.2))),
        ),
        child: Row(children: [
          Text(
            _counting ? '...' : '$_resultCount Locations',
            style: kTitle(14),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () { _f.apply(); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen, foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: const Text('View',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ]),
      ),
    );
  }

  Widget _section(String t) =>
      Text(t, style: kTitle(15).copyWith(fontWeight: FontWeight.w800));

  Widget _chipGroup(List<String> options, Set<String> selected) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: options.map((o) {
        final isSel = selected.contains(o);
        return GestureDetector(
          onTap: () => _change(() {
            if (isSel) { selected.remove(o); } else { selected.add(o); }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSel ? kGreen.withOpacity(0.15) : null,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSel ? kGreen : cSub2.withOpacity(0.3),
                width: isSel ? 1.5 : 1,
              ),
            ),
            child: Text(o, style: TextStyle(
              fontSize: 12,
              color: isSel ? kGreen : null,
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
            )),
          ),
        );
      }).toList(),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) =>
      Expanded(child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? kGreen.withOpacity(0.15) : null,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? kGreen : cSub2.withOpacity(0.3)),
          ),
          child: Center(child: Text(label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? kGreen : null,
                fontWeight: FontWeight.w700,
              ))),
        ),
      ));

  Widget _toggleChip(String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? kGreen.withOpacity(0.15) : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? kGreen : cSub2.withOpacity(0.3),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? kGreen : cSub2, size: 18),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(
                fontSize: 13,
                color: selected ? kGreen : null,
                fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  Widget _radio(String label, bool selected, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? kGreen : cSub2, size: 20),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(
                fontSize: 14,
                color: selected ? kGreen : null,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ]),
        ),
      );
}
