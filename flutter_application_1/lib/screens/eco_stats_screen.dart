import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class EcoStatsScreen extends StatefulWidget {
  const EcoStatsScreen({super.key});

  @override
  State<EcoStatsScreen> createState() => _EcoStatsScreenState();
}

class _EcoStatsScreenState extends State<EcoStatsScreen> {
  int _totalBookings = 0;
  double _co2Saved = 0;
  int _trees = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final res = await ApiService.instance.getBookings();
    setState(() {
      _loading = false;
      if (res['success']) {
        final bookings = res['data'] as List? ?? [];
        _totalBookings = bookings.where((b) => b['status'] == 'Completed').length;
        _co2Saved = _totalBookings * 4.2;
        _trees = (_co2Saved / 21).floor();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: kAppBar('Eco Impact', context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: kGreen.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.eco, color: kGreen, size: 40),
                ),
                const SizedBox(height: 24),
                Text('Eco Impact', style: kTitle(22), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  "You've saved ${_co2Saved.toStringAsFixed(1)} kg of CO2 this month.\n"
                  "Equivalent to planting $_trees trees!\n\n"
                  "$_totalBookings completed charging sessions.\nKeep charging green!",
                  style: kSub(14), textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen, foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Share My Impact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
            ),
    );
  }
}
