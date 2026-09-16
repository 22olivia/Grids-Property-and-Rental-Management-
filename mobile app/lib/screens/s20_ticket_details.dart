import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/routes.dart';
import '../core/theme/tokens.dart';
import '../data/mock/mock_data.dart';
import '../data/models/models.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/common.dart';
import '../widgets/resivyn_image.dart';

/// SCREEN 20 — TICKET DETAILS
class TicketDetailsScreen extends StatefulWidget {
  const TicketDetailsScreen({super.key});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  int _navIndex = 0;
  final _composer = TextEditingController();
  final _scrollController = ScrollController();

  late List<TicketMessage> _messages =
      List<TicketMessage>.from(MockData.detailedTicket.messages);
  bool _resolved = false;

  SupportTicket get _ticket => MockData.detailedTicket;

  @override
  void dispose() {
    _composer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages = [
        ..._messages,
        TicketMessage(
          author: 'Alex Johnson',
          role: 'You',
          body: text,
          timestamp: 'Just now',
          fromAgent: false,
        ),
      ];
      _composer.clear();
    });

    // Let the new bubble lay out before scrolling to it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          children: [
            ResivynHeader(
              showBack: true,
              trailing: [
                RIconButton(
                  icon: Icons.headset_mic_outlined,
                  tooltip: 'call_support_tooltip'.tr(),
                  onTap: () async {
                    final uri = Uri.parse('tel:+97141234567');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      toast(context, 'Could not initiate call',
                          icon: Icons.error_outline_rounded);
                    }
                  },
                ),
              ],
            ),

            PageTitle('ticket_details'.tr()),

            // ---- Ticket summary ----
            Padding(
              padding: RS.page,
              child: RCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('#${_ticket.id}',
                                  style: RT.h2.copyWith(color: RC.teal)),
                              const SizedBox(height: RS.x4),
                              Text('Created: ${_ticket.createdAt}',
                                  style: RT.captionSm),
                            ],
                          ),
                        ),
                        RBadge(
                          _resolved ? 'Resolved' : _ticket.status,
                          color: _resolved ? RC.success : RC.info,
                          solid: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: RS.x16),
                    const ThinDivider(),
                    const SizedBox(height: RS.x16),
                    Row(
                      children: [
                        Expanded(
                          child: _MetaCell(
                            label: 'priority'.tr(),
                            value: _ticket.priority,
                            tint: RC.warning,
                          ),
                        ),
                        Container(width: 1, height: 34, color: RC.border),
                        Expanded(
                          child: _MetaCell(
                            label: 'category'.tr(),
                            value: _ticket.category,
                            tint: RC.purple,
                          ),
                        ),
                        Container(width: 1, height: 34, color: RC.border),
                        Expanded(
                          child: _MetaCell(
                            label: 'status'.tr(),
                            value: _resolved ? 'Resolved' : _ticket.status,
                            tint: _resolved ? RC.success : RC.info,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ---- Issue ----
            SectionTitle('issue'.tr()),
            Padding(
              padding: RS.page,
              child: RCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_ticket.title, style: RT.title),
                    const SizedBox(height: RS.x10),
                    Text(_ticket.description, style: RT.body),
                  ],
                ),
              ),
            ),

            // ---- Conversation ----
            SectionTitle('conversation'.tr()),
            Padding(
              padding: RS.page,
              child: Column(
                children: [
                  for (final message in _messages)
                    _MessageBubble(message: message),
                ],
              ),
            ),

            // ---- Assigned agent ----
            SectionTitle('assigned_agent'.tr()),
            Padding(
              padding: RS.page,
              child: RCard(
                child: Row(
                  children: [
                    const ResivynAvatar(
                      url: Img.avatarSara,
                      name: 'Sara Collins',
                      size: 48,
                      ring: true,
                    ),
                    const SizedBox(width: RS.x12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sara Collins', style: RT.title),
                          const SizedBox(height: 2),
                          Text('support_specialist'.tr(), style: RT.captionSm),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('2h 15m', style: RT.h2),
                        const SizedBox(height: 2),
                        Text('avg_response'.tr(),
                            style: TextStyle(
                                fontSize: 9.5, color: RC.textTertiary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ---- Actions ----
            Padding(
              padding: const EdgeInsets.fromLTRB(RS.x20, RS.x24, RS.x20, 0),
              child: Column(
                children: [
                  RButton(
                    _resolved ? 'ticket_resolved'.tr() : 'mark_resolved'.tr(),
                    kind: _resolved ? RButtonKind.soft : RButtonKind.primary,
                    expanded: true,
                    icon: Icons.task_alt_rounded,
                    onPressed: _resolved
                        ? null
                        : () {
                            setState(() => _resolved = true);
                            toast(context, 'ticket_marked_resolved'.tr(),
                                icon: Icons.task_alt_rounded);
                          },
                  ),
                  const SizedBox(height: RS.x12),
                  RButton(
                    'need_urgent_help'.tr(),
                    kind: RButtonKind.outline,
                    expanded: true,
                    icon: Icons.phone_in_talk_outlined,
                    onPressed: () async {
                      final uri = Uri.parse('tel:+97141234567');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        toast(context, 'Could not initiate call',
                            icon: Icons.error_outline_rounded);
                      }
                    },
                  ),
                ],
              ),
            ),

            const BottomGutter(extra: 64),
          ],
        ),
      ),

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---- Composer ----
          Container(
            padding: const EdgeInsets.fromLTRB(RS.x16, RS.x10, RS.x16, RS.x10),
            decoration: const BoxDecoration(
              color: RC.surface,
              border: Border(top: BorderSide(color: RC.border)),
            ),
            child: Row(
              children: [
                RIconButton(
                  icon: Icons.attach_file_rounded,
                  tooltip: 'attach_file'.tr(),
                  onTap: () => showMockAttachmentPicker(context),
                ),
                const SizedBox(width: RS.x8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: RC.bg,
                      borderRadius: RR.chip,
                      border: Border.all(color: RC.border),
                    ),
                    child: TextField(
                      controller: _composer,
                      style: RT.bodyStrong,
                      cursorColor: RC.teal,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'type_message'.tr(),
                        hintStyle: RT.body.copyWith(color: RC.textTertiary),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: RS.x16,
                          vertical: RS.x12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: RS.x8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: RC.teal,
                      shape: BoxShape.circle,
                      boxShadow: RShadow.teal,
                    ),
                    child: const Icon(Icons.send_rounded,
                        size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          ResivynBottomNav(
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
        ],
      ),
    );
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: RT.captionSm.copyWith(fontSize: 9.5)),
        const SizedBox(height: RS.x6),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: RT.captionSm.copyWith(
            color: tint,
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final TicketMessage message;

  @override
  Widget build(BuildContext context) {
    final agent = message.fromAgent;

    return Padding(
      padding: const EdgeInsets.only(bottom: RS.x16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            agent ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (agent) ...[
            const ResivynAvatar(
              url: Img.avatarSara,
              name: 'Sara Collins',
              size: 34,
            ),
            const SizedBox(width: RS.x8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  agent ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.author,
                      style: RT.captionSm.copyWith(
                        color: RC.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: RS.x6),
                    Text(message.role,
                        style: RT.captionSm.copyWith(fontSize: 9.5)),
                  ],
                ),
                const SizedBox(height: RS.x6),
                Container(
                  padding: const EdgeInsets.all(RS.x14),
                  decoration: BoxDecoration(
                    color: agent ? RC.surface : RC.navy,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(agent ? 4 : 16),
                      topRight: Radius.circular(agent ? 16 : 4),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                    border: agent ? Border.all(color: RC.border) : null,
                    boxShadow: RShadow.soft,
                  ),
                  child: Text(
                    message.body,
                    style: RT.body.copyWith(
                      color: agent ? RC.textSecondary : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: RS.x6),
                Text(message.timestamp,
                    style: RT.captionSm.copyWith(fontSize: 9.5)),
              ],
            ),
          ),
          if (!agent) ...[
            const SizedBox(width: RS.x8),
            const ResivynAvatar(
              url: Img.avatarAlex,
              name: 'Alex Johnson',
              size: 34,
            ),
          ],
        ],
      ),
    );
  }
}
