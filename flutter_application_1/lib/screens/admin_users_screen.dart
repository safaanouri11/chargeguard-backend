import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';
import 'admin_user_detail_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  String _query = '';
  String _roleFilter = 'all'; // all | driver | host | suspended

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiService.instance.getAllUsers();
    if (mounted) {
      setState(() {
        _loading = false;
        _users = result['success'] ? (result['data'] as List? ?? []) : [];
      });
    }
  }

  List<dynamic> get _filtered {
    var list = _users;
    if (_roleFilter == 'driver') {
      list = list.where((u) => u['role'] == 'driver').toList();
    } else if (_roleFilter == 'host') {
      list = list.where((u) => u['role'] == 'host').toList();
    } else if (_roleFilter == 'suspended') {
      list = list.where((u) => u['suspended'] == true).toList();
    }
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list.where((u) {
      final name = '${u['firstName']} ${u['lastName']}'.toLowerCase();
      final email = (u['email'] as String? ?? '').toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  Future<void> _editBalance(Map<String, dynamic> user) async {
    final ctrl = TextEditingController(text: (user['balance'] ?? 0).toString());
    final v = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Balance', style: kTitle(16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${user['firstName']} ${user['lastName']}', style: kSub(13)),
          const SizedBox(height: 12),
          TextField(controller: ctrl, keyboardType: TextInputType.number,
            style: TextStyle(color: cTitle),
            decoration: InputDecoration(
              labelText: 'Balance (NIS)', labelStyle: TextStyle(color: cSub),
              filled: true, fillColor: cBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cBorder)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: cSub))),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null) Navigator.pop(context, v);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black),
            child: const Text('Save')),
        ]));

    if (v == null || !mounted) return;
    final result = await ApiService.instance.updateUserBalance(user['_id'] as String, v);
    if (mounted) {
      _snack(result['success'] ? 'Balance updated ✅' : result['message'] ?? 'Error',
          isError: !result['success']);
      if (result['success']) _load();
    }
  }

  Future<void> _delete(Map<String, dynamic> user) async {
    // Defensive: don't allow self-delete on the client either (backend also blocks).
    if (user['_id'] == UserSession.instance.id) {
      _snack('You cannot delete your own admin account', isError: true);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete User?', style: kTitle(16)),
        content: Text('Delete ${user['firstName']} ${user['lastName']}?\nThis cannot be undone.',
            style: kSub(13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: cSub))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete')),
        ]));

    if (confirm != true || !mounted) return;
    final result = await ApiService.instance.deleteUser(user['_id'] as String);
    if (mounted) {
      _snack(result['success'] ? 'User deleted' : result['message'] ?? 'Error',
          isError: !result['success']);
      if (result['success']) _load();
    }
  }

  Future<void> _export() async {
    _snack('Exporting...');
    final csv = await ApiService.instance.exportCsv('users');
    if (!mounted) return;
    if (csv == null) {
      _snack('Export failed', isError: true);
      return;
    }
    // Show in a dialog — easy to copy on web/desktop; on mobile, this is still
    // a useful preview. (A full file-save flow needs the path_provider plugin.)
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: cCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Users CSV', style: kTitle(15)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: SelectableText(csv, style: TextStyle(color: cSub, fontSize: 10, fontFamily: 'monospace')))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: kGreen))),
      ]));
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
          title: Text('All Users (${_filtered.length})', style: kTitle(18)),
          actions: [
            IconButton(tooltip: 'Export CSV',
                icon: const Icon(Icons.file_download_outlined, color: kGreen),
                onPressed: _export),
            IconButton(icon: const Icon(Icons.refresh, color: kGreen), onPressed: _load),
          ]),
      body: Column(children: [
        // Search
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            style: TextStyle(color: cTitle),
            decoration: InputDecoration(
              hintText: 'Search by name or email', hintStyle: TextStyle(color: cSub),
              prefixIcon: Icon(Icons.search, color: cSub2, size: 20),
              filled: true, fillColor: cCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGreen))))),

        // Role filter chips
        SizedBox(height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _filterChip('all',       'All',       _users.length),
              _filterChip('driver',    'Drivers',   _users.where((u) => u['role'] == 'driver').length),
              _filterChip('host',      'Hosts',     _users.where((u) => u['role'] == 'host').length),
              _filterChip('suspended', 'Suspended', _users.where((u) => u['suspended'] == true).length),
            ],
          )),
        const SizedBox(height: 4),

        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: kGreen))
          : _filtered.isEmpty
              ? Center(child: Text('No users found', style: kSub(14)))
              : RefreshIndicator(color: kGreen, onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final u = _filtered[i] as Map<String, dynamic>;
                      final role = u['role'] as String? ?? 'driver';
                      final roleColor = role == 'host' ? Colors.blueAccent : kGreen;
                      final suspended = u['suspended'] as bool? ?? false;
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AdminUserDetailScreen(userId: u['_id'] as String))).then((_) => _load()),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                          decoration: kCardDeco(),
                          child: Column(children: [
                            Row(children: [
                              Stack(children: [
                                Container(width: 42, height: 42,
                                  decoration: BoxDecoration(color: roleColor.withOpacity(0.12), shape: BoxShape.circle),
                                  child: Center(child: Text((u['firstName'] as String? ?? '?')[0].toUpperCase(),
                                      style: TextStyle(color: roleColor, fontSize: 16, fontWeight: FontWeight.w800)))),
                                if (suspended)
                                  Positioned(bottom: 0, right: 0,
                                    child: Container(width: 14, height: 14,
                                      decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle,
                                          border: Border.all(color: cCard, width: 1.5)),
                                      child: const Icon(Icons.block, color: Colors.white, size: 9))),
                              ]),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text('${u['firstName']} ${u['lastName']}', style: kTitle(13),
                                      overflow: TextOverflow.ellipsis)),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: roleColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                                    child: Text(role, style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w700))),
                                ]),
                                Text(u['email'] as String? ?? '', style: kSub(11),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ])),
                            ]),
                            const SizedBox(height: 10),
                            Container(padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(8)),
                              child: Row(children: [
                                Icon(Icons.account_balance_wallet_outlined, color: cSub2, size: 16),
                                const SizedBox(width: 8),
                                Text('NIS ${((u['balance'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                                    style: TextStyle(color: cTitle, fontSize: 13, fontWeight: FontWeight.w700)),
                                const Spacer(),
                                IconButton(onPressed: () => _editBalance(u),
                                  icon: const Icon(Icons.edit, color: kGreen, size: 18),
                                  padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                const SizedBox(width: 16),
                                IconButton(onPressed: () => _delete(u),
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                  padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                              ])),
                          ])),
                      );
                    }))),
      ]),
    );
  }

  Widget _filterChip(String value, String label, int count) {
    final sel = _roleFilter == value;
    return Padding(padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _roleFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: sel ? kGreen : cCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? kGreen : cBorder)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: TextStyle(
                color: sel ? Colors.black : cSub,
                fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: sel ? Colors.black.withOpacity(0.18) : kGreen.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('$count', style: TextStyle(
                  color: sel ? Colors.black : kGreen,
                  fontSize: 10, fontWeight: FontWeight.w800))),
          ]),
        )));
  }
}
