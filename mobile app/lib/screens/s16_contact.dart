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

/// SCREEN 16 — CONTACT US
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  int _navIndex = 0;
  int _selectedArea = 0;

  late Future<List<OfficeArea>> _offices;

  static final _channels = <(String, String, IconData, Color)>[
    ('call_us'.tr(), '+971 4 123 4567', Icons.phone_in_talk_outlined,
        RC.teal),
    ('WhatsApp', '+971 50 123 4567', Icons.chat_bubble_outline_rounded,
        RC.success),
    ('Email Us', 'hello@resivyn.com', Icons.mail_outline_rounded, RC.info),
    ('visit_offices'.tr(), 'view_branches'.tr(), Icons.location_on_outlined,
        RC.purple),
  ];

  @override
  void initState() {
    super.initState();
    _offices = Services.content.offices();
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
                  icon: Icons.forum_outlined,
                  tooltip: 'live_chat_tooltip'.tr(),
                  onTap: () => Navigator.pushNamed(context, Routes.liveChat),
                ),
              ],
            ),

            PageTitle('contact_us_title'.tr(), subtitle: 'were_here_help'.tr()),

            // ---- Channels ----
            Padding(
              padding: RS.page,
              child: RCard(
                padding: const EdgeInsets.symmetric(horizontal: RS.x16),
                child: Column(
                  children: [
                    for (var i = 0; i < _channels.length; i++) ...[
                      RowItem(
                        title: _channels[i].$1,
                        subtitle: _channels[i].$2,
                        leading: IconBubble(_channels[i].$3,
                            tint: _channels[i].$4, size: 42),
                        onTap: () async {
                          final name = _channels[i].$1;
                          final detail = _channels[i].$2;
                          if (name == 'call_us'.tr()) {
                            final uri = Uri.parse('tel:+97141234567');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              toast(context, 'Could not initiate call',
                                  icon: Icons.error_outline_rounded);
                            }
                          } else if (name == 'WhatsApp') {
                            final uri =
                                Uri.parse('https://wa.me/971501234567');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            } else {
                              toast(context, 'Could not open WhatsApp',
                                  icon: Icons.error_outline_rounded);
                            }
                          } else if (name == 'Email Us') {
                            final uri =
                                Uri.parse('mailto:hello@resivyn.com');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              toast(context, 'Could not open email client',
                                  icon: Icons.error_outline_rounded);
                            }
                          } else {
                            toast(context, '$name • $detail',
                                icon: _channels[i].$3);
                          }
                        },
                      ),
                      if (i != _channels.length - 1)
                        const ThinDivider(inset: 54),
                    ],
                  ],
                ),
              ),
            ),

            // ---- Map ----
            SectionTitle('our_locations'.tr(),
                subtitle: 'six_offices'.tr()),
            Padding(
              padding: RS.page,
              child: ClipRRect(
                borderRadius: RR.card,
                child: Stack(
                  children: [
                    const ResivynImage(
                      url: Img.dubaiSkyline,
                      height: 170,
                      icon: Icons.map_outlined,
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration:
                            BoxDecoration(color: RC.navy.withOpacity(0.55)),
                      ),
                    ),
                    const Positioned.fill(
                      child: Center(
                        child: Icon(Icons.place_rounded,
                            size: 36, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: RS.x16),
            FutureBuilder<List<OfficeArea>>(
              future: _offices,
              builder: (context, snapshot) {
                final offices = snapshot.data ?? MockData.offices;
                return RPillBar(
                  items: [for (final o in offices) o.name],
                  selectedIndex: _selectedArea,
                  onChanged: (i) => setState(() => _selectedArea = i),
                );
              },
            ),

            // ---- Head office ----
            SectionTitle('head_office'.tr()),
            Padding(
              padding: RS.page,
              child: RCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const IconBubble(Icons.apartment_outlined,
                            tint: RC.teal),
                        const SizedBox(width: RS.x12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('head_office_dubai'.tr(), style: RT.title),
                              const SizedBox(height: 2),
                              const Text(
                                '101 Business Bay, Dubai, United Arab Emirates',
                                style: RT.captionSm,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: RS.x16),
                    const ThinDivider(),
                    const SizedBox(height: RS.x8),
                    const KeyValueRow('Mon – Fri', '9:00 AM – 6:00 PM'),
                    const KeyValueRow('Saturday – Sunday', 'Closed',
                        valueColor: RC.danger),
                    const SizedBox(height: RS.x12),
                    RButton(
                      'get_directions'.tr(),
                      kind: RButtonKind.navy,
                      expanded: true,
                      icon: Icons.directions_outlined,
                      onPressed: () => toast(context, 'Opening directions',
                          icon: Icons.directions_outlined),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Live chat prompt ----
            Padding(
              padding: const EdgeInsets.fromLTRB(RS.x20, RS.x24, RS.x20, 0),
              child: InfoBanner(
                title: 'need_faster_support'.tr(),
                body: 'start_live_chat'.tr(),
                icon: Icons.bolt_rounded,
                dark: true,
                ctaLabel: 'start_live_chat_btn'.tr(),
                onCta: () => Navigator.pushNamed(context, Routes.liveChat),
              ),
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
