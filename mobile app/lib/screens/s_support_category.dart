import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/routes.dart';
import '../core/theme/tokens.dart';
import '../data/mock/mock_data.dart';
import '../widgets/common.dart';

/// Support category detail — FAQs filtered by category, contact options,
/// and a create-ticket button pre-set to the category.
class SupportCategoryDetailScreen extends StatelessWidget {
  const SupportCategoryDetailScreen({super.key, required this.category});

  final String category;

  static const _categoryFaqs = <String, List<(String, String)>>{
    'Payments': [
      ('How do I make a rent payment?',
          'Open the Payments tab, select the outstanding invoice and pay by card, bank transfer or direct debit. A receipt is issued instantly.'),
      ('How can I get a refund?',
          'Refunds are processed within 5–7 business days. Contact support with your payment receipt to initiate a refund request.'),
      ('What payment methods are accepted?',
          'We accept Visa, Mastercard, Amex, bank transfers, and direct debit. You can manage your cards in Settings → Payment Methods.'),
      ('Why was my payment declined?',
          'Common reasons include insufficient funds, expired card, or bank restrictions. Try another card or contact your bank for details.'),
    ],
    'Leasing': [
      ('How do I renew my lease?',
          'Lease renewal options appear 60 days before expiry in your dashboard. You can review new terms and accept online.'),
      ('Can I transfer my lease to someone else?',
          'Lease transfers require landlord approval. Submit a transfer request via Support → Create Ticket with the new tenant details.'),
      ('What happens to my deposit at lease end?',
          'Deposits are refunded within 14 days of move-out, minus any deductions for damages. An inspection report is shared with you.'),
      ('How do I give notice to vacate?',
          'Submit a notice-to-vacate at least 30 days before your lease end date through your tenant dashboard.'),
    ],
    'Maintenance': [
      ('How do I submit a maintenance request?',
          'Go to Support → Create Ticket, choose Maintenance, describe the issue and attach photos. A maintainer is assigned within 2 hours.'),
      ('What is the response time for repairs?',
          'Emergency repairs: within 4 hours. Standard requests: within 24–48 hours. You can track status in your dashboard.'),
      ('Who pays for maintenance?',
          'Routine maintenance is covered by the landlord. Tenant-caused damage may be charged to the tenant as per lease terms.'),
    ],
    'Technical Help': [
      ('The app is not loading properly',
          'Try force-closing and reopening the app. If the issue persists, clear the app cache from your device settings.'),
      ('I cannot log into my account',
          'Check your email and password. Use "Forgot Password" on the login screen to reset. Contact support if you still cannot access your account.'),
      ('How do I enable push notifications?',
          'Go to Profile → Preferences and enable Push Notifications. Also check your device settings to ensure notifications are allowed for RESIVYN.'),
      ('How do I update my email or phone number?',
          'Go to Profile → Personal Information to update your contact details. A verification email will be sent to confirm the change.'),
    ],
    'Legal': [
      ('Where can I find the Terms & Conditions?',
          'Navigate to Profile → Terms & Conditions to read the full legal document.'),
      ('Where is the Privacy Policy?',
          'Navigate to Profile → Privacy Policy to review how we collect and protect your data.'),
      ('How do I request my data under GDPR?',
          'Submit a data request via Profile → Account Settings → Export My Data, or contact our compliance team at legal@resivyn.com.'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final faqs = _categoryFaqs[category] ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: RC.navy),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(category, style: RT.h2),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: RS.x8),

          // ---- Info banner ----
          Padding(
            padding: RS.page,
            child: InfoBanner(
              title: '$category Support',
              body: 'Find answers below or create a ticket for personalized help.',
              icon: Icons.help_outline_rounded,
            ),
          ),

          const SizedBox(height: RS.x16),

          // ---- FAQs ----
          if (faqs.isNotEmpty) ...[
            const SectionTitle('Frequently Asked Questions'),
            Padding(
              padding: RS.page,
              child: RCard(
                padding: const EdgeInsets.symmetric(horizontal: RS.x16),
                child: Column(
                  children: [
                    for (var i = 0; i < faqs.length; i++) ...[
                      _ExpandableFaq(
                        question: faqs[i].$1,
                        answer: faqs[i].$2,
                      ),
                      if (i != faqs.length - 1) const ThinDivider(),
                    ],
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: RS.x12),

          // ---- Contact options ----
          const SectionTitle('Still need help?'),
          Padding(
            padding: RS.page,
            child: RCard(
              padding: const EdgeInsets.symmetric(horizontal: RS.x16),
              child: Column(
                children: [
                  RowItem(
                    title: 'Create a Ticket',
                    subtitle: 'Get a response within 24 hours',
                    leading: const IconBubble(Icons.confirmation_number_outlined,
                        tint: RC.teal, size: 38),
                    onTap: () {
                      Navigator.pushNamed(context, Routes.support);
                      toast(context,
                          'Create a ticket — select $category from the category list',
                          icon: Icons.confirmation_number_outlined);
                    },
                    dense: true,
                  ),
                  const ThinDivider(inset: 50),
                  RowItem(
                    title: 'Live Chat',
                    subtitle: 'Chat with our support team now',
                    leading: const IconBubble(Icons.forum_outlined,
                        tint: RC.info, size: 38),
                    onTap: () =>
                        Navigator.pushNamed(context, Routes.liveChat),
                    dense: true,
                  ),
                  const ThinDivider(inset: 50),
                  RowItem(
                    title: 'Email Us',
                    subtitle: 'hello@resivyn.com',
                    leading: const IconBubble(Icons.mail_outline_rounded,
                        tint: RC.purple, size: 38),
                    onTap: () async {
                      final uri = Uri.parse(
                          'mailto:hello@resivyn.com?subject=$category Support');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        toast(context, 'Could not open email client',
                            icon: Icons.error_outline_rounded);
                      }
                    },
                    dense: true,
                  ),
                  const ThinDivider(inset: 50),
                  RowItem(
                    title: 'Call Support',
                    subtitle: '+971 4 123 4567',
                    leading: const IconBubble(Icons.phone_in_talk_outlined,
                        tint: RC.success, size: 38),
                    onTap: () async {
                      final uri = Uri.parse('tel:+97141234567');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        toast(context, 'Could not initiate call',
                            icon: Icons.error_outline_rounded);
                      }
                    },
                    dense: true,
                  ),
                ],
              ),
            ),
          ),

          // ---- Legal shortcuts for Legal category ----
          if (category == 'Legal') ...[
            const SizedBox(height: RS.x12),
            const SectionTitle('Legal Documents'),
            Padding(
              padding: RS.page,
              child: RCard(
                padding: const EdgeInsets.symmetric(horizontal: RS.x16),
                child: Column(
                  children: [
                    RowItem(
                      title: 'Privacy Policy',
                      subtitle: 'How we collect and protect your data',
                      leading: const IconBubble(Icons.shield_outlined,
                          tint: RC.purple, size: 38),
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.privacy),
                      dense: true,
                    ),
                    const ThinDivider(inset: 50),
                    RowItem(
                      title: 'Terms & Conditions',
                      subtitle: 'Terms of service and usage',
                      leading: const IconBubble(Icons.gavel_outlined,
                          tint: RC.navy, size: 38),
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.terms),
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: RS.x32),
        ],
      ),
    );
  }
}

class _ExpandableFaq extends StatefulWidget {
  const _ExpandableFaq({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_ExpandableFaq> createState() => _ExpandableFaqState();
}

class _ExpandableFaqState extends State<_ExpandableFaq> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: RS.x14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.question, style: RT.title)),
                const SizedBox(width: RS.x8),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: RC.textTertiary),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.only(top: RS.x10),
                child: Text(widget.answer, style: RT.body),
              ),
              secondChild: const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
