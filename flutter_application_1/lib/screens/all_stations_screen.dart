import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import '../utils/station_filters.dart';
import 'charger_detail_screen.dart';
import 'map_filters_screen.dart';

Color _connectorColor(String? c) {
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

class AllStationsScreen extends StatefulWidget {
  const AllStationsScreen({super.key});
  @override
  State<AllStationsScreen> createState() => _AllStationsScreenState();
}

class _AllStationsScreenState extends State<AllStationsScreen> {
  List<dynamic> _stations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStations();
    StationFilters.instance.addListener(_onFiltersChanged);
  }

  @override
  void dispose() {
    StationFilters.instance.removeListener(_onFiltersChanged);
    super.dispose();
  }

  void _onFiltersChanged() => _loadStations();

  Future<void> _loadStations() async {
    setState(() => _loading = true);
    final filters = StationFilters.instance.toQuery();
    final result = await ApiService.instance.getStations(
        filters: filters.isEmpty ? null : filters);
    if (mounted) {
      setState(() {
        _loading  = false;
        _stations = result['success'] ? (result['data'] as List) : [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = StationFilters.instance.activeCount;
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('All Stations', context, actions: [
        Stack(clipBehavior: Clip.none, children: [
          IconButton(
            icon: const Icon(Icons.tune, color: kGreen),
            tooltip: 'Filters',
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MapFiltersScreen()));
              if (mounted) setState(() {});
            },
          ),
          if (activeCount > 0) Positioned(top: 6, right: 4, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$activeCount',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
          )),
        ]),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : RefreshIndicator(
              color: kGreen,
              onRefresh: _loadStations,
              child: _stations.isEmpty
                  ? Center(child: Text('No stations found', style: kSub(14)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _stations.length,
                      itemBuilder: (_, i) {
                        final s           = _stations[i];
                        final ok          = s['available'] as bool? ?? true;
                        final status      = s['status'] as String? ?? 'Active';
                        final conn        = s['connector'] as String? ?? 'CCS2';
                        final networkName = s['network'] as String? ?? 'Independent';
                        final network     = networkInfo(networkName);
                        final isComingSoon = status == 'Coming Soon';
                        final connColor   = _connectorColor(conn);
                        final statusColor = isComingSoon ? Colors.grey : (ok ? kGreen : Colors.redAccent);

                        return GestureDetector(
                          onTap: () => goTo(context, ChargerDetailScreen(s)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: kCardDeco(),
                            child: Row(children: [
                              // Connector color icon
                              Container(width: 46, height: 46,
                                decoration: BoxDecoration(
                                    color: connColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: connColor.withOpacity(0.4))),
                                child: Icon(Icons.ev_station, color: connColor, size: 24)),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(s['name'] as String, style: kTitle(13)),
                                const SizedBox(height: 3),
                                // Network badge inline
                                Row(children: [
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: network.color, borderRadius: BorderRadius.circular(6)),
                                    child: Text(network.abbr, style: TextStyle(color: network.textColor,
                                        fontSize: 9, fontWeight: FontWeight.w900))),
                                  const SizedBox(width: 5),
                                  Expanded(child: Text('${network.name} · ${s['power']} · ${s['price']} NIS/kWh',
                                      style: kSub(11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ]),
                                if (s['location'] != null)
                                  Text(s['location']['address'] as String? ?? '',
                                      style: kSub(10), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ])),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  isComingSoon ? 'Soon' : (ok ? 'Available' : 'Busy'),
                                  style: TextStyle(color: statusColor,
                                      fontSize: 11, fontWeight: FontWeight.w700))),
                            ])));
                      }),
            ),
    );
  }
}
