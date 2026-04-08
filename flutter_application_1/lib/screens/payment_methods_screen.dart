import 'package:flutter/material.dart';
import '../utils/constants.dart';

// ════════════════════════════════════════
//  PAYMENT METHODS SCREEN
// ════════════════════════════════════════
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});
  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  double _balance    = 124.50;
  int    _defaultIdx = 0;

  final List<Map<String, dynamic>> _cards = [
    {
      'type':   'Visa',
      'number': '4532 •••• •••• 7891',
      'holder': 'Ahmed Al-Rashidi',
      'expiry': '12/26',
      'color1': 0xFF1A1F71,
      'color2': 0xFF2563EB,
      'icon':   'VISA',
    },
    {
      'type':   'Mastercard',
      'number': '5412 •••• •••• 3344',
      'holder': 'Ahmed Al-Rashidi',
      'expiry': '08/25',
      'color1': 0xFF1A1A1A,
      'color2': 0xFF333333,
      'icon':   'MC',
    },
  ];

  final List<Map<String, dynamic>> _transactions = [
    {'label': 'An-Najah EV Station', 'date': 'Apr 4',  'amount': '-35.5',  'type': 'charge'},
    {'label': 'Booking Fee',          'date': 'Apr 3',  'amount': '-5.0',   'type': 'booking'},
    {'label': 'Refund — City Mall',   'date': 'Apr 1',  'amount': '+18.0',  'type': 'refund'},
    {'label': 'Campus Green Charger', 'date': 'Mar 30', 'amount': '-22.5',  'type': 'charge'},
    {'label': 'Loyalty Reward',       'date': 'Mar 28', 'amount': '+5.0',   'type': 'reward'},
  ];

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? kRed : cCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  // ── Top Up ────────────────────────────────────────────────
  void _topUp() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TopUpSheet(cards: _cards, defaultIdx: _defaultIdx, balance: _balance));

    if (result != null && mounted) {
      setState(() {
        _balance += result['amount'] as double;
        _transactions.insert(0, {
          'label': 'Wallet Top Up (${result['cardIcon']})',
          'date':  'Now',
          'amount': '+${(result['amount'] as double).toStringAsFixed(1)}',
          'type':  'topup',
        });
      });
      _snack('NIS ${(result['amount'] as double).toStringAsFixed(2)} added! ✅');
    }
  }

  // ── Transfer ──────────────────────────────────────────────
  void _transfer() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TransferSheet(balance: _balance));

    if (result != null && mounted) {
      final amount = result['amount'] as double;
      if (amount > _balance) { _snack('Insufficient balance!', isError: true); return; }
      setState(() {
        _balance -= amount;
        _transactions.insert(0, {
          'label': 'Transfer → ${result['typeName']}',
          'date':  'Now',
          'amount': '-${amount.toStringAsFixed(1)}',
          'type':  'transfer',
        });
      });
      _snack('NIS ${amount.toStringAsFixed(2)} transferred! ✅');
    }
  }

  // ── Add Card ──────────────────────────────────────────────
  void _addCard() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddCardSheet());

    if (result != null && mounted) {
      setState(() => _cards.add(result));
      _snack('Card added! ✅');
    }
  }

  // ── Card Options ──────────────────────────────────────────
  void _cardOptions(int idx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: cBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(_cards[idx]['number'] as String, style: kTitle(16)),
          const SizedBox(height: 20),
          if (_defaultIdx != idx) _optTile(Icons.star_outline, kGreen, 'Set as Default', () {
            setState(() => _defaultIdx = idx);
            Navigator.pop(context);
            _snack('Default card updated! ✅');
          }),
          _optTile(Icons.delete_outline, Colors.redAccent, 'Remove Card', () {
            setState(() {
              _cards.removeAt(idx);
              if (_defaultIdx >= _cards.length) _defaultIdx = 0;
            });
            Navigator.pop(context);
            _snack('Card removed');
          }),
          _optTile(Icons.close, cSub, 'Cancel', () => Navigator.pop(context)),
        ])));
  }

  Widget _optTile(IconData icon, Color color, String label, VoidCallback onTap) =>
    GestureDetector(onTap: onTap,
      child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Row(children: [
          Icon(icon, color: color, size: 20), const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
        ])));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Payment Methods', context, actions: [
        IconButton(icon: const Icon(Icons.add_circle_outline, color: kGreen), onPressed: _addCard),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Balance Card
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF00E5A0), Color(0xFF00B37A)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Wallet Balance',
                  style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('NIS ${_balance.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.black, fontSize: 38, fontWeight: FontWeight.w900, height: 1)),
              const SizedBox(height: 14),
              Row(children: [
                _balBtn(Icons.add, 'Top Up', _topUp),
                const SizedBox(width: 10),
                _balBtn(Icons.send_outlined, 'Transfer', _transfer),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Saved Cards
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Saved Cards', style: kTitle(15)),
            GestureDetector(onTap: _addCard,
              child: const Text('+ Add New',
                  style: TextStyle(color: kGreen, fontSize: 13, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 14),

          if (_cards.isEmpty)
            Container(width: double.infinity, padding: const EdgeInsets.all(30),
              decoration: kCardDeco(), alignment: Alignment.center,
              child: Column(children: [
                Icon(Icons.credit_card_off_outlined, color: cSub2, size: 40),
                const SizedBox(height: 12),
                Text('No cards saved', style: kTitle(14)),
                const SizedBox(height: 6),
                Text('Add a card to pay faster', style: kSub(12)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _addCard,
                  style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Add Card', style: TextStyle(fontWeight: FontWeight.w800))),
              ]))
          else ...[
            ..._cards.asMap().entries.map((e) {
              final i = e.key;
              final c = e.value;
              final isDefault = _defaultIdx == i;
              return GestureDetector(
                onLongPress: () => _cardOptions(i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14), height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(c['color1'] as int), Color(c['color2'] as int)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    border: isDefault ? Border.all(color: kGreen, width: 2.5) : null,
                    boxShadow: [BoxShadow(color: Color(c['color1'] as int).withOpacity(0.4),
                        blurRadius: 16, offset: const Offset(0, 6))]),
                  child: Padding(padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(c['icon'] as String,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                        const Spacer(),
                        if (isDefault) Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(20)),
                          child: const Text('Default',
                              style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w800))),
                        const SizedBox(width: 8),
                        GestureDetector(onTap: () => _cardOptions(i),
                          child: const Icon(Icons.more_horiz, color: Colors.white60, size: 22)),
                      ]),
                      const Spacer(),
                      Text(c['number'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 15,
                              fontWeight: FontWeight.w600, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('CARD HOLDER',
                              style: TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1)),
                          Text(c['holder'] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                        const Spacer(),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('EXPIRES',
                              style: TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 1)),
                          Text(c['expiry'] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ]),
                    ])),
                ),
              );
            }),
            Text('Hold card to set default or remove', style: kSub(11)),
            const SizedBox(height: 24),
          ],

          // ── Transactions
          Text('Transaction History', style: kTitle(15)),
          const SizedBox(height: 12),
          Container(decoration: kCardDeco(),
            child: Column(children: _transactions.asMap().entries.map((e) {
              final i   = e.key;
              final t   = e.value;
              final isLast = i == _transactions.length - 1;
              final isPlus = (t['amount'] as String).startsWith('+');
              const iconMap = <String, IconData>{
                'charge': Icons.bolt, 'booking': Icons.calendar_today_outlined,
                'refund': Icons.refresh, 'reward': Icons.star_outline,
                'topup': Icons.add_circle_outline, 'transfer': Icons.send_outlined,
              };
              final colorMap = <String, Color>{
                'charge': Colors.blueAccent, 'booking': Colors.orange,
                'refund': kGreen, 'reward': kGreen,
                'topup': kGreen, 'transfer': Colors.blueAccent,
              };
              final ic  = iconMap[t['type']] ?? Icons.circle;
              final col = colorMap[t['type']] ?? cSub;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(border: !isLast
                    ? Border(bottom: BorderSide(color: cBorder)) : null),
                child: Row(children: [
                  Container(width: 40, height: 40,
                      decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(ic, color: col, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t['label'] as String,
                        style: TextStyle(color: cTitle, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(t['date'] as String, style: kSub(11)),
                  ])),
                  Text('${t['amount']} NIS',
                      style: TextStyle(color: isPlus ? kGreen : cTitle,
                          fontSize: 13, fontWeight: FontWeight.w800)),
                ]));
            }).toList())),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _balBtn(IconData icon, String label, VoidCallback onTap) =>
    GestureDetector(onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.black87, size: 16), const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w700)),
        ])));
}

