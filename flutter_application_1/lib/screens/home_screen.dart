import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/app_settings.dart';
import 'notifications_screen.dart';
import 'charger_detail_screen.dart';
import 'all_stations_screen.dart';
import 'bookings_screen.dart';
import 'history_screen.dart';
import 'start_charge_screen.dart';
import 'eco_stats_screen.dart';
import 'promo_detail_screen.dart';
import 'booking_detail_screen.dart';
import 'offers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isCharging    = true;
  int  _chargePercent = 65;
  int  _minutesLeft   = 23;

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  static const _stations = [
    {'name': 'An-Najah EV Station', 'dist': '1.2 km', 'ok': true,  'price': '2.5 NIS', 'kw': '50 kW'},
    {'name': 'City Mall Charger',   'dist': '2.5 km', 'ok': false, 'price': '1.8 NIS', 'kw': '22 kW'},
    {'name': 'Campus Green Charger','dist': '3.1 km', 'ok': true,  'price': '1.5 NIS', 'kw': 'AC'},
  ];

  static const _promos = [
    {'title': 'First Charge Free! ⚡', 'sub': 'New users get 1 free session',  'color': 0xFF00E5A0},
    {'title': '20% Off This Weekend',  'sub': 'Use code: CHARGE20',             'color': 0xFF6C63FF},
    {'title': 'Refer & Earn 🎁',       'sub': 'Invite friends, get free kWh',   'color': 0xFFFF6B6B},
  ];

  static const _recentBookings = [
    {'station': 'An-Najah EV Station', 'date': 'Today, 3:00 PM',      'status': 'Upcoming',  'color': 0xFF00E5A0},
    {'station': 'Campus Green Charger','date': 'Yesterday, 11:00 AM', 'status': 'Completed', 'color': 0xFF6C9EFF},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _header(context),             const SizedBox(height: 20),
            if (_isCharging) ...[_activeSession(), const SizedBox(height: 20)]
            else             ...[_batteryCard(),   const SizedBox(height: 20)],
            _quickStats(context),         const SizedBox(height: 20),
            _recommendation(context),     const SizedBox(height: 20),
            Text(L.quickActions, style: kTitle(16)),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _actionBtn(context, Icons.map_outlined,            L.findCharger,  true,  AllStationsScreen()),
              _actionBtn(context, Icons.calendar_today_outlined, L.myBookings,   false, BookingsScreen()),
              _actionBtn(context, Icons.bolt_outlined,           L.startCharge,  false, StartChargeScreen()),
              _actionBtn(context, Icons.history_outlined,        L.history,      false, HistoryScreen()),
            ]),
            const SizedBox(height: 20),
            _promoSection(context),       const SizedBox(height: 20),
            _miniMap(context),            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(L.nearestSt, style: kTitle(16)),
              GestureDetector(
                onTap: () => goTo(context, AllStationsScreen()),
                child: Text(L.seeAll,
                    style: const TextStyle(color: kGreen, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 14),
            ..._stations.map((s) => _stationCard(context, s)),
            const SizedBox(height: 20),
            _recentSection(context),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _header(BuildContext ctx) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(L.welcome, style: kTitle(22)),
        const SizedBox(height: 4),
        Text('ChargeGuard ${L.dashboard}', style: kSub(13)),
      ]),
      GestureDetector(
        onTap: () => goTo(ctx, NotificationsScreen()),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cBorder)),
          child: Stack(children: [
            Icon(Icons.notifications_outlined, color: cTitle, size: 24),
            Positioned(right: 0, top: 0,
              child: Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle))),
          ]),
        ),
      ),
    ],
  );

  // ── Active Session ────────────────────────────────────────
  Widget _activeSession() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
          colors: [kGreen.withOpacity(0.9), const Color(0xFF00B37A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: kGreen.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            const Icon(Icons.circle, color: Colors.white, size: 8), const SizedBox(width: 6),
            Text(L.chargingNow,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => setState(() => _isCharging = false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(L.stop,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('$_chargePercent%',
            style: const TextStyle(color: Colors.black, fontSize: 52, fontWeight: FontWeight.w900, height: 1)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: _chargePercent / 100,
              backgroundColor: Colors.black.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.black), minHeight: 10)),
          const SizedBox(height: 6),
          Text('$_minutesLeft min remaining · An-Najah EV',
              style: TextStyle(color: Colors.black.withOpacity(0.65), fontSize: 11)),
        ])),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        _ss('⚡', '22 kW', 'Power'),
        Container(width: 1, height: 30, color: Colors.black.withOpacity(0.15)),
        _ss('🔋', '14.3 kWh', 'Added'),
        Container(width: 1, height: 30, color: Colors.black.withOpacity(0.15)),
        _ss('💰', '2.5 NIS', 'Per kWh'),
      ]),
    ]),
  );

  Widget _ss(String e, String v, String l) => Expanded(
    child: Column(children: [
      Text('$e $v', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13)),
      Text(l, style: TextStyle(color: Colors.black.withOpacity(0.55), fontSize: 11)),
    ]),
  );

  // ── Battery Card ──────────────────────────────────────────
  Widget _batteryCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [Color(0xFF00E5A0), Color(0xFF00B37A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(L.batteryStatus,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 16)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
          child: const Row(children: [
            Icon(Icons.access_time, size: 13, color: Colors.black87), SizedBox(width: 4),
            Text('40 min left', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
          ])),
      ]),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('$_chargePercent%',
            style: const TextStyle(color: Colors.black, fontSize: 48, fontWeight: FontWeight.w900, height: 1)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: _chargePercent / 100,
              backgroundColor: Colors.black.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.black), minHeight: 10)),
          const SizedBox(height: 6),
          Text('Estimated range: ~210 km',
              style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 12)),
        ])),
      ]),
    ]),
  );

  // ── Quick Stats ───────────────────────────────────────────
  Widget _quickStats(BuildContext ctx) => Row(children: [
    _chip(ctx, '12',     'Sessions',     Icons.bolt,                  HistoryScreen()),
    const SizedBox(width: 10),
    _chip(ctx, '340 kWh','Charged',      Icons.battery_charging_full, HistoryScreen()),
    const SizedBox(width: 10),
    _chip(ctx, '85 kg',  'CO₂ Saved ♻️', Icons.eco,                  EcoStatsScreen()),
  ]);

  Widget _chip(BuildContext ctx, String val, String label, IconData icon, Widget page) =>
    Expanded(child: GestureDetector(onTap: () => goTo(ctx, page),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: kCardDeco(radius: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: kGreen, size: 18), const SizedBox(height: 8),
          Text(val, style: kTitle(14)),
          Text(label, style: kSub(10), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]))));

  // ── Recommendation ────────────────────────────────────────
  Widget _recommendation(BuildContext ctx) => GestureDetector(
    onTap: () => goTo(ctx, ChargerDetailScreen({
      'name': 'An-Najah EV Station',
      'power': '50 kW',
      'connector': 'CCS2',
      'price': 2.5,
      'available': true,
      'location': {'address': 'An-Najah University, Nablus'},
      'rating': 4.8,
    })),
    child: Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kGreen.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16), border: Border.all(color: kGreen.withOpacity(0.25))),
      child: Row(children: [
        Container(width: 42, height: 42,
            decoration: BoxDecoration(color: kGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.auto_awesome, color: kGreen, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Smart Recommendation',
              style: TextStyle(color: kGreen, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('An-Najah EV Station is available — your favorite!', style: kSub(12), maxLines: 2),
        ])),
        const Icon(Icons.arrow_forward_ios, color: kGreen, size: 14),
      ])),
  );

  // ── Promos ────────────────────────────────────────────────
  Widget _promoSection(BuildContext ctx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${L.offers} 🎉', style: kTitle(16)),
        GestureDetector(onTap: () => goTo(ctx, OffersScreen()),
          child: Text(L.seeAll, style: const TextStyle(color: kGreen, fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 12),
      SizedBox(height: 110,
        child: ListView.separated(scrollDirection: Axis.horizontal,
          itemCount: _promos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final p     = _promos[i];
            final color = Color(p['color'] as int);
            return GestureDetector(onTap: () => goTo(ctx, OffersScreen()),
              child: Container(width: 220, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p['title'] as String,
                      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(p['sub'] as String, style: TextStyle(color: cSub, fontSize: 12)),
                  const Spacer(),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text('Claim Now', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))),
                ])));
          })),
    ],
  );

  // ── Mini Map ──────────────────────────────────────────────
  Widget _miniMap(BuildContext ctx) => GestureDetector(
    onTap: () => goTo(ctx, AllStationsScreen()),
    child: Container(height: 130,
      decoration: BoxDecoration(color: AppSettings.instance.isDark ? const Color(0xFF0D1421) : const Color(0xFFEEF2F7),
          borderRadius: BorderRadius.circular(16), border: Border.all(color: cBorder)),
      child: Stack(children: [
        ClipRRect(borderRadius: BorderRadius.circular(16),
            child: Center(child: Icon(Icons.map, color: kGreen.withOpacity(0.15), size: 80))),
        Positioned(top: 35, left: 80,  child: _pin(kGreen)),
        Positioned(top: 55, left: 160, child: _pin(Colors.redAccent)),
        Positioned(top: 25, right: 60, child: _pin(kGreen)),
        Positioned(bottom: 0, left: 0, right: 0,
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: cCard.withOpacity(0.97),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: cBorder))),
            child: Row(children: [
              const Icon(Icons.location_on, color: kGreen, size: 16), const SizedBox(width: 6),
              Text('2 stations nearby', style: kSub(12)), const Spacer(),
              Text('Open Map', style: const TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w700)),
              const Icon(Icons.arrow_forward_ios, color: kGreen, size: 12),
            ]))),
      ])),
  );

  Widget _pin(Color c) => Container(width: 20, height: 20,
    decoration: BoxDecoration(color: c.withOpacity(0.2), shape: BoxShape.circle,
        border: Border.all(color: c, width: 1.5)),
    child: Icon(Icons.ev_station, color: c, size: 10));

  // ── Recent Bookings ───────────────────────────────────────
  Widget _recentSection(BuildContext ctx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(L.recentBook, style: kTitle(16)),
        GestureDetector(onTap: () => goTo(ctx, BookingsScreen()),
          child: Text(L.viewAll, style: const TextStyle(color: kGreen, fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 12),
      ..._recentBookings.map((b) {
        final color = Color(b['color'] as int);
        return GestureDetector(onTap: () => goTo(ctx, BookingDetailScreen(b)),
          child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
            decoration: kCardDeco(radius: 14),
            child: Row(children: [
              Container(width: 42, height: 42,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.ev_station, color: color, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b['station'] as String, style: kTitle(13)),
                Text(b['date'] as String, style: kSub(11)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(b['status'] as String,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))),
            ])));
      }),
    ],
  );

  // ── Helpers ───────────────────────────────────────────────
  Widget _actionBtn(BuildContext ctx, IconData icon, String label, bool hl, Widget page) =>
    GestureDetector(onTap: () => goTo(ctx, page),
      child: Container(width: 76, padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: hl ? kGreen.withOpacity(0.12) : cCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: hl ? kGreen.withOpacity(0.4) : cBorder)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: hl ? kGreen : cSub, size: 26), const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(color: hl ? kGreen : cSub,
                  fontSize: 11, fontWeight: FontWeight.w600, height: 1.3)),
        ])));

  Widget _stationCard(BuildContext ctx, Map<String, dynamic> s) {
    final ok = s['ok'] as bool;
    return GestureDetector(onTap: () => goTo(ctx, ChargerDetailScreen(s)),
      child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
        decoration: kCardDeco(),
        child: Row(children: [
          Container(width: 46, height: 46,
              decoration: BoxDecoration(color: ok ? kGreen.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.ev_station, color: ok ? kGreen : Colors.redAccent, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s['name'] as String, style: kTitle(13)),
            Row(children: [
              Icon(Icons.bolt, size: 12, color: cSub2),
              Text(' ${s['kw']}', style: kSub(12)), const SizedBox(width: 8),
              Icon(Icons.attach_money, size: 12, color: cSub2),
              Text(s['price'] as String, style: kSub(12)),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(s['dist'] as String, style: kTitle(13)), const SizedBox(height: 4),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: ok ? kGreen.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(ok ? L.available : L.busy,
                  style: TextStyle(color: ok ? kGreen : Colors.redAccent,
                      fontSize: 11, fontWeight: FontWeight.w700))),
          ]),
        ])));
  }
}
