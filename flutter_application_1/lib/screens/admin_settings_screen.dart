import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});
  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  Map<String, dynamic> _cfg = {};
  bool _loading = true;
  bool _saving  = false;

  late final _commissionCtrl   = TextEditingController();
  late final _minBookingCtrl   = TextEditingController();
  late final _maxBookingCtrl   = TextEditingController();
  late final _cancelWindowCtrl = TextEditingController();
  late final _pointsCtrl       = TextEditingController();
  late final _referralCtrl     = TextEditingController();
  late final _maintMsgCtrl     = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commissionCtrl.dispose(); _minBookingCtrl.dispose();
    _maxBookingCtrl.dispose(); _cancelWindowCtrl.dispose();
    _pointsCtrl.dispose();     _referralCtrl.dispose();
    _maintMsgCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.instance.getPlatformConfig();
    if (mounted) {
      setState(() {
        _loading = false;
        if (result['success']) {
          _cfg = Map<String, dynamic>.from(result['data'] as Map);
          _commissionCtrl.text   = '${_cfg['commissionRate'] ?? 15}';
          _minBookingCtrl.text   = '${_cfg['minBookingMinutes'] ?? 15}';
          _maxBookingCtrl.text   = '${_cfg['maxBookingMinutes'] ?? 240}';
          _cancelWindowCtrl.text = '${_cfg['cancellationWindowMin'] ?? 30}';
          _pointsCtrl.text       = '${_cfg['pointsPerKwh'] ?? 1}';
          _referralCtrl.text     = '${_cfg['referralBonus'] ?? 10}';
          _maintMsgCtrl.text     = _cfg['maintenanceMessage'] as String? ?? '';
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final changes = {
      'commissionRate':        double.tryParse(_commissionCtrl.text) ?? 15,
      'minBookingMinutes':     int.tryParse(_minBookingCtrl.text)    ?? 15,
      'maxBookingMinutes':     int.tryParse(_maxBookingCtrl.text)    ?? 240,
      'cancellationWindowMin': int.tryParse(_cancelWindowCtrl.text)  ?? 30,
      'pointsPerKwh':          double.tryParse(_pointsCtrl.text)     ?? 1,
      'referralBonus':         double.tryParse(_referralCtrl.text)   ?? 10,
      'aiFeaturesEnabled':     _cfg['aiFeaturesEnabled'] ?? true,
      'reviewsEnabled':        _cfg['reviewsEnabled']    ?? true,
      'referralsEnabled':      _cfg['referralsEnabled']  ?? true,
      'maintenanceMode':       _cfg['maintenanceMode']   ?? false,
      'maintenanceMessage':    _maintMsgCtrl.text.trim(),
    };
    final result = await ApiService.instance.updatePlatformConfig(changes);
    if (mounted) {
      setState(() => _saving = false);
      _snack(result['success'] ? 'Settings saved ✅' : result['message'] ?? 'Error',
          isError: !result['success']);
      if (result['success']) _load();
    }
  }

  void _snack(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: isError ? kRed : cCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(backgroundColor: cBg, elevation: 0,
          title: Text('Platform Settings', style: kTitle(18)),
          actions: [IconButton(icon: const Icon(Icons.refresh, color: kGreen), onPressed: _load)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _section('Pricing', Icons.attach_money, [
                  _numField('Commission Rate (%)',   _commissionCtrl),
                  _numField('Points per kWh',         _pointsCtrl),
                  _numField('Referral Bonus (NIS)',   _referralCtrl),
                ]),
                _section('Bookings', Icons.calendar_today, [
                  _numField('Min booking duration (min)',  _minBookingCtrl),
                  _numField('Max booking duration (min)',  _maxBookingCtrl),
                  _numField('Cancellation window (min)',   _cancelWindowCtrl),
                ]),
                _section('Features', Icons.toggle_on, [
                  _toggle('AI Features (recommendations + trip planner)',
                      'aiFeaturesEnabled'),
                  _toggle('Reviews & Ratings', 'reviewsEnabled'),
                  _toggle('Referral Program', 'referralsEnabled'),
                ]),
                _section('Maintenance', Icons.engineering, [
                  _toggle('Maintenance mode (drivers see banner)', 'maintenanceMode'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _maintMsgCtrl,
                    maxLines: 2,
                    style: TextStyle(color: cTitle, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Maintenance message (shown to drivers)',
                      hintStyle: TextStyle(color: cSub2, fontSize: 12),
                      filled: true, fillColor: cBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kGreen)),
                    )),
                ]),
                const SizedBox(height: 24),

                SizedBox(width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Icon(Icons.save, size: 18),
                    label: Text(_saving ? 'Saving...' : 'Save All Changes',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen, foregroundColor: Colors.black,
                      disabledBackgroundColor: kGreen.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
              ]),
            ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: kGreen, size: 18),
            const SizedBox(width: 8),
            Text(title, style: kTitle(15)),
          ]),
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(14), decoration: kCardDeco(radius: 14),
            child: Column(children: children)),
        ]),
      );

  Widget _numField(String label, TextEditingController ctrl) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: cTitle, fontSize: 14),
          decoration: InputDecoration(
            labelText: label, labelStyle: TextStyle(color: cSub, fontSize: 12),
            filled: true, fillColor: cBg, isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kGreen)),
          )),
      );

  Widget _toggle(String label, String key) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(color: cTitle, fontSize: 13))),
          Switch(
            value: _cfg[key] as bool? ?? true,
            activeColor: kGreen,
            onChanged: (v) => setState(() => _cfg[key] = v),
          ),
        ]),
      );
}
