import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import 'host_profile_screen.dart';
import 'host_payouts_screen.dart';
import 'host_reviews_screen.dart';
import 'host_add_charger_screen.dart';
import 'host_settings_screen.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({super.key});
  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  Map<String, dynamic> _stats    = {};
  List<dynamic>        _stations = [];
  List<dynamic>        _bookings = [];
  List<dynamic>        _daily    = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    // Check role
    if (UserSession.instance.role != 'host') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
      return;
    }
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.instance.getHostProfile(),   // ← يجلب أحدث بيانات الهوست
      ApiService.instance.getHostStats(),
      ApiService.instance.getHostStations(),
      ApiService.instance.getHostBookings(),
      ApiService.instance.getHostAnalytics(),
    ]);
    if (mounted) {
      setState(() {
        _loading  = false;
        _stats    = results[1]['success'] ? results[1]['data'] as Map<String, dynamic> : {};
        _stations = results[2]['success'] ? results[2]['data'] as List : [];
        _bookings = results[3]['success'] ? results[3]['data'] as List : [];
        _daily    = results[4]['success'] ? (results[4]['data']['daily'] as List? ?? []) : [];
      });
    }
  }

  void _snack(String msg, {bool isError = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? kRed : cCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg, elevation: 0,
        title: Text('Host Dashboard', style: kTitle(18)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: kGreen), onPressed: _loadAll),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: kGreen),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HostSettingsScreen())).then((_) => _loadAll()),
            tooltip: 'Settings'),
          IconButton(
            icon: const Icon(Icons.directions_car, color: kGreen),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            tooltip: 'Switch to Driver'),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cBorder)),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black,
              unselectedLabelColor: cSub,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              dividerColor: Colors.transparent,
              tabs: const [Tab(text: '📊 Overview'), Tab(text: '⚡ Chargers'), Tab(text: '📋 Bookings'), Tab(text: '📈 Analytics')],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : TabBarView(controller: _tabCtrl, children: [
              _buildOverview(),
              _buildChargers(),
              _buildBookings(),
              _buildAnalytics(),
            ]),
    );
  }

  // ── Overview ──────────────────────────────────────────────
  Widget _buildOverview() {
    final earnings  = (_stats['totalEarnings'] as num?)?.toDouble() ?? 0;
    final today     = (_stats['bookingsToday'] as num?)?.toInt() ?? 0;
    final active    = (_stats['activeChargers'] as num?)?.toInt() ?? 0;
    final total     = (_stats['totalBookings'] as num?)?.toInt() ?? 0;
    final rating    = (_stats['avgRating'] as num?)?.toDouble() ?? 0;
    final reviews   = (_stats['totalReviews'] as num?)?.toInt() ?? 0;

    return RefreshIndicator(color: kGreen, onRefresh: _loadAll,
      child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Earnings Card
          Container(width: double.infinity, padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00E5A0), Color(0xFF00B37A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Earnings',
                  style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('NIS ${earnings.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.black, fontSize: 38, fontWeight: FontWeight.w900, height: 1)),
              const SizedBox(height: 4),
              Text('From $total bookings total',
                  style: TextStyle(color: Colors.black.withOpacity(0.55), fontSize: 13)),
            ])),
          const SizedBox(height: 20),

          // Stats row
          Row(children: [
            _stat('$today',  'Bookings\nToday'),
            const SizedBox(width: 12),
            _stat('$active', 'Active\nChargers'),
            const SizedBox(width: 12),
            _stat(rating > 0 ? '${rating.toStringAsFixed(1)}⭐' : '—', 'Avg\nRating'),
          ]),
          const SizedBox(height: 24),

          Text('Quick Actions', style: kTitle(16)),
          const SizedBox(height: 14),
          _action(Icons.person_outline, 'Host Profile', 'Edit business info and banking',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HostProfileScreen()))),
          _action(Icons.account_balance_wallet_outlined, 'Payouts', 'Withdraw your earnings',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HostPayoutsScreen()))),
          _action(Icons.star_outline, 'Reviews', 'See what customers say',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HostReviewsScreen()))),
          _action(Icons.add_circle_outline, 'Add New Charger', 'Register a new charging station',
              () => _showAddStation()),
          _action(Icons.power_settings_new, 'Manage Chargers', '${_stations.length} stations registered',
              () => _tabCtrl.animateTo(1)),
          _action(Icons.inbox_outlined, 'Booking Requests', '$total total bookings',
              () => _tabCtrl.animateTo(2)),
          _action(Icons.bar_chart, 'Earnings Report', 'NIS ${earnings.toStringAsFixed(2)} total',
              () {}),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/home'),
            child: Container(width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kGreen)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.directions_car, color: kGreen, size: 20), SizedBox(width: 8),
                Text('Switch to Driver Mode',
                    style: TextStyle(color: kGreen, fontWeight: FontWeight.w700, fontSize: 14)),
              ]))),
        ])));
  }

  // ── Chargers ──────────────────────────────────────────────
  Widget _buildChargers() {
    return RefreshIndicator(color: kGreen, onRefresh: _loadAll,
      child: _stations.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.ev_station, color: cSub2, size: 64),
              const SizedBox(height: 16),
              Text('No chargers yet', style: kTitle(18)),
              const SizedBox(height: 8),
              Text('Add your first charging station', style: kSub(13)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showAddStation,
                icon: const Icon(Icons.add),
                label: const Text('Add Charger', style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _stations.length + 1,
              itemBuilder: (_, i) {
                if (i == _stations.length) {
                  return Padding(padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton.icon(
                      onPressed: _showAddStation,
                      icon: const Icon(Icons.add),
                      label: const Text('Add New Charger', style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))));
                }
                final s   = _stations[i] as Map<String, dynamic>;
                final occ = (s['occupancy'] as String?) ??
                    ((s['available'] as bool? ?? true) ? 'free' : 'busy');
                final color = occ == 'busy'
                    ? Colors.redAccent
                    : (occ == 'offline' ? Colors.grey : kGreen);
                final label = occ == 'busy'
                    ? 'In Use'
                    : (occ == 'offline' ? 'Offline' : 'Available');
                return Container(
                  margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                  decoration: kCardDeco(),
                  child: Row(children: [
                    Container(width: 46, height: 46,
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.ev_station, color: color, size: 24)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['name'] as String, style: kTitle(13)),
                      Text('${s['power']} · ${s['connector']} · ${s['price']} NIS/kWh', style: kSub(11)),
                      const SizedBox(height: 4),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(label,
                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700))),
                    ])),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: cSub2, size: 20),
                      onPressed: () => _showEditStation(s)),
                    PopupMenuButton<String>(
                      tooltip: 'Set status',
                      icon: Icon(Icons.more_vert, color: cSub2, size: 20),
                      onSelected: (value) async {
                        final res = await ApiService.instance
                            .setStationOccupancy(s['_id'] as String, value);
                        if (res['success'] && mounted) {
                          _snack('Status: ${value[0].toUpperCase()}${value.substring(1)}');
                          _loadAll();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'free',    child: Text('Mark Available')),
                        PopupMenuItem(value: 'busy',    child: Text('Mark In Use')),
                        PopupMenuItem(value: 'offline', child: Text('Take Offline')),
                      ],
                    ),
                  ]));
              }));
  }

  // ── Bookings ──────────────────────────────────────────────
  Widget _buildBookings() {
    return RefreshIndicator(color: kGreen, onRefresh: _loadAll,
      child: _bookings.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.calendar_today_outlined, color: cSub2, size: 64),
              const SizedBox(height: 16),
              Text('No bookings yet', style: kTitle(18)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _bookings.length,
              itemBuilder: (_, i) {
                final b       = _bookings[i] as Map<String, dynamic>;
                final status  = b['status'] as String? ?? 'Upcoming';
                final station = b['station'];
                final user    = b['user'];
                final stName  = station is Map ? station['name'] as String : 'Station';
                final uName   = user is Map
                    ? '${user['firstName']} ${user['lastName']}'
                    : 'User';
                final color = status == 'Upcoming' ? kGreen
                    : status == 'Completed' ? Colors.blueAccent : Colors.redAccent;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                  decoration: kCardDeco(),
                  child: Row(children: [
                    Container(width: 44, height: 44,
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.ev_station, color: color, size: 22)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(stName, style: kTitle(13)),
                      Text(uName, style: kSub(12)),
                      Text('${b['date']}  ${b['time']}', style: kSub(11)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700))),
                      const SizedBox(height: 4),
                      Text('${b['price']?.toString() ?? '5'} NIS',
                          style: const TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ]));
              }));
  }

  // ── Analytics ─────────────────────────────────────────────
  Widget _buildAnalytics() {
    if (_daily.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.bar_chart, color: cSub2, size: 64),
        const SizedBox(height: 16),
        Text('No data yet', style: kTitle(18)),
        const SizedBox(height: 8),
        Text('Start getting bookings to see analytics', style: kSub(13)),
      ]));
    }

    final maxVal = _daily.fold<double>(0, (m, d) {
      final v = (d['earnings'] as num?)?.toDouble() ?? 0;
      return v > m ? v : m;
    });

    final totalWeek = _daily.fold<double>(0, (s, d) => s + ((d['earnings'] as num?)?.toDouble() ?? 0));
    final totalBookings = _daily.fold<int>(0, (s, d) => s + ((d['count'] as num?)?.toInt() ?? 0));

    return RefreshIndicator(color: kGreen, onRefresh: _loadAll,
      child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Weekly summary
          Row(children: [
            _stat('NIS ${totalWeek.toStringAsFixed(0)}', 'This Week'),
            const SizedBox(width: 12),
            _stat('$totalBookings', 'Bookings'),
            const SizedBox(width: 12),
            _stat('${_stations.length}', 'Stations'),
          ]),
          const SizedBox(height: 24),

          Text('Daily Earnings (Last 7 Days)', style: kTitle(15)),
          const SizedBox(height: 16),

          // Bar chart
          Container(padding: const EdgeInsets.all(16), decoration: kCardDeco(),
            child: Column(children: [
              SizedBox(height: 180,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  // Y axis
                  Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${maxVal.toStringAsFixed(0)}', style: kSub(9)),
                    Text('${(maxVal / 2).toStringAsFixed(0)}', style: kSub(9)),
                    Text('0', style: kSub(9)),
                  ]),
                  const SizedBox(width: 8),
                  // Bars
                  Expanded(child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _daily.map((d) {
                      final val     = (d['earnings'] as num?)?.toDouble() ?? 0;
                      final ratio   = maxVal > 0 ? val / maxVal : 0.0;
                      final barH    = 140 * ratio;
                      final isToday = _daily.indexOf(d) == _daily.length - 1;
                      return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Text('${val.toStringAsFixed(0)}',
                            style: TextStyle(color: isToday ? kGreen : cSub2, fontSize: 9, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Container(width: 28, height: barH.clamp(4, 140).toDouble(),
                          decoration: BoxDecoration(
                            color: isToday ? kGreen : kGreen.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(6))),
                      ]);
                    }).toList())),
                ])),
              const SizedBox(height: 8),
              // X axis labels
              Row(children: [
                const SizedBox(width: 32),
                Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _daily.map((d) => Text(d['label'] as String,
                      style: kSub(9), textAlign: TextAlign.center)).toList())),
              ]),
            ])),
          const SizedBox(height: 24),

          Text('Daily Breakdown', style: kTitle(15)),
          const SizedBox(height: 12),
          Container(decoration: kCardDeco(),
            child: Column(children: List.generate(_daily.length, (i) {
              final d   = _daily[_daily.length - 1 - i];
              final val = (d['earnings'] as num?)?.toDouble() ?? 0;
              final cnt = (d['count'] as num?)?.toInt() ?? 0;
              return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(border: i < _daily.length - 1
                    ? Border(bottom: BorderSide(color: cBorder)) : null),
                child: Row(children: [
                  Text(d['label'] as String, style: kSub(13)), const Spacer(),
                  Text('$cnt bookings', style: kSub(12)), const SizedBox(width: 16),
                  Text('NIS ${val.toStringAsFixed(2)}',
                      style: TextStyle(color: val > 0 ? kGreen : cSub2,
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ]));
            }))),
        ])));
  }

  // ── Edit Station Sheet ────────────────────────────────────
  void _showEditStation(Map<String, dynamic> s) {
    final nameCtrl  = TextEditingController(text: s['name'] as String? ?? '');
    final addrCtrl  = TextEditingController(text: s['location']?['address'] as String? ?? '');
    final priceCtrl = TextEditingController(text: s['price']?.toString() ?? '2.5');
    String power    = s['power'] as String? ?? '22 kW';
    String conn     = s['connector'] as String? ?? 'CCS2';
    String network  = s['network'] as String? ?? 'Independent';
    int    plugs    = (s['plugCount'] as num?)?.toInt() ?? 1;
    final amenities = ((s['amenities'] as List?) ?? []).map((e) => e.toString()).toSet();
    final parking   = ((s['parking']   as List?) ?? []).map((e) => e.toString()).toSet();
    bool   saving   = false;

    const powers = ['7 kW', '11 kW', '22 kW', '43 kW', '50 kW',
                    '100 kW', '150 kW', '250 kW', '350 kW', 'AC'];
    const conns  = ['CCS2', 'CCS1', 'CHAdeMO', 'Type 2', 'NACS', 'GB/T', 'AC', 'J-1772'];
    const networks = ['Independent', 'ChargePoint', 'EVgo', 'Tesla',
                      'Electrify America', 'Shell Recharge', 'BP Pulse', 'Other'];
    const amenList = ['WiFi', 'Dining', 'Restroom', 'Shopping', 'Lodging', 'Park',
                      'Grocery', 'Valet', 'Hiking', 'Camping', 'Free Charge'];
    const parkList = ['Accessible', 'Covered', 'Garage', 'Illuminated',
                      'Pull In', 'Pull Through', 'Trailer Friendly'];
    if (!powers.contains(power))     power   = '22 kW';
    if (!conns.contains(conn))       conn    = 'CCS2';
    if (!networks.contains(network)) network = 'Independent';

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: cCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: cBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Edit Charger', style: kTitle(18)),
            const SizedBox(height: 20),
            _field(nameCtrl,  'Station Name',  Icons.ev_station),
            const SizedBox(height: 12),
            _field(addrCtrl,  'Address',       Icons.location_on_outlined),
            const SizedBox(height: 12),
            _field(priceCtrl, 'Price NIS/kWh', Icons.attach_money, type: TextInputType.number),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _dropdown('Power', power, powers, (v) => set(() => power = v!))),
              const SizedBox(width: 12),
              Expanded(child: _dropdown('Connector', conn, conns, (v) => set(() => conn = v!))),
            ]),
            const SizedBox(height: 12),
            _dropdown('Network', network, networks, (v) => set(() => network = v!)),
            const SizedBox(height: 12),
            // Plug count stepper
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cBorder)),
              child: Row(children: [
                Text('Plug Count', style: kSub(12)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.remove, color: kGreen),
                    onPressed: () => set(() { if (plugs > 1) plugs--; })),
                Text('$plugs', style: kTitle(15)),
                IconButton(icon: const Icon(Icons.add, color: kGreen),
                    onPressed: () => set(() { if (plugs < 20) plugs++; })),
              ]),
            ),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft,
                child: Text('Amenities', style: kTitle(13))),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: amenList.map((a) {
              final sel = amenities.contains(a);
              return GestureDetector(
                onTap: () => set(() { sel ? amenities.remove(a) : amenities.add(a); }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? Colors.purpleAccent.withOpacity(0.15) : cBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? Colors.purpleAccent : cBorder),
                  ),
                  child: Text(a, style: TextStyle(
                      color: sel ? Colors.purpleAccent : cSub,
                      fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              );
            }).toList()),
            const SizedBox(height: 14),
            Align(alignment: Alignment.centerLeft,
                child: Text('Parking', style: kTitle(13))),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: parkList.map((p) {
              final sel = parking.contains(p);
              return GestureDetector(
                onTap: () => set(() { sel ? parking.remove(p) : parking.add(p); }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? Colors.orange.withOpacity(0.15) : cBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? Colors.orange : cBorder),
                  ),
                  child: Text(p, style: TextStyle(
                      color: sel ? Colors.orange : cSub,
                      fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              );
            }).toList()),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: saving ? null : () async {
                  set(() => saving = true);
                  final res = await ApiService.instance.updateHostStation(s['_id'] as String, {
                    'name':      nameCtrl.text.trim(),
                    'address':   addrCtrl.text.trim(),
                    'power':     power,
                    'connector': conn,
                    'network':   network,
                    'plugCount': plugs,
                    'amenities': amenities.toList(),
                    'parking':   parking.toList(),
                    'price':     double.tryParse(priceCtrl.text) ?? 2.5,
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    _snack(res['success'] ? 'Charger updated! ✅' : res['message'] ?? 'Error',
                        isError: !res['success']);
                    if (res['success']) _loadAll();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                    disabledBackgroundColor: kGreen.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: saving
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                    : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)))),
          ])))));
  }

  // ── Add Station Sheet ─────────────────────────────────────
  void _showAddStation() async {
    final added = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const HostAddChargerScreen()));
    if (added == true) _loadAll();
  }

  void _oldShowAddStation() {
    final nameCtrl  = TextEditingController();
    final addrCtrl  = TextEditingController();
    final priceCtrl = TextEditingController(text: '2.5');
    String power    = '22 kW';
    String conn     = 'CCS2';
    bool   saving   = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: cCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: cBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Add New Charger', style: kTitle(18)),
            const SizedBox(height: 20),
            _field(nameCtrl,  'Station Name',  Icons.ev_station),
            const SizedBox(height: 12),
            _field(addrCtrl,  'Address',       Icons.location_on_outlined),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(priceCtrl, 'Price NIS/kWh', Icons.attach_money,
                  type: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _dropdown('Power', power, ['22 kW', '50 kW', 'AC', '7 kW'],
                  (v) => set(() => power = v!))),
              const SizedBox(width: 12),
              Expanded(child: _dropdown('Connector', conn, ['CCS2', 'Type 2', 'CHAdeMO', 'GB/T'],
                  (v) => set(() => conn = v!))),
            ]),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: saving ? null : () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  set(() => saving = true);
                  final res = await ApiService.instance.addHostStation({
                    'name':      nameCtrl.text.trim(),
                    'location':  {'address': addrCtrl.text.trim(), 'lat': 32.221, 'lng': 35.258},
                    'power':     power,
                    'connector': conn,
                    'price':     double.tryParse(priceCtrl.text) ?? 2.5,
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    _snack(res['success'] ? 'Charger added! ✅' : res['message'], isError: !res['success']);
                    if (res['success']) _loadAll();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                    disabledBackgroundColor: kGreen.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: saving
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                    : const Text('Add Charger', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)))),
          ]))));
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType? type}) =>
    TextField(controller: ctrl, keyboardType: type, style: TextStyle(color: cTitle, fontSize: 14),
      decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: cSub),
        prefixIcon: Icon(icon, color: cSub2, size: 20), filled: true, fillColor: cBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGreen, width: 1.5))));

  Widget _dropdown(String label, String val, List<String> items, ValueChanged<String?> onChanged) =>
    DropdownButtonFormField<String>(
      value: val, onChanged: onChanged,
      style: TextStyle(color: cTitle, fontSize: 14),
      dropdownColor: cCard,
      decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: cSub),
        filled: true, fillColor: cBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGreen, width: 1.5))),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList());

  Widget _stat(String v, String l) => Expanded(
    child: Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: kCardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(v, style: kTitle(18)), Text(l, style: kSub(11)),
      ])));

  Widget _action(IconData icon, String title, String sub, VoidCallback onTap) =>
    GestureDetector(onTap: onTap,
      child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
        decoration: kCardDeco(),
        child: Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: kGreen, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: kTitle(14)), Text(sub, style: kSub(12)),
          ])),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ])));
}
