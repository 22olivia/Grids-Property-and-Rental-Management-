import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../core/app_state.dart';
import '../core/theme/tokens.dart';
import '../data/models/models.dart';
import 'common.dart';
import 'resivyn_image.dart';

/// Full-width listing card used on Search, Saved and Home.
class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.showAgency = true,
  });

  final Property property;
  final VoidCallback? onTap;
  final bool showAgency;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final saved = state.isSaved(property.id);
    final forSale = property.listingType == ListingType.forSale;

    return RCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ResivynImage(
                url: property.imageUrl,
                height: 186,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(21),
                ),
              ),
              Positioned(
                top: RS.x12,
                left: RS.x12,
                child: Row(
                  children: [
                    RBadge(
                      property.listingType.label,
                      color: forSale ? RC.teal : RC.info,
                      solid: true,
                      uppercase: true,
                    ),
                    if (property.featured) ...[
                      const SizedBox(width: RS.x6),
                      RBadge('featured_badge'.tr(),
                          color: RC.warning, solid: true, uppercase: true),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: RS.x8,
                right: RS.x8,
                child: RIconButton(
                  icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  tint: saved ? RC.danger : RC.navy,
                  floating: true,
                  tooltip: saved ? 'Remove from saved' : 'Save property',
                  onTap: () {
                    final nowSaved = state.toggleSaved(property.id);
                    toast(
                      context,
                      nowSaved
                          ? '${property.title} saved'
                          : '${property.title} removed from saved',
                      icon: nowSaved
                          ? Icons.favorite_rounded
                          : Icons.heart_broken_outlined,
                    );
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(RS.x16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property.priceLabel, style: RT.h1),
                const SizedBox(height: RS.x6),
                Text(property.title, style: RT.title),
                const SizedBox(height: RS.x4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: RC.textTertiary),
                    const SizedBox(width: RS.x4),
                    Expanded(
                      child: Text(
                        property.location,
                        style: RT.captionSm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: RS.x12),
                PropertySpecRow(property: property),
                if (property.features.isNotEmpty) ...[
                  const SizedBox(height: RS.x12),
                  Wrap(
                    spacing: RS.x6,
                    runSpacing: RS.x6,
                    children: [
                      for (final f in property.features)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: RS.x10, vertical: 5),
                          decoration: BoxDecoration(
                            color: RC.bg,
                            borderRadius: RR.chip,
                            border: Border.all(color: RC.border),
                          ),
                          child: Text(f, style: RT.captionSm),
                        ),
                    ],
                  ),
                ],
                if (showAgency && property.agency != null) ...[
                  const SizedBox(height: RS.x12),
                  const ThinDivider(),
                  const SizedBox(height: RS.x10),
                  Row(
                    children: [
                      const IconBubble(Icons.verified_outlined,
                          tint: RC.teal, size: 26),
                      const SizedBox(width: RS.x8),
                      Expanded(
                        child: Text(
                          property.agency!,
                          style: RT.captionSm.copyWith(
                            color: RC.navy,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('View details',
                          style: RT.captionSm.copyWith(
                            color: RC.teal,
                            fontWeight: FontWeight.w700,
                          )),
                      const Icon(Icons.chevron_right_rounded,
                          size: 16, color: RC.teal),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bed / bath / area / type row, adapting to properties without bedrooms.
class PropertySpecRow extends StatelessWidget {
  const PropertySpecRow({super.key, required this.property, this.compact = true});

  final Property property;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final specs = <(IconData, String)>[
      if (property.bedrooms != null)
        (Icons.bed_outlined, '${property.bedrooms} bedrooms'),
      if (property.bathrooms != null)
        (Icons.bathtub_outlined, '${property.bathrooms} bathrooms'),
      (Icons.straighten_outlined, property.areaSqft),
    ];

    return Row(
      children: [
        for (final (icon, label) in specs)
          Expanded(
            child: Row(
              children: [
                Icon(icon, size: 14, color: RC.teal),
                const SizedBox(width: RS.x4),
                Expanded(
                  child: Text(
                    label,
                    style: RT.captionSm.copyWith(color: RC.navy),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Compact horizontal card for "Featured Properties" carousels.
class PropertyMiniCard extends StatelessWidget {
  const PropertyMiniCard({super.key, required this.property, this.onTap});

  final Property property;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 232,
      child: RCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ResivynImage(
                  url: property.imageUrl,
                  height: 124,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(21)),
                ),
                Positioned(
                  top: RS.x8,
                  left: RS.x8,
                  child: RBadge(
                    property.listingType.label,
                    color: property.listingType == ListingType.forSale
                        ? RC.teal
                        : RC.info,
                    solid: true,
                    uppercase: true,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(RS.x12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.priceLabel,
                    style: RT.h2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: RS.x4),
                  Text(
                    property.title,
                    style: RT.caption.copyWith(
                      color: RC.navy,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    property.location,
                    style: RT.captionSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: RS.x8),
                  Row(
                    children: [
                      if (property.bedrooms != null) ...[
                        const Icon(Icons.bed_outlined, size: 13, color: RC.teal),
                        const SizedBox(width: 3),
                        Text('${property.bedrooms}', style: RT.captionSm),
                        const SizedBox(width: RS.x10),
                      ],
                      if (property.bathrooms != null) ...[
                        const Icon(Icons.bathtub_outlined,
                            size: 13, color: RC.teal),
                        const SizedBox(width: 3),
                        Text('${property.bathrooms}', style: RT.captionSm),
                        const SizedBox(width: RS.x10),
                      ],
                      const Icon(Icons.straighten_outlined,
                          size: 13, color: RC.teal),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          property.areaSqft,
                          style: RT.captionSm,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
