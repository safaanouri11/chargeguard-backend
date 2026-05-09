import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import 'booking_form_screen.dart';
import 'charger_detail_screen.dart';

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

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});
  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _bookmarks = [];
  List<dynamic> _recent    = [];
  bool _loading = true;
  bool _loadingRecent = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
    _loadRecent();
    UserSession.instance.bookmarkNotifier.addListener(_onBookmarkChange);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    UserSession.instance.bookmarkNotifier.removeListener(_onBookmarkChange);
    super.dispose();
  }

  void _onBookmarkChange() => _load();

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final result = await ApiService.instance.getBookmarks();
    if (mounted) {
      setState(() {
        _loading = false;
        _bookmarks = result['success'] ? (result['data'] as List? ?? []) : [];
      });
    }
  }

  Future<void> _loadRecent() async {
    if (!mounted) return;
    setState(() => _loadingRecent = true);
    final result = await ApiService.instance.getRecentStations();
    if (mounted) {
      setState(() {
        _loadingRecent = false;
        _recent = result['success'] ? (result['data'] as List? ?? []) : [];
      });
    }
  }

  Future<void> _clearRecent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cBg,
        title: const Text('Clear Recently Viewed?'),
        content: const Text('This will clear all recently viewed stations.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ApiService.instance.clearRecentStations();
      _loadRecent();
    }
  }

  Future<void> _remove(String stationId) async {
    await ApiService.instance.removeBookmark(stationId);
    UserSession.instance.notifyBookmarkChange();
    setState(() {
      _bookmarks.removeWhere((b) {
        final s = b['station'];
        return s is Map && s['_id'] == stationId;
      });
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Bookmark removed'),
        backgroundColor: cCard, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg, elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(children: [
          const Icon(Icons.bookmark, color: kGreen, size: 22),
          const SizedBox(width: 10),
          Text('Bookmarks', style: kTitle(18)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: kGreen),
            onPressed: () { _load(); _loadRecent(); },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: cCard, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cBorder),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black,
              unselectedLabelColor: cSub,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Saved (${_bookmarks.length})'),
                Tab(text: 'Recently Viewed (${_recent.length})'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        _buildSavedTab(),
        _buildRecentTab(),
      ]),
    );
  }

  Widget _buildSavedTab() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kGreen));
    if (_bookmarks.isEmpty) return _emptyState();
    return RefreshIndicator(color: kGreen, onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _bookmarks.length,
        itemBuilder: (_, i) {
          final b = _bookmarks[i] as Map<String, dynamic>;
          final s = b['station'];
          if (s == null) return const SizedBox();
          final station = s as Map<String, dynamic>;
                      final id        = station['_id'] as String? ?? '';
                      final name      = station['name'] as String? ?? 'Station';
                      final conn      = station['connector'] as String? ?? 'CCS2';
                      final power     = station['power'] as String? ?? '22 kW';
                      final price     = station['price']?.toString() ?? '2.5';
                      final ok        = station['available'] as bool? ?? true;
                      final status    = station['status'] as String? ?? 'Active';
                      final networkName = station['network'] as String? ?? 'Independent';
                      final addr      = station['location']?['address'] as String? ?? '';
                      final amenities = (station['amenities'] as List? ?? []).map((e) => e.toString()).toList();
                      final parking   = (station['parking'] as List? ?? []).map((e) => e.toString()).toList();
                      final plugCount = station['plugCount'] ?? 1;
                      final color     = status == 'Coming Soon' ? Colors.grey : _connColor(conn);
                      final isComingSoon = status == 'Coming Soon';
                      final network   = networkInfo(networkName);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: kCardDeco(),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                          // Header
                          Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: Row(children: [
                              Container(width: 50, height: 50,
                                decoration: BoxDecoration(color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(color: color.withOpacity(0.4))),
                                child: Icon(isComingSoon ? Icons.schedule : Icons.ev_station,
                                    color: color, size: 24)),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(name, style: kTitle(14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(addr, style: kSub(11), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ])),
                              GestureDetector(
                                onTap: () => _remove(id),
                                child: Container(padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: kGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.bookmark, color: kGreen, size: 20))),
                            ])),

                          // Network Badge
                          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: network.color,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Text(network.abbr,
                                    style: TextStyle(color: network.textColor,
                                        fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                const SizedBox(width: 6),
                                Text(network.name,
                                    style: TextStyle(color: network.textColor,
                                        fontSize: 11, fontWeight: FontWeight.w700)),
                              ]))),

                          // Tags
                          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Wrap(spacing: 8, runSpacing: 6, children: [
                              _tag(conn, color),
                              _tag(power, cSub2),
                              _tag('NIS $price/kWh', cSub2),
                              _tag('$plugCount Plugs', Colors.blueAccent),
                              _tag(isComingSoon ? 'Coming Soon' : (ok ? 'Available' : 'Busy'),
                                  isComingSoon ? Colors.grey : (ok ? kGreen : Colors.orange)),
                            ])),

                          // Amenities
                          if (amenities.isNotEmpty)
                            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Wrap(spacing: 6, runSpacing: 4, children: amenities.take(4).map((a) =>
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(a, style: const TextStyle(color: Colors.purpleAccent,
                                      fontSize: 10, fontWeight: FontWeight.w600)))).toList())),

                          // Parking
                          if (parking.isNotEmpty)
                            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Wrap(spacing: 6, runSpacing: 4, children: parking.take(3).map((p) =>
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Text(p, style: const TextStyle(color: Colors.orange,
                                      fontSize: 10, fontWeight: FontWeight.w600)))).toList())),

                          // Book Button
                          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: SizedBox(width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (ok && !isComingSoon) ? () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => BookingFormScreen(station: station))) : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kGreen, foregroundColor: Colors.black,
                                  disabledBackgroundColor: Colors.white12,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: Text(
                                  isComingSoon ? 'Coming Soon' : (ok ? 'Book Now' : 'Unavailable'),
                                  style: const TextStyle(fontWeight: FontWeight.w800))))),
                        ]));
                    }));
  }

  // ── Recently Viewed Tab ───────────────────────────────────
  Widget _buildRecentTab() {
    if (_loadingRecent) return const Center(child: CircularProgressIndicator(color: kGreen));
    if (_recent.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 90, height: 90,
          decoration: BoxDecoration(color: kGreen.withOpacity(0.08), shape: BoxShape.circle),
          child: const Icon(Icons.history, color: kGreen, size: 44)),
        const SizedBox(height: 20),
        Text('No recent stations', style: kTitle(20)),
        const SizedBox(height: 10),
        Text('Stations you view will appear here',
            style: kSub(13), textAlign: TextAlign.center),
      ]));
    }
    return RefreshIndicator(color: kGreen, onRefresh: _loadRecent,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _recent.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Text('${_recent.length} viewed recently', style: kSub(12)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _clearRecent,
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                  label: const Text('Clear All',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
              ]),
            );
          }
          final s = _recent[i - 1] as Map<String, dynamic>;
          final name = s['name'] as String? ?? 'Station';
          final conn = s['connector'] as String? ?? 'CCS2';
          final power = s['power'] as String? ?? '';
          final price = s['price']?.toString() ?? '';
          final addr = s['location'] is Map ? s['location']['address'] as String? ?? '' : '';
          final occ = s['occupancy'] as String? ??
              ((s['available'] as bool? ?? true) ? 'free' : 'busy');
          final color = occ == 'busy' ? Colors.redAccent
              : (occ == 'offline' ? Colors.grey : kGreen);
          final viewedAt = s['viewedAt'] as String?;
          final dt = viewedAt != null ? DateTime.tryParse(viewedAt) : null;
          final relative = dt == null ? '' : _relative(dt);
          return GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ChargerDetailScreen(s))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: kCardDeco(),
              child: Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.ev_station, color: color, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: kTitle(13)),
                  if (addr.isNotEmpty) Text(addr,
                      style: kSub(11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(spacing: 8, children: [
                      _miniTag(conn, color),
                      if (power.isNotEmpty) _miniTag(power, cSub2),
                      if (price.isNotEmpty) _miniTag('$price NIS', cSub2),
                    ]),
                  ),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Icon(Icons.chevron_right, color: cSub2, size: 18),
                  if (relative.isNotEmpty) Text(relative,
                      style: TextStyle(color: cSub2, fontSize: 10)),
                ]),
              ]),
            ),
          );
        }));
  }

  Widget _miniTag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text, style: TextStyle(
        color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );

  String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24)   return '${diff.inHours}h';
    if (diff.inDays < 7)     return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  Widget _emptyState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 90, height: 90,
      decoration: BoxDecoration(color: kGreen.withOpacity(0.08), shape: BoxShape.circle),
      child: const Icon(Icons.bookmark_outline, color: kGreen, size: 44)),
    const SizedBox(height: 20),
    Text('No Saved Stations', style: kTitle(20)),
    const SizedBox(height: 10),
    Text('Tap the 🔖 bookmark icon on any\nstation in the map to save it here',
        style: kSub(13), textAlign: TextAlign.center),
    const SizedBox(height: 20),
  ]));

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)));
}