// ════════════════════════════════════════
//  TOP UP SHEET
// ════════════════════════════════════════
class _TopUpSheet extends StatefulWidget {
  final List<Map<String, dynamic>> cards;
  final int    defaultIdx;
  final double balance;
  const _TopUpSheet({required this.cards, required this.defaultIdx, required this.balance});
  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final _amtCtrl = TextEditingController();
  double? _parsed;
  int _selCard = 0;
  final _quick = [10.0, 25.0, 50.0, 100.0, 200.0];

  @override
  void initState() {
    super.initState();
    _selCard = widget.defaultIdx;
  }

  @override
  void dispose() { _amtCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
            decoration: BoxDecoration(color: cBorder, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: kGreen.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.add, color: kGreen, size: 24)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Top Up Wallet', style: kTitle(18)),
            Text('Balance: ${widget.balance.toStringAsFixed(2)} NIS', style: kSub(12)),
          ]),
        ]),
        const SizedBox(height: 20),

        // Amount
        TextField(
          controller: _amtCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => setState(() => _parsed = double.tryParse(v)),
          style: TextStyle(color: cTitle, fontSize: 22, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '0.00', hintStyle: TextStyle(color: cSub2, fontSize: 22),
            prefixText: 'NIS  ',
            prefixStyle: const TextStyle(color: kGreen, fontSize: 18, fontWeight: FontWeight.w700),
            filled: true, fillColor: cBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: cBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: kGreen, width: 2)))),
        const SizedBox(height: 12),

        // Quick amounts
        Row(children: _quick.map((a) {
          final sel = _parsed == a;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _amtCtrl.text = a.toStringAsFixed(0);
                _parsed = a;
              }),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? kGreen.withOpacity(0.12) : cBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? kGreen : cBorder)),
                child: Center(
                  child: Text(a.toStringAsFixed(0),
                      style: TextStyle(
                          color: sel ? kGreen : cSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w700))))));
        }).toList()),
        const SizedBox(height: 16),

        // Card selection
        Text('Pay from:', style: kSub(13)),
        const SizedBox(height: 10),
        ...List.generate(widget.cards.length, (i) {
          final c   = widget.cards[i];
          final sel = _selCard == i;
          return GestureDetector(
            onTap: () => setState(() => _selCard = i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sel ? kGreen.withOpacity(0.06) : cBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? kGreen : cBorder, width: 1.5)),
              child: Row(children: [
                Text(c['icon'] as String,
                    style: TextStyle(color: sel ? kGreen : cSub, fontSize: 13, fontWeight: FontWeight.w900)),
                const SizedBox(width: 12),
                Expanded(child: Text(c['number'] as String,
                    style: TextStyle(color: sel ? cTitle : cSub, fontSize: 13))),
                if (sel) const Icon(Icons.check_circle, color: kGreen, size: 18),
              ])));
        }),
        const SizedBox(height: 20),

        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: (_parsed != null && _parsed! > 0)
                ? () => Navigator.pop(context, {
                    'amount': _parsed,
                    'cardIcon': widget.cards[_selCard]['icon'],
                  })
                : null,
            style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                disabledBackgroundColor: kGreen.withOpacity(0.2),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text(
              _parsed != null && _parsed! > 0
                  ? 'Top Up  NIS ${_parsed!.toStringAsFixed(2)}'
                  : 'Enter Amount',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)))),
      ]),
    );
  }
}

