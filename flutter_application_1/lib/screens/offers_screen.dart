import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'promo_detail_screen.dart';

// ═══════════════════════════════════════
//  OFFERS SCREEN
// ═══════════════════════════════════════
class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});
  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Offers & Rewards', style: kTitle(18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder)),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                  color: kGreen, borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white54,
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: '🎁  Promos'),
                Tab(text: '⭐  Points'),
                Tab(text: '⏰  Flash'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _PromosTab(),
          _LoyaltyTab(),
          _FlashTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
//  TAB 1 — PROMOS
// ═══════════════════════════════════════
class _PromosTab extends StatelessWidget {
  const _PromosTab();

  static const _promos = [
    {
      'title':    'First Charge Free! ⚡',
      'sub':      'Get your first charging session completely free.',
      'code':     'FIRST-FREE',
      'discount': '100%',
      'expires':  'Dec 31, 2026',
      'color':    0xFF00E5A0,
      'claimed':  false,
    },
    {
      'title':    '20% Off This Weekend',
      'sub':      'Enjoy 20% discount on all sessions this weekend.',
      'code':     'CHARGE20',
      'discount': '20%',
      'expires':  'Apr 7, 2026',
      'color':    0xFF6C63FF,
      'claimed':  false,
    },
    {
      'title':    'Refer & Earn 🎁',
      'sub':      'Invite a friend and get 5 kWh free.',
      'code':     'REFER-5KWH',
      'discount': '5 kWh',
      'expires':  'No expiry',
      'color':    0xFFFF6B6B,
      'claimed':  true,
    },
    {
      'title':    'Night Owl Special 🌙',
      'sub':      'Charge 10 PM – 6 AM and get 30% off.',
      'code':     'NIGHT30',
      'discount': '30%',
      'expires':  'Jun 30, 2026',
      'color':    0xFF4ECDC4,
      'claimed':  false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _promos.length,
      itemBuilder: (_, i) =>
          _PromoCard(promo: Map<String, dynamic>.from(_promos[i])),
    );
  }
}

// ─── Promo Card ───────────────────────────────────────────
class _PromoCard extends StatefulWidget {
  final Map<String, dynamic> promo;
  const _PromoCard({required this.promo});
  @override
  State<_PromoCard> createState() => _PromoCardState();
}

class _PromoCardState extends State<_PromoCard> {
  late bool _claimed;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _claimed = widget.promo['claimed'] as bool;
  }

  void _copy() {
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2),
        () { if (mounted) setState(() => _copied = false); });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Code "${widget.promo['code']}" copied! ✅'),
      backgroundColor: kCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.promo['color'] as int);
    return GestureDetector(
      onTap: () => goTo(context, PromoDetailScreen(widget.promo)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(20)),
                child: Text(widget.promo['discount'] as String,
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(widget.promo['title'] as String,
                      style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w800))),
              if (_claimed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Claimed ✓',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
            ]),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.promo['sub'] as String, style: kSub(13)),
              const SizedBox(height: 14),
              // Code row
              Row(children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: color.withOpacity(0.4), width: 1.5)),
                    child: Row(children: [
                      const Icon(Icons.discount_outlined,
                          size: 15, color: Colors.white38),
                      const SizedBox(width: 8),
                      Text(widget.promo['code'] as String,
                          style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5)),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _copy,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withOpacity(0.3))),
                    child: Icon(
                        _copied ? Icons.check : Icons.copy_outlined,
                        color: color,
                        size: 18),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.access_time, size: 13, color: Colors.white38),
                const SizedBox(width: 4),
                Text('Expires: ${widget.promo['expires']}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
                const Spacer(),
                if (!_claimed)
                  GestureDetector(
                    onTap: () => setState(() => _claimed = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text('Claim',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════
//  TAB 2 — LOYALTY POINTS
// ═══════════════════════════════════════
class _LoyaltyTab extends StatelessWidget {
  const _LoyaltyTab();

  static const _rewards = [
    {'points': 500,  'title': 'Free Session (30 min)', 'icon': Icons.bolt,              'color': 0xFF00E5A0, 'unlocked': true},
    {'points': 1000, 'title': '20% Discount Code',     'icon': Icons.discount,          'color': 0xFF6C63FF, 'unlocked': true},
    {'points': 2000, 'title': '1 Hour Free Charging',  'icon': Icons.battery_full,      'color': 0xFFFF6B6B, 'unlocked': false},
    {'points': 5000, 'title': 'Premium Membership',    'icon': Icons.workspace_premium, 'color': 0xFFFFD700, 'unlocked': false},
  ];

  static const _history = [
    {'desc': 'Charging session · An-Najah', 'pts': '+25',  'date': 'Apr 4'},
    {'desc': 'Booking completed',            'pts': '+10',  'date': 'Apr 2'},
    {'desc': 'Referral bonus',              'pts': '+100', 'date': 'Mar 28'},
    {'desc': 'Redeemed: 20% Discount',      'pts': '-200', 'date': 'Mar 20'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Points card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF00E5A0), Color(0xFF00B37A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: kGreen.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Your Points Balance',
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('1,240',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      height: 1)),
              SizedBox(width: 8),
              Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('pts',
                    style: TextStyle(
                        color: Colors.black54,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: 1240 / 2000,
                backgroundColor: Colors.black.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation(Colors.black),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text('760 pts until next reward',
                style: TextStyle(
                    color: Colors.black.withOpacity(0.6), fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 24),

        // How to earn
        Text('How to Earn', style: kTitle(15)),
        const SizedBox(height: 12),
        Row(children: [
          _earnCard('⚡', '25 pts', 'Per session'),
          const SizedBox(width: 10),
          _earnCard('📅', '10 pts', 'Per booking'),
          const SizedBox(width: 10),
          _earnCard('👥', '100 pts', 'Per referral'),
        ]),
        const SizedBox(height: 24),

        // Rewards
        Text('Redeem Rewards', style: kTitle(15)),
        const SizedBox(height: 12),
        ..._rewards.map(
            (r) => _RewardCard(reward: Map<String, dynamic>.from(r))),
        const SizedBox(height: 24),

        // History
        Text('Points History', style: kTitle(15)),
        const SizedBox(height: 12),
        Container(
          decoration: kCardDeco(),
          child: Column(
            children: _history.asMap().entries.map((e) {
              final isLast = e.key == _history.length - 1;
              final h      = e.value;
              final isPlus = (h['pts'] as String).startsWith('+');
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: !isLast
                      ? const Border(bottom: BorderSide(color: kBorder))
                      : null,
                ),
                child: Row(children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: isPlus ? kGreen : Colors.redAccent,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(h['desc']!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                        Text(h['date']!, style: kSub(11)),
                      ])),
                  Text(h['pts']!,
                      style: TextStyle(
                          color: isPlus ? kGreen : Colors.redAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ]),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _earnCard(String emoji, String pts, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: kCardDeco(radius: 14),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(pts, style: kTitle(13)),
            Text(label, style: kSub(10)),
          ]),
        ),
      );
}

// ─── Reward Card ──────────────────────────────────────────
class _RewardCard extends StatefulWidget {
  final Map<String, dynamic> reward;
  const _RewardCard({required this.reward});
  @override
  State<_RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends State<_RewardCard> {
  bool _redeemed = false;

  @override
  Widget build(BuildContext context) {
    final color    = Color(widget.reward['color'] as int);
    final unlocked = widget.reward['unlocked'] as bool;
    final pts      = widget.reward['points'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: unlocked ? color.withOpacity(0.3) : kBorder),
      ),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: unlocked
                  ? color.withOpacity(0.12)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(widget.reward['icon'] as IconData,
              color: unlocked ? color : Colors.white24, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.reward['title'] as String,
              style: TextStyle(
                  color: unlocked ? Colors.white : Colors.white38,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text('$pts points',
              style: TextStyle(
                  color: unlocked ? color : Colors.white24,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ])),
        if (_redeemed)
          const Text('Redeemed ✓',
              style: TextStyle(color: Colors.white38, fontSize: 12))
        else if (unlocked)
          GestureDetector(
            onTap: () {
              setState(() => _redeemed = true);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${widget.reward['title']} redeemed! 🎉'),
                backgroundColor: kCard,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(10)),
              child: const Text('Redeem',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder)),
            child: const Icon(Icons.lock_outline,
                color: Colors.white24, size: 16),
          ),
      ]),
    );
  }
}

// ═══════════════════════════════════════
//  TAB 3 — FLASH DEALS
// ═══════════════════════════════════════
class _FlashTab extends StatefulWidget {
  const _FlashTab();
  @override
  State<_FlashTab> createState() => _FlashTabState();
}

class _FlashTabState extends State<_FlashTab> {
  int _seconds = 3 * 3600 + 24 * 60 + 18;

  @override
  void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() { if (_seconds > 0) _seconds--; });
      return mounted;
    });
  }

  String get _timer {
    final h = _seconds ~/ 3600;
    final m = (_seconds % 3600) ~/ 60;
    final s = _seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static const _deals = [
    {'title': 'Happy Hour ⚡',       'sub': 'All stations 40% off',       'time': '10 PM – 6 AM', 'color': 0xFF00E5A0, 'badge': 'ACTIVE'},
    {'title': 'Weekend Special 🎉',  'sub': '25% off Fri & Sat',          'time': 'Fri & Sat',    'color': 0xFF6C63FF, 'badge': 'UPCOMING'},
    {'title': 'Flash Deal 🔥',       'sub': '50% off next 3 hours only!', 'time': 'Limited time', 'color': 0xFFFF6B6B, 'badge': 'HOT'},
    {'title': 'Lunch Break ☀️',      'sub': '15% off between 12–2 PM',   'time': '12 PM – 2 PM', 'color': 0xFFFFD700, 'badge': 'DAILY'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Countdown banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.4)),
          ),
          child: Row(children: [
            const Text('🔥', style: TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
                child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Flash Deal ends in',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              Text(_timer,
                  style: const TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2)),
            ])),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B),
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('50% OFF',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900)),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        Text("Today's Deals", style: kTitle(15)),
        const SizedBox(height: 12),

        ..._deals.map((d) {
          final color = Color(d['color'] as int);
          final badge = d['badge'] as String;
          final badgeColor = badge == 'ACTIVE'
              ? kGreen
              : badge == 'HOT'
                  ? const Color(0xFFFF6B6B)
                  : badge == 'DAILY'
                      ? const Color(0xFFFFD700)
                      : Colors.blueAccent;

          // ✅ FIX: cast to String before split
          final titleStr = d['title'] as String;
          final emoji    = titleStr.split(' ').last;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.25))),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14)),
                child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                Text(titleStr,
                    style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(d['sub'] as String, style: kSub(12)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.access_time,
                      size: 12, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(d['time'] as String, style: kSub(11)),
                ]),
              ])),
              Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(badge,
                      style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () =>
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('$titleStr applied! ✅'),
                    backgroundColor: kCard,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  )),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('Apply',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
            ]),
          );
        }),
      ]),
    );
  }
}
