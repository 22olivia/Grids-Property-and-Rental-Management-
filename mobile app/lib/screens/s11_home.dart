import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/service_locator.dart';
import '../core/theme/tokens.dart';
import '../data/mock/mock_data.dart';
import '../data/models/models.dart';
import '../widgets/common.dart';
import '../widgets/property_card.dart';
import '../widgets/resivyn_image.dart';

/// SCREEN 11 — RESIVYN HOME
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenSearch});

  /// Lets the tab shell switch to the Search tab instead of pushing a route.
  final VoidCallback? onOpenSearch;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navPill = 0;
  late Future<List<Property>> _featured;

  static final _pills = [
    'buy'.tr(),
    'rent'.tr(),
    'sell'.tr(),
    'commercial'.tr(),
    'communities'.tr(),
    'manage'.tr(),
  ];

  static const _pillIcons = [
    Icons.sell_outlined,
    Icons.vpn_key_outlined,
    Icons.real_estate_agent_outlined,
    Icons.corporate_fare_outlined,
    Icons.holiday_village_outlined,
    Icons.tune_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _featured = Services.properties.featured();
  }

  void _openSearch() {
    if (widget.onOpenSearch != null) {
      widget.onOpenSearch!();
    } else {
      Navigator.pushNamed(context, Routes.search);
    }
  }

  void _handlePill(int i) {
    setState(() => _navPill = i);
    switch (i) {
      case 2:
        Navigator.pushNamed(context, Routes.sellProperty);
      case 5:
        Navigator.pushNamed(context, Routes.ownerDashboard);
      case 4:
        toast(context, 'exploring_communities'.tr(), icon: Icons.holiday_village_outlined);
      default:
        _openSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ResivynHeader(
          trailing: [
            RIconButton(
              icon: Icons.notifications_none_rounded,
              badge: true,
              tooltip: 'notifications'.tr(),
              onTap: () => Navigator.pushNamed(context, Routes.notifications),
            ),
            const SizedBox(width: RS.x8),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, Routes.profile),
              child: const ResivynAvatar(
                url: Img.avatarAlex,
                name: 'Alex Johnson',
                size: 40,
                ring: true,
              ),
            ),
          ],
        ),

        GreetingBlock(
          greeting: 'good_morning'.tr(namedArgs: {'name': 'Alex'}),
          subtitle: 'dubai_uae'.tr(),
        ),

        // ---- Search ----
        Padding(
          padding: const EdgeInsets.fromLTRB(RS.x20, RS.x20, RS.x20, 0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _openSearch,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: RS.x16),
                    decoration: BoxDecoration(
                      color: RC.surface,
                      borderRadius: RR.button,
                      border: Border.all(color: RC.border),
                      boxShadow: RShadow.soft,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            size: 20, color: RC.textTertiary),
                        const SizedBox(width: RS.x10),
                        Expanded(
                          child: Text(
                            'search_properties_hint'.tr(),
                            style: RT.body.copyWith(
                                color: RC.textTertiary, fontSize: 12.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: RS.x10),
              GestureDetector(
                onTap: _openSearch,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: RC.navy,
                    borderRadius: RR.button,
                    boxShadow: RShadow.soft,
                  ),
                  child: const Center(
                    child: Icon(Icons.tune_rounded, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: RS.x16),
        RPillBar(
          items: _pills,
          icons: _pillIcons,
          selectedIndex: _navPill,
          onChanged: _handlePill,
        ),

        // ---- Hero banner ----
        Padding(
          padding: const EdgeInsets.fromLTRB(RS.x20, RS.x24, RS.x20, 0),
          child: ClipRRect(
            borderRadius: RR.cardLg,
            child: Stack(
              children: [
                const ResivynImage(url: Img.villaHero, height: 230),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          RC.navy.withOpacity(0.15),
                          RC.navy.withOpacity(0.85),
                        ],
                        stops: const [0.25, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: RS.x16,
                  left: RS.x16,
                  child: RBadge('featured'.tr(),
                      color: RC.warning, solid: true, uppercase: true),
                ),
                Positioned(
                  left: RS.x20,
                  right: RS.x20,
                  bottom: RS.x20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'luxury_living'.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: RS.x4),
                      Text(
                        'luxury_living_desc'.tr(),
                        style: RT.caption.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: RS.x16),
                      RButton(
                        'explore_now'.tr(),
                        compact: true,
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _openSearch,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ---- Feature cards ----
        SectionTitle('everything_in_one_place'.tr()),
        Padding(
          padding: RS.page,
          child: RGrid(
            childAspectRatio: 1.12,
            children: [
              _FeatureCard(
                title: 'explore_properties'.tr(),
                body: 'explore_properties_desc'.tr(),
                icon: Icons.apartment_rounded,
                tint: RC.teal,
                onTap: _openSearch,
              ),
              _FeatureCard(
                title: 'property_management'.tr(),
                body: 'property_management_desc'.tr(),
                icon: Icons.corporate_fare_rounded,
                tint: RC.info,
                onTap: () =>
                    Navigator.pushNamed(context, Routes.ownerDashboard),
              ),
              _FeatureCard(
                title: 'communities'.tr(),
                body: 'find_community'.tr(),
                icon: Icons.holiday_village_rounded,
                tint: RC.purple,
                onTap: () => Navigator.pushNamed(context, Routes.community),
              ),
              _FeatureCard(
                title: 'book_viewing'.tr(),
                body: 'schedule_visit'.tr(),
                icon: Icons.event_available_rounded,
                tint: RC.warning,
                onTap: () => showBookViewingSheet(context),
              ),
            ],
          ),
        ),

        // ---- Featured properties ----
        SectionTitle(
          'featured_properties'.tr(),
          actionLabel: 'see_all'.tr(),
          onAction: _openSearch,
        ),
        FutureBuilder<List<Property>>(
          future: _featured,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 260,
                child: Center(
                  child: CircularProgressIndicator(color: RC.teal, strokeWidth: 2.5),
                ),
              );
            }
            final items = snapshot.data!;
            return SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: RS.page,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: RS.x12),
                itemBuilder: (context, i) => PropertyMiniCard(
                  property: items[i],
                  onTap: () => Navigator.pushNamed(
                    context,
                    Routes.propertyDetails,
                    arguments: items[i],
                  ),
                ),
              ),
            );
          },
        ),

        // ---- Support prompt ----
        Padding(
          padding: const EdgeInsets.fromLTRB(RS.x20, RS.x24, RS.x20, 0),
          child: InfoBanner(
            title: 'need_a_hand'.tr(),
            body: 'dubai_team_reply'.tr(),
            icon: Icons.support_agent_rounded,
            dark: true,
            ctaLabel: 'contact_support'.tr(),
            onCta: () => Navigator.pushNamed(context, Routes.support),
          ),
        ),

        const BottomGutter(),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RCard(
      onTap: onTap,
      padding: const EdgeInsets.all(RS.x14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(icon, tint: tint, size: 38),
          const Spacer(),
          Flexible(
            child: Text(title,
                style: RT.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: RS.x4),
          Flexible(
            child: Text(
              body,
              style: RT.captionSm.copyWith(fontSize: 10.5, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
