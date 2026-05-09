import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class EcoStatsScreen extends StatefulWidget {
  const EcoStatsScreen({super.key});

  @override
  State<EcoStatsScreen> createState() => _EcoStatsScreenState();
}

class _EcoStatsScreenState extends State<EcoStatsScreen> {
  bool _loading = true;
  double _co2KgSaved = 0;
  double _treesEquivalent = 0;
  double _kmDriven = 0;
  double _totalKwh = 0;
  double _litersGasSaved = 0;
  int _sessions = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final res = await ApiService.instance.getCO2();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success']) {
        final d = res['data'] as Map<String, dynamic>;
        _co2KgSaved      = (d['co2KgSaved']      as num?)?.toDouble() ?? 0;
        _treesEquivalent = (d['treesEquivalent'] as num?)?.toDouble() ?? 0;
        _kmDriven        = (d['kmDriven']        as num?)?.toDouble() ?? 0;
        _totalKwh        = (d['totalKwh']        as num?)?.toDouble() ?? 0;
        _litersGasSaved  = (d['litersGasSaved']  as num?)?.toDouble() ?? 0;
        _sessions        = (d['sessions']        as num?)?.toInt()    ?? 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Eco Impact', context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : RefreshIndicator(
              color: kGreen, onRefresh: _loadStats,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                _heroCard(),
                const SizedBox(height: 16),
                _statsGrid(),
                const SizedBox(height: 16),
                _impactCard(),
                const SizedBox(height: 20),
              ]),
            ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kGreen.withOpacity(0.25), Colors.green.withOpacity(0.05)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kGreen.withOpacity(0.4)),
        ),
        child: Column(children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: kGreen.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.eco, color: kGreen, size: 38),
          ),
          const SizedBox(height: 14),
          Text(
            '${_co2KgSaved.toStringAsFixed(1)} kg',
            style: kTitle(36).copyWith(color: kGreen, fontWeight: FontWeight.w900),
          ),
          Text('CO₂ Saved', style: kSub(13)),
          const SizedBox(height: 8),
          Text(
            "By choosing electric, you've avoided ${_co2KgSaved.toStringAsFixed(1)} kg "
            "of CO₂ emissions — that's like planting "
            "${_treesEquivalent.toStringAsFixed(1)} trees! 🌳",
            style: kSub(13), textAlign: TextAlign.center,
          ),
        ]),
      );

  Widget _statsGrid() => Column(children: [
        Row(children: [
          _statCard(Icons.directions_car, '${_kmDriven.toStringAsFixed(0)} km', 'EV Distance'),
          const SizedBox(width: 10),
          _statCard(Icons.bolt, '${_totalKwh.toStringAsFixed(1)} kWh', 'Energy Used'),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _statCard(Icons.local_gas_station, '${_litersGasSaved.toStringAsFixed(1)} L', 'Gas Saved'),
          const SizedBox(width: 10),
          _statCard(Icons.local_florist, _treesEquivalent.toStringAsFixed(1), 'Tree Equivalent'),
        ]),
      ]);

  Widget _statCard(IconData icon, String value, String label) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(14),
        decoration: kCardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: kGreen, size: 20),
          const SizedBox(height: 8),
          Text(value, style: kTitle(18)),
          const SizedBox(height: 2),
          Text(label, style: kSub(11)),
        ]),
      ));

  Widget _impactCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: kCardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.celebration, color: kGreen, size: 20),
            const SizedBox(width: 8),
            Text('Your Impact', style: kTitle(14)),
          ]),
          const SizedBox(height: 12),
          _bullet('$_sessions completed charging sessions'),
          _bullet('${_kmDriven.toStringAsFixed(0)} km driven cleanly'),
          _bullet('${_litersGasSaved.toStringAsFixed(1)} liters of gasoline saved'),
          _bullet('${_treesEquivalent.toStringAsFixed(1)} trees worth of CO₂ absorbed'),
          const SizedBox(height: 8),
          Text('Every kWh charged makes a difference 🌱', style: kSub(12)),
        ]),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.check_circle, color: kGreen, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: kSub(12))),
        ]),
      );
}
