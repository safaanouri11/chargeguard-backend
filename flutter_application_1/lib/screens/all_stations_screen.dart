import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import 'charger_detail_screen.dart';

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
  }

  Future<void> _loadStations() async {
    setState(() => _loading = true);
    final result = await ApiService.instance.getStations();
    if (mounted) {
      setState(() {
        _loading  = false;
        _stations = result['success'] ? (result['data'] as List) : [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('All Stations', context),
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
                        final s  = _stations[i];
                        final ok = s['available'] as bool? ?? true;
                        return GestureDetector(
                          onTap: () => goTo(context, ChargerDetailScreen(s)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: kCardDeco(),
                            child: Row(children: [
                              Container(width: 46, height: 46,
                                  decoration: BoxDecoration(
                                      color: ok ? kGreen.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Icon(Icons.ev_station,
                                      color: ok ? kGreen : Colors.redAccent, size: 24)),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(s['name'] as String, style: kTitle(13)),
                                Text('${s['power']} · ${s['price']} NIS/kWh', style: kSub(12)),
                                if (s['location'] != null)
                                  Text(s['location']['address'] as String? ?? '',
                                      style: kSub(11), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ])),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: ok ? kGreen.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text(ok ? 'Available' : 'Busy',
                                      style: TextStyle(
                                          color: ok ? kGreen : Colors.redAccent,
                                          fontSize: 11, fontWeight: FontWeight.w700))),
                              ]),
                            ])));
                      }),
            ),
    );
  }
}
