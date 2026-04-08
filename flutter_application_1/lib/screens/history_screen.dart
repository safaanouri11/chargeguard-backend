import 'package:flutter/material.dart';
import '../utils/constants.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const _history = [
    {'station': 'An-Najah EV Station', 'date': 'Apr 4, 2026',  'kwh': '22.4 kWh', 'cost': '56 NIS'},
    {'station': 'Campus Green Charger','date': 'Apr 2, 2026',  'kwh': '15.1 kWh', 'cost': '22 NIS'},
    {'station': 'City Mall Charger',   'date': 'Mar 30, 2026', 'kwh': '30.0 kWh', 'cost': '54 NIS'},
    {'station': 'An-Najah EV Station', 'date': 'Mar 25, 2026', 'kwh': '18.7 kWh', 'cost': '46 NIS'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: kAppBar('Charging History', context),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _history.length,
        itemBuilder: (_, i) {
          final h = _history[i];
          return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
            decoration: kCardDeco(),
            child: Row(children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.bolt, color: kGreen, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(h['station']!, style: kTitle(13)),
                Text(h['date']!, style: kSub(11)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(h['kwh']!, style: kTitle(13)),
                Text(h['cost']!,
                    style: const TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ]));
        }),
    );
  }
}
