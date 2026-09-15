import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/service_locator.dart';
import '../core/theme/tokens.dart';
import '../data/models/models.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/common.dart';

/// SCREEN 18 — PRIVACY POLICY
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalScreen(
      title: 'privacy_policy_title'.tr(),
      lastUpdated: 'last_updated'.tr(),
      headerIcon: Icons.shield_outlined,
      sections: Services.content.privacySections(),
      bannerTitle: 'your_privacy_matters'.tr(),
      bannerBody: 'protect_data'.tr(),
      bannerIcon: Icons.lock_outline_rounded,
      ctaLabel: 'i_understand'.tr(),
      ctaMessage: 'prefs_saved'.tr(),
    );
  }
}

/// SCREEN 19 — TERMS & CONDITIONS
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalScreen(
      title: 'terms_conditions_title'.tr(),
      lastUpdated: 'last_updated'.tr(),
      headerIcon: Icons.gavel_outlined,
      sections: Services.content.termsSections(),
      bannerTitle: 'agree_terms_banner'.tr(),
      bannerBody: 'read_carefully'.tr(),
      bannerIcon: Icons.description_outlined,
      ctaLabel: 'i_agree'.tr(),
      ctaMessage: 'terms_accepted'.tr(),
    );
  }
}

/// Shared scaffold for the two legal documents. Same structure, different copy.
class LegalScreen extends StatefulWidget {
  const LegalScreen({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.headerIcon,
    required this.sections,
    required this.bannerTitle,
    required this.bannerBody,
    required this.bannerIcon,
    required this.ctaLabel,
    required this.ctaMessage,
  });

  final String title;
  final String lastUpdated;
  final IconData headerIcon;
  final Future<List<LegalSection>> sections;
  final String bannerTitle;
  final String bannerBody;
  final IconData bannerIcon;
  final String ctaLabel;
  final String ctaMessage;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  int _navIndex = 0;
  bool _acknowledged = false;

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
                  icon: widget.headerIcon,
                  tooltip: widget.title,
                  onTap: () => toast(context, widget.title,
                      icon: widget.headerIcon),
                ),
              ],
            ),

            PageTitle(widget.title, subtitle: widget.lastUpdated),

            FutureBuilder<List<LegalSection>>(
              future: widget.sections,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: RC.teal, strokeWidth: 2.5),
                    ),
                  );
                }
                return Padding(
                  padding: RS.page,
                  child: Column(
                    children: [
                      for (final section in snapshot.data!)
                        Padding(
                          padding: const EdgeInsets.only(bottom: RS.x12),
                          child: RCard(
                            padding: const EdgeInsets.all(RS.x18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: RC.tealSoft,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${section.index}',
                                          style: RT.captionSm.copyWith(
                                            color: RC.tealDark,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: RS.x12),
                                    Expanded(
                                      child: Text(section.title, style: RT.h2),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: RS.x12),
                                Text(section.body, style: RT.body),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // ---- Banner ----
            Padding(
              padding: const EdgeInsets.fromLTRB(RS.x20, RS.x8, RS.x20, 0),
              child: InfoBanner(
                title: widget.bannerTitle,
                body: widget.bannerBody,
                icon: widget.bannerIcon,
                dark: true,
              ),
            ),

            // ---- CTA ----
            Padding(
              padding: const EdgeInsets.fromLTRB(RS.x20, RS.x20, RS.x20, 0),
              child: RButton(
                _acknowledged ? 'acknowledged'.tr() : widget.ctaLabel,
                kind: _acknowledged ? RButtonKind.soft : RButtonKind.primary,
                expanded: true,
                icon: Icons.check_rounded,
                onPressed: () {
                  setState(() => _acknowledged = true);
                  toast(context, widget.ctaMessage,
                      icon: Icons.check_circle_outline_rounded);
                },
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
