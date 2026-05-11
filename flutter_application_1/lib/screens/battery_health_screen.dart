import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class BatteryHealthScreen extends StatefulWidget {
  const BatteryHealthScreen({super.key});
  @override
  State<BatteryHealthScreen> createState() => _BatteryHealthScreenState();
}

class _BatteryHealthScreenState extends State<BatteryHealthScreen> {
  bool _loading = true;
  int? _readingsCount;
  int? _chargeCycles;
  int? _currentPct;
  int? _estimatedMaxRangeKm;
  List<Map<String, dynamic>> _rangeSeries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.instance.getBatteryHealth();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success']) {
        final d = res['data'] as Map<String, dynamic>;
        _readingsCount = (d['readingsCount'] as num?)?.toInt() ?? 0;
        _chargeCycles  = (d['chargeCycles']  as num?)?.toInt() ?? 0;
        _currentPct    = (d['currentPct']    as num?)?.toInt();
        _estimatedMaxRangeKm = (d['estimatedMaxRangeKm'] as num?)?.toInt();
        _rangeSeries = ((d['rangeSeries'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Battery Health', context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : RefreshIndicator(
              color: kGreen, onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                _heroCard(),
                const SizedBox(height: 16),
                _statsRow(),
                const SizedBox(height: 16),
                _rangeChart(),
                const SizedBox(height: 16),
                _info(),
                const SizedBox(height: 20),
              ]),
            ),
    );
  }

  Widget _heroCard() {
    final pct = _currentPct ?? 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kGreen.withOpacity(0.22), Colors.purpleAccent.withOpacity(0.08)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kGreen.withOpacity(0.4)),
      ),
      child: Column(children: [
        const Icon(Icons.battery_charging_full, color: kGreen, size: 48),
        const SizedBox(height: 14),
        Text(
          _estimatedMaxRangeKm != null ? '$_estimatedMaxRangeKm km' : '—',
          style: kTitle(36).copyWith(color: kGreen, fontWeight: FontWeight.w900),
        ),
        Text('Estimated max range', style: kSub(13)),
        const SizedBox(height: 14),
        Container(height: 12, decoration: BoxDecoration(
            color: cSub2.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (pct / 100).clamp(0.0, 1.0),
            child: Container(decoration: BoxDecoration(
              color: kGreen, borderRadius: BorderRadius.circular(6),
              boxShadow: [BoxShadow(color: kGreen.withOpacity(0.4), blurRadius: 8)],
            )),
          ),
        ),
        const SizedBox(height: 8),
        Text('Current charge: $pct%', style: kSub(13)),
      ]),
    );
  }

  Widget _statsRow() => Row(children: [
        _statCard(Icons.battery_std, '${_chargeCycles ?? 0}',
            'Charge Cycles', 'of 1,500 expected'),
        const SizedBox(width: 10),
        _statCard(Icons.timeline, '${_readingsCount ?? 0}',
            'Readings', 'Battery samples'),
      ]);

  Widget _statCard(IconData icon, String value, String label, String hint) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(14),
        decoration: kCardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: kGreen, size: 18),
          const SizedBox(height: 8),
          Text(value, style: kTitle(20)),
          const SizedBox(height: 2),
          Text(label, style: kSub(11)),
          Text(hint, style: kSub(10).copyWith(color: cSub2)),
        ]),
      ));

  Widget _rangeChart() {
    if (_rangeSeries.length < 2) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: kCardDeco(),
        child: Column(children: [
          Icon(Icons.show_chart, color: cSub2, size: 40),
          const SizedBox(height: 8),
          Text('Not enough data yet', style: kTitle(14)),
          const SizedBox(height: 4),
          Text('Complete at least 2 charging sessions to see your battery health trend.',
              style: kSub(12), textAlign: TextAlign.center),
        ]),
      );
    }

    final spots = <FlSpot>[];
    final ranges = _rangeSeries.map((r) =>
        (r['rangeKm'] as num?)?.toDouble() ?? 0).toList();
    for (var i = 0; i < ranges.length; i++) {
      spots.add(FlSpot(i.toDouble(), ranges[i]));
    }
    final minY = ranges.reduce((a, b) => a < b ? a : b);
    final maxY = ranges.reduce((a, b) => a > b ? a : b);
    final padY = ((maxY - minY) * 0.15).clamp(5.0, 50.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: kCardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.trending_up, color: kGreen, size: 18),
          const SizedBox(width: 6),
          Text('Max range over time', style: kTitle(14)),
        ]),
        const SizedBox(height: 14),
        SizedBox(height: 200, child: LineChart(LineChartData(
          minY: minY - padY, maxY: maxY + padY,
          gridData: FlGridData(show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxY - minY) / 4).clamp(5.0, 100.0),
            getDrawingHorizontalLine: (_) =>
                FlLine(color: cSub2.withOpacity(0.15), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 42,
              getTitlesWidget: (v, _) => Text('${v.round()} km',
                  style: kSub(10), textAlign: TextAlign.right),
            )),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: kGreen,
              barWidth: 2.5,
              dotData: FlDotData(show: true,
                getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                  radius: 3, color: kGreen, strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [kGreen.withOpacity(0.3), kGreen.withOpacity(0.0)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ))),
      ]),
    );
  }

  Widget _info() => Container(
        padding: const EdgeInsets.all(16),
        decoration: kCardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.info_outline, color: kGreen, size: 18),
            const SizedBox(width: 8),
            Text('How is this calculated?', style: kTitle(13)),
          ]),
          const SizedBox(height: 10),
          Text(
            'Every charging session records the kWh added and the battery '
            'percentage gained. We estimate your full-pack capacity from '
            'these samples, then convert to km using a typical EV '
            'consumption of 0.2 kWh per km.',
            style: kSub(12),
          ),
          const SizedBox(height: 10),
          Text(
            'EV batteries typically last 1,500+ cycles before noticeable '
            'degradation. Your cycle count grows by one for each completed '
            'charging session.',
            style: kSub(12),
          ),
        ]),
      );
}
