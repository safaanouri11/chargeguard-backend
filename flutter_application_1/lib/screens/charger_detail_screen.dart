import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/app_settings.dart';
import '../utils/api_service.dart';
import 'booking_form_screen.dart';

Color _connColor(String? c) {
  switch (c?.toUpperCase()) {
    case 'CCS2':    return const Color(0xFF00E5A0);
    case 'CCS1':    return const Color(0xFF00C9E0);
    case 'TYPE 2':  return const Color(0xFF4A90E2);
    case 'CHADEMO': return const Color(0xFFFF6B35);
    case 'GB/T':    return const Color(0xFFB44FE8);
    case 'NACS':    return const Color(0xFFE8334F);
    case 'AC':      return const Color(0xFFFFD93D);
    default:        return const Color(0xFF00E5A0);
  }
}

class ChargerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> station;
  const ChargerDetailScreen(this.station, {super.key});
  @override
  State<ChargerDetailScreen> createState() => _ChargerDetailScreenState();
}

class _ChargerDetailScreenState extends State<ChargerDetailScreen> {
  Map<String, dynamic> get station => widget.station;

  @override
  void initState() {
    super.initState();
    final id = station['_id'] as String?;
    if (id != null && id.isNotEmpty) {
      ApiService.instance.trackStationView(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name        = station['name']      as String? ?? 'Station';
    final power       = station['power']     as String? ?? '22 kW';
    final conn        = station['connector'] as String? ?? 'CCS2';
    final price       = station['price']?.toString() ?? '2.5';
    final occupancy   = (station['occupancy'] as String?) ??
        ((station['available'] as bool? ?? true) ? 'free' : 'busy');
    final ok          = occupancy == 'free';
    final isOffline   = occupancy == 'offline';
    final addr        = (station['location'] as Map?)?['address'] as String? ?? '';
    final rating      = (station['rating'] as num?)?.toDouble() ?? 5.0;
    final networkName = station['network'] as String? ?? 'Independent';
    final status      = station['status'] as String? ?? 'Active';
    final plugCount   = (station['plugCount'] as num?)?.toInt() ?? 1;
    final amenities   = (station['amenities'] as List? ?? []).map((e) => e.toString()).toList();
    final parking     = (station['parking']   as List? ?? []).map((e) => e.toString()).toList();
    final network     = networkInfo(networkName);
    final connColor   = _connColor(conn);
    final isComingSoon = status == 'Coming Soon';
    final statusColor  = isComingSoon
        ? Colors.grey
        : (isOffline ? Colors.grey : (ok ? kGreen : Colors.redAccent));
    final statusLabel  = isComingSoon
        ? 'Coming Soon'
        : (isOffline ? 'Offline' : (ok ? 'Available' : 'In Use'));

    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar(name, context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Station header card ──────────────────────────
          Container(padding: const EdgeInsets.all(16), decoration: kCardDeco(),
            child: Row(children: [
              // Connector icon with color
              Container(width: 60, height: 60,
                decoration: BoxDecoration(
                    color: isComingSoon ? Colors.grey.withOpacity(0.15) : connColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isComingSoon ? Colors.grey.withOpacity(0.4) : connColor.withOpacity(0.5))),
                child: Icon(Icons.ev_station,
                    color: isComingSoon ? Colors.grey : connColor, size: 30)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: kTitle(16)),
                const SizedBox(height: 6),
                // Network badge (شعار الشركة)
                _networkBadge(network),
                const SizedBox(height: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor,
                        fontSize: 11, fontWeight: FontWeight.w700))),
              ])),
            ])),
          const SizedBox(height: 16),

          // ── Address ───────────────────────────────────────
          if (addr.isNotEmpty)
            Container(padding: const EdgeInsets.all(12),
              decoration: kCardDeco(radius: 12),
              child: Row(children: [
                const Icon(Icons.location_on, color: kGreen, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(addr, style: kSub(13))),
              ])),
          const SizedBox(height: 12),

          // ── Rating ────────────────────────────────────────
          Container(padding: const EdgeInsets.all(12),
            decoration: kCardDeco(radius: 12),
            child: Row(children: [
              ...List.generate(5, (i) => Icon(
                i < rating.round() ? Icons.star : Icons.star_border,
                color: Colors.amber, size: 18)),
              const SizedBox(width: 8),
              Text(rating.toStringAsFixed(1), style: kTitle(14)),
              const Spacer(),
              Text('Station Rating', style: kSub(12)),
            ])),
          const SizedBox(height: 20),

          // ── Info grid ─────────────────────────────────────
          Row(children: [
            _info(connColor, '🔌', 'Connector', conn),
            _info(connColor, '⚡', 'Power',     power),
            _info(connColor, '💰', 'Price',     '$price NIS'),
            _info(connColor, '🔢', 'Plugs',     '$plugCount'),
          ]),
          const SizedBox(height: 20),

          // ── Amenities ─────────────────────────────────────
          if (amenities.isNotEmpty) ...[
            Text('Amenities', style: kTitle(15)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: amenities.map((a) =>
              _chip(a, Colors.purpleAccent)).toList()),
            const SizedBox(height: 16),
          ],

          // ── Parking ───────────────────────────────────────
          if (parking.isNotEmpty) ...[
            Text('Parking', style: kTitle(15)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: parking.map((p) =>
              _chip(p, Colors.orange)).toList()),
            const SizedBox(height: 16),
          ],

          // ── About ─────────────────────────────────────────
          Text('About', style: kTitle(15)),
          const SizedBox(height: 8),
          Text('$name is a ${network.name} charging station '
              'with $power output and $conn connector. '
              'Price: $price NIS/kWh. '
              '${isComingSoon ? "Opening soon." : (isOffline ? "Currently offline." : (ok ? "Currently available." : "Currently in use."))}',
              style: kSub(13)),
          const SizedBox(height: 24),

          // ── Reviews ───────────────────────────────────────
          _ReviewsSection(stationId: station['_id'] as String? ?? '',
              stationName: name),
          const SizedBox(height: 24),

          // ── Book button ───────────────────────────────────
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: (ok && !isComingSoon && !isOffline)
                  ? () => goTo(context, BookingFormScreen(station: station))
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                disabledBackgroundColor: Colors.grey.withOpacity(0.2),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text(
                isComingSoon ? 'Coming Soon' : (isOffline ? 'Offline' : (ok ? 'Book Now' : 'In Use')),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)))),
        ]),
      ),
    );
  }

  // شعار الشركة
  Widget _networkBadge(EVNetwork network) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: network.color, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        // Logo: colored letter badge
        Container(width: 18, height: 18,
          decoration: BoxDecoration(
              color: network.textColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4)),
          child: Center(child: Text(network.abbr.substring(0, 1),
              style: TextStyle(color: network.textColor,
                  fontSize: 10, fontWeight: FontWeight.w900)))),
        const SizedBox(width: 6),
        Text(network.name,
            style: TextStyle(color: network.textColor,
                fontSize: 11, fontWeight: FontWeight.w800)),
      ])),
  ]);

  Widget _info(Color connColor, String e, String label, String val) => Expanded(
    child: Container(margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: kCardDeco(radius: 12),
      child: Column(children: [
        Text(e, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 6),
        Text(val, style: kTitle(11), textAlign: TextAlign.center),
        Text(label, style: kSub(10)),
      ])));

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3))),
    child: Text(text, style: TextStyle(color: color,
        fontSize: 12, fontWeight: FontWeight.w600)));
}

