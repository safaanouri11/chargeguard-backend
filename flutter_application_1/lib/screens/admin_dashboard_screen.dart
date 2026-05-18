import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import 'admin_hosts_screen.dart';
import 'admin_users_screen.dart';
import 'admin_stations_screen.dart';
import 'admin_payouts_screen.dart';
import 'admin_tickets_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_broadcast_screen.dart';
import 'admin_audit_log_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_live_screen.dart';
import 'admin_fraud_screen.dart';
import 'admin_insights_screen.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  Map<String, dynamic>  _pendingCounts = {};
  int _fraudCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.instance.getAdminAnalytics(),
      ApiService.instance.getAdminPendingCounts(),
      ApiService.instance.getFraudAlerts(),
    ]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (results[0]['success']) _stats = results[0]['data'] as Map<String, dynamic>;
      if (results[1]['success']) _pendingCounts = Map<String, dynamic>.from(results[1]['data'] as Map);
      if (results[2]['success']) _fraudCount = (results[2]['data']?['count'] as int?) ?? 0;
    });
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout?', style: kTitle(16)),
        content: Text('You will need to sign in again to access the admin panel.',
            style: kSub(13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: cSub))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Logout')),
        ]));
    if (ok == true && mounted) {
      await ApiService.instance.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  void _showPendingSheet() {
    showModalBottomSheet(
      context: context, backgroundColor: cCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: cBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Pending Items', style: kTitle(17)),
          const SizedBox(height: 14),
          _pendingItem(Icons.verified_outlined, 'Host Applications',
              _pendingCounts['hosts'] as int? ?? 0, kGreen, () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHostsScreen()))
                .then((_) => _load());
          }),
          _pendingItem(Icons.payments_outlined, 'Payouts',
              _pendingCounts['payouts'] as int? ?? 0, Colors.amber, () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPayoutsScreen()))
                .then((_) => _load());
          }),
          _pendingItem(Icons.support_agent, 'Tickets',
              _pendingCounts['tickets'] as int? ?? 0, Colors.blueAccent, () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTicketsScreen()))
                .then((_) => _load());
          }),
          if (_fraudCount > 0)
            _pendingItem(Icons.warning_amber, 'Fraud Alerts',
                _fraudCount, Colors.redAccent, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFraudScreen()))
                  .then((_) => _load());
            }),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  Widget _pendingItem(IconData icon, String label, int count, Color color, VoidCallback onTap) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 6),
        child: GestureDetector(onTap: onTap,
          child: Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cBorder)),
            child: Row(children: [
              Icon(icon, color: color, size: 22), const SizedBox(width: 12),
              Expanded(child: Text(label, style: kTitle(13))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10)),
                child: Text('$count',
                    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800))),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: cSub2, size: 18),
            ]))));

  @override
  Widget build(BuildContext context) {
    final users    = (_stats?['users']    as Map<String, dynamic>?) ?? {};
    final stations = (_stats?['stations'] as Map<String, dynamic>?) ?? {};
    final bookings = (_stats?['bookings'] as Map<String, dynamic>?) ?? {};
    final revenue  = (_stats?['revenue']  as Map<String, dynamic>?) ?? {};
    final pending  = (_stats?['pending']  as Map<String, dynamic>?) ?? {};
    final daily    = (bookings['daily']   as List?) ?? [];
    final pendingTotal = _pendingCounts['total'] as int? ?? 0;

    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg, elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          Container(width: 32, height: 32,
              decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.admin_panel_settings, color: Colors.black, size: 20)),
          const SizedBox(width: 12),
          Text('Admin Panel', style: kTitle(18)),
        ]),
        actions: [
          // Live indicator
          IconButton(
            tooltip: 'Live',
            icon: const Icon(Icons.radio_button_checked, color: Colors.redAccent),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminLiveScreen())),
          ),
          // Bell with badge
          Stack(children: [
            IconButton(
              tooltip: 'Pending',
              icon: const Icon(Icons.notifications_outlined, color: kGreen),
              onPressed: _showPendingSheet,
            ),
            if (pendingTotal > 0)
              Positioned(top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(9)),
                  child: Center(child: Text('$pendingTotal',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))))),
          ]),
          IconButton(icon: const Icon(Icons.refresh, color: kGreen), onPressed: _load),
          IconButton(icon: Icon(Icons.logout, color: cSub), onPressed: _confirmLogout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : RefreshIndicator(color: kGreen, onRefresh: _load,
              child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Revenue Card
                  Container(width: double.infinity, padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00E5A0), Color(0xFF00B37A)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Platform Revenue',
                          style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('NIS ${((revenue['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.black, fontSize: 38, fontWeight: FontWeight.w900, height: 1)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Total Paid Out', style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 11)),
                          Text('NIS ${((revenue['paidOut'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800)),
                        ])),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Net Profit', style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 11)),
                          Text('NIS ${(((revenue['total'] as num?)?.toDouble() ?? 0) - ((revenue['paidOut'] as num?)?.toDouble() ?? 0)).toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800)),
                        ])),
                      ]),
                    ])),
                  const SizedBox(height: 20),

                  // Stats grid
                  Row(children: [
                    _stat('${users['total'] ?? 0}',    'Users',    Icons.people_outline, kGreen),
                    const SizedBox(width: 12),
                    _stat('${stations['total'] ?? 0}', 'Stations', Icons.ev_station,     Colors.blueAccent),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    _stat('${bookings['total'] ?? 0}',     'Bookings',  Icons.calendar_today_outlined, Colors.orange),
                    const SizedBox(width: 12),
                    _stat('${bookings['completed'] ?? 0}', 'Completed', Icons.check_circle_outline,    Colors.purpleAccent),
                  ]),
                  const SizedBox(height: 24),

                  // Chart (fl_chart)
                  Row(children: [
                    Text('Bookings — Last 7 Days', style: kTitle(15)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen())),
                      child: Row(children: [
                        Text('Full Analytics', style: TextStyle(
                            color: kGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                        const Icon(Icons.arrow_forward, color: kGreen, size: 14),
                      ])),
                  ]),
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.fromLTRB(8, 14, 14, 8),
                    decoration: kCardDeco(),
                    child: SizedBox(height: 180, child: _buildBarChart(daily))),
                  const SizedBox(height: 24),

                  // AI Insights teaser
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AdminInsightsScreen())),
                    child: Container(padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [kGreen.withOpacity(0.18), kGreen.withOpacity(0.06)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kGreen.withOpacity(0.3))),
                      child: Row(children: [
                        Container(width: 44, height: 44,
                          decoration: BoxDecoration(color: kGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.auto_awesome, color: kGreen, size: 22)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('AI Insights', style: kTitle(14)),
                          const SizedBox(height: 3),
                          Text('Claude-generated monthly summary', style: kSub(11)),
                        ])),
                        const Icon(Icons.chevron_right, color: kGreen),
                      ]))),
                  const SizedBox(height: 24),

                  // Quick Actions
                  Text('Management', style: kTitle(15)),
                  const SizedBox(height: 12),
                  _action(Icons.verified_outlined, 'Host Applications',
                      '${users['pendingHosts'] ?? 0} pending review',
                      (users['pendingHosts'] ?? 0) > 0,
                      () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const AdminHostsScreen())).then((_) => _load())),
                  _action(Icons.people_outline, 'All Users',
                      '${users['drivers'] ?? 0} drivers · ${users['hosts'] ?? 0} hosts',
                      false,
                      () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const AdminUsersScreen())).then((_) => _load())),
                  _action(Icons.ev_station, 'All Stations',
                      '${stations['active'] ?? 0} active of ${stations['total'] ?? 0}',
                      false,
                      () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const AdminStationsScreen())).then((_) => _load())),
                  _action(Icons.payments_outlined, 'Payout Approvals',
                      '${pending['payouts'] ?? 0} pending approval',
                      (pending['payouts'] ?? 0) > 0,
                      () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const AdminPayoutsScreen())).then((_) => _load())),
                  _action(Icons.support_agent, 'Support Tickets',
                      '${pending['tickets'] ?? 0} open tickets',
                      (pending['tickets'] ?? 0) > 0,
                      () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const AdminTicketsScreen())).then((_) => _load())),
                  const SizedBox(height: 20),
                  Text('Advanced', style: kTitle(15)),
                  const SizedBox(height: 12),
                  _action(Icons.insert_chart_outlined, 'Full Analytics',
                      'Revenue, growth, top performers',
                      false,
                      () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const AdminAnalyticsScreen()))),
                  _action(Icons.campaign, 'Broadcast Notification',
                      'Send to all users, drivers, or hosts',
                      false,
                      () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const AdminBroadcastScreen()))),
                  _action(Icons.warning_amber, 'Fraud Alerts',
                      '$_fraudCount suspicious item${_fraudCount == 1 ? '' : 's'}',
                      _fraudCount > 0,
                      () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const AdminFraudScreen())).then((_) => _load())),
                  _action(Icons.radio_button_checked, 'Live Activity',
                      'Active sessions & recent transactions',
                      false,
                      () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const AdminLiveScreen()))),
                  _action(Icons.history, 'Audit Log',
                      'Every admin action recorded',
                      false,
                      () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const AdminAuditLogScreen()))),
                  _action(Icons.settings_outlined, 'Platform Settings',
                      'Commission, features, maintenance',
                      false,
                      () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const AdminSettingsScreen()))),
                  const SizedBox(height: 30),
                ]))),
    );
  }

  Widget _buildBarChart(List daily) {
    if (daily.isEmpty) return Center(child: Text('No data', style: kSub(12)));
    final groups = <BarChartGroupData>[];
    var maxY = 0.0;
    for (var i = 0; i < daily.length; i++) {
      final v = ((daily[i] as Map)['count'] as num?)?.toDouble() ?? 0;
      if (v > maxY) maxY = v;
      groups.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: v, color: kGreen, width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
      ]));
    }
    return BarChart(BarChartData(
      maxY: maxY <= 0 ? 1 : maxY * 1.2,
      gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: cBorder, strokeWidth: 0.6)),
      borderData: FlBorderData(show: false),
      barGroups: groups,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => cCard,
          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
            '${(daily[group.x] as Map)['label']}\n${rod.toY.toInt()} bookings',
            const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 28,
            getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                style: TextStyle(color: cSub2, fontSize: 9)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 22,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= daily.length) return const SizedBox.shrink();
              final lbl = (daily[i] as Map)['label'] as String? ?? '';
              return Padding(padding: const EdgeInsets.only(top: 6),
                  child: Text(lbl.split(' ')[0],
                      style: TextStyle(color: cSub2, fontSize: 9)));
            })),
      ),
    ));
  }

  Widget _stat(String v, String l, IconData icon, Color color) => Expanded(
    child: Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20), const SizedBox(height: 8),
        Text(v, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900, height: 1)),
        const SizedBox(height: 4),
        Text(l, style: kSub(11)),
      ])));

  Widget _action(IconData icon, String title, String sub, bool hasAlert, VoidCallback onTap) =>
    GestureDetector(onTap: onTap,
      child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
        decoration: kCardDeco(),
        child: Row(children: [
          Stack(children: [
            Container(width: 42, height: 42,
                decoration: BoxDecoration(color: kGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: kGreen, size: 22)),
            if (hasAlert)
              Positioned(top: 0, right: 0,
                child: Container(width: 10, height: 10,
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle))),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: kTitle(14)),
            Text(sub, style: kSub(11)),
          ])),
          Icon(Icons.chevron_right, color: cSub2, size: 20),
        ])));
}
