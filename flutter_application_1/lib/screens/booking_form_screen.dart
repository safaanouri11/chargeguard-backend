import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class BookingFormScreen extends StatefulWidget {
  final Map<String, dynamic>? station;
  const BookingFormScreen({super.key, this.station});
  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  String _date    = 'Today';
  String _time    = '10:00 AM';
  bool   _loading = false;

  final _dates = ['Today', 'Tomorrow', 'Wed 8 Apr', 'Thu 9 Apr'];
  final _times = ['9:00 AM', '10:00 AM', '11:00 AM', '2:00 PM', '4:00 PM', '6:00 PM'];

  Future<void> _confirm() async {
    setState(() => _loading = true);

    final stationId = widget.station?['_id'] as String? ?? '';
    final result = await ApiService.instance.createBooking(
      stationId: stationId,
      date:      _date,
      time:      _time,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle, color: kGreen, size: 18), SizedBox(width: 8),
          Text('Booking confirmed! ✅'),
        ]),
        backgroundColor: cCard, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      Navigator.popUntil(context, (r) => r.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Booking failed'),
        backgroundColor: kRed, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final station = widget.station;
    final stName  = station?['name'] as String? ?? 'Unknown Station';
    final price   = station?['price']?.toString() ?? '2.5';
    final conn    = station?['connector'] as String? ?? 'CCS2';
    final balance = UserSession.instance.balance;

    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Book Charger', context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Station info
          Container(padding: const EdgeInsets.all(14), decoration: kCardDeco(),
            child: Row(children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.ev_station, color: kGreen, size: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(stName, style: kTitle(14)),
                Text('$conn · $price NIS/kWh', style: kSub(12)),
              ])),
            ])),
          const SizedBox(height: 20),

          // Balance warning
          if (balance < 5)
            Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 18), const SizedBox(width: 8),
                Expanded(child: Text('Low balance (${balance.toStringAsFixed(2)} NIS). Top up to book.',
                    style: const TextStyle(color: Colors.orange, fontSize: 12))),
              ])),

          // Date
          Text('Select Date', style: kTitle(15)), const SizedBox(height: 12),
          SizedBox(height: 46,
            child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _dates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final sel = _date == _dates[i];
                return GestureDetector(onTap: () => setState(() => _date = _dates[i]),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(color: sel ? kGreen : cCard,
                        borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? kGreen : cBorder)),
                    child: Text(_dates[i], style: TextStyle(
                        color: sel ? Colors.black : cSub, fontWeight: FontWeight.w700, fontSize: 13))));
              })),
          const SizedBox(height: 24),

          // Time
          Text('Select Time', style: kTitle(15)), const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10,
            children: _times.map((t) {
              final sel = _time == t;
              return GestureDetector(onTap: () => setState(() => _time = t),
                child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? kGreen.withOpacity(0.12) : cCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? kGreen : cBorder)),
                  child: Text(t, style: TextStyle(
                      color: sel ? kGreen : cSub, fontWeight: FontWeight.w700))));
            }).toList()),
          const SizedBox(height: 24),

          // Summary
          Container(padding: const EdgeInsets.all(16), decoration: kCardDeco(),
            child: Column(children: [
              _row('Station',  stName),
              _row('Date',     _date),
              _row('Time',     _time),
              _row('Price',    '$price NIS/kWh'),
              _row('Connector', conn),
              _row('Booking Fee', '5 NIS (from wallet)'),
              const Divider(height: 16),
              _row('Wallet After', 'NIS ${(balance - 5).toStringAsFixed(2)}',
                  valueColor: balance < 5 ? kRed : kGreen),
            ])),
          const SizedBox(height: 28),

          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: (_loading || balance < 5) ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                disabledBackgroundColor: kGreen.withOpacity(0.2),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                  : const Text('Confirm Booking',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)))),
        ]),
      ),
    );
  }

  Widget _row(String label, String val, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: [
      Text(label, style: kSub(13)), const Spacer(),
      Text(val, style: TextStyle(
          color: valueColor ?? cTitle, fontSize: 13, fontWeight: FontWeight.w700)),
    ]));
}
