import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme/tokens.dart';
import '../data/mock/mock_data.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/common.dart';
import '../widgets/resivyn_image.dart';

/// SCREEN 15 — ABOUT RESIVYN
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int _navIndex = 0;

  static const _stats = <(String, String)>[
    ('50K+', 'Active Listings\nAcross Dubai & UAE'),
    ('120+', 'Communities\nPremium & Verified'),
    ('98%', 'Client Satisfaction\nTrusted by Thousands'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const ResivynHeader(showBack: true, centerLogo: true),

            PageTitle('about_resivyn_title'.tr()),

            // ---- Hero ----
            Padding(
              padding: RS.page,
              child: ClipRRect(
                borderRadius: RR.cardLg,
                child: Stack(
                  children: [
                    const ResivynImage(url: Img.dubaiWaterfront, height: 190),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              RC.navy.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: RS.x20,
                      bottom: RS.x20,
                      right: RS.x20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ResivynWordmark(onLight: false),
                          const SizedBox(height: RS.x8),
                          Text(
                            'real_estate_os'.tr(),
                            style: RT.caption.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Description ----
            const Padding(
              padding: EdgeInsets.fromLTRB(RS.x20, RS.x20, RS.x20, 0),
              child: RCard(
                child: Text(MockData.aboutBlurb, style: RT.body),
              ),
            ),

            // ---- Mission / vision / values ----
            SectionTitle('what_drives_us'.tr()),
            Padding(
              padding: RS.page,
              child: Column(
                children: [
                  for (final (title, body, icon) in MockData.aboutPillars)
                    Padding(
                      padding: const EdgeInsets.only(bottom: RS.x12),
                      child: RCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconBubble(icon, tint: RC.teal, size: 42),
                            const SizedBox(width: RS.x14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: RT.title),
                                  const SizedBox(height: RS.x6),
                                  Text(body, style: RT.caption),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ---- Offerings ----
            SectionTitle('what_we_offer'.tr()),
            Padding(
              padding: RS.page,
              child: RGrid(
                columns: 3,
                childAspectRatio: 0.92,
                children: [
                  for (final (label, icon) in MockData.offerings)
                    RCard(
                      padding: const EdgeInsets.all(RS.x10),
                      onTap: () => toast(context, '$label — explore',
                          icon: icon),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconBubble(icon, tint: RC.teal, size: 38),
                          const SizedBox(height: RS.x8),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: RT.captionSm.copyWith(
                              color: RC.navy,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ---- Stats ----
            SectionTitle('by_the_numbers'.tr()),
            Padding(
              padding: RS.page,
              child: RCard(
                color: RC.navy,
                showBorder: false,
                padding: const EdgeInsets.symmetric(
                    vertical: RS.x20, horizontal: RS.x8),
                child: Row(
                  children: [
                    for (var i = 0; i < _stats.length; i++) ...[
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _stats[i].$1,
                              style: RT.h1.copyWith(color: RC.teal),
                            ),
                            const SizedBox(height: RS.x6),
                            Text(
                              _stats[i].$2,
                              textAlign: TextAlign.center,
                              style: RT.captionSm.copyWith(
                                color: Colors.white70,
                                fontSize: 9.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i != _stats.length - 1)
                        Container(
                            width: 1,
                            height: 46,
                            color: Colors.white.withOpacity(0.15)),
                    ],
                  ],
                ),
              ),
            ),

            // ---- Links ----
            SectionTitle('more'.tr()),
            Padding(
              padding: RS.page,
              child: RCard(
                padding: const EdgeInsets.symmetric(horizontal: RS.x16),
                child: Column(
                  children: [
                    RowItem(
                      title: 'contact_us'.tr(),
                      leading: const IconBubble(Icons.mail_outline_rounded,
                          tint: RC.info, size: 36),
                      onTap: () => Navigator.pushNamed(context, Routes.contact),
                      dense: true,
                    ),
                    const ThinDivider(inset: 48),
                    RowItem(
                      title: 'privacy_policy_title'.tr(),
                      leading: const IconBubble(Icons.shield_outlined,
                          tint: RC.purple, size: 36),
                      onTap: () => Navigator.pushNamed(context, Routes.privacy),
                      dense: true,
                    ),
                    const ThinDivider(inset: 48),
                    RowItem(
                      title: 'terms_conditions_title'.tr(),
                      leading: const IconBubble(Icons.gavel_outlined,
                          tint: RC.navy, size: 36),
                      onTap: () => Navigator.pushNamed(context, Routes.terms),
                      dense: true,
                    ),
                  ],
                ),
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
