import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import 'payment_methods_screen.dart';

class BookingFormScreen extends StatefulWidget {
  final Map<String, dynamic>? station;
  const BookingFormScreen({super.key, this.station});
  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  DateTime? _selectedDateTime;
  bool      _loading = false;
  final _promoCtrl = TextEditingController();
  bool _validatingPromo = false;
  Map<String, dynamic>? _appliedPromo; // {code, discount, finalAmount, ...}
  String? _promoError;

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyPromo() async {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() { _validatingPromo = true; _promoError = null; });
    final res = await ApiService.instance.validatePromo(code, amount: 5);
    if (!mounted) return;
    setState(() {
      _validatingPromo = false;
      if (res['success']) {
        _appliedPromo = res['data'] as Map<String, dynamic>;
      } else {
        _promoError = res['message'] as String? ?? 'Invalid code';
      }
    });
  }

  void _removePromo() {
    setState(() {
      _appliedPromo = null;
      _promoCtrl.clear();
      _promoError = null;
    });
  }

  // ── Pick Date & Time ──────────────────────────────────────
  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    // Pick Date
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
              primary: kGreen, surface: Color(0xFF1A2332))),
        child: child!));

    if (date == null || !mounted) return;

    // Pick Time
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
              primary: kGreen, surface: Color(0xFF1A2332))),
        child: child!));

    if (time == null || !mounted) return;

    final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    // Validate — no past times
    if (selected.isBefore(now.add(const Duration(minutes: 30)))) {
      _snack('Please select a time at least 30 minutes from now', isError: true);
      return;
    }

    setState(() => _selectedDateTime = selected);
  }

  String get _formattedDate {
    if (_selectedDateTime == null) return '';
    final d = _selectedDateTime!;
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String get _formattedTime {
    if (_selectedDateTime == null) return '';
    final d    = _selectedDateTime!;
    final h    = d.hour > 12 ? d.hour - 12 : d.hour == 0 ? 12 : d.hour;
    final m    = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  // ── Confirm Booking ───────────────────────────────────────
  Future<void> _confirm() async {
    if (_selectedDateTime == null) {
      _snack('Please select a date and time', isError: true);
      return;
    }

    setState(() => _loading = true);

    final stationId = widget.station?['_id'] as String? ?? '';
    final result = await ApiService.instance.createBooking(
      stationId: stationId,
      date:      _formattedDate,
      time:      _formattedTime,
      promoCode: _appliedPromo?['code'] as String?,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success']) {
      // Update balance locally — use the actual final amount paid
      final paid = (_appliedPromo != null
          ? (_appliedPromo!['finalAmount'] as num?)?.toDouble()
          : null) ?? 5.0;
      UserSession.instance.updateBalance(UserSession.instance.balance - paid);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle, color: kGreen, size: 18), SizedBox(width: 8),
          Text('Booking confirmed! ✅'),
        ]),
        backgroundColor: cCard, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
    } else {
      _snack(result['message'] ?? 'Booking failed', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? kRed : cCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  @override
  Widget build(BuildContext context) {
    final station = widget.station;
    final stName  = station?['name']      as String? ?? 'Unknown Station';
    final price   = station?['price']?.toString() ?? '2.5';
    final conn    = station?['connector'] as String? ?? 'CCS2';
    final balance = UserSession.instance.balance;

    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Book Charger', context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Station info
          Container(padding: const EdgeInsets.all(14), decoration: kCardDeco(),
            child: Row(children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.ev_station, color: kGreen, size: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(stName, style: kTitle(14)),
                Text('$conn · $price NIS/kWh', style: kSub(12)),
              ])),
            ])),
          const SizedBox(height: 20),

          // Balance warning
          if (balance < 5)
            Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 18), const SizedBox(width: 8),
                  Expanded(child: Text('Low balance (${balance.toStringAsFixed(2)} NIS). Top up to book.',
                      style: const TextStyle(color: Colors.orange, fontSize: 12))),
                ]),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()));
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Top Up Wallet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange, foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
              ])),

          // Date & Time Picker
          Text('Select Date & Time', style: kTitle(15)),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: _pickDateTime,
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _selectedDateTime != null ? kGreen.withOpacity(0.06) : cCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _selectedDateTime != null ? kGreen.withOpacity(0.4) : cBorder,
                    width: 1.5)),
              child: _selectedDateTime == null
                  ? Row(children: [
                      const Icon(Icons.calendar_today_outlined, color: kGreen, size: 22),
                      const SizedBox(width: 12),
                      Text('Tap to choose date & time', style: TextStyle(color: cSub, fontSize: 15)),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, color: kGreen, size: 14),
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.calendar_today, color: kGreen, size: 18),
                        const SizedBox(width: 8),
                        Text(_formattedDate,
                            style: const TextStyle(color: kGreen, fontSize: 16, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        GestureDetector(
                          onTap: _pickDateTime,
                          child: const Text('Change',
                              style: TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w600))),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.access_time, color: kGreen, size: 18),
                        const SizedBox(width: 8),
                        Text(_formattedTime,
                            style: TextStyle(color: cTitle, fontSize: 15, fontWeight: FontWeight.w700)),
                      ]),
                    ])),
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.info_outline, color: kGreen, size: 13), const SizedBox(width: 5),
            Text('Must be at least 30 minutes from now', style: kSub(11)),
          ]),
          const SizedBox(height: 24),

          // Promo code
          Text('Promo Code', style: kTitle(15)),
          const SizedBox(height: 8),
          if (_appliedPromo == null) ...[
            Row(children: [
              Expanded(child: TextField(
                controller: _promoCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter code',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              )),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _validatingPromo ? null : _applyPromo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen, foregroundColor: Colors.black,
                  minimumSize: const Size(80, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _validatingPromo
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
            if (_promoError != null) Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(_promoError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kGreen.withOpacity(0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle, color: kGreen, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${_appliedPromo!['code']} applied',
                      style: const TextStyle(color: kGreen, fontWeight: FontWeight.w800)),
                  Text(
                    'Saved ${(_appliedPromo!['discount'] as num).toStringAsFixed(2)} NIS',
                    style: kSub(12),
                  ),
                ])),
                IconButton(
                  icon: const Icon(Icons.close, color: kGreen),
                  onPressed: _removePromo,
                ),
              ]),
            ),
          const SizedBox(height: 24),

          // Summary
          if (_selectedDateTime != null) ...[
            Builder(builder: (_) {
              final fee = 5.0;
              final discount = (_appliedPromo?['discount'] as num?)?.toDouble() ?? 0;
              final finalFee = (_appliedPromo?['finalAmount'] as num?)?.toDouble() ?? fee;
              return Container(padding: const EdgeInsets.all(16), decoration: kCardDeco(),
                child: Column(children: [
                  _row('Station',    stName),
                  _row('Date',       _formattedDate),
                  _row('Time',       _formattedTime),
                  _row('Price',      '$price NIS/kWh'),
                  _row('Connector',  conn),
                  _row('Booking Fee','${fee.toStringAsFixed(2)} NIS'),
                  if (_appliedPromo != null)
                    _row('Promo (${_appliedPromo!['code']})',
                         '-${discount.toStringAsFixed(2)} NIS',
                         valueColor: kGreen),
                  Divider(color: cBorder, height: 16),
                  _row('Total',
                      '${finalFee.toStringAsFixed(2)} NIS',
                      valueColor: kGreen),
                  _row('Balance After',
                      'NIS ${(balance - finalFee).toStringAsFixed(2)}',
                      valueColor: balance < finalFee ? kRed : kGreen),
                ]));
            }),
            const SizedBox(height: 28),
          ],

          Builder(builder: (_) {
            final required = (_appliedPromo?['finalAmount'] as num?)?.toDouble() ?? 5.0;
            return SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: (_loading || balance < required || _selectedDateTime == null) ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                disabledBackgroundColor: kGreen.withOpacity(0.2),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                  : Text(
                      _selectedDateTime == null ? 'Select Date & Time First' : 'Confirm Booking',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))));
          }),
        ]),
      ),
    );
  }

  Widget _row(String label, String val, {Color? valueColor}) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Text(label, style: kSub(13)), const Spacer(),
        Text(val, style: TextStyle(
            color: valueColor ?? cTitle, fontSize: 13, fontWeight: FontWeight.w700)),
      ]));
}
