import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});
  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int? _expandedFaq;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _faqs = [
    { 'q': 'How do I book a charging station?', 'a': 'Go to the Map tab or tap "Find Charger" on the Home screen. Select a station, tap "Book Now", choose your date and time, then confirm your booking.', 'cat': 'Booking' },
    { 'q': 'How do I start a charging session?', 'a': 'Tap "Start Charge" on the Home screen. Select a station and tap Start Charging.', 'cat': 'Charging' },
    { 'q': 'How do I cancel a booking?', 'a': 'Go to Bookings tab, tap on your upcoming booking, then tap "Cancel Booking". You will get a full refund of 5 NIS.', 'cat': 'Booking' },
    { 'q': 'How are loyalty points calculated?', 'a': 'You earn 10 points per booking and extra points per kWh charged. Points are shown in your Profile.', 'cat': 'Rewards' },
    { 'q': 'What payment methods are accepted?', 'a': 'We accept Visa, Mastercard, and PayPal. You can add cards in Payment Methods.', 'cat': 'Payment' },
    { 'q': 'My charger is not working, what should I do?', 'a': 'Contact us via the Live Chat and our team will assist you immediately.', 'cat': 'Technical' },
    { 'q': 'How do I become a charger host?', 'a': 'On the Login screen, tap "I\'m a Charger Host". Fill in your information and our team will verify your application.', 'cat': 'Account' },
    { 'q': 'How do I get a refund?', 'a': 'Refunds are processed automatically for cancelled bookings. For other requests, contact support.', 'cat': 'Payment' },
  ];

  List<Map<String, dynamic>> get _filtered => _searchQuery.isEmpty
      ? List<Map<String, dynamic>>.from(_faqs)
      : _faqs.where((f) =>
          (f['q'] as String).toLowerCase().contains(_searchQuery) ||
          (f['a'] as String).toLowerCase().contains(_searchQuery)).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, size: 18, color: cTitle),
            onPressed: () => Navigator.pop(context)),
        title: Text('Help & Support', style: kTitle(18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cBorder)),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black,
              unselectedLabelColor: cSub,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              dividerColor: Colors.transparent,
              tabs: const [Tab(text: '❓ FAQ'), Tab(text: '📩 Contact'), Tab(text: '💬 Chat')],
            ),
          ),
        ),
      ),
      body: TabBarView(controller: _tabCtrl, children: [_faqTab(), _ContactTab(), _ChatTab()]),
    );
  }

  // ── FAQ Tab ───────────────────────────────────────────────
  Widget _faqTab() {
    final items = _filtered;
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16),
        child: TextField(controller: _searchCtrl, style: TextStyle(color: cTitle, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search questions...', hintStyle: TextStyle(color: cSub2),
            prefixIcon: Icon(Icons.search, color: cSub2, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(icon: Icon(Icons.clear, color: cSub2, size: 18),
                    onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); })
                : null,
            filled: true, fillColor: cCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGreen, width: 1.5))))),
      if (items.isEmpty)
        Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off, color: cSub2, size: 48), const SizedBox(height: 12),
          Text('No results for "$_searchQuery"', style: kSub(14)),
        ])))
      else
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final f = items[i]; final exp = _expandedFaq == i;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: exp ? kGreen.withOpacity(0.06) : cCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: exp ? kGreen.withOpacity(0.3) : cBorder)),
              child: Column(children: [
                GestureDetector(
                  onTap: () => setState(() => _expandedFaq = exp ? null : i),
                  child: Padding(padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(f['cat'] as String,
                            style: const TextStyle(color: kGreen, fontSize: 10, fontWeight: FontWeight.w700))),
                      const SizedBox(width: 10),
                      Expanded(child: Text(f['q'] as String,
                          style: TextStyle(color: cTitle, fontSize: 13, fontWeight: FontWeight.w600))),
                      Icon(exp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: exp ? kGreen : cSub2, size: 20),
                    ]))),
                if (exp) Container(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Text(f['a'] as String, style: TextStyle(color: cSub, fontSize: 13, height: 1.6))),
              ]));
          })),
    ]);
  }
}

// ════════════════════════════════════════
//  Contact Tab — Backend Connected
// ════════════════════════════════════════
class _ContactTab extends StatefulWidget {
  @override
  State<_ContactTab> createState() => _ContactTabState();
}

class _ContactTabState extends State<_ContactTab> {
  final _subjectCtrl  = TextEditingController();
  final _msgCtrl      = TextEditingController();
  String _category    = 'Booking Issue';
  bool   _sending     = false;
  final _categories   = ['Booking Issue', 'Payment Problem', 'Technical Issue', 'Account Help', 'Other'];