// ════════════════════════════════════════
//  TRANSFER SHEET
// ════════════════════════════════════════
class _TransferSheet extends StatefulWidget {
  final double balance;
  const _TransferSheet({required this.balance});
  @override
  State<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<_TransferSheet> {
  int    _step      = 1;
  String _type      = '';   // 'user' | 'card' | 'paypal'
  String _typeName  = '';
  double? _parsed;
  final _amtCtrl    = TextEditingController();
  final _destCtrl   = TextEditingController();

  @override
  void dispose() { _amtCtrl.dispose(); _destCtrl.dispose(); super.dispose(); }

  static const _typeConfig = {
    'user':   {'label': 'Phone Number',  'hint': '+970 5X XXX XXXX',              'icon': Icons.phone_outlined},
    'card':   {'label': 'IBAN Number',   'hint': 'PS00 XXXX XXXX XXXX XXXX XXXX', 'icon': Icons.credit_card_outlined},
    'paypal': {'label': 'PayPal Email',  'hint': 'example@paypal.com',            'icon': Icons.email_outlined},
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
            decoration: BoxDecoration(color: cBorder, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        // Header
        Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.send_outlined, color: Colors.blueAccent, size: 20)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Transfer Funds', style: kTitle(17)),
            Text('Step $_step of 3', style: kSub(12)),
          ]),
          const Spacer(),
          Row(children: List.generate(3, (i) => Container(
            margin: const EdgeInsets.only(left: 4),
            width: i + 1 <= _step ? 20 : 8, height: 6,
            decoration: BoxDecoration(
                color: i + 1 <= _step ? kGreen : cBorder,
                borderRadius: BorderRadius.circular(3))))),
        ]),
        const SizedBox(height: 20),

        if (_step == 1) _step1(),
        if (_step == 2) _step2(),
        if (_step == 3) _step3(),
      ]),
    );
  }

  // ── Step 1: Choose type ───────────────────────────────────
  Widget _step1() => Column(mainAxisSize: MainAxisSize.min, children: [
    Text('Where to transfer?', style: kSub(13)),
    const SizedBox(height: 14),
    _typeOption(Icons.person_outline,   kGreen,               'ChargeGuard User',
        'Transfer to a friend by phone',  'user',   'ChargeGuard User'),
    const SizedBox(height: 10),
    _typeOption(Icons.credit_card_outlined, Colors.blueAccent, 'Bank Card',
        'Withdraw to your card via IBAN',  'card',   'Bank Card'),
    const SizedBox(height: 10),
    _typeOption(Icons.account_balance_wallet_outlined, const Color(0xFF003087), 'PayPal',
        'Send to a PayPal email address',  'paypal', 'PayPal'),
  ]);

  Widget _typeOption(IconData icon, Color color, String title, String sub,
      String type, String name) =>
    GestureDetector(
      onTap: () => setState(() { _type = type; _typeName = name; _step = 2; }),
      child: Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Row(children: [
          Container(width: 42, height: 42,
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: cTitle, fontSize: 14, fontWeight: FontWeight.w700)),
            Text(sub, style: kSub(11)),
          ])),
          Icon(Icons.arrow_forward_ios, color: color, size: 14),
        ])));

  // ── Step 2: Enter details ─────────────────────────────────
  Widget _step2() {
    final cfg = _typeConfig[_type]!;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: () => setState(() => _step = 1),
        child: Row(children: [
          Icon(Icons.arrow_back_ios_new, size: 14, color: cSub),
          const SizedBox(width: 4),
          Text('Back', style: TextStyle(color: cSub, fontSize: 13)),
        ])),
      const SizedBox(height: 16),

      // Amount
      TextField(
        controller: _amtCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (v) => setState(() => _parsed = double.tryParse(v)),
        style: TextStyle(color: cTitle, fontSize: 22, fontWeight: FontWeight.w800),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: '0.00', hintStyle: TextStyle(color: cSub2, fontSize: 22),
          prefixText: 'NIS  ',
          prefixStyle: const TextStyle(color: kGreen, fontSize: 18, fontWeight: FontWeight.w700),
          filled: true, fillColor: cBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: cBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: cBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kGreen, width: 2)))),
      const SizedBox(height: 6),
      Text('Balance: ${widget.balance.toStringAsFixed(2)} NIS', style: kSub(12)),
      const SizedBox(height: 14),

      // Destination
      TextField(
        controller: _destCtrl,
        onChanged: (_) => setState(() {}),
        keyboardType: _type == 'user' ? TextInputType.phone
            : _type == 'paypal' ? TextInputType.emailAddress
            : TextInputType.text,
        style: TextStyle(color: cTitle, fontSize: 15),
        decoration: InputDecoration(
          labelText: cfg['label'] as String, labelStyle: TextStyle(color: cSub),
          hintText: cfg['hint'] as String, hintStyle: TextStyle(color: cSub2, fontSize: 12),
          prefixIcon: Icon(cfg['icon'] as IconData, color: cSub2, size: 20),
          filled: true, fillColor: cBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: cBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: cBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kGreen, width: 1.5)))),
      const SizedBox(height: 20),

      SizedBox(width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: (_parsed != null && _parsed! > 0 && _destCtrl.text.trim().isNotEmpty)
              ? () {
                  if (_parsed! > widget.balance) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Insufficient balance!'),
                      backgroundColor: kRed, behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                    return;
                  }
                  setState(() => _step = 3);
                }
              : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: kGreen, disabledBackgroundColor: kGreen.withOpacity(0.2),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: const Text('Review Transfer',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)))),
    ]);
  }

  // ── Step 3: Confirm ───────────────────────────────────────
  Widget _step3() => Column(mainAxisSize: MainAxisSize.min, children: [
    GestureDetector(
      onTap: () => setState(() => _step = 2),
      child: Row(children: [
        Icon(Icons.arrow_back_ios_new, size: 14, color: cSub),
        const SizedBox(width: 4),
        Text('Back', style: TextStyle(color: cSub, fontSize: 13)),
      ])),
    const SizedBox(height: 16),

    // Summary
    Container(width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kGreen.withOpacity(0.06), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kGreen.withOpacity(0.25))),
      child: Column(children: [
        const Icon(Icons.send_outlined, color: kGreen, size: 36),
        const SizedBox(height: 12),
        Text('NIS ${_parsed!.toStringAsFixed(2)}',
            style: const TextStyle(color: kGreen, fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        _row('To',            _typeName),
        _row('Destination',   _destCtrl.text),
        _row('From',          'ChargeGuard Wallet'),
        _row('After transfer','NIS ${(widget.balance - _parsed!).toStringAsFixed(2)}'),
      ])),
    const SizedBox(height: 14),

    // Warning
    Container(padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withOpacity(0.25))),
      child: Row(children: [
        const Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text('Transfers cannot be reversed. Verify details.',
            style: TextStyle(color: cSub, fontSize: 11))),
      ])),
    const SizedBox(height: 16),

    SizedBox(width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, {
          'amount':   _parsed,
          'typeName': _typeName,
        }),
        style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: const Text('Confirm Transfer',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)))),
  ]);

  Widget _row(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Text('$label:', style: kSub(13)), const Spacer(),
      Text(val, style: TextStyle(color: cTitle, fontSize: 13, fontWeight: FontWeight.w700)),
    ]));
}

