import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/routes.dart';
import '../core/theme/tokens.dart';
import '../data/mock/mock_data.dart';
import '../data/models/models.dart';
import '../widgets/common.dart';
import '../widgets/detail_parts.dart';

/// SCREEN 12 — PROPERTY DETAILS — FULL VIEW
///
/// The canonical property page. Screen 08 is the compact sales variant and
/// screen 01 is the Floor Plan deep-dive.
class PropertyDetailsScreen extends StatefulWidget {
  const PropertyDetailsScreen({super.key, this.property});

  final Property? property;

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  int _tab = 0;

  static final _tabs = [
    'overview'.tr(),
    'amenities_tab'.tr(),
    'floor_plan'.tr(),
    'nearby'.tr(),
  ];

  Property get _property => widget.property ?? MockData.luxuryVilla;

  /// Numeric price for the estimator, parsed out of the display label.
  double get _numericPrice {
    final digits = _property.priceLabel.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = double.tryParse(digits) ?? 8200000;
    // Annual rent labels would otherwise be treated as a purchase price.
    return _property.listingType == ListingType.forRent ? parsed * 12 : parsed;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final saved = state.isSaved(_property.id);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          PropertyHero(
            property: _property,
            height: 330,
            showGalleryButton: true,
          ),

          const SizedBox(height: RS.x20),
          PropertyTitleBlock(property: _property),

          Padding(
            padding: const EdgeInsets.fromLTRB(RS.x20, RS.x16, RS.x20, RS.x20),
            child: PropertyStatsCard(property: _property),
          ),

          RUnderlineTabs(
            items: _tabs,
            selectedIndex: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),

          const SizedBox(height: RS.x20),
          Padding(
            padding: RS.page,
            child: switch (_tab) {
              0 => _OverviewTab(property: _property, price: _numericPrice),
              1 => const AmenitiesGrid(),
              2 => _FloorPlanTeaser(property: _property),
              _ => const NearbyList(),
            },
          ),

          const BottomGutter(extra: RS.x20),
        ],
      ),

      bottomNavigationBar: StickyActionBar(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_property.priceLabel,
                    style: RT.h2, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(_property.title, style: RT.captionSm, maxLines: 1),
              ],
            ),
          ),
          const SizedBox(width: RS.x12),
          Flexible(
            child: RButton(
              saved ? 'Saved' : 'save'.tr(),
              kind: RButtonKind.outline,
              icon:
                  saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              compact: true,
              onPressed: () {
                final nowSaved = state.toggleSaved(_property.id);
toast(context,
 nowSaved ? 'saved_to_list'.tr() : 'removed_from_saved'.tr(),
    icon: Icons.favorite_rounded);
              },
            ),
          ),
          const SizedBox(width: RS.x8),
          Flexible(
            child: RButton(
              'book_viewing_btn'.tr(),
              compact: true,
              icon: Icons.event_available_outlined,
              onPressed: () => showBookViewingSheet(context,
                  propertyTitle: _property.title),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.property, required this.price});

  final Property property;
  final double price;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('description'.tr(), style: RT.h2),
        const SizedBox(height: RS.x10),
        RCard(
          child: Text(
            property.description.isEmpty
                ? MockData.luxuryVilla.description
                : property.description,
            style: RT.body,
          ),
        ),

        const SizedBox(height: RS.x24),
        Text('property_consultant'.tr(), style: RT.h2),
        const SizedBox(height: RS.x10),
        const ConsultantCard(showBookViewing: false),

        const SizedBox(height: RS.x24),
        Text('monthly_payment'.tr(), style: RT.h2),
        const SizedBox(height: RS.x10),
        PaymentEstimator(propertyPrice: price),

        const SizedBox(height: RS.x24),
        Text('community_highlights'.tr(), style: RT.h2),
        const SizedBox(height: RS.x10),
        const HighlightsCard(),
      ],
    );
  }
}

class _FloorPlanTeaser extends StatelessWidget {
  const _FloorPlanTeaser({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final plan in MockData.floorPlans)
          Padding(
            padding: const EdgeInsets.only(bottom: RS.x12),
            child: RCard(
              onTap: () => Navigator.pushNamed(
                context,
                Routes.floorPlan,
                arguments: property,
              ),
              child: Row(
                children: [
                  const IconBubble(Icons.architecture_outlined, tint: RC.teal),
                  const SizedBox(width: RS.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.name, style: RT.title),
                        const SizedBox(height: 2),
                        Text('${plan.areaSqft} • ${plan.rooms.length} rooms',
                            style: RT.captionSm),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, matchTextDirection: true,
                      size: 20, color: RC.textTertiary),
                ],
              ),
            ),
          ),
        const SizedBox(height: RS.x8),
        RButton(
          'open_full_floor_plans'.tr(),
          kind: RButtonKind.navy,
          expanded: true,
          icon: Icons.open_in_full_rounded,
          onPressed: () => Navigator.pushNamed(
            context,
            Routes.floorPlan,
            arguments: property,
          ),
        ),
      ],
    );
  }
}
