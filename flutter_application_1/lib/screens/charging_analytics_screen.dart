import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class ChargingAnalyticsScreen extends StatefulWidget {
  const ChargingAnalyticsScreen({super.key});
  @override
  State<ChargingAnalyticsScreen> createState() => _ChargingAnalyticsScreenState();
}

class _ChargingAnalyticsScreenState extends State<ChargingAnalyticsScreen> {
  bool _loading = true;
  int _totalTrips = 0;
  double _totalKwh = 0;
  double _totalCost = 0;
  int _totalDurationMin = 0;
  double _avgKwh = 0;
  double _avgCost = 0;
  double _avgPricePerKwh = 0;
  List<Map<String, dynamic>> _daily = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.instance.getTripStats();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success']) {
        final d = res['data'] as Map<String, dynamic>;
        _totalTrips      = (d['totalTrips']       as num?)?.toInt()    ?? 0;
        _totalKwh        = (d['totalKwh']         as num?)?.toDouble() ?? 0;
        _totalCost       = (d['totalCost']        as num?)?.toDouble() ?? 0;
        _totalDurationMin= (d['totalDurationMin'] as num?)?.toInt()    ?? 0;
        _avgKwh          = (d['avgKwh']           as num?)?.toDouble() ?? 0;
        _avgCost         = (d['avgCost']          as num?)?.toDouble() ?? 0;
        _avgPricePerKwh  = (d['avgPricePerKwh']   as num?)?.toDouble() ?? 0;
        _daily = ((d['daily'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Analytics', context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : RefreshIndicator(
              color: kGreen, onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                _heroCard(),
                const SizedBox(height: 16),
                _statsGrid(),
                const SizedBox(height: 16),
                _weeklyChart(),
                const SizedBox(height: 16),
                _averages(),
                const SizedBox(height: 20),
              ]),
            ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kGreen.withOpacity(0.22), Colors.blueAccent.withOpacity(0.08)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kGreen.withOpacity(0.4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.insert_chart, color: kGreen, size: 22),
            const SizedBox(width: 8),
            Text('Charging Analytics', style: kTitle(16)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _hero('$_totalTrips', 'Sessions'),
            _hero(_totalKwh.toStringAsFixed(1), 'kWh'),
            _hero('${_totalCost.toStringAsFixed(0)}', 'NIS'),
          ]),
        ]),
      );

  Widget _hero(String value, String label) => Expanded(child: Column(children: [
        Text(value, style: kTitle(22).copyWith(color: kGreen, fontWeight: FontWeight.w900)),
        Text(label, style: kSub(11)),
      ]));

  Widget _statsGrid() => Row(children: [
        _statCard(Icons.access_time, _fmtDuration(_totalDurationMin), 'Total Time'),
        const SizedBox(width: 10),
        _statCard(Icons.payments,
            _avgPricePerKwh > 0 ? '${_avgPricePerKwh.toStringAsFixed(2)}' : '—',
            'Avg NIS/kWh'),
      ]);

  Widget _statCard(IconData icon, String value, String label) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(14),
        decoration: kCardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: kGreen, size: 18),
          const SizedBox(height: 8),
          Text(value, style: kTitle(18)),
          const SizedBox(height: 2),
          Text(label, style: kSub(11)),
        ]),
      ));

  Widget _weeklyChart() {
    if (_daily.isEmpty) return const SizedBox.shrink();
    final maxKwh = _daily.fold<double>(0,
        (m, d) => ((d['kwh'] as num?)?.toDouble() ?? 0) > m
            ? (d['kwh'] as num).toDouble() : m);
    final yMax = (maxKwh < 1 ? 1.0 : maxKwh * 1.2).ceilToDouble();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: kCardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bar_chart, color: kGreen, size: 18),
          const SizedBox(width: 6),
          Text('Last 7 days (kWh)', style: kTitle(14)),
        ]),
        const SizedBox(height: 14),
        SizedBox(height: 200, child: BarChart(BarChartData(
          maxY: yMax, minY: 0,
          barGroups: List.generate(_daily.length, (i) {
            final v = (_daily[i]['kwh'] as num?)?.toDouble() ?? 0;
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: v,
                gradient: LinearGradient(
                  colors: [kGreen, kGreen.withOpacity(0.6)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ]);
          }),
          gridData: FlGridData(show: true,
            drawVerticalLine: false,
            horizontalInterval: yMax / 4,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: cSub2.withOpacity(0.15), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 30,
              getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                  style: kSub(10), textAlign: TextAlign.right),
            )),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 28,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= _daily.length) return const SizedBox.shrink();
                final label = _daily[i]['label'] as String? ?? '';
                return Padding(padding: const EdgeInsets.only(top: 6),
                    child: Text(label.split(' ').first, style: kSub(9)));
              },
            )),
          ),
          borderData: FlBorderData(show: false),
        ))),
      ]),
    );
  }

  Widget _averages() => Container(
        padding: const EdgeInsets.all(16),
        decoration: kCardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.tune, color: kGreen, size: 18),
            const SizedBox(width: 6),
            Text('Averages per session', style: kTitle(14)),
          ]),
          const SizedBox(height: 12),
          _row('Avg energy', '${_avgKwh.toStringAsFixed(1)} kWh'),
          _row('Avg cost',   '${_avgCost.toStringAsFixed(2)} NIS'),
          _row('Avg price',  _avgPricePerKwh > 0
              ? '${_avgPricePerKwh.toStringAsFixed(2)} NIS / kWh' : '—'),
        ]),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Text(label, style: kSub(13)), const Spacer(),
          Text(value, style: kTitle(13).copyWith(color: kGreen)),
        ]),
      );

  String _fmtDuration(int min) {
    if (min < 60) return '$min min';
    final h = min ~/ 60; final m = min % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