  @override
  void dispose() { _subjectCtrl.dispose(); _msgCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_subjectCtrl.text.trim().isEmpty || _msgCtrl.text.trim().isEmpty) {
      _snack('Please fill all fields', isError: true); return;
    }
    setState(() => _sending = true);
    final result = await ApiService.instance.submitTicket(
      category: _category,
      subject:  _subjectCtrl.text.trim(),
      message:  _msgCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => _sending = false);
      if (result['success']) {
        _subjectCtrl.clear(); _msgCtrl.clear();
        _snack('Message sent! We\'ll reply within 24 hours ✅');
      } else {
        _snack(result['message'] ?? 'Failed to send', isError: true);
      }
    }
  }

  void _snack(String msg, {bool isError = false}) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: isError ? kRed : cCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _method(Icons.email_outlined, 'Email', 'support@chargeguard.app', Colors.blueAccent),
          const SizedBox(width: 12),
          _method(Icons.phone_outlined, 'Phone', '+970 2 000 0000', kGreen),
          const SizedBox(width: 12),
          _method(Icons.access_time, 'Response', '< 24 hours', Colors.orange),
        ]),
        const SizedBox(height: 24),
        Text('Send a Message', style: kTitle(15)),
        const SizedBox(height: 14),
        Text('Category', style: kSub(13)), const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _categories.map((c) {
          final sel = _category == c;
          return GestureDetector(onTap: () => setState(() => _category = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? kGreen.withOpacity(0.12) : cCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? kGreen : cBorder, width: 1.5)),
              child: Text(c, style: TextStyle(
                  color: sel ? kGreen : cSub, fontSize: 12, fontWeight: FontWeight.w700))));
        }).toList()),
        const SizedBox(height: 16),
        Text('Subject', style: kSub(13)), const SizedBox(height: 8),
        _field(_subjectCtrl, 'What is your issue?', Icons.subject_outlined),
        const SizedBox(height: 14),
        Text('Message', style: kSub(13)), const SizedBox(height: 8),
        TextField(controller: _msgCtrl, maxLines: 5,
          style: TextStyle(color: cTitle, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Describe your issue in detail...', hintStyle: TextStyle(color: cSub2),
            filled: true, fillColor: cCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGreen, width: 1.5)))),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Icon(Icons.send_outlined),
            label: Text(_sending ? 'Sending...' : 'Send Message',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(backgroundColor: kGreen,
                disabledBackgroundColor: kGreen.withOpacity(0.3),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
      ]));
  }

  Widget _method(IconData icon, String label, String val, Color color) =>
    Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25))),
      child: Column(children: [
        Icon(icon, color: color, size: 20), const SizedBox(height: 6),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(color: cSub, fontSize: 9), textAlign: TextAlign.center),
      ])));

  Widget _field(TextEditingController ctrl, String hint, IconData icon) =>
    TextField(controller: ctrl, style: TextStyle(color: cTitle, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: cSub2),
        prefixIcon: Icon(icon, color: cSub2, size: 20), filled: true, fillColor: cCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kGreen, width: 1.5))));
}

// ════════════════════════════════════════
//  Chat Tab — Backend Connected
// ════════════════════════════════════════
class _ChatTab extends StatefulWidget {
  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading  = true;
  bool _sending  = false;

  @override
  void initState() { super.initState(); _loadMessages(); }

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  Future<void> _loadMessages() async {
    final result = await ApiService.instance.getChatMessages();
    if (mounted) {
      setState(() {
        _loading = false;
        if (result['success']) {
          _messages = (result['data'] as List).map((m) => {
            'text':  m['text'] as String,
            'isBot': m['isBot'] as bool,
            'time':  _fmt(m['createdAt'] as String?),
          }).toList();
        }
        // Show welcome if no messages
        if (_messages.isEmpty) {
          _messages = [
            {'text': 'Hello! How can I help you today? 👋', 'isBot': true, 'time': 'Now'},
            {'text': 'Common questions I can help with:\n\n• Booking issues\n• Payment problems\n• Technical support\n• Account help', 'isBot': true, 'time': 'Now'},
          ];
        }
      });
      _scrollDown();
    }
  }

  String _fmt(String? iso) {
    if (iso == null) return 'Now';
    try {
      final d = DateTime.parse(iso).toLocal();
      final h = d.hour > 12 ? d.hour - 12 : d.hour == 0 ? 12 : d.hour;
      final m = d.minute.toString().padLeft(2, '0');
      return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) { return 'Now'; }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    setState(() {
      _sending = true;
      _messages.add({'text': text, 'isBot': false, 'time': 'Now'});
    });
    _scrollDown();

    final result = await ApiService.instance.sendChatMessage(text);
    if (mounted) {
      setState(() {
        _sending = false;
        if (result['success']) {
          final bot = result['data']['botMessage'];
          _messages.add({'text': bot['text'] as String, 'isBot': true, 'time': 'Now'});
        }
      });
      _scrollDown();
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: cCard, border: Border(bottom: BorderSide(color: cBorder))),
        child: Row(children: [
          Container(width: 10, height: 10,
              decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('Support Team • Online now', style: TextStyle(color: cSub, fontSize: 12)),
          const Spacer(),
          Text('Avg reply: 2 min', style: const TextStyle(color: kGreen, fontSize: 11, fontWeight: FontWeight.w600)),
        ])),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kGreen))
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final m = _messages[i]; final bot = m['isBot'] as bool;
                  return Align(
                    alignment: bot ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                      decoration: BoxDecoration(
                        color: bot ? cCard : kGreen,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(bot ? 4 : 16),
                          bottomRight: Radius.circular(bot ? 16 : 4)),
                        border: bot ? Border.all(color: cBorder) : null),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m['text'] as String, style: TextStyle(
                            color: bot ? cTitle : Colors.black, fontSize: 13, height: 1.5)),
                        const SizedBox(height: 4),
                        Text(m['time'] as String, style: TextStyle(
                            color: bot ? cSub2 : Colors.black45, fontSize: 10)),
                      ])));
                })),
      Container(padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cCard, border: Border(top: BorderSide(color: cBorder))),
        child: Row(children: [
          Expanded(child: TextField(controller: _msgCtrl,
            style: TextStyle(color: cTitle, fontSize: 14),
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: 'Type your message...', hintStyle: TextStyle(color: cSub2),
              filled: true, fillColor: cBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: cBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: cBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: kGreen, width: 1.5))))),
          const SizedBox(width: 8),
          GestureDetector(onTap: _sending ? null : _send,
            child: Container(width: 44, height: 44,
              decoration: BoxDecoration(color: _sending ? kGreen.withOpacity(0.4) : kGreen, shape: BoxShape.circle),
              child: _sending
                  ? const Padding(padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.black, size: 20))),
        ])),
    ]);
  }
}
