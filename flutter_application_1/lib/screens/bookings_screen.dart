import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/app_settings.dart';
import '../utils/api_service.dart';
import 'all_stations_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<dynamic> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_refresh);
    _loadBookings();
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _loadBookings() async {
    setState(() => _loading = true);
    final result = await ApiService.instance.getBookings();
    if (mounted) {
      setState(() {
        _loading  = false;
        _bookings = result['success'] ? (result['data'] as List) : [];
      });
    }
  }

  Future<void> _cancel(String bookingId) async {
    final result = await ApiService.instance.cancelBooking(bookingId);
    if (mounted) {
      _snack(result['success'] ? 'Booking cancelled & refunded ✅' : result['message']);
      if (result['success']) _loadBookings();
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: cCard, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  String _localStatus(String s) {
    if (s == 'Upcoming')  return L.upcoming;
    if (s == 'Completed') return L.completed;
    if (s == 'Cancelled') return L.cancelled;
    return s;
  }

  Color _statusColor(String s) {
    if (s == 'Upcoming')  return kGreen;
    if (s == 'Completed') return Colors.blueAccent;
    return Colors.redAccent;
  }

  int _count(String status) => _bookings.where((b) => b['status'] == status).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar(L.bookings, context, showBack: false, actions: [
        IconButton(icon: const Icon(Icons.add_circle_outline, color: kGreen),
            onPressed: () => goTo(context, AllStationsScreen())),
      ]),
      body: _loading
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(color: kGreen),
              const SizedBox(height: 16),
              Text('Loading bookings...', style: kSub(14)),
            ]))
          : RefreshIndicator(
              color: kGreen,
              onRefresh: _loadBookings,
              child: _bookings.isEmpty
                  ? _emptyView()
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Summary
                        Row(children: [
                          _sum(_count('Upcoming').toString(),  L.upcoming,  kGreen),
                          const SizedBox(width: 12),
                          _sum(_count('Completed').toString(), L.completed, Colors.blueAccent),
                          const SizedBox(width: 12),
                          _sum(_count('Cancelled').toString(), L.cancelled, Colors.redAccent),
                        ]),
                        const SizedBox(height: 20),
                        // Bookings
                        ..._bookings.map((b) {
                          final status = b['status'] as String;
                          final color  = _statusColor(status);
                          final station = b['station'];
                          final stName  = station is Map ? station['name'] : 'Unknown Station';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: kCardDeco(),
                            child: Row(children: [
                              Container(width: 46, height: 46,
                                  decoration: BoxDecoration(color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Icon(Icons.ev_station, color: color, size: 24)),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(stName, style: kTitle(13)),
                                Text('${b['date']}  ${b['time']}', style: kSub(12)),
                                if (station is Map && station['power'] != null)
                                  Text(station['power'] as String,
                                      style: const TextStyle(color: kGreen, fontSize: 11, fontWeight: FontWeight.w600)),
                              ])),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text(_localStatus(status),
                                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))),
                                if (status == 'Upcoming') ...[
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => _confirmCancel(b['_id'] as String),
                                    child: const Text('Cancel',
                                        style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600))),
                                ],
                              ]),
                            ]));
                        }),
                      ],
                    ),
            ),
    );
  }

  void _confirmCancel(String id) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: cCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Cancel Booking?', style: TextStyle(color: cTitle, fontWeight: FontWeight.w800)),
      content: Text('You will be refunded 5 NIS.', style: kSub(13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Keep', style: TextStyle(color: cSub))),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); _cancel(id); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.w700))),
      ]));
  }

  Widget _emptyView() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.calendar_today_outlined, color: cSub2, size: 64),
    const SizedBox(height: 16),
    Text('No bookings yet', style: kTitle(18)),
    const SizedBox(height: 8),
    Text('Book a charging station to get started', style: kSub(14)),
    const SizedBox(height: 24),
    ElevatedButton.icon(
      onPressed: () => goTo(context, AllStationsScreen()),
      icon: const Icon(Icons.add),
      label: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.w800)),
      style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
  ]));

  Widget _sum(String c, String l, Color col) => Expanded(
    child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: col.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: col.withOpacity(0.25))),
      child: Column(children: [
        Text(c, style: TextStyle(color: col, fontSize: 20, fontWeight: FontWeight.w800)),
        Text(l, style: TextStyle(color: col.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600)),
      ])));
}
