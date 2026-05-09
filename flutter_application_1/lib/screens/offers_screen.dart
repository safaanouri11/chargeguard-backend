import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});
  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _offers  = [];
  List<String>  _claimed = [];
  List<dynamic> _promoCodes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
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
      ApiService.instance.getOffers(),
      ApiService.instance.getMyClaims(),
      ApiService.instance.getActivePromos(),
    ]);
    if (mounted) {
      setState(() {
        _loading = false;
        _offers  = results[0]['success'] ? (results[0]['data'] as List) : [];
        _claimed = results[1]['success']
            ? List<String>.from(results[1]['data'] as List)
            : [];
        _promoCodes = results[2]['success'] ? (results[2]['data'] as List) : [];
      });
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$code copied — paste at checkout'),
      backgroundColor: kGreen,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _promoCodesSection() {
    if (_promoCodes.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kGreen.withOpacity(0.18), Colors.purpleAccent.withOpacity(0.06)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGreen.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.qr_code_2, color: kGreen, size: 18),
          const SizedBox(width: 6),
          Text('Promo Codes', style: kTitle(13)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: kGreen, borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${_promoCodes.length}',
                style: const TextStyle(
                    color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 4),
        Text('Tap to copy — apply at booking checkout', style: kSub(11)),
        const SizedBox(height: 10),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _promoCodes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final p = _promoCodes[i] as Map<String, dynamic>;
              final code = p['code'] as String? ?? '';
              final type = p['type'] as String? ?? 'percentage';
              final value = (p['value'] as num?)?.toDouble() ?? 0;
              final label = type == 'percentage'
                  ? '${value.toStringAsFixed(0)}% off'
                  : '${value.toStringAsFixed(0)} NIS off';
              return GestureDetector(
                onTap: () => _copyCode(code),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kGreen.withOpacity(0.5), width: 1.2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(code,
                            style: const TextStyle(
                                color: kGreen, fontSize: 13,
                                fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                        const SizedBox(width: 6),
                        Icon(Icons.copy, color: cSub2, size: 12),
                      ]),
                      const SizedBox(height: 3),
                      Text(label, style: kSub(10)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Future<void> _loadOffers() => _loadAll();

  List<dynamic> get _promos => _offers.where((o) => o['type'] == 'promo').toList();
  List<dynamic> get _flash  => _offers.where((o) => o['type'] == 'flash').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cTitle),
            onPressed: () => Navigator.pop(context)),
        title: Text('Offers & Rewards', style: kTitle(18)),
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
              tabs: const [Tab(text: '🎁  Promos'), Tab(text: '⭐  Points'), Tab(text: '⏰  Flash')],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : TabBarView(controller: _tabCtrl, children: [
              _buildPromos(),
              _buildLoyalty(),
              _buildFlash(),
            ]),
    );
  }

  // ── Promos Tab ────────────────────────────────────────────
  Widget _buildPromos() {
    if (_promos.isEmpty && _promoCodes.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.local_offer_outlined, color: cSub2, size: 48),
        const SizedBox(height: 12),
        Text('No offers available', style: kSub(14)),
      ]));
    }
    return RefreshIndicator(
      color: kGreen, onRefresh: _loadOffers,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _promoCodesSection(),
          const SizedBox(height: 8),
          ...List.generate(_promos.length, (i) {
          final promo = Map<String, dynamic>.from(_promos[i]);
          final id    = promo['_id']?.toString() ?? '';
          return _PromoCard(
            promo:     promo,
            isClaimed: _claimed.contains(id),
            onClaim: () async {
              final res = await ApiService.instance.claimOffer(id);
              if (mounted) {
                if (res['success']) {
                  setState(() => _claimed.add(id));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Offer claimed! ✅'),
                    backgroundColor: cCard, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(res['message'] ?? 'Already claimed'),
                    backgroundColor: kRed, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                }
              }
            });
        }),
        ],
      ),
    );
  }

  // ── Loyalty Tab ───────────────────────────────────────────
  Widget _buildLoyalty() {
    final pts = UserSession.instance.points;
    final nextReward = pts < 500 ? 500 : pts < 1000 ? 1000 : pts < 2000 ? 2000 : 5000;
    final progress = pts / nextReward;

    return SingleChildScrollView(padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Points card
        Container(width: double.infinity, padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00E5A0), Color(0xFF00B37A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Your Points Balance',
                style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$pts', style: const TextStyle(color: Colors.black,
                  fontSize: 46, fontWeight: FontWeight.w900, height: 1)),
              const SizedBox(width: 8),
              const Padding(padding: EdgeInsets.only(bottom: 6),
                  child: Text('pts', style: TextStyle(color: Colors.black54, fontSize: 18, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.black.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation(Colors.black), minHeight: 8)),
            const SizedBox(height: 6),
            Text('${nextReward - pts} pts until next reward',
                style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 12)),
          ])),
        const SizedBox(height: 24),

        Text('How to Earn', style: kTitle(15)),
        const SizedBox(height: 12),
        Row(children: [
          _earnCard('⚡', '10 pts', 'Per booking'),
          const SizedBox(width: 10),
          _earnCard('🔋', '10 pts', 'Per kWh'),
          const SizedBox(width: 10),
          _earnCard('👥', '100 pts', 'Referral'),
        ]),
        const SizedBox(height: 24),

        Text('Redeem Rewards', style: kTitle(15)),
        const SizedBox(height: 12),
        ...[
          {'points': 500,  'title': 'Free Session (30 min)', 'icon': Icons.bolt,              'color': 0xFF00E5A0},
          {'points': 1000, 'title': '20% Discount Code',     'icon': Icons.discount,          'color': 0xFF6C63FF},
          {'points': 2000, 'title': '1 Hour Free Charging',  'icon': Icons.battery_full,      'color': 0xFFFF6B6B},
          {'points': 5000, 'title': 'Premium Membership',    'icon': Icons.workspace_premium,  'color': 0xFFFFD700},
        ].map((r) => _RewardCard(reward: r, userPoints: pts)),
      ]));
  }

  Widget _earnCard(String emoji, String pts, String label) =>
    Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: kCardDeco(radius: 14),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)), const SizedBox(height: 6),
        Text(pts, style: kTitle(13)), Text(label, style: kSub(10)),
      ])));

  // ── Flash Tab ─────────────────────────────────────────────
  Widget _buildFlash() {
    if (_flash.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.flash_on_outlined, color: cSub2, size: 48),
        const SizedBox(height: 12),
        Text('No flash deals right now', style: kSub(14)),
      ]));
    }
    return RefreshIndicator(
      color: kGreen, onRefresh: _loadOffers,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _flash.length,
        itemBuilder: (_, i) {
          final d     = _flash[i];
          final color = Color((d['color'] as num).toInt());
          final badge = d['badge'] as String? ?? '';
          final badgeColor = badge == 'ACTIVE' ? kGreen
              : badge == 'HOT' ? Colors.redAccent
              : badge == 'DAILY' ? Colors.amber : Colors.blueAccent;
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.25))),
            child: Row(children: [
              Container(width: 52, height: 52,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(d['discount'] as String,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d['title'] as String, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(d['sub'] as String, style: kSub(12)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.access_time, size: 12, color: Colors.white38), const SizedBox(width: 4),
                  Text(d['expires'] as String, style: kSub(11)),
                ]),
              ])),
              Column(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: badgeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w800))),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${d['title']} applied! Code: ${d['code']}'),
                    backgroundColor: cCard, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Apply', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800)))),
              ]),
            ]));
        }));
  }
}

