import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    {
      'title': '1. Information We Collect',
      'body':
          'We collect information you provide directly to us, such as when you create an account, make a booking, or contact us for support. This includes:\n\n• Name, email address, and phone number\n• Vehicle information (model, connector type)\n• Location data when you use the map feature\n• Payment information (processed securely)\n• Charging session history',
    },
    {
      'title': '2. How We Use Your Information',
      'body':
          'We use the information we collect to:\n\n• Provide, maintain, and improve our services\n• Process your bookings and payments\n• Send you booking confirmations and notifications\n• Offer personalized recommendations\n• Communicate with you about promotions and offers\n• Ensure the safety and security of our platform',
    },
    {
      'title': '3. Location Data',
      'body':
          'ChargeGuard uses your location to show nearby charging stations and calculate routes. Location data is only collected when the app is in use and is never sold to third parties. You can disable location access in your device settings at any time.',
    },
    {
      'title': '4. Data Sharing',
      'body':
          'We do not sell, trade, or rent your personal information to third parties. We may share your data with:\n\n• Charging station operators (to process your session)\n• Payment processors (to handle transactions securely)\n• Service providers who assist our operations\n• Law enforcement when required by law',
    },
    {
      'title': '5. Data Security',
      'body':
          'We implement industry-standard security measures to protect your personal information, including:\n\n• SSL/TLS encryption for data transmission\n• Encrypted storage for sensitive data\n• Regular security audits\n• Access controls for our team',
    },
    {
      'title': '6. Your Rights',
      'body':
          'You have the right to:\n\n• Access your personal data\n• Correct inaccurate information\n• Request deletion of your account and data\n• Opt out of marketing communications\n• Export your data\n\nTo exercise these rights, contact us at privacy@chargeguard.app',
    },
    {
      'title': '7. Cookies',
      'body':
          'We use cookies and similar tracking technologies to enhance your experience. You can control cookie settings through your browser or device settings.',
    },
    {
      'title': '8. Changes to This Policy',
      'body':
          'We may update this Privacy Policy from time to time. We will notify you of significant changes via email or in-app notification. Continued use of our service after changes constitutes acceptance of the updated policy.',
    },
    {
      'title': '9. Contact Us',
      'body':
          'If you have questions about this Privacy Policy, please contact us:\n\n📧 privacy@chargeguard.app\n📞 +970 2 000 0000\n🌐 www.chargeguard.app',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: kAppBar('Privacy Policy', context),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: kGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kGreen.withOpacity(0.25))),
            child: Row(children: [
              const Icon(Icons.privacy_tip_outlined, color: kGreen, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Privacy Policy', style: kTitle(15)),
                Text('Last updated: April 2026', style: kSub(12)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          Text(
            'At ChargeGuard, we take your privacy seriously. This policy explains how we collect, use, and protect your personal information.',
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
      Text(title, style: TextStyle(
          color: kGreen, fontSize: 14, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Text(body, style: TextStyle(color: cSub, fontSize: 13, height: 1.6)),
    ]),
  );
}
