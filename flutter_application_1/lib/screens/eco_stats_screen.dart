import 'package:flutter/material.dart';
import '../utils/constants.dart';

class EcoStatsScreen extends StatelessWidget {
  const EcoStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: kAppBar('Eco Impact ♻️', context),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 80, height: 80,
              decoration: BoxDecoration(color: kGreen.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.eco, color: kGreen, size: 40)),
          const SizedBox(height: 24),
          Text('Eco Impact ♻️', style: kTitle(22), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text("You've saved 85 kg of CO₂ this month.\nEquivalent to planting 4 trees! 🌳\n\nKeep charging green!",
              style: kSub(14), textAlign: TextAlign.center),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Share My Impact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            )),
        ]),
      ),
    );
  }
}
