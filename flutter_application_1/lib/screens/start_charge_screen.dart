import 'package:flutter/material.dart';
import '../utils/constants.dart';

class StartChargeScreen extends StatefulWidget {
  const StartChargeScreen({super.key});
  @override
  State<StartChargeScreen> createState() => _StartChargeScreenState();
}

class _StartChargeScreenState extends State<StartChargeScreen>
    with SingleTickerProviderStateMixin {
  // 0 = QR tab, 1 = Station ID tab
  int _tab = 0;

  final _idCtrl = TextEditingController();
  bool _scanning = false;
  bool _connected = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  void _simulateScan() {
    setState(() => _scanning = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() { _scanning = false; _connected = true; });
    });
  }

  void _connectById() {
    if (_idCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please enter a Station ID'),
        backgroundColor: kCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _connected = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: kAppBar('Start Charge', context),
      body: _connected ? _connectedView() : _mainView(),
    );
  }

  // ── Connected View ────────────────────────────────────────
  Widget _connectedView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Success icon
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
              color: kGreen.withOpacity(0.12), shape: BoxShape.circle,
              border: Border.all(color: kGreen.withOpacity(0.5), width: 2)),
          child: const Icon(Icons.check_circle_outline, color: kGreen, size: 52),
        ),
        const SizedBox(height: 20),
        Text('Charger Connected!', style: kTitle(22), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Station A · 50 kW · CCS2', style: kSub(14), textAlign: TextAlign.center),
        const SizedBox(height: 32),

        // Live charging stats
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [kGreen.withOpacity(0.9), const Color(0xFF00B37A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(children: [
            const Text('Charging in Progress',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 16),
            const Text('65%',
                style: TextStyle(color: Colors.black, fontSize: 52, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: 0.65,
                backgroundColor: Colors.black.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation(Colors.black),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              _liveStat('⚡', '22 kW',    'Power'),
              Container(width: 1, height: 30, color: Colors.black.withOpacity(0.15)),
              _liveStat('🔋', '14.3 kWh', 'Added'),
              Container(width: 1, height: 30, color: Colors.black.withOpacity(0.15)),
              _liveStat('⏱️', '23 min',   'Left'),
            ]),
          ]),
        ),
        const SizedBox(height: 28),

        // Stop button
        SizedBox(
          width: double.infinity, height: 54,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _connected = false),
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
            label: const Text('Stop Charging',
                style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _liveStat(String e, String v, String l) => Expanded(
    child: Column(children: [
      Text('$e $v',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13)),
      Text(l, style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 11)),
    ]),
  );

  // ── Main View (tabs) ──────────────────────────────────────
  Widget _mainView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        // Tab switcher
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder)),
          child: Row(children: [
            _tabBtn(0, Icons.qr_code_scanner, 'Scan QR'),
            _tabBtn(1, Icons.keyboard,         'Station ID'),
          ]),
        ),
        const SizedBox(height: 32),

        // Tab content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _tab == 0 ? _qrTab() : _idTab(),
        ),
      ]),
    );
  }

  Widget _tabBtn(int idx, IconData icon, String label) {
    final sel = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? kGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: sel ? Colors.black : Colors.white54, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: sel ? Colors.black : Colors.white54,
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }

  // ── QR Tab ────────────────────────────────────────────────
  Widget _qrTab() {
    return Column(key: const ValueKey(0), children: [
      // QR frame
      AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Transform.scale(
          scale: _scanning ? _pulse.value : 1.0,
          child: Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              color: kCard, borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _scanning ? kGreen : kBorder, width: _scanning ? 2.5 : 1.5),
              boxShadow: _scanning
                  ? [BoxShadow(color: kGreen.withOpacity(0.3), blurRadius: 20)]
                  : [],
            ),
            child: Stack(alignment: Alignment.center, children: [
              // Corner markers
              ..._corners(),
              // Center
              if (_scanning)
                Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(color: kGreen, strokeWidth: 2.5),
                  const SizedBox(height: 14),
                  Text('Scanning...', style: kSub(13)),
                ])
              else
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.qr_code_2, color: kGreen.withOpacity(0.6), size: 72),
                  const SizedBox(height: 8),
                  Text('Point camera at QR code', style: kSub(12), textAlign: TextAlign.center),
                ]),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 32),

      // Scan button
      SizedBox(
        width: double.infinity, height: 54,
        child: ElevatedButton.icon(
          onPressed: _scanning ? null : _simulateScan,
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(_scanning ? 'Scanning...' : 'Scan QR Code',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kGreen, foregroundColor: Colors.black,
            disabledBackgroundColor: kGreen.withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text('Or enter the station ID manually below',
          style: kSub(12), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => setState(() => _tab = 1),
        child: const Text('Switch to Station ID →',
            style: TextStyle(color: kGreen, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  List<Widget> _corners() {
    const s = 24.0;
    const t = 3.0;
    const r = 6.0;
    const c = kGreen;
    return [
      // Top-left
      Positioned(top: 16, left: 16, child: _corner(s, t, r, c, top: true,  left: true)),
      // Top-right
      Positioned(top: 16, right: 16, child: _corner(s, t, r, c, top: true,  left: false)),
      // Bottom-left
      Positioned(bottom: 16, left: 16, child: _corner(s, t, r, c, top: false, left: true)),
      // Bottom-right
      Positioned(bottom: 16, right: 16, child: _corner(s, t, r, c, top: false, left: false)),
    ];
  }

  Widget _corner(double s, double t, double r, Color c,
      {required bool top, required bool left}) {
    return SizedBox(
      width: s, height: s,
      child: CustomPaint(
        painter: _CornerPainter(color: c, thickness: t, radius: r, top: top, left: left),
      ),
    );
  }

  // ── Station ID Tab ────────────────────────────────────────
  Widget _idTab() {
    return Column(key: const ValueKey(1), children: [
      // Icon
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: kGreen.withOpacity(0.1), shape: BoxShape.circle,
            border: Border.all(color: kGreen.withOpacity(0.3), width: 1.5)),
        child: const Icon(Icons.ev_station, color: kGreen, size: 40),
      ),
      const SizedBox(height: 20),
      Text('Enter Station ID', style: kTitle(20)),
      const SizedBox(height: 8),
      Text('Find the ID on the charger label or in the app map',
          style: kSub(13), textAlign: TextAlign.center),
      const SizedBox(height: 28),

      // Input field
      TextField(
        controller: _idCtrl,
        keyboardType: TextInputType.text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 4),
        maxLength: 8,
        decoration: InputDecoration(
          hintText: 'e.g.  CG-1024',
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 16, letterSpacing: 2),
          counterText: '',
          filled: true, fillColor: kCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: kGreen, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
      const SizedBox(height: 12),

      // Quick IDs
      Text('Quick connect:', style: kSub(12)),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _quickId('CG-1024'),
        const SizedBox(width: 10),
        _quickId('CG-2048'),
        const SizedBox(width: 10),
        _quickId('CG-3001'),
      ]),
      const SizedBox(height: 28),

      // Connect button
      SizedBox(
        width: double.infinity, height: 54,
        child: ElevatedButton.icon(
          onPressed: _connectById,
          icon: const Icon(Icons.power),
          label: const Text('Connect & Start',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kGreen, foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    ]);
  }

  Widget _quickId(String id) => GestureDetector(
    onTap: () => setState(() => _idCtrl.text = id),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: kGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10), border: Border.all(color: kGreen.withOpacity(0.3))),
      child: Text(id, style: const TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w700)),
    ),
  );
}

// ── Corner Painter ────────────────────────────────────────
class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness, radius;
  final bool top, left;

  const _CornerPainter(
      {required this.color, required this.thickness, required this.radius,
       required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, radius);
      path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width - radius, 0);
      path.arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius));
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height - radius);
      path.arcToPoint(Offset(radius, size.height), radius: Radius.circular(radius));
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width - radius, size.height);
      path.arcToPoint(Offset(size.width, size.height - radius), radius: Radius.circular(radius));
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
