import 'package:flutter/material.dart';
import '../utils/constants.dart';

class BookingDetailScreen extends StatelessWidget {
  final Map<String, dynamic> booking;
  const BookingDetailScreen(this.booking, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = Color(booking['color'] as int);
    return Scaffold(
      backgroundColor: kBg,
      appBar: kAppBar('Booking Detail', context),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.25))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.ev_station, color: color, size: 32),
              const SizedBox(height: 12),
              Text(booking['station'] as String, style: kTitle(18)),
              const SizedBox(height: 6),
              Text(booking['date'] as String, style: kSub(14)),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(booking['status'] as String,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700))),
            ])),
          const SizedBox(height: 24),
          if (booking['status'] == 'Upcoming') ...[
            SizedBox(width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Get Directions',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)))),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 54,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Cancel Booking',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800)))),
          ],
        ]),
      ),
    );
  }
}
