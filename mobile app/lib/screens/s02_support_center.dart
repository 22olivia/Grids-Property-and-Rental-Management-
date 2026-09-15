import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/routes.dart';
import '../core/service_locator.dart';
import '../core/theme/tokens.dart';
import '../data/mock/mock_data.dart';
import '../data/models/models.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/common.dart';
import '../widgets/resivyn_image.dart';

/// SCREEN 02 — SUPPORT & CONTACT CENTER
class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  int _navIndex = 0;
  int? _expandedFaq;

  late Future<List<FaqItem>> _faqs;
  late Future<List<SupportTicket>> _tickets;

  static final _channels = <(String, String, IconData, Color)>[
    ('live_chat'.tr(), 'chat_with_team'.tr(), Icons.forum_outlined, RC.teal),
    ('whatsapp'.tr(), 'whatsapp_message'.tr(),
        Icons.chat_bubble_outline_rounded, RC.success),
    ('call_support'.tr(), 'speak_with_experts'.tr(),
        Icons.phone_in_talk_outlined, RC.info),
    ('email_us'.tr(), 'send_email'.tr(), Icons.mail_outline_rounded,
        RC.purple),
    ('create_ticket'.tr(), 'submit_request'.tr(),
        Icons.confirmation_number_outlined, RC.warning),
  ];

  @override
  void initState() {
    super.initState();
    _faqs = Services.support.faqs();
    _tickets = Services.support.recentTickets();
  }

  Color _statusColor(String status) => switch (status) {
        'In Progress' => RC.warning,
        'Resolved' => RC.success,
        'Closed' => RC.textSecondary,
        _ => RC.info,
      };

  void _openTicketComposer() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(RS.x20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('create_ticket'.tr(), style: RT.h1),
                const SizedBox(height: RS.x6),
                Text('tell_us_happened'.tr(),
                    style: RT.caption),
                const SizedBox(height: RS.x20),
                RTextField(
                  label: 'subject'.tr(),
                  hint: 'briefly_describe'.tr(),
                ),
                const SizedBox(height: RS.x16),
                RTextField(
                  label: 'details'.tr(),
                  hint: 'add_detail'.tr(),
                  maxLines: 4,
                ),
                const SizedBox(height: RS.x20),
                RButton(
                  'submit_ticket_btn'.tr(),
                  expanded: true,
                  icon: Icons.send_rounded,
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    toast(context, 'ticket_created'.tr(),
                        icon: Icons.confirmation_number_outlined);
                  },
                ),
                const SizedBox(height: RS.x12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleChannel(String name) async {
    if (name == 'create_ticket'.tr()) {
      _openTicketComposer();
      return;
    }
    if (name == 'live_chat'.tr()) {
      Navigator.pushNamed(context, Routes.liveChat);
      return;
    }
    if (name == 'whatsapp'.tr()) {
      final uri = Uri.parse('https://wa.me/971501234567');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        toast(context, 'could_not_open_whatsapp'.tr(),
            icon: Icons.error_outline_rounded);
      }
      return;
    }
    if (name == 'call_support'.tr()) {
      final uri = Uri.parse('tel:+97141234567');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        toast(context, 'could_not_initiate_call'.tr(),
            icon: Icons.error_outline_rounded);
      }
      return;
    }
    if (name == 'email_us'.tr()) {
      final uri = Uri.parse('mailto:hello@resivyn.com');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        toast(context, 'could_not_open_email'.tr(),
            icon: Icons.error_outline_rounded);
      }
      return;
    }
    toast(context, '$name opening…', icon: Icons.support_agent_outlined);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ResivynHeader(
              showBack: true,
              trailing: [
                RIconButton(
                  icon: Icons.notifications_none_rounded,
                  badge: true,
                  tooltip: 'notifications'.tr(),
                  onTap: () =>
                      Navigator.pushNamed(context, Routes.notifications),
                ),
                const SizedBox(width: RS.x8),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, Routes.profile),
                  child: const ResivynAvatar(
                    url: Img.avatarAlex,
                    name: 'Alex Johnson',
                    size: 40,
                  ),
                ),
              ],
            ),

            const GreetingBlock(
              greeting: 'Good morning, Alex',
              subtitle: 'Dubai, UAE',
            ),

            PageTitle(
              'support_contact_center'.tr(),
              subtitle: 'support_desc'.tr(),
              padding: const EdgeInsets.fromLTRB(RS.x20, RS.x24, RS.x20, RS.x16),
            ),

            // ---- Channels ----
            Padding(
              padding: RS.page,
              child: Column(
                children: [
                  for (final (title, subtitle, icon, tint) in _channels)
                    Padding(
                      padding: const EdgeInsets.only(bottom: RS.x12),
                      child: RCard(
                        onTap: () => _handleChannel(title),
                        child: Row(
                          children: [
                            IconBubble(icon, tint: tint, size: 44),
                            const SizedBox(width: RS.x14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: RT.title),
                                  const SizedBox(height: 2),
                                  Text(subtitle, style: RT.captionSm),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, matchTextDirection: true,
                                size: 20, color: RC.textTertiary),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ---- Categories ----
            SectionTitle('how_can_we_help'.tr()),
            Padding(
              padding: RS.page,
              child: RCard(
                padding: const EdgeInsets.symmetric(horizontal: RS.x16),
                child: Column(
                  children: [
                    for (var i = 0;
                        i < MockData.supportCategories.length;
                        i++) ...[
                      RowItem(
                        title: MockData.supportCategories[i].title,
                        subtitle: MockData.supportCategories[i].subtitle,
                        leading: IconBubble(
                          MockData.supportCategories[i].icon,
                          tint: MockData.supportCategories[i].tint,
                          size: 38,
                        ),
                        onTap: () => Navigator.pushNamed(
                          context,
                          Routes.supportCategory,
                          arguments: MockData.supportCategories[i].title,
                        ),
                      ),
                      if (i != MockData.supportCategories.length - 1)
                        const ThinDivider(inset: 50),
                    ],
                  ],
                ),
              ),
            ),

            // ---- FAQs ----
            SectionTitle(
                'quick_answers'.tr(), subtitle: 'find_answers'.tr()),
            FutureBuilder<List<FaqItem>>(
              future: _faqs,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 140,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: RC.teal, strokeWidth: 2.5),
                    ),
                  );
                }
                final faqs = snapshot.data!;
                return Padding(
                  padding: RS.page,
                  child: RCard(
                    padding: const EdgeInsets.symmetric(horizontal: RS.x16),
                    child: Column(
                      children: [
                        for (var i = 0; i < faqs.length; i++) ...[
                          _FaqTile(
                            item: faqs[i],
                            expanded: _expandedFaq == i,
                            onTap: () => setState(
                              () => _expandedFaq = _expandedFaq == i ? null : i,
                            ),
                          ),
                          if (i != faqs.length - 1) const ThinDivider(),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            // ---- Recent conversations ----
            SectionTitle('recent_conversations'.tr()),
            FutureBuilder<List<SupportTicket>>(
              future: _tickets,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 140,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: RC.teal, strokeWidth: 2.5),
                    ),
                  );
                }
                final tickets = snapshot.data!;
                return Padding(
                  padding: RS.page,
                  child: Column(
                    children: [
                      for (final ticket in tickets)
                        Padding(
                          padding: const EdgeInsets.only(bottom: RS.x12),
                          child: RCard(
                            onTap: () => Navigator.pushNamed(
                                context, Routes.ticketDetails),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IconBubble(
                                  Icons.chat_outlined,
                                  tint: _statusColor(ticket.status),
                                  size: 42,
                                ),
                                const SizedBox(width: RS.x12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(ticket.title,
                                          style: RT.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: RS.x6),
                                      Wrap(
                                        spacing: RS.x8,
                                        runSpacing: RS.x6,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text('Ticket #${ticket.id}',
                                              style: RT.captionSm),
                                          RBadge(ticket.status,
                                              color:
                                                  _statusColor(ticket.status)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            const BottomGutter(),
          ],
        ),
      ),

      bottomNavigationBar: ResivynBottomNav(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.shell,
            (route) => route.settings.name == Routes.login,
            arguments: i,
          );
        },
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.item,
    required this.expanded,
    required this.onTap,
  });

  final FaqItem item;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: RS.x14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.question, style: RT.title)),
                const SizedBox(width: RS.x8),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: RC.textTertiary),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.only(top: RS.x10),
                child: Text(item.answer, style: RT.body),
              ),
              secondChild: const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
