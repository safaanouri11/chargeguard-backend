import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/app_settings.dart';
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

class ChargerDetailScreen extends StatelessWidget {
  final Map<String, dynamic> station;
  const ChargerDetailScreen(this.station, {super.key});

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
          const SizedBox(height: 28),

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
