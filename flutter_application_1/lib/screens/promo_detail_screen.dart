import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PromoDetailScreen extends StatefulWidget {
  final Map<String, dynamic> promo;
  const PromoDetailScreen(this.promo, {super.key});
  @override
  State<PromoDetailScreen> createState() => _PromoDetailScreenState();
}

class _PromoDetailScreenState extends State<PromoDetailScreen> {
  late bool _claimed;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _claimed = widget.promo['claimed'] as bool? ?? false;
  }

  void _copy() {
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2),
        () { if (mounted) setState(() => _copied = false); });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Code "${widget.promo['code']}" copied! ✅'),
      backgroundColor: const Color(0xFF131929), behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.promo['color'] as int);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: kAppBar(widget.promo['title'] as String, context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Hero banner
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                child: Text(widget.promo['discount'] as String? ?? 'OFF',
                    style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 16),
              Text(widget.promo['title'] as String,
                  style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(widget.promo['sub'] as String? ?? '',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center),
            ]),
          ),
          const SizedBox(height: 24),

          // Promo code
          const Text('Promo Code',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131929), borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.4), width: 1.5),
                ),
                child: Text(widget.promo['code'] as String? ?? '',
                    style: TextStyle(color: color, fontSize: 20,
                        fontWeight: FontWeight.w900, letterSpacing: 3)),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _copy,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.3))),
                child: Icon(_copied ? Icons.check : Icons.copy_outlined, color: color, size: 22),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // Details
          const Text('Offer Details',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _detail(Icons.access_time,    'Expires',   widget.promo['expires'] as String? ?? 'No expiry'),
          _detail(Icons.ev_station,     'Valid at',  'All ChargeGuard stations'),
          _detail(Icons.person_outline, 'Usage',     'Once per account'),
          _detail(Icons.info_outline,   'Terms',     'Cannot combine with other offers'),
          const SizedBox(height: 28),

          // Claim button
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: _claimed ? null : () => setState(() => _claimed = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                disabledBackgroundColor: Colors.white.withOpacity(0.07),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _claimed ? 'Offer Claimed ✓' : 'Claim Offer',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _detail(IconData icon, String label, String val) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Icon(icon, color: Colors.white38, size: 18),
      const SizedBox(width: 10),
      Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
      Expanded(child: Text(val, style: const TextStyle(color: Colors.white70, fontSize: 13))),
    ]),
  );
}
