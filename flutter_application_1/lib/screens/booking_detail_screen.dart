import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingDetailScreen(this.booking, {super.key});
  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _cancelling = false;
  late Map<String, dynamic> _booking;

  @override
  void initState() {
    super.initState();
    _booking = Map<String, dynamic>.from(widget.booking);
  }

  // ── Cancel Booking ────────────────────────────────────────
  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Booking?', style: kTitle(16)),
        content: Text('You will get a full refund of 5 NIS.', style: kSub(13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: TextStyle(color: cSub))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Yes, Cancel')),
        ]));

    if (confirm != true || !mounted) return;

    setState(() => _cancelling = true);

    final bookingId = _booking['_id'] as String? ?? '';
    final result = await ApiService.instance.cancelBooking(bookingId);

    if (!mounted) return;
    setState(() => _cancelling = false);

    if (result['success']) {
      setState(() => _booking['status'] = 'Cancelled');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle, color: kGreen, size: 18), SizedBox(width: 8),
          Text('Booking cancelled — 5 NIS refunded ✅'),
        ]),
        backgroundColor: cCard, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Cancel failed'),
        backgroundColor: kRed, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status  = _booking['status'] as String? ?? 'Upcoming';
    final station = _booking['station'];
    final stName  = station is Map ? station['name'] as String? ?? 'Station' : 'Station';
    final stPower = station is Map ? station['power'] as String? ?? '' : '';
    final stConn  = station is Map ? station['connector'] as String? ?? '' : '';
    final stPrice = station is Map ? station['price']?.toString() ?? '' : '';
    final stAddr  = station is Map
        ? (station['location'] is Map ? station['location']['address'] as String? ?? '' : '')
        : '';
    final date    = _booking['date'] as String? ?? '';
    final time    = _booking['time'] as String? ?? '';
    final price   = (_booking['price'] as num?)?.toStringAsFixed(2) ?? '5.00';

    final color = status == 'Upcoming'  ? kGreen
        : status == 'Completed' ? Colors.blueAccent
        : Colors.redAccent;

    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Booking Detail', context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Status Card ───────────────────────────────────
          Container(width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.25))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 48, height: 48,
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.ev_station, color: color, size: 26)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(stName, style: kTitle(16)),
                  if (stAddr.isNotEmpty)
                    Text(stAddr, style: kSub(11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700))),
              ]),
            ])),
          const SizedBox(height: 20),

          // ── Details ───────────────────────────────────────
          Container(padding: const EdgeInsets.all(16), decoration: kCardDeco(),
            child: Column(children: [
              _row(Icons.calendar_today_outlined, 'Date',      date),
              _row(Icons.access_time,             'Time',      time),
              if (stPower.isNotEmpty)
                _row(Icons.bolt_outlined,         'Power',     stPower),
              if (stConn.isNotEmpty)
                _row(Icons.electrical_services,   'Connector', stConn),
              if (stPrice.isNotEmpty)
                _row(Icons.attach_money,          'Price',     '$stPrice NIS/kWh'),
              Divider(color: cBorder, height: 20),
              _row(Icons.receipt_outlined,        'Booking Fee', '$price NIS',
                  valueColor: status == 'Upcoming' ? kRed : cSub),
            ])),
          const SizedBox(height: 24),

          // ── Actions ───────────────────────────────────────
          if (status == 'Upcoming') ...[
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.directions_outlined, size: 18),
                label: const Text('Get Directions',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 52,
              child: OutlinedButton.icon(
                onPressed: _cancelling ? null : _cancel,
                icon: _cancelling
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2))
                    : const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18),
                label: Text(_cancelling ? 'Cancelling...' : 'Cancel Booking',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
          ],

          if (status == 'Completed') ...[
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.07), borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.25))),
              child: Row(children: [
                const Icon(Icons.check_circle, color: Colors.blueAccent, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text('This session is completed. Thank you for using ChargeGuard!',
                    style: kSub(12))),
              ])),
          ],

          if (status == 'Cancelled') ...[
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.07), borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.redAccent.withOpacity(0.25))),
              child: Row(children: [
                const Icon(Icons.cancel, color: Colors.redAccent, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text('This booking was cancelled. Refund has been processed.',
                    style: kSub(12))),
              ])),
          ],

        ]),
      ),
    );
  }

  Widget _row(IconData icon, String label, String val, {Color? valueColor}) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, color: cSub2, size: 16), const SizedBox(width: 10),
        Text(label, style: kSub(13)), const Spacer(),
        Text(val, style: TextStyle(color: valueColor ?? cTitle,
            fontSize: 13, fontWeight: FontWeight.w700)),
      ]));
}
