import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme/tokens.dart';
import '../widgets/common.dart';

/// A developer-facing directory of every screen, so the whole build can be
/// reviewed without walking the full navigation flow.
class DevIndexScreen extends StatelessWidget {
  const DevIndexScreen({super.key});

  static const _screens = <(String, String, String, IconData, Color)>[
    ('01', 'Property Floor Plan', Routes.floorPlan, Icons.architecture_outlined,
        RC.teal),
    ('02', 'Support & Contact Center', Routes.support,
        Icons.support_agent_outlined, RC.info),
    ('03', 'Notifications', Routes.notifications,
        Icons.notifications_none_rounded, RC.warning),
    ('04', 'Super Admin Dashboard', Routes.adminDashboard,
        Icons.shield_outlined, RC.navy),
    ('05', 'Maintenance Dashboard', Routes.maintenanceDashboard,
        Icons.handyman_outlined, RC.purple),
    ('06', 'Tenant Dashboard', Routes.tenantDashboard,
        Icons.king_bed_outlined, RC.teal),
    ('07', 'Owner Dashboard', Routes.ownerDashboard,
        Icons.business_center_outlined, RC.success),
    ('08', 'Luxury Villa Details', Routes.villaDetails, Icons.villa_outlined,
        RC.warning),
    ('09', 'Search Properties', Routes.search, Icons.search_rounded, RC.info),
    ('10', 'Login / Role Selection', Routes.login, Icons.login_rounded, RC.navy),
    ('11', 'RESIVYN Home', Routes.shell, Icons.home_outlined, RC.teal),
    ('12', 'Property Details — Full', Routes.propertyDetails,
        Icons.apartment_outlined, RC.purple),
    ('13', 'Property Gallery', Routes.gallery, Icons.photo_library_outlined,
        RC.info),
    ('14', 'Sell Your Property', Routes.sellProperty,
        Icons.real_estate_agent_outlined, RC.success),
    ('15', 'About RESIVYN', Routes.about, Icons.info_outline_rounded, RC.navy),
    ('16', 'Contact Us', Routes.contact, Icons.mail_outline_rounded, RC.teal),
    ('17', 'Choose Your Plan', Routes.plans,
        Icons.workspace_premium_outlined, RC.warning),
    ('18', 'Privacy Policy', Routes.privacy, Icons.shield_outlined, RC.purple),
    ('19', 'Terms & Conditions', Routes.terms, Icons.gavel_outlined, RC.navy),
    ('20', 'Ticket Details', Routes.ticketDetails,
        Icons.confirmation_number_outlined, RC.info),
    ('21', 'Profile / Settings', Routes.profile, Icons.person_outline_rounded,
        RC.teal),
  ];

  static const _supporting = <(String, String, IconData)>[
    ('Tab Shell (Home/Search/Saved/…)', Routes.shell, Icons.grid_view_rounded),
    ('Saved', Routes.saved, Icons.bookmark_outline_rounded),
    ('Community', Routes.community, Icons.people_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const ResivynHeader(showBack: true),

            const PageTitle(
              'All Screens',
              subtitle: '21 screens from the RESIVYN spec. Tap any to open it.',
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(RS.x20, 0, RS.x20, RS.x16),
              child: InfoBanner(
                title: 'Local preview build',
                body: 'Every screen runs on in-memory mock data — no backend '
                    'or network connection required.',
                icon: Icons.offline_bolt_outlined,
              ),
            ),

            Padding(
              padding: RS.page,
              child: RCard(
                padding: const EdgeInsets.symmetric(horizontal: RS.x16),
                child: Column(
                  children: [
                    for (var i = 0; i < _screens.length; i++) ...[
                      RowItem(
                        title: _screens[i].$2,
                        subtitle: _screens[i].$3,
                        dense: true,
                        leading: Stack(
                          alignment: Alignment.center,
                          children: [
                            IconBubble(_screens[i].$4,
                                tint: _screens[i].$5, size: 38),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: RS.x8, vertical: 4),
                          decoration: BoxDecoration(
                            color: RC.bg,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: RC.border),
                          ),
                          child: Text(
                            _screens[i].$1,
                            style: RT.captionSm.copyWith(
                              fontWeight: FontWeight.w700,
                              color: RC.navy,
                            ),
                          ),
                        ),
                        onTap: () =>
                            Navigator.pushNamed(context, _screens[i].$3),
                      ),
                      if (i != _screens.length - 1) const ThinDivider(inset: 50),
                    ],
                  ],
                ),
              ),
            ),

            const SectionTitle('Supporting screens'),
            Padding(
              padding: RS.page,
              child: RCard(
                padding: const EdgeInsets.symmetric(horizontal: RS.x16),
                child: Column(
                  children: [
                    for (var i = 0; i < _supporting.length; i++) ...[
                      RowItem(
                        title: _supporting[i].$1,
                        subtitle: _supporting[i].$2,
                        dense: true,
                        leading: IconBubble(_supporting[i].$3,
                            tint: RC.textSecondary, size: 38),
                        onTap: () =>
                            Navigator.pushNamed(context, _supporting[i].$2),
                      ),
                      if (i != _supporting.length - 1)
                        const ThinDivider(inset: 50),
                    ],
                  ],
                ),
              ),
            ),

            const BottomGutter(),
          ],
        ),
      ),
    );
  }
}