// ════════════════════════════════════════
//  Promo Card
// ════════════════════════════════════════
class _PromoCard extends StatefulWidget {
  final Map<String, dynamic> promo;
  final bool isClaimed;
  final VoidCallback? onClaim;
  const _PromoCard({required this.promo, this.isClaimed = false, this.onClaim});
  @override
  State<_PromoCard> createState() => _PromoCardState();
}

class _PromoCardState extends State<_PromoCard> {
  bool _copied = false;

  bool get _claimed => widget.isClaimed;

  void _copy() {
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _copied = false); });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Code "${widget.promo['code']}" copied! ✅'),
      backgroundColor: cCard, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  @override
  Widget build(BuildContext context) {
    final color = Color((widget.promo['color'] as num).toInt());
    final badge = widget.promo['badge'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
              child: Text(widget.promo['discount'] as String,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13))),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.promo['title'] as String,
                style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800))),
            if (badge.isNotEmpty) Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(badge, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700))),
          ])),
        Padding(padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.promo['sub'] as String, style: kSub(13)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.4), width: 1.5)),
                child: Row(children: [
                  const Icon(Icons.discount_outlined, size: 15, color: Colors.white38), const SizedBox(width: 8),
                  Text(widget.promo['code'] as String,
                      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                ]))),
              const SizedBox(width: 10),
              GestureDetector(onTap: _copy,
                child: Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.3))),
                  child: Icon(_copied ? Icons.check : Icons.copy_outlined, color: color, size: 18))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.access_time, size: 13, color: Colors.white38), const SizedBox(width: 4),
              Text('Expires: ${widget.promo['expires']}', style: kSub(12)),
              const Spacer(),
              if (!_claimed) GestureDetector(
                onTap: widget.onClaim,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Claim', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w800))))
              else Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Claimed ✓', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600))),
            ]),
          ])),
      ]));
  }
}

// ════════════════════════════════════════
//  Reward Card
// ════════════════════════════════════════
class _RewardCard extends StatefulWidget {
  final Map<String, dynamic> reward;
  final int userPoints;
  const _RewardCard({required this.reward, required this.userPoints});
  @override
  State<_RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends State<_RewardCard> {
  bool _redeemed = false;

  @override
  Widget build(BuildContext context) {
    final color    = Color((widget.reward['color'] as num).toInt());
    final pts      = widget.reward['points'] as int;
    final unlocked = widget.userPoints >= pts;

    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: unlocked ? color.withOpacity(0.3) : cBorder)),
      child: Row(children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(
              color: unlocked ? color.withOpacity(0.12) : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(widget.reward['icon'] as IconData,
              color: unlocked ? color : Colors.white24, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.reward['title'] as String,
              style: TextStyle(color: unlocked ? cTitle : cSub2, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text('$pts points', style: TextStyle(color: unlocked ? color : cSub2, fontSize: 12, fontWeight: FontWeight.w600)),
        ])),
        if (_redeemed)
          const Text('Redeemed ✓', style: TextStyle(color: Colors.white38, fontSize: 12))
        else if (unlocked)
          GestureDetector(
            onTap: () {
              setState(() => _redeemed = true);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${widget.reward['title']} redeemed!'),
                backgroundColor: cCard, behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
            },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
              child: const Text('Redeem', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w800))))
        else
          Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: cBorder)),
            child: const Icon(Icons.lock_outline, color: Colors.white24, size: 16)),
      ]));
  }
}
