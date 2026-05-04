import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import 'payment_methods_screen.dart';

class StartChargeScreen extends StatefulWidget {
  final Map<String, dynamic>? station;
  const StartChargeScreen({super.key, this.station});
  @override
  State<StartChargeScreen> createState() => _StartChargeScreenState();
}

class _StartChargeScreenState extends State<StartChargeScreen>
    with TickerProviderStateMixin {

  bool   _isCharging = false;
  bool   _isLoading  = false;
  bool   _isDone     = false;
  int    _seconds    = 0;
  double _kwh        = 0.0;
  double _cost       = 0.0;
  int    _batteryPct = 0; // will be set from UserSession
  double _newBalance = 0;
  int    _pointsEarned = 0;

  Map<String, dynamic>? _selectedStation;
  Timer? _timer;

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _selectedStation = widget.station;
    _batteryPct = UserSession.instance.batteryPct; // sync with home
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _startCharge() async {
    if (_selectedStation == null) { _snack('Please select a station first'); return; }

    // ── Check balance ─────────────────────────────────────
    final balance = UserSession.instance.balance;
    if (balance <= 0) {
      showModalBottomSheet(
        context: context, backgroundColor: cCard,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 60, height: 60,
                decoration: BoxDecoration(color: kRed.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet_outlined, color: kRed, size: 30)),
            const SizedBox(height: 16),
            Text('Insufficient Balance', style: kTitle(18)),
            const SizedBox(height: 8),
            Text('Your wallet balance is NIS ${balance.toStringAsFixed(2)}.\nPlease top up to start charging.',
                style: kSub(13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()));
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Top Up Wallet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: cSub, fontSize: 14)))),
          ])));
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.instance.startCharging(
        _selectedStation!['_id'] as String);

    setState(() => _isLoading = false);
    if (!result['success']) { _snack(result['message'] ?? 'Failed'); return; }

    final price = (_selectedStation!['price'] as num?)?.toDouble() ?? 2.5;
    final stName = _selectedStation!['name'] as String? ?? 'Station';

    setState(() { _isCharging = true; _seconds = 0; _kwh = 0; _cost = 0; });

    // Update global session
    UserSession.instance.startChargingSession(
        _selectedStation!['_id'] as String, stName);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _seconds++;
        _kwh  = _seconds * 0.006;
        _cost = _kwh * price;
        if (_batteryPct < 100 && _seconds % 10 == 0) _batteryPct++;
      });
      // Update global session every second
      UserSession.instance.updateChargingSession(_seconds, _kwh, _cost);
    });
  }

  Future<void> _stopCharge() async {
    _timer?.cancel();
    setState(() => _isLoading = true);

    final result = await ApiService.instance.stopCharging(
      stationId:  _selectedStation!['_id'] as String,
      kwhCharged: _kwh,
      duration:   _seconds,
      batteryPct: _batteryPct,
    );

    setState(() => _isLoading = false);
    if (!result['success']) { _snack(result['message'] ?? 'Error'); return; }

    final data = result['data'] as Map<String, dynamic>;
    setState(() {
      _isCharging   = false;
      _isDone       = true;
      _newBalance   = (data['newBalance'] as num?)?.toDouble() ?? 0;
      _pointsEarned = (data['pointsEarned'] as num?)?.toInt() ?? 0;
    });
    UserSession.instance.updateBalance(_newBalance);
    UserSession.instance.stopChargingSession(_batteryPct);
  }

  void _pickStation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
        context, MaterialPageRoute(builder: (_) => const _StationPickerScreen()));
    if (result != null) setState(() => _selectedStation = result);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: cCard, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    if (m > 0) return '${m}m ${sec}s';
    return '${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Start Charging', context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isDone ? _buildDone() : _buildMain(),
      ),
    );
  }

  // ── Done ──────────────────────────────────────────────────
  Widget _buildDone() {
    return Column(children: [
      const SizedBox(height: 20),
      Container(
        width: 120, height: 120,
        decoration: BoxDecoration(color: kGreen.withOpacity(0.1), shape: BoxShape.circle,
            border: Border.all(color: kGreen, width: 3)),
        child: const Icon(Icons.check_circle, color: kGreen, size: 60)),
      const SizedBox(height: 20),
      Text('Charging Complete!', style: kTitle(22)),
      const SizedBox(height: 8),
      Text('Session saved to your history', style: kSub(14)),
      const SizedBox(height: 30),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: kCardDeco(),
        child: Column(children: [
          _row('Station',    _selectedStation?['name'] ?? 'Unknown'),
          _row('Duration',   _fmt(_seconds)),
          _row('kWh Charged','${_kwh.toStringAsFixed(3)} kWh'),
          _row('Total Cost', '${_cost.toStringAsFixed(2)} NIS'),
          Divider(color: cBorder, height: 24),
          _row('New Balance','NIS ${_newBalance.toStringAsFixed(2)}', color: kGreen),
          _row('Points',     '+$_pointsEarned pts', color: kGreen),
        ])),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: const Text('Back to Home', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)))),
    ]);
  }

  // ── Main ──────────────────────────────────────────────────
  Widget _buildMain() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Station selection
      if (!_isCharging) ...[
        Text('Station', style: kTitle(16)),
        const SizedBox(height: 12),
        _selectedStation != null ? _buildStationCard() : _buildPickStation(),
        const SizedBox(height: 24),
      ],

      // Charging animation
      if (_isCharging) ...[
        Center(child: _buildPulse()),
        const SizedBox(height: 24),
        Row(children: [
          _liveCard('⏱️', _fmt(_seconds), 'Duration'),
          const SizedBox(width: 12),
          _liveCard('⚡', _kwh.toStringAsFixed(3), 'kWh'),
          const SizedBox(width: 12),
          _liveCard('💰', _cost.toStringAsFixed(2), 'NIS'),
        ]),
        const SizedBox(height: 20),
        Text('Battery Level', style: kSub(13)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _batteryPct / 100,
            backgroundColor: cBorder,
            valueColor: const AlwaysStoppedAnimation(kGreen),
            minHeight: 14)),
        const SizedBox(height: 4),
        Text('$_batteryPct%',
            style: const TextStyle(color: kGreen, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 24),
      ],

      // Info
      if (!_isCharging && _selectedStation != null) ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: kCardDeco(),
          child: Column(children: [
            _row('Power',     _selectedStation!['power'] ?? '22 kW'),
            _row('Connector', _selectedStation!['connector'] ?? 'CCS2'),
            _row('Price',     '${_selectedStation!['price']} NIS/kWh'),
            _row('Balance',   'NIS ${UserSession.instance.balance.toStringAsFixed(2)}'),
          ])),
        const SizedBox(height: 24),
      ],

      // Button
      SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : (_isCharging ? _stopCharge : _startCharge),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isCharging ? Colors.redAccent : kGreen,
            disabledBackgroundColor: kGreen.withOpacity(0.3),
            foregroundColor: _isCharging ? Colors.white : Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: _isLoading
              ? const SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_isCharging ? Icons.stop : Icons.bolt, size: 22),
                  const SizedBox(width: 8),
                  Text(_isCharging ? 'Stop Charging' : 'Start Charging',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ])),
      ),

      // Low balance warning
      if (!_isCharging && UserSession.instance.balance <= 0) ...[
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: kRed.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kRed.withOpacity(0.25))),
          child: Row(children: [
            Icon(Icons.warning_amber_outlined, color: kRed, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('No balance — top up your wallet first',
                style: TextStyle(color: kRed, fontSize: 12))),
          ])),
      ],
    ]);
  }

  Widget _buildPulse() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnim.value,
          child: Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kGreen.withOpacity(0.1),
              border: Border.all(color: kGreen, width: 3),
              boxShadow: [BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 30)]),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.bolt, color: kGreen, size: 48),
              Text('$_batteryPct%',
                  style: const TextStyle(color: kGreen, fontSize: 32, fontWeight: FontWeight.w900)),
              Text('Charging', style: kSub(12)),
            ])));
      });
  }

  Widget _buildStationCard() {
    final s = _selectedStation!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: kCardDeco(),
      child: Row(children: [
        Container(width: 44, height: 44,
            decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.ev_station, color: kGreen, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s['name'] as String, style: kTitle(14)),
          Text('${s['power']} · ${s['connector']}', style: kSub(12)),
        ])),
        if (!_isCharging)
          GestureDetector(
            onTap: _pickStation,
            child: const Text('Change',
                style: TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w700))),
      ]));
  }

  Widget _buildPickStation() {
    return GestureDetector(
      onTap: _pickStation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: kCardDeco(),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add_circle_outline, color: kGreen, size: 24),
          const SizedBox(width: 10),
          Text('Choose a Station', style: TextStyle(color: kGreen, fontWeight: FontWeight.w700)),
        ])));
  }

  Widget _liveCard(String emoji, String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: kGreen.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kGreen.withOpacity(0.25))),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(color: kGreen, fontSize: 15, fontWeight: FontWeight.w800)),
          Text(label, style: kSub(10)),
        ])));
  }

  Widget _row(String label, String val, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text(label, style: kSub(13)),
        const Spacer(),
        Text(val, style: TextStyle(color: color ?? cTitle, fontSize: 13, fontWeight: FontWeight.w700)),
      ]));
  }
}

