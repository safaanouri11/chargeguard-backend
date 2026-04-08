import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/app_settings.dart';
import 'booking_form_screen.dart';

class ChargerDetailScreen extends StatelessWidget {
  final Map<String, dynamic> station;
  const ChargerDetailScreen(this.station, {super.key});

  @override
  Widget build(BuildContext context) {
    final name  = station['name']      as String? ?? 'Station';
    final power = station['power']     as String? ?? '22 kW';
    final conn  = station['connector'] as String? ?? 'CCS2';
    final price = station['price']?.toString() ?? '2.5';
    final ok    = station['available'] as bool? ?? true;
    final addr  = (station['location'] as Map?)?['address'] as String? ?? '';
    final rating = station['rating']?.toString() ?? '5.0';

    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar(name, context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Map placeholder
          Container(height: 180,
            decoration: BoxDecoration(color: AppSettings.instance.isDark
                ? const Color(0xFF0D1421) : const Color(0xFFEEF2F7),
                borderRadius: BorderRadius.circular(16), border: Border.all(color: cBorder)),
            child: Center(child: Icon(Icons.map, color: kGreen.withOpacity(0.2), size: 60))),
          const SizedBox(height: 16),

          // Address
          if (addr.isNotEmpty)
            Row(children: [
              const Icon(Icons.location_on, color: kGreen, size: 16), const SizedBox(width: 6),
              Expanded(child: Text(addr, style: kSub(13))),
            ]),
          const SizedBox(height: 12),

          // Status + Rating
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ok ? kGreen.withOpacity(0.12) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
              child: Text(ok ? 'Available' : 'Busy',
                  style: TextStyle(color: ok ? kGreen : Colors.redAccent, fontWeight: FontWeight.w700))),
            const SizedBox(width: 10),
            const Icon(Icons.star, color: Colors.amber, size: 16),
            Text('  $rating', style: TextStyle(color: cSub, fontSize: 13)),
          ]),
          const SizedBox(height: 20),

          // Info grid
          Row(children: [
            _info('⚡', 'Type',      power),
            _info('🔌', 'Connector', conn),
            _info('💰', 'Price',     '$price NIS'),
            _info('⏱️', 'Wait',      ok ? '0 min' : '~15 min'),
          ]),
          const SizedBox(height: 24),

          Text('Description', style: kTitle(15)),
          const SizedBox(height: 8),
          Text('$name is a ${ok ? "available" : "currently busy"} charging station '
              'with $power output and $conn connector. Price: $price NIS/kWh.',
              style: kSub(13)),
          const SizedBox(height: 28),

          // Book button
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: ok ? () => goTo(context, BookingFormScreen(station: station)) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                disabledBackgroundColor: Colors.grey.withOpacity(0.2),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text(ok ? 'Book Now' : 'Not Available',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)))),
        ]),
      ),
    );
  }

  Widget _info(String e, String label, String val) => Expanded(
    child: Container(margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12), decoration: kCardDeco(radius: 12),
      child: Column(children: [
        Text(e, style: const TextStyle(fontSize: 18)), const SizedBox(height: 6),
        Text(val, style: kTitle(11), textAlign: TextAlign.center),
        Text(label, style: kSub(10)),
      ])));
}
