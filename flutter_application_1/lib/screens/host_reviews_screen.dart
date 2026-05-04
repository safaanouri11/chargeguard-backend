import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class HostReviewsScreen extends StatefulWidget {
  const HostReviewsScreen({super.key});
  @override
  State<HostReviewsScreen> createState() => _HostReviewsScreenState();
}

class _HostReviewsScreenState extends State<HostReviewsScreen> {
  List<dynamic> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ApiService.instance.getHostReviews();
    if (mounted) {
      setState(() {
        _loading = false;
        _reviews = result['success'] ? (result['data'] as List? ?? []) : [];
      });
    }
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    final total = _reviews.fold<double>(0, (s, r) => s + ((r['rating'] as num?)?.toDouble() ?? 0));
    return total / _reviews.length;
  }

  Map<int, int> get _distribution {
    final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var r in _reviews) {
      final rating = (r['rating'] as num?)?.toInt() ?? 0;
      dist[rating] = (dist[rating] ?? 0) + 1;
    }
    return dist;
  }

  String _fmtDate(dynamic iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso.toString()).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Customer Reviews', context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : RefreshIndicator(color: kGreen, onRefresh: _load,
              child: _reviews.isEmpty
                  ? ListView(children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.star_outline, color: cSub2, size: 64),
                        const SizedBox(height: 16),
                        Text('No reviews yet', style: kTitle(18)),
                        const SizedBox(height: 8),
                        Text('Reviews from customers will appear here', style: kSub(13)),
                      ])),
                    ])
                  : ListView(padding: const EdgeInsets.all(20), children: [

                      // Average rating card
                      Container(padding: const EdgeInsets.all(20), decoration: kCardDeco(),
                        child: Row(children: [
                          Column(children: [
                            Text(_avgRating.toStringAsFixed(1),
                                style: const TextStyle(color: kGreen, fontSize: 48, fontWeight: FontWeight.w900, height: 1)),
                            const SizedBox(height: 6),
                            Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) =>
                              Icon(i < _avgRating.round() ? Icons.star : Icons.star_border,
                                  color: Colors.amber, size: 16))),
                            const SizedBox(height: 4),
                            Text('${_reviews.length} reviews', style: kSub(11)),
                          ]),
                          const SizedBox(width: 24),
                          Expanded(child: Column(children: [5, 4, 3, 2, 1].map((star) {
                            final count = _distribution[star] ?? 0;
                            final ratio = _reviews.isEmpty ? 0.0 : count / _reviews.length;
                            return Padding(padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(children: [
                                Text('$star', style: kSub(11)),
                                const SizedBox(width: 4),
                                const Icon(Icons.star, color: Colors.amber, size: 12),
                                const SizedBox(width: 8),
                                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(value: ratio,
                                      backgroundColor: cBorder,
                                      valueColor: const AlwaysStoppedAnimation(kGreen),
                                      minHeight: 6))),
                                const SizedBox(width: 8),
                                SizedBox(width: 24, child: Text('$count', style: kSub(10))),
                              ]));
                          }).toList())),
                        ])),
                      const SizedBox(height: 24),

                      Text('All Reviews', style: kTitle(16)),
                      const SizedBox(height: 12),
                      ..._reviews.map((r) {
                        final user    = r['user'];
                        final station = r['station'];
                        final name    = user is Map ? '${user['firstName']} ${user['lastName']}' : 'Customer';
                        final stName  = station is Map ? station['name'] as String? ?? 'Station' : 'Station';
                        final rating  = (r['rating'] as num?)?.toInt() ?? 0;
                        final comment = r['comment'] as String? ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: kCardDeco(),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(width: 40, height: 40,
                                decoration: BoxDecoration(color: kGreen.withOpacity(0.12), shape: BoxShape.circle),
                                child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: kGreen, fontSize: 16, fontWeight: FontWeight.w800)))),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(name, style: kTitle(13)),
                                Text(stName, style: kSub(11)),
                              ])),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) =>
                                  Icon(i < rating ? Icons.star : Icons.star_border,
                                      color: Colors.amber, size: 14))),
                                const SizedBox(height: 2),
                                Text(_fmtDate(r['createdAt']), style: kSub(10)),
                              ]),
                            ]),
                            if (comment.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(10)),
                                child: Text(comment, style: TextStyle(color: cTitle, fontSize: 13, height: 1.5))),
                            ],
                          ]));
                      }),
                    ])),
    );
  }
}
