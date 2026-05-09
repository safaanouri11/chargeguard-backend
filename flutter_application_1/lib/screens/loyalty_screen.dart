import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});
  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  bool _loading = true;
  String _tier = 'Bronze';
  int _points = 0;
  int _discountPct = 0;
  String? _nextTier;
  int _pointsToNext = 0;
  int _progressPct = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.instance.getLoyalty();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success']) {
        final d = res['data'] as Map<String, dynamic>;
        _tier         = d['tier'] as String? ?? 'Bronze';
        _points       = (d['points'] as num?)?.toInt() ?? 0;
        _discountPct  = (d['discountPct'] as num?)?.toInt() ?? 0;
        _nextTier     = d['nextTier'] as String?;
        _pointsToNext = (d['pointsToNext'] as num?)?.toInt() ?? 0;
        _progressPct  = (d['progressPct'] as num?)?.toInt() ?? 0;
      }
    });
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'Gold':   return const Color(0xFFFFD700);
      case 'Silver': return const Color(0xFFC0C0C0);
      default:       return const Color(0xFFCD7F32);
    }
  }

  IconData _tierIcon(String tier) {
    switch (tier) {
      case 'Gold':   return Icons.workspace_premium;
      case 'Silver': return Icons.military_tech;
      default:       return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(_tier);
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Loyalty Program', context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : RefreshIndicator(
              color: kGreen, onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                _tierCard(color),
                const SizedBox(height: 16),
                if (_nextTier != null) _progressCard(color),
                const SizedBox(height: 16),
                _benefitsCard(),
                const SizedBox(height: 16),
                _allTiersCard(),
                const SizedBox(height: 20),
              ]),
            ),
    );
  }

  Widget _tierCard(Color color) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.3), color.withOpacity(0.05)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        ),
        child: Column(children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(_tierIcon(_tier), color: color, size: 40),
          ),
          const SizedBox(height: 14),
          Text(_tier, style: kTitle(28).copyWith(color: color, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('Member', style: kSub(12)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_points points',
              style: const TextStyle(color: kGreen,
                  fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ]),
      );

  Widget _progressCard(Color color) => Container(
        padding: const EdgeInsets.all(16),
        decoration: kCardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.trending_up, color: color, size: 20),
            const SizedBox(width: 8),
            Text('Next: $_nextTier', style: kTitle(14)),
            const Spacer(),
            Text('$_progressPct%', style: kTitle(14).copyWith(color: kGreen)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progressPct / 100,
              minHeight: 10,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(kGreen),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Earn $_pointsToNext more points to reach $_nextTier!',
            style: kSub(12),
          ),
        ]),
      );

  Widget _benefitsCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: kCardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.card_giftcard, color: kGreen, size: 20),
            const SizedBox(width: 8),
            Text('Your Benefits', style: kTitle(14)),
          ]),
          const SizedBox(height: 12),
          if (_discountPct > 0)
            _benefit(Icons.discount, '$_discountPct% off all bookings',
                'Automatic discount applied at checkout')
          else
            _benefit(Icons.bolt, 'Earn points on every booking',
                'Get 10 points per booking — climb to Silver for 5% off!'),
          _benefit(Icons.star, 'Priority support',
              'Faster response times for your tickets'),
          _benefit(Icons.local_offer, 'Exclusive promo codes',
              'Special offers for loyalty members'),
        ]),
      );

  Widget _benefit(IconData icon, String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: kGreen, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: kTitle(12)),
            Text(body, style: kSub(11)),
          ])),
        ]),
      );

  Widget _allTiersCard() {
    final tiers = [
      {'name': 'Bronze', 'min': 0,    'discount': 0,  'color': const Color(0xFFCD7F32)},
      {'name': 'Silver', 'min': 500,  'discount': 5,  'color': const Color(0xFFC0C0C0)},
      {'name': 'Gold',   'min': 2000, 'discount': 10, 'color': const Color(0xFFFFD700)},
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: kCardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('All Tiers', style: kTitle(14)),
        const SizedBox(height: 12),
        ...tiers.map((t) {
          final isCurrent = t['name'] == _tier;
          final color = t['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrent ? color.withOpacity(0.1) : null,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrent ? color : cSub2.withOpacity(0.2),
              ),
            ),
            child: Row(children: [
              Icon(_tierIcon(t['name'] as String), color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t['name'] as String, style: kTitle(13).copyWith(color: color)),
                Text('${t['min']}+ points · ${t['discount']}% off',
                    style: kSub(11)),
              ])),
              if (isCurrent) Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('YOU', style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}
