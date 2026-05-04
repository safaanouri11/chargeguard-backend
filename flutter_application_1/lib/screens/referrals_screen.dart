import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});
  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  bool _loading = true;
  String _code = '';
  int _count = 0;
  double _earnings = 0;
  List _invitees = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.instance.getMyReferrals();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success']) {
        final data = res['data'] as Map<String, dynamic>;
        _code     = data['code'] as String? ?? '';
        _count    = (data['count'] as num?)?.toInt() ?? 0;
        _earnings = (data['earnings'] as num?)?.toDouble() ?? 0;
        _invitees = (data['invitees'] as List?) ?? [];
      }
    });
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _code));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Code copied to clipboard'),
      backgroundColor: kGreen, duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Invite Friends', context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : RefreshIndicator(
              color: kGreen, onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(20), children: [
                _heroCard(),
                const SizedBox(height: 16),
                _statsRow(),
                const SizedBox(height: 22),
                _howItWorks(),
                const SizedBox(height: 22),
                _inviteesList(),
                const SizedBox(height: 16),
              ]),
            ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kGreen.withOpacity(0.25), Colors.purpleAccent.withOpacity(0.1)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kGreen.withOpacity(0.45)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.card_giftcard, color: kGreen, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Invite & Earn', style: kTitle(18)),
              const SizedBox(height: 2),
              Text('Get 10 NIS for each friend who joins',
                  style: kSub(12)),
            ])),
          ]),
          const SizedBox(height: 18),
          Text('Your referral code', style: kSub(11)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kGreen.withOpacity(0.5), width: 1.5),
            ),
            child: Row(children: [
              Expanded(
                child: SelectableText(
                  _code.isEmpty ? '—' : _code,
                  style: kTitle(22).copyWith(letterSpacing: 4, color: kGreen),
                ),
              ),
              IconButton(
                onPressed: _code.isEmpty ? null : _copyCode,
                icon: const Icon(Icons.copy, color: kGreen),
                tooltip: 'Copy',
              ),
            ]),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: _code.isEmpty ? null : _copyCode,
              icon: const Icon(Icons.copy_outlined, color: Colors.black),
              label: const Text('Copy Code',
                  style: TextStyle(color: Colors.black,
                      fontWeight: FontWeight.w800, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ]),
      );

  Widget _statsRow() => Row(children: [
        Expanded(child: _statCard(
          Icons.people_outline, '$_count', 'Friends Joined',
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          Icons.account_balance_wallet_outlined,
          '${_earnings.toStringAsFixed(0)} NIS', 'Total Earned',
        )),
      ]);

  Widget _statCard(IconData icon, String value, String label) => Container(
        padding: const EdgeInsets.all(14),
        decoration: kCardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: kGreen, size: 20),
          const SizedBox(height: 8),
          Text(value, style: kTitle(20)),
          const SizedBox(height: 2),
          Text(label, style: kSub(11)),
        ]),
      );

  Widget _howItWorks() => Container(
        padding: const EdgeInsets.all(16),
        decoration: kCardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('How it works', style: kTitle(14)),
          const SizedBox(height: 14),
          _step(1, 'Share your code', 'Send your unique code to friends'),
          _step(2, 'They sign up', 'Friend creates account using your code'),
          _step(3, 'You both win!', 'You get 10 NIS, they get 5 NIS instantly'),
        ]),
      );

  Widget _step(int n, String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: kGreen, width: 1.5),
            ),
            child: Center(child: Text('$n',
                style: const TextStyle(
                    color: kGreen, fontWeight: FontWeight.w800, fontSize: 12))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: kTitle(13)),
            const SizedBox(height: 2),
            Text(body, style: kSub(11)),
          ])),
        ]),
      );

  Widget _inviteesList() {
    if (_invitees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: kCardDeco(),
        child: Center(child: Column(children: [
          Icon(Icons.person_add_outlined, color: cSub2, size: 40),
          const SizedBox(height: 10),
          Text('No friends joined yet', style: kTitle(14)),
          const SizedBox(height: 4),
          Text('Share your code to start earning',
              style: kSub(12), textAlign: TextAlign.center),
        ])),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Friends Joined', style: kTitle(14)),
      const SizedBox(height: 10),
      ..._invitees.map((u) {
        final m = u as Map<String, dynamic>;
        final name = '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'.trim();
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
        final when = m['createdAt'] as String?;
        final dt = when != null ? DateTime.tryParse(when) : null;
        final dateStr = dt != null
            ? '${dt.day}/${dt.month}/${dt.year}' : '';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: kCardDeco(),
          child: Row(children: [
            CircleAvatar(
              radius: 18, backgroundColor: kGreen.withOpacity(0.2),
              child: Text(initial, style: const TextStyle(
                  color: kGreen, fontWeight: FontWeight.w800, fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name.isEmpty ? 'User' : name, style: kTitle(13)),
              if (dateStr.isNotEmpty)
                Text('Joined $dateStr', style: kSub(11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('+10 NIS',
                  style: TextStyle(color: kGreen,
                      fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ]),
        );
      }),
    ]);
  }
}