// ─────────────────────────────────────────────────────────
//  REVIEWS SECTION
// ─────────────────────────────────────────────────────────
class _ReviewsSection extends StatefulWidget {
  final String stationId;
  final String stationName;
  const _ReviewsSection({required this.stationId, required this.stationName});
  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  List _reviews = [];
  double _avg = 0;
  int _count = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.stationId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final res = await ApiService.instance.getStationReviews(widget.stationId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success']) {
        final data = res['data'] as Map<String, dynamic>;
        _reviews = (data['reviews'] as List?) ?? [];
        _avg     = (data['avgRating'] as num?)?.toDouble() ?? 0;
        _count   = (data['count']     as num?)?.toInt()    ?? 0;
      }
    });
  }

  Future<void> _showAddReviewDialog() async {
    double rating = 5;
    final ctrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: cBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Rate ${widget.stationName}', style: kTitle(15)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children:
              List.generate(5, (i) {
                final filled = (i + 1) <= rating;
                return GestureDetector(
                  onTap: () => setS(() => rating = (i + 1).toDouble()),
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(filled ? Icons.star : Icons.star_border,
                        color: Colors.amber, size: 36)),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl, maxLines: 3, maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Share your experience (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen, foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      final res = await ApiService.instance.submitReview(
        stationId: widget.stationId,
        rating: rating,
        comment: ctrl.text.trim(),
      );
      if (!mounted) return;
      if (res['success']) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Review submitted ✅'), backgroundColor: kGreen,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] as String? ?? 'Failed'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(padding: const EdgeInsets.all(20), decoration: kCardDeco(),
        child: const Center(child: CircularProgressIndicator(color: kGreen)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Reviews', style: kTitle(15)),
        const SizedBox(width: 8),
        if (_count > 0) Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: kGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Text('$_count', style: const TextStyle(
              color: kGreen, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _showAddReviewDialog,
          icon: const Icon(Icons.rate_review_outlined, size: 16, color: kGreen),
          label: const Text('Write', style: TextStyle(color: kGreen)),
        ),
      ]),
      const SizedBox(height: 8),
      if (_reviews.isEmpty)
        Container(padding: const EdgeInsets.all(20), decoration: kCardDeco(),
          child: Center(child: Column(children: [
            Icon(Icons.star_border, color: cSub2, size: 36),
            const SizedBox(height: 8),
            Text('No reviews yet — be the first!', style: kSub(13)),
          ])))
      else ...[
        Container(padding: const EdgeInsets.all(14), decoration: kCardDeco(),
          child: Row(children: [
            Text(_avg.toStringAsFixed(1), style: kTitle(28).copyWith(color: kGreen)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: List.generate(5, (i) => Icon(
                i < _avg.round() ? Icons.star : Icons.star_border,
                color: Colors.amber, size: 16,
              ))),
              const SizedBox(height: 2),
              Text('Based on $_count review${_count == 1 ? '' : 's'}',
                  style: kSub(11)),
            ]),
          ]),
        ),
        const SizedBox(height: 10),
        ..._reviews.take(5).map((r) => _reviewCard(r as Map<String, dynamic>)),
        if (_reviews.length > 5) Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('+ ${_reviews.length - 5} more', style: kSub(11)),
        ),
      ],
    ]);
  }

  Widget _reviewCard(Map<String, dynamic> r) {
    final user    = r['user'] is Map ? r['user'] as Map<String, dynamic> : null;
    final name    = user != null
        ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim()
        : 'User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final rating  = (r['rating'] as num?)?.toDouble() ?? 0;
    final comment = r['comment'] as String? ?? '';
    final when    = r['createdAt'] as String?;
    final dt      = when != null ? DateTime.tryParse(when) : null;
    final dateStr = dt != null
        ? '${dt.day}/${dt.month}/${dt.year}'
        : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: kCardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 16, backgroundColor: kGreen.withOpacity(0.2),
            child: Text(initial,
                style: const TextStyle(
                    color: kGreen, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: kTitle(13))),
          Row(children: List.generate(5, (i) => Icon(
            i < rating.round() ? Icons.star : Icons.star_border,
            color: Colors.amber, size: 14,
          ))),
        ]),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(comment, style: kSub(12)),
        ],
        if (dateStr.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(dateStr, style: TextStyle(color: cSub2, fontSize: 10)),
        ],
      ]),
    );
  }
}