// ════════════════════════════════════════
//  ADD CARD SHEET
// ════════════════════════════════════════
class _AddCardSheet extends StatefulWidget {
  const _AddCardSheet();
  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _numberCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl    = TextEditingController();
  bool   _obscureCvv = true;
  String _cardType   = 'Visa';

  @override
  void dispose() {
    _numberCtrl.dispose(); _holderCtrl.dispose();
    _expiryCtrl.dispose(); _cvvCtrl.dispose();
    super.dispose();
  }

  static const _types = ['Visa', 'Mastercard', 'PayPal'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
            decoration: BoxDecoration(color: cBorder, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text('Add New Card', style: kTitle(18)),
        const SizedBox(height: 20),

        // Type selector
        Row(children: _types.map((t) {
          final sel = _cardType == t;
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _cardType = t),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: sel ? kGreen.withOpacity(0.12) : cBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? kGreen : cBorder, width: 1.5)),
              child: Center(child: Text(t, style: TextStyle(
                  color: sel ? kGreen : cSub, fontSize: 11, fontWeight: FontWeight.w700))))));
        }).toList()),
        const SizedBox(height: 14),

        _f(_numberCtrl, 'Card Number', Icons.credit_card_outlined,
            type: TextInputType.number, hint: '0000 0000 0000 0000'),
        const SizedBox(height: 12),
        _f(_holderCtrl, 'Holder Name', Icons.person_outline, hint: 'Name on card'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _f(_expiryCtrl, 'Expiry', Icons.date_range_outlined,
              hint: 'MM/YY', type: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: TextField(
            controller: _cvvCtrl,
            obscureText: _obscureCvv,
            keyboardType: TextInputType.number,
            maxLength: 3,
            style: TextStyle(color: cTitle, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'CVV', labelStyle: TextStyle(color: cSub), counterText: '',
              prefixIcon: Icon(Icons.lock_outline, color: cSub2, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscureCvv ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: cSub2, size: 18),
                onPressed: () => setState(() => _obscureCvv = !_obscureCvv)),
              filled: true, fillColor: cBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: cBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: kGreen, width: 1.5))))),
        ]),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(color: kGreen.withOpacity(0.06), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kGreen.withOpacity(0.2))),
          child: Row(children: [
            const Icon(Icons.lock, color: kGreen, size: 15), const SizedBox(width: 8),
            Text('Your card data is encrypted and secure', style: TextStyle(color: cSub, fontSize: 11)),
          ])),
        const SizedBox(height: 16),

        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: () {
              if ([_numberCtrl, _holderCtrl, _expiryCtrl, _cvvCtrl]
                  .any((c) => c.text.trim().isEmpty)) return;
              final num = _numberCtrl.text.trim();
              final last4 = num.length >= 4 ? num.substring(num.length - 4) : '0000';
              final color1 = _cardType == 'Visa' ? 0xFF1A1F71
                  : _cardType == 'Mastercard' ? 0xFF1A1A1A : 0xFF003087;
              final color2 = _cardType == 'Visa' ? 0xFF2563EB
                  : _cardType == 'Mastercard' ? 0xFF333333 : 0xFF009CDE;
              final icon = _cardType == 'Visa' ? 'VISA'
                  : _cardType == 'Mastercard' ? 'MC' : 'PP';
              Navigator.pop(context, {
                'type':   _cardType,
                'number': '•••• •••• •••• $last4',
                'holder': _holderCtrl.text.trim(),
                'expiry': _expiryCtrl.text.trim(),
                'color1': color1,
                'color2': color2,
                'icon':   icon,
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Add Card', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)))),
      ]),
    );
  }

  Widget _f(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? type, String? hint}) =>
    TextField(controller: ctrl, keyboardType: type,
      style: TextStyle(color: cTitle, fontSize: 15),
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: cSub),
        hintText: hint, hintStyle: TextStyle(color: cSub2, fontSize: 12),
        prefixIcon: Icon(icon, color: cSub2, size: 20),
        filled: true, fillColor: cBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kGreen, width: 1.5))));
}
