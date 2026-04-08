import 'package:flutter/material.dart';
import '../utils/constants.dart';

class HostDashboardScreen extends StatelessWidget {
  const HostDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: kAppBar('Host Dashboard', context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Earnings Card
          Container(width: double.infinity, padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00E5A0), Color(0xFF00B37A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Earnings',
                  style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('NIS 1,240',
                  style: TextStyle(color: Colors.black, fontSize: 38, fontWeight: FontWeight.w900, height: 1)),
              Text('This month', style: TextStyle(color: Colors.black.withOpacity(0.55), fontSize: 13)),
            ])),
          const SizedBox(height: 20),

          Row(children: [
            _stat('8',    'Bookings\nToday'),
            const SizedBox(width: 12),
            _stat('2',    'Active\nChargers'),
            const SizedBox(width: 12),
            _stat('4.8⭐','Avg\nRating'),
          ]),
          const SizedBox(height: 24),

          Text('Manage', style: kTitle(16)),
          const SizedBox(height: 14),
          _action(context, Icons.add_circle_outline, 'Add New Charger',  'Register a new charger'),
          _action(context, Icons.power_settings_new,  'Manage Chargers',  'Enable or disable chargers'),
          _action(context, Icons.inbox_outlined,       'Booking Requests', '3 pending requests'),
          _action(context, Icons.bar_chart,            'Earnings Report',  'View detailed analytics'),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kGreen)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.directions_car, color: kGreen, size: 20), SizedBox(width: 8),
                Text('Switch to Driver Mode',
                    style: TextStyle(color: kGreen, fontWeight: FontWeight.w700, fontSize: 14)),
              ])),
          ),
        ]),
      ),
    );
  }

  Widget _stat(String v, String l) => Expanded(
    child: Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: kCardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(v, style: kTitle(18)), Text(l, style: kSub(11)),
      ])));

  Widget _action(BuildContext ctx, IconData icon, String title, String sub) =>
    Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: kCardDeco(),
      child: Row(children: [
        Container(width: 44, height: 44,
            decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: kGreen, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: kTitle(14)), Text(sub, style: kSub(12)),
        ])),
        const Icon(Icons.chevron_right, color: Colors.white24),
      ]));
}
