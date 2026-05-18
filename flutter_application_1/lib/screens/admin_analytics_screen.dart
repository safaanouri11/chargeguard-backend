import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});
  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.instance.getAdminAnalyticsFull();
    if (mounted) {
      setState(() {
        _loading = false;
        if (result['success']) _data = result['data'] as Map<String, dynamic>;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg, elevation: 0,
        title: Text('Analytics', style: kTitle(18)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: kGreen), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : _data == null
              ? Center(child: Text('No data available', style: kSub(14)))
              : RefreshIndicator(
                  color: kGreen,
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _sectionTitle('Revenue — Last 30 Days', 'NIS'),
                      const SizedBox(height: 12),
                      _lineChart(_data!['revenue30'] as List? ?? [], kGreen),
                      const SizedBox(height: 28),

                      _sectionTitle('User Growth (Cumulative)', 'Users'),
                      const SizedBox(height: 12),
                      _lineChart(_data!['userGrowth30'] as List? ?? [], Colors.blueAccent),
                      const SizedBox(height: 28),

                      _sectionTitle('Bookings per Day', 'Bookings'),
                      const SizedBox(height: 12),
                      _barChart(_data!['bookings30'] as List? ?? [], Colors.orange),
                      const SizedBox(height: 28),

                      _sectionTitle('Top 5 Stations', 'by booking count'),
                      const SizedBox(height: 12),
                      ..._topList(_data!['topStations'] as List? ?? [], (m) {
                        return _TopRow(
                          title: m['name'] as String? ?? '',
                          subtitle: m['network'] as String? ?? '',
                          value: '${m['count'] ?? 0}',
                        );
                      }),
                      const SizedBox(height: 28),

                      _sectionTitle('Top 5 Hosts', 'by earnings'),
                      const SizedBox(height: 12),
                      ..._topList(_data!['topHosts'] as List? ?? [], (m) {
                        return _TopRow(
                          title: m['name'] as String? ?? '',
                          subtitle: '',
                          value: 'NIS ${(m['earnings'] as num? ?? 0).toStringAsFixed(0)}',
                        );
                      }),
                      const SizedBox(height: 28),

                      _sectionTitle('Connector Distribution', 'across stations'),
                      const SizedBox(height: 12),
                      _connectorPie(_data!['connectors'] as List? ?? []),
                      const SizedBox(height: 28),

                      _sectionTitle('Peak Hours', 'last 30 days'),
                      const SizedBox(height: 12),
                      _peakHoursBar(_data!['peakHours'] as List? ?? []),
                      const SizedBox(height: 20),
                    ]),
                  ),
                ),
    );
  }

  Widget _sectionTitle(String title, String sub) => Row(children: [
        Text(title, style: kTitle(15)),
        const SizedBox(width: 8),
        Text(sub, style: kSub(11)),
      ]);

  Widget _lineChart(List points, Color color) {
    if (points.isEmpty) return _emptyChart();
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final v = ((points[i] as Map)['value'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), v));
    }
    final maxY = spots.map((s) => s.y).fold<double>(0, (m, v) => v > m ? v : m);
    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 14, 14, 8),
      decoration: kCardDeco(),
      child: LineChart(LineChartData(
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY * 1.15,
        gridData: FlGridData(show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: cBorder, strokeWidth: 0.6)),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 36,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                  style: TextStyle(color: cSub2, fontSize: 9)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, interval: (points.length / 5).ceilToDouble(),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                final lbl = (points[i] as Map)['label'] as String? ?? '';
                return Padding(padding: const EdgeInsets.only(top: 4),
                    child: Text(lbl.split(' ')[0],
                        style: TextStyle(color: cSub2, fontSize: 9)));
              })),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: color.withOpacity(0.12)),
        )],
      )),
    );
  }

  Widget _barChart(List points, Color color) {
    if (points.isEmpty) return _emptyChart();
    final groups = <BarChartGroupData>[];
    var maxY = 0.0;
    for (var i = 0; i < points.length; i++) {
      final v = ((points[i] as Map)['value'] as num?)?.toDouble() ?? 0;
      if (v > maxY) maxY = v;
      groups.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: v, color: color, width: 6,
            borderRadius: BorderRadius.circular(2)),
      ]));
    }
    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 14, 14, 8),
      decoration: kCardDeco(),
      child: BarChart(BarChartData(
        maxY: maxY <= 0 ? 1 : maxY * 1.15,
        gridData: FlGridData(show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: cBorder, strokeWidth: 0.6)),
        borderData: FlBorderData(show: false),
        barGroups: groups,
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 30,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                  style: TextStyle(color: cSub2, fontSize: 9)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, interval: (points.length / 5).ceilToDouble(),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                final lbl = (points[i] as Map)['label'] as String? ?? '';
                return Padding(padding: const EdgeInsets.only(top: 4),
                    child: Text(lbl.split(' ')[0],
                        style: TextStyle(color: cSub2, fontSize: 9)));
              })),
        ),
      )),
    );
  }

  Widget _connectorPie(List items) {
    if (items.isEmpty) return _emptyChart();
    final palette = [kGreen, Colors.blueAccent, Colors.orange, Colors.purpleAccent,
                     Colors.tealAccent, Colors.amber, Colors.redAccent];
    final total = items.fold<int>(0, (s, m) => s + ((m as Map)['count'] as int? ?? 0));
    final sections = <PieChartSectionData>[];
    for (var i = 0; i < items.length; i++) {
      final m = items[i] as Map;
      final v = (m['count'] as num?)?.toDouble() ?? 0;
      final pct = total > 0 ? (v / total * 100).toStringAsFixed(0) : '0';
      sections.add(PieChartSectionData(
        color: palette[i % palette.length],
        value: v,
        title: '$pct%',
        radius: 60,
        titleStyle: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800),
      ));
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: kCardDeco(),
      child: Row(children: [
        SizedBox(width: 150, height: 150,
            child: PieChart(PieChartData(
              sections: sections, sectionsSpace: 2, centerSpaceRadius: 32,
            ))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(items.length, (i) {
          final m = items[i] as Map;
          return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
            Container(width: 12, height: 12,
                decoration: BoxDecoration(color: palette[i % palette.length],
                    borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Expanded(child: Text(m['name'] as String? ?? '',
                style: TextStyle(color: cTitle, fontSize: 12, fontWeight: FontWeight.w600))),
            Text('${m['count']}', style: TextStyle(color: cSub, fontSize: 12)),
          ]));
        }))),
      ]),
    );
  }

  Widget _peakHoursBar(List items) {
    if (items.isEmpty) return _emptyChart();
    final groups = <BarChartGroupData>[];
    var maxY = 0.0;
    for (var i = 0; i < items.length; i++) {
      final v = ((items[i] as Map)['count'] as num?)?.toDouble() ?? 0;
      if (v > maxY) maxY = v;
      groups.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: v, color: Colors.purpleAccent, width: 6,
            borderRadius: BorderRadius.circular(2)),
      ]));
    }
    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 14, 14, 8),
      decoration: kCardDeco(),
      child: BarChart(BarChartData(
        maxY: maxY <= 0 ? 1 : maxY * 1.15,
        gridData: FlGridData(show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: cBorder, strokeWidth: 0.6)),
        borderData: FlBorderData(show: false),
        barGroups: groups,
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 30,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                  style: TextStyle(color: cSub2, fontSize: 9)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, interval: 3,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= items.length) return const SizedBox.shrink();
                final hour = (items[i] as Map)['hour'] as int? ?? 0;
                return Padding(padding: const EdgeInsets.only(top: 4),
                    child: Text('${hour}h',
                        style: TextStyle(color: cSub2, fontSize: 9)));
              })),
        ),
      )),
    );
  }

  List<Widget> _topList<T>(List items, Widget Function(Map) build) {
    if (items.isEmpty) {
      return [Container(padding: const EdgeInsets.all(16), decoration: kCardDeco(),
        child: Center(child: Text('No data', style: kSub(12))))];
    }
    return items.map<Widget>((m) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: build(m as Map))).toList();
  }

  Widget _emptyChart() => Container(
        height: 160, decoration: kCardDeco(),
        child: Center(child: Text('No data', style: kSub(12))),
      );
}

class _TopRow extends StatelessWidget {
  final String title, subtitle, value;
  const _TopRow({required this.title, required this.subtitle, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: kCardDeco(radius: 12),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: kGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.star, color: kGreen, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: kTitle(13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: kSub(11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Text(value, style: TextStyle(
              color: kGreen, fontSize: 14, fontWeight: FontWeight.w800)),
        ]),
      );
}
