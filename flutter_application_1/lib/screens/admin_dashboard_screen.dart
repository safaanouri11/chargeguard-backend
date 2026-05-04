import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import 'admin_hosts_screen.dart';
import 'admin_users_screen.dart';
import 'admin_stations_screen.dart';
import 'admin_payouts_screen.dart';
import 'admin_tickets_screen.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.instance.getAdminAnalytics();
    if (mounted) {
      setState(() {
        _loading = false;
        if (result['success']) _stats = result['data'] as Map<String, dynamic>;
      });
    }
  }

  void _logout() {
    ApiService.instance.logout();
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final users    = (_stats?['users']    as Map<String, dynamic>?) ?? {};
    final stations = (_stats?['stations'] as Map<String, dynamic>?) ?? {};
    final bookings = (_stats?['bookings'] as Map<String, dynamic>?) ?? {};
    final revenue  = (_stats?['revenue']  as Map<String, dynamic>?) ?? {};
    final pending  = (_stats?['pending']  as Map<String, dynamic>?) ?? {};
    final daily    = (bookings['daily']   as List?) ?? [];

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
          IconButton(icon: const Icon(Icons.refresh, color: kGreen), onPressed: _load),
          IconButton(icon: Icon(Icons.logout, color: cSub), onPressed: _logout),
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

                  // Chart
                  Text('Bookings — Last 7 Days', style: kTitle(15)),
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.all(16), decoration: kCardDeco(),
                    child: SizedBox(height: 160,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _buildBars(daily)))),
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
                ]))),
    );
  }

  List<Widget> _buildBars(List daily) {
    if (daily.isEmpty) return [Center(child: Text('No data', style: kSub(12)))];
    final maxVal = daily.fold<int>(0, (m, d) {
      final v = (d['count'] as num?)?.toInt() ?? 0;
      return v > m ? v : m;
    });
    return daily.map<Widget>((d) {
      final val   = (d['count'] as num?)?.toInt() ?? 0;
      final ratio = maxVal > 0 ? val / maxVal : 0.0;
      return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Text('$val', style: kSub(10)),
        const SizedBox(height: 4),
        Container(width: 24, height: (110 * ratio).clamp(3, 110).toDouble(),
          decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(6))),
        const SizedBox(height: 6),
        Text(d['label'] as String, style: kSub(9)),
      ]);
    }).toList();
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