// ════════════════════════════════════════
//  Station Picker
// ════════════════════════════════════════
class _StationPickerScreen extends StatefulWidget {
  const _StationPickerScreen();
  @override
  State<_StationPickerScreen> createState() => _StationPickerScreenState();
}

class _StationPickerScreenState extends State<_StationPickerScreen> {
  List<dynamic> _stations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
      appBar: kAppBar('Choose Station', context),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _stations.length,
              itemBuilder: _buildItem),
    );
  }

  Widget _buildItem(BuildContext context, int i) {
    final s  = _stations[i] as Map<String, dynamic>;
    final ok = s['available'] as bool? ?? true;

    return GestureDetector(
      onTap: ok ? () => Navigator.pop(context, s) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: kCardDeco(),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: ok ? kGreen.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.ev_station, color: ok ? kGreen : Colors.grey, size: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s['name'] as String,
                  style: TextStyle(
                      color: ok ? cTitle : cSub2,
                      fontSize: 14, fontWeight: FontWeight.w700)),
              Text('${s['power']} · ${s['price']} NIS/kWh', style: kSub(12)),
            ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ok ? kGreen.withOpacity(0.12) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20)),
            child: Text(
              ok ? 'Available' : 'Busy',
              style: TextStyle(
                  color: ok ? kGreen : Colors.grey,
                  fontSize: 11, fontWeight: FontWeight.w700))),
        ])));
  }
}
