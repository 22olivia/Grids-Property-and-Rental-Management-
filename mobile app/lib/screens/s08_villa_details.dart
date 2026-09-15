import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/theme/tokens.dart';
import '../data/mock/mock_data.dart';
import '../data/models/models.dart';
import '../widgets/common.dart';
import '../widgets/detail_parts.dart';

/// SCREEN 08 — LUXURY VILLA PROPERTY DETAILS
///
/// The sales-oriented variant: evening hero, consultant front and centre,
/// affordability teaser rather than a full calculator.
class VillaDetailsScreen extends StatefulWidget {
  const VillaDetailsScreen({super.key});

  @override
  State<VillaDetailsScreen> createState() => _VillaDetailsScreenState();
}

class _VillaDetailsScreenState extends State<VillaDetailsScreen> {
  int _tab = 0;

  static final _tabs = [
    'overview'.tr(),
    'amenities_tab'.tr(),
    'floor_plan'.tr(),
    'nearby'.tr(),
  ];

  static const _villa = Property(
    id: 'RV-9842',
    title: 'Luxury Villa',
    community: 'Palm Jumeirah',
    city: 'Dubai',
    priceLabel: 'AED 8,200,000',
    listingType: ListingType.forSale,
    category: 'Villa',
    imageUrl: Img.villaDusk,
    bedrooms: 5,
    bathrooms: 6,
    areaSqft: '7,280 sqft',
    featured: true,
    description: MockData.villaDescription,
    gallery: [
      GalleryItem(label: 'Evening Exterior', url: Img.villaDusk),
      GalleryItem(label: 'Infinity Pool', url: Img.pool),
      GalleryItem(label: 'Living Room', url: Img.livingRoom),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final saved = state.isSaved(_villa.id);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const PropertyHero(property: _villa, height: 300, showCounter: false),

          const SizedBox(height: RS.x20),
          const PropertyTitleBlock(property: _villa),

          // Built-up area gets its own emphasis on the sales variant.
          Padding(
            padding: const EdgeInsets.fromLTRB(RS.x20, RS.x16, RS.x20, 0),
            child: RCard(
              padding: const EdgeInsets.all(RS.x16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          icon: Icons.bed_outlined,
                          value: '5',
                          label: 'bedrooms_label'.tr(),
                        ),
                      ),
                      Container(width: 1, height: 36, color: RC.border),
                      Expanded(
                        child: _MiniStat(
                          icon: Icons.bathtub_outlined,
                          value: '6',
                          label: 'bathrooms_label'.tr(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: RS.x14),
                  const ThinDivider(),
                  const SizedBox(height: RS.x14),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          icon: Icons.straighten_outlined,
                          value: '7,280 sqft',
                          label: 'built_up_area'.tr(),
                        ),
                      ),
                      Container(width: 1, height: 36, color: RC.border),
                      Expanded(
                        child: _MiniStat(
                          icon: Icons.home_work_outlined,
                          value: 'Villa',
                          label: 'property_type'.tr(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: RS.x20),
          RUnderlineTabs(
            items: _tabs,
            selectedIndex: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),

          const SizedBox(height: RS.x20),
          Padding(
            padding: RS.page,
            child: switch (_tab) {
              0 => const _VillaOverview(),
              1 => const AmenitiesGrid(),
              2 => const _FloorPlanSummary(),
              _ => const NearbyList(),
            },
          ),

          const BottomGutter(extra: RS.x20),
        ],
      ),

      bottomNavigationBar: StickyActionBar(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('AED 8,200,000', style: RT.h2),
                Text('Palm Jumeirah, Dubai', style: RT.captionSm),
              ],
            ),
          ),
          const SizedBox(width: RS.x12),
          Flexible(
            child: RButton(
              saved ? 'saved_to_list'.tr() : 'save'.tr(),
              kind: RButtonKind.outline,
              icon:
                  saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              compact: true,
              onPressed: () {
                final nowSaved = state.toggleSaved(_villa.id);
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
                  propertyTitle: 'Luxury Villa'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconBubble(icon, tint: RC.teal, size: 34),
        const SizedBox(width: RS.x8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: RT.title.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(label,
                  style: RT.captionSm.copyWith(fontSize: 9.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _VillaOverview extends StatelessWidget {
  const _VillaOverview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RCard(
          child: Text(MockData.luxuryVilla.description, style: RT.body),
        ),

        const SizedBox(height: RS.x24),
        Text('property_consultant'.tr(), style: RT.h2),
        const SizedBox(height: RS.x10),
        const ConsultantCard(),

        const SizedBox(height: RS.x24),
        Text('affordability'.tr(), style: RT.h2),
        const SizedBox(height: RS.x10),
        const PaymentEstimator(propertyPrice: 8200000, showResult: false),

        const SizedBox(height: RS.x24),
        Text('community_highlights'.tr(), style: RT.h2),
        const SizedBox(height: RS.x10),
        const HighlightsCard(),
      ],
    );
  }
}

class _FloorPlanSummary extends StatelessWidget {
  const _FloorPlanSummary();

  @override
  Widget build(BuildContext context) {
    return RCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('area_summary'.tr(), style: RT.h2),
          const SizedBox(height: RS.x8),
          for (final entry in MockData.areaSummary.entries)
            KeyValueRow(entry.key, entry.value),
          const SizedBox(height: RS.x12),
          const ThinDivider(),
          const SizedBox(height: RS.x12),
          for (final plan in MockData.floorPlans)
            Padding(
              padding: const EdgeInsets.only(bottom: RS.x10),
              child: Row(
                children: [
                  const Icon(Icons.architecture_outlined,
                      size: 16, color: RC.teal),
                  const SizedBox(width: RS.x8),
                  Expanded(child: Text(plan.name, style: RT.bodyStrong)),
                  Text(plan.areaSqft, style: RT.captionSm),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
