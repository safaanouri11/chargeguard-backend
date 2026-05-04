import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/app_settings.dart';
import '../utils/api_service.dart';
import 'notifications_screen.dart';
import 'charger_detail_screen.dart';
import 'all_stations_screen.dart';
import 'map_screen.dart';
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
  bool get _isCharging    => UserSession.instance.isCharging;
  int  get _chargePercent => UserSession.instance.batteryPct;
  int  get _minutesLeft   => 23;

  List<dynamic> _stations      = [];
  List<dynamic> _recentBookings = [];
  bool _loadingStations = true;
  bool _loadingBookings = true;
  bool _usingLocation   = false; // true if list is sorted by distance

  Map<String, dynamic>? _aiRecommendation;
  bool _loadingAI = true;

  int    _statSessions = 0;
  double _statKwh      = 0;
  bool   _loadingStats = true;

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_refresh);
    UserSession.instance.addListener(_refresh);
    _loadStations();
    _loadAI();
    _loadBookings();
    _loadStats();
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_refresh);
    UserSession.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload bookings when returning from other screens
    if (!_loadingBookings) _loadBookings();
  }

  Future<void> _loadStations() async {
    // Try location-based nearby first; fall back to all stations on denial/failure.
    final pos = await ApiService.instance.getCurrentPosition();
    if (pos != null) {
      final nearby = await ApiService.instance.getNearbyStations(
        lat: pos['lat']!, lng: pos['lng']!, radius: 25,
      );
      if (mounted && nearby['success']) {
        final data = nearby['data'] as Map<String, dynamic>;
        setState(() {
          _loadingStations = false;
          _usingLocation   = true;
          _stations        = (data['results'] as List?) ?? [];
        });
        return;
      }
    }
    final result = await ApiService.instance.getStations();
    if (mounted) {
      setState(() {
        _loadingStations = false;
        _usingLocation   = false;
        _stations        = result['success'] ? (result['data'] as List) : [];
      });
    }
  }

  Future<void> _loadBookings() async {
    final result = await ApiService.instance.getBookings();
    if (mounted) {
      setState(() {
        _loadingBookings  = false;
        _recentBookings   = result['success'] ? (result['data'] as List).take(2).toList() : [];
      });
    }
  }

  Future<void> _loadStats() async {
    final result = await ApiService.instance.getStats();
    if (mounted) {
      setState(() {
        _loadingStats = false;
        if (result['success']) {
          _statSessions = (result['data']['sessions'] as num?)?.toInt() ?? 0;
          _statKwh      = (result['data']['totalKwh'] as num?)?.toDouble() ?? 0;
        }
      });
    }
  }

  Future<void> _loadAI() async {
    final result = await ApiService.instance.getRecommendation();
    if (mounted) {
      setState(() {
        _loadingAI = false;
        _aiRecommendation = result['success']
            ? result['data']['recommendation'] as Map<String, dynamic>?
            : null;
      });
    }
  }

  static const _promos = [
    {'title': 'First Charge Free! ⚡', 'sub': 'New users get 1 free session',  'color': 0xFF00E5A0},
    {'title': '20% Off This Weekend',  'sub': 'Use code: CHARGE20',             'color': 0xFF6C63FF},
    {'title': 'Refer & Earn 🎁',       'sub': 'Invite friends, get free kWh',   'color': 0xFFFF6B6B},
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
              _actionBtn(context, Icons.map_outlined,            L.findCharger,  true,  const MapScreen()),
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
            if (_loadingStations)
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: kGreen, strokeWidth: 2)))
            else if (_stations.isEmpty)
              Container(padding: const EdgeInsets.all(20), decoration: kCardDeco(),
                child: Center(child: Text('No stations found', style: kSub(13))))
            else
              ..._stations.take(3).map((s) => _stationCard(context, s as Map<String, dynamic>)),
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
        Text('${L.welcome}, ${UserSession.instance.firstName.isNotEmpty ? UserSession.instance.firstName : 'User'}! 👋', style: kTitle(20)),
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
  Widget _activeSession() {
    final session = UserSession.instance;
    final secs    = session.chargeSecs;
    final m       = secs ~/ 60;
    final s       = secs % 60;
    final timeStr = m > 0 ? '${m}m ${s}s' : '${s}s';

    return GestureDetector(
      onTap: () => goTo(context, StartChargeScreen()),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [kGreen.withOpacity(0.9), const Color(0xFF00B37A)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: kGreen.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))]),
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
              ])),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: const Text('Tap to manage',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
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
              Text('$timeStr · ${session.chargeName}',
                  style: TextStyle(color: Colors.black.withOpacity(0.65), fontSize: 11)),
            ])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _ss('⚡', timeStr, 'Duration'),
            Container(width: 1, height: 30, color: Colors.black.withOpacity(0.15)),
            _ss('🔋', '${session.chargeKwh.toStringAsFixed(2)} kWh', 'Added'),
            Container(width: 1, height: 30, color: Colors.black.withOpacity(0.15)),
            _ss('💰', '${session.chargeCost.toStringAsFixed(2)} NIS', 'Cost'),
          ]),
        ])));
  }

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
    _chip(ctx, '$_statSessions', 'Sessions', Icons.bolt, HistoryScreen()),
    const SizedBox(width: 10),
    _chip(ctx, '${_statKwh.toStringAsFixed(1)} kWh', 'Charged', Icons.battery_charging_full, HistoryScreen()),
    const SizedBox(width: 10),
    _chip(ctx, '${UserSession.instance.points} pts', 'Points ⭐', Icons.eco, EcoStatsScreen()),
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
  Widget _recommendation(BuildContext ctx) {
    if (_loadingAI) {
      return Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kGreen.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16), border: Border.all(color: kGreen.withOpacity(0.25))),
        child: Row(children: [
          const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(color: kGreen, strokeWidth: 2)),
          const SizedBox(width: 14),
          Text('Finding best station for you...', style: kSub(13)),
        ]));
    }

    if (_aiRecommendation == null) {
      return Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kGreen.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16), border: Border.all(color: kGreen.withOpacity(0.25))),
        child: Row(children: [
          const Icon(Icons.auto_awesome, color: kGreen, size: 22), const SizedBox(width: 14),
          Expanded(child: Text('No available stations right now', style: kSub(12))),
        ]));
    }

    final rec = _aiRecommendation!;
    return GestureDetector(
      onTap: () => goTo(ctx, ChargerDetailScreen(rec)),
      child: Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kGreen.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16), border: Border.all(color: kGreen.withOpacity(0.25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 42, height: 42,
                decoration: BoxDecoration(color: kGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.auto_awesome, color: kGreen, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🤖 AI Smart Recommendation',
                  style: TextStyle(color: kGreen, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(rec['name'] as String, style: kTitle(14)),
            ])),
            const Icon(Icons.arrow_forward_ios, color: kGreen, size: 14),
          ]),
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(rec['reason'] as String? ?? 'Best match for you',
                style: const TextStyle(color: kGreen, fontSize: 11))),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.bolt, size: 12, color: cSub2),
            Text(' ${rec['power']}', style: kSub(11)),
            const SizedBox(width: 12),
            Icon(Icons.electrical_services, size: 12, color: cSub2),
            Text(' ${rec['connector']}', style: kSub(11)),
            const SizedBox(width: 12),
            Icon(Icons.attach_money, size: 12, color: cSub2),
            Text(' ${rec['price']} NIS/kWh', style: kSub(11)),
          ]),
        ])));
  }

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
    onTap: () => goTo(ctx, const MapScreen()),
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
  Widget _recentSection(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(L.recentBook, style: kTitle(16)),
          GestureDetector(onTap: () => goTo(ctx, BookingsScreen()),
            child: Text(L.viewAll,
                style: const TextStyle(color: kGreen, fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 12),
        if (_loadingBookings)
          const Center(child: Padding(padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: kGreen, strokeWidth: 2)))
        else if (_recentBookings.isEmpty)
          Container(padding: const EdgeInsets.all(16), decoration: kCardDeco(),
            child: Row(children: [
              Icon(Icons.calendar_today_outlined, color: cSub2, size: 20),
              const SizedBox(width: 12),
              Text('No recent bookings', style: kSub(13)),
            ]))
        else
          ..._recentBookings.map((b) {
            final status  = b['status'] as String? ?? 'Upcoming';
            final station = b['station'];
            final stName  = station is Map ? station['name'] as String : 'Station';
            final color   = status == 'Upcoming' ? kGreen
                : status == 'Completed' ? Colors.blueAccent : Colors.redAccent;
            return GestureDetector(
              onTap: () => goTo(ctx, BookingsScreen()),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: kCardDeco(radius: 14),
                child: Row(children: [
                  Container(width: 42, height: 42,
                      decoration: BoxDecoration(color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.ev_station, color: color, size: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(stName, style: kTitle(13)),
                    Text('${b['date']}  ${b['time']}', style: kSub(11)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(status,
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))),
                ])));
          }),
      ],
    );
  }

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
    final ok = s['available'] as bool? ?? true;
    final name  = s['name'] as String? ?? 'Station';
    final power = s['power'] as String? ?? '22 kW';
    final price = '${s['price']?.toString() ?? '2.5'} NIS';
    final distanceKm = (s['distanceKm'] as num?)?.toDouble();
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
            Text(name, style: kTitle(13)),
            Row(children: [
              Icon(Icons.bolt, size: 12, color: cSub2),
              Text(' $power', style: kSub(12)), const SizedBox(width: 8),
              Icon(Icons.attach_money, size: 12, color: cSub2),
              Text(price, style: kSub(12)),
              if (distanceKm != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.place_outlined, size: 12, color: cSub2),
                Text(' ${distanceKm.toStringAsFixed(1)} km', style: kSub(12)),
              ],
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
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