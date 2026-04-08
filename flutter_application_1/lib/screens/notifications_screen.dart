import 'package:flutter/material.dart';
import '../utils/constants.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _notifs = [
    {'icon': Icons.bolt,           'color': 0xFF00E5A0, 'title': 'Charging Complete!',    'sub': 'Your car is at 100%',          'time': 'Just now',   'read': false},
    {'icon': Icons.calendar_today, 'color': 0xFF6C9EFF, 'title': 'Booking Confirmed',      'sub': 'Today at 3:00 PM',            'time': '2h ago',    'read': false},
    {'icon': Icons.local_offer,    'color': 0xFFFF6B6B, 'title': '20% Off This Weekend!',  'sub': 'Use code CHARGE20',           'time': '5h ago',    'read': true},
    {'icon': Icons.star,           'color': 0xFFFFD700, 'title': 'Rate Your Last Session', 'sub': 'How was City Mall Charger?',  'time': 'Yesterday', 'read': true},
    {'icon': Icons.warning_amber,  'color': 0xFFFF9500, 'title': 'Low Battery Alert',      'sub': 'Battery at 20%',             'time': '2 days ago','read': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: kAppBar('Notifications', context, actions: [
        TextButton(
          onPressed: () {},
          child: const Text('Mark all read', style: TextStyle(color: kGreen, fontSize: 13)),
        ),
      ]),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _notifs.length,
        itemBuilder: (_, i) {
          final n     = _notifs[i];
          final color = Color(n['color'] as int);
          final read  = n['read'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: read ? kCard : kGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: read ? kBorder : kGreen.withOpacity(0.2)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(n['icon'] as IconData, color: color, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(n['title'] as String, style: kTitle(13))),
                  if (!read)
                    Container(width: 8, height: 8,
                        decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle)),
                ]),
                const SizedBox(height: 4),
                Text(n['sub'] as String, style: kSub(12)),
                const SizedBox(height: 6),
                Text(n['time'] as String, style: const TextStyle(color: Colors.white24, fontSize: 11)),
              ])),
            ]),
          );
        },
      ),
    );
  }
}
