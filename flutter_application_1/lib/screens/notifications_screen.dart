import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.instance.getNotifications();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _notifs = res['success'] ? (res['data'] as List) : [];
    });
  }

  Future<void> _markAllRead() async {
    final res = await ApiService.instance.markAllNotificationsRead();
    if (res['success']) _load();
  }

  Future<void> _markRead(String id) async {
    await ApiService.instance.markNotificationRead(id);
    _load();
  }

  Future<void> _delete(String id) async {
    await ApiService.instance.deleteNotification(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Notifications', context, actions: [
        TextButton(
          onPressed: _notifs.any((n) => n['read'] == false) ? _markAllRead : null,
          child: const Text('Mark all read',
              style: TextStyle(color: kGreen, fontSize: 13)),
        ),
      ]),
      body: RefreshIndicator(
        color: kGreen,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kGreen))
            : _notifs.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 100),
                    Icon(Icons.notifications_off_outlined,
                        color: cSub2, size: 64),
                    const SizedBox(height: 16),
                    Center(child: Text('No notifications yet', style: kTitle(16))),
                    const SizedBox(height: 8),
                    Center(child: Text('We\'ll notify you here', style: kSub(13))),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _notifs.length,
                    itemBuilder: (_, i) {
                      final n = _notifs[i] as Map<String, dynamic>;
                      return _notifCard(n);
                    },
                  ),
      ),
    );
  }

  Widget _notifCard(Map<String, dynamic> n) {
    final id    = n['_id'] as String;
    final type  = n['type'] as String? ?? 'system';
    final title = n['title'] as String? ?? '';
    final body  = n['body']  as String? ?? '';
    final read  = n['read']  as bool? ?? false;
    final when  = n['createdAt'] as String?;
    final color = _typeColor(type);
    final icon  = _typeIcon(type);

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: const Icon(Icons.delete, color: Colors.redAccent),
      ),
      onDismissed: (_) => _delete(id),
      child: GestureDetector(
        onTap: read ? null : () => _markRead(id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: read ? null : kGreen.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: read ? cSub2.withOpacity(0.2) : kGreen.withOpacity(0.3),
            ),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(title, style: kTitle(13))),
                  if (!read)
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                          color: kGreen, shape: BoxShape.circle),
                    ),
                ]),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(body, style: kSub(12)),
                ],
                const SizedBox(height: 6),
                Text(_relativeTime(when),
                    style: TextStyle(color: cSub2, fontSize: 11)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'booking':  return const Color(0xFF6C9EFF);
      case 'payout':   return kGreen;
      case 'host':     return const Color(0xFF6C63FF);
      case 'review':   return const Color(0xFFFFD700);
      case 'referral': return const Color(0xFFFF6B6B);
      default:         return kGreen;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'booking':  return Icons.calendar_today;
      case 'payout':   return Icons.account_balance_wallet;
      case 'host':     return Icons.verified_user;
      case 'review':   return Icons.star;
      case 'referral': return Icons.card_giftcard;
      default:         return Icons.notifications;
    }
  }

  String _relativeTime(String? iso) {
    if (iso == null) return '';
    final dt  = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
