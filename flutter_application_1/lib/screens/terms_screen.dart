import 'package:flutter/material.dart';
import '../utils/constants.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    {
      'title': '1. Acceptance of Terms',
      'body':
          'By downloading, installing, or using the ChargeGuard application, you agree to be bound by these Terms of Use. If you do not agree to these terms, please do not use our service.',
    },
    {
      'title': '2. Service Description',
      'body':
          'ChargeGuard is a platform that connects electric vehicle (EV) drivers with charging station owners (hosts). We provide:\n\n• Charging station search and mapping\n• Booking and reservation services\n• Payment processing\n• Loyalty rewards program\n• Host management tools',
    },
    {
      'title': '3. User Accounts',
      'body':
          'To use ChargeGuard, you must:\n\n• Be at least 18 years old\n• Provide accurate and complete information\n• Maintain the security of your account\n• Not share your account with others\n• Notify us immediately of any unauthorized access\n\nYou are responsible for all activity that occurs under your account.',
    },
    {
      'title': '4. Booking & Cancellation',
      'body':
          'When you book a charging session:\n\n• Bookings are confirmed immediately upon payment\n• Free cancellation is available up to 1 hour before the session\n• Late cancellations (less than 1 hour) may incur a fee\n• No-shows will be charged the full session fee\n• Hosts may cancel bookings in exceptional circumstances with full refund',
    },
    {
      'title': '5. Payments',
      'body':
          'All payments are processed securely through our payment partners. By making a payment you agree that:\n\n• All charges are in the local currency\n• Prices shown include applicable taxes\n• Refunds are processed within 5-7 business days\n• Dispute resolution follows our refund policy',
    },
    {
      'title': '6. Host Responsibilities',
      'body':
          'As a charging station host, you agree to:\n\n• Ensure your charger is operational and safe\n• Accurately describe your charger specifications\n• Honor confirmed bookings\n• Maintain a minimum 4.0 star rating\n• Comply with all local regulations\n\nHosts who repeatedly cancel or maintain low ratings may be removed from the platform.',
    },
    {
      'title': '7. Prohibited Activities',
      'body':
          'You agree not to:\n\n• Use the service for any unlawful purpose\n• Provide false or misleading information\n• Interfere with the platform\'s operation\n• Attempt to access other users\' accounts\n• Use bots or automated tools\n• Engage in fraudulent transactions',
    },
    {
      'title': '8. Limitation of Liability',
      'body':
          'ChargeGuard is not liable for:\n\n• Damage to your vehicle during charging\n• Service interruptions or downtime\n• Actions of hosts or other users\n• Indirect or consequential damages\n\nOur maximum liability is limited to the amount paid for the specific service in question.',
    },
    {
      'title': '9. Governing Law',
      'body':
          'These terms are governed by the laws of Palestine. Any disputes shall be resolved through binding arbitration in accordance with local regulations.',
    },
    {
      'title': '10. Contact',
      'body':
          'For questions about these Terms of Use:\n\n📧 legal@chargeguard.app\n📞 +970 2 000 0000\n🌐 www.chargeguard.app',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Terms of Use', context),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.25))),
            child: Row(children: [
              const Icon(Icons.description_outlined, color: Colors.blueAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Terms of Use', style: kTitle(15)),
                Text('Effective: April 2026', style: kSub(12)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          Text(
            'Please read these Terms of Use carefully before using ChargeGuard. These terms govern your use of our platform and services.',
            style: kSub(14),
          ),
          const SizedBox(height: 20),
          ..._sections.map((s) => _section(s['title']!, s['body']!)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _section(String title, String body) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: kCardDeco(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(
          color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Text(body, style: TextStyle(color: cSub, fontSize: 13, height: 1.6)),
    ]),
  );
}
