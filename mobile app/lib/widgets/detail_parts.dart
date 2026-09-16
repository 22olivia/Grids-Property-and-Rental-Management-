import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_state.dart';
import '../core/routes.dart';
import '../core/theme/tokens.dart';
import '../data/mock/mock_data.dart';
import '../data/models/models.dart';
import 'common.dart';
import 'resivyn_image.dart';

/// Hero imagery with floating controls, badges, counter and carousel dots.
/// Shared by the property detail screens (01, 08, 12).
class PropertyHero extends StatefulWidget {
  const PropertyHero({
    super.key,
    required this.property,
    this.height = 320,
    this.showCounter = true,
    this.showGalleryButton = false,
  });

  final Property property;
  final double height;
  final bool showCounter;
  final bool showGalleryButton;

  @override
  State<PropertyHero> createState() => _PropertyHeroState();
}

class _PropertyHeroState extends State<PropertyHero> {
  final _pageController = PageController();
  int _page = 0;

  List<String> get _images {
    final urls = widget.property.gallery.map((g) => g.url).toList();
    return urls.isEmpty ? [widget.property.imageUrl] : urls;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final saved = state.isSaved(widget.property.id);
    final topInset = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => ResivynImage(url: _images[i]),
          ),

          // Scrim so the white controls stay legible on any photo.
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    RC.navy.withOpacity(0.28),
                    Colors.transparent,
                    RC.navy.withOpacity(0.45),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          ),

          // Floating controls.
          Positioned(
            top: topInset + RS.x8,
            left: RS.x20,
            right: RS.x20,
            child: Row(
              children: [
                RIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  floating: true,
                  tooltip: 'back'.tr(),
                  onTap: () => Navigator.maybePop(context),
                ),
                const Spacer(),
                RIconButton(
                  icon: Icons.ios_share_rounded,
                  floating: true,
                  tooltip: 'share_action'.tr(),
                  onTap: () => toast(context, 'Share link copied to clipboard',
                      icon: Icons.link_rounded),
                ),
                const SizedBox(width: RS.x8),
                RIconButton(
                  icon: saved
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  tint: saved ? RC.danger : RC.navy,
                  floating: true,
                  tooltip: saved ? 'Remove from saved' : 'Save property',
                  onTap: () {
                    final nowSaved = state.toggleSaved(widget.property.id);
                    toast(
                      context,
                      nowSaved ? 'Saved to your list' : 'Removed from saved',
                      icon: nowSaved
                          ? Icons.favorite_rounded
                          : Icons.heart_broken_outlined,
                    );
                  },
                ),
              ],
            ),
          ),

          // Counter + gallery button.
          Positioned(
            bottom: RS.x20,
            left: RS.x20,
            right: RS.x20,
            child: Row(
              children: [
                if (widget.showCounter)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: RS.x12, vertical: RS.x6),
                    decoration: BoxDecoration(
                      color: RC.navy.withOpacity(0.65),
                      borderRadius: RR.chip,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library_outlined,
                            size: 13, color: Colors.white),
                        const SizedBox(width: RS.x6),
                        Text(
                          '${_page + 1} / ${widget.property.photoCount}',
                          style: RT.captionSm.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                if (widget.showGalleryButton)
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      Routes.gallery,
                      arguments: widget.property,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: RS.x14, vertical: RS.x10),
                      decoration: const BoxDecoration(
                        color: RC.surface,
                        borderRadius: RR.chip,
                        boxShadow: RShadow.soft,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.grid_view_rounded,
                              size: 14, color: RC.navy),
                          const SizedBox(width: RS.x6),
                          Text('View Gallery',
                              style: RT.captionSm.copyWith(
                                color: RC.navy,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Carousel indicators.
          Positioned(
            bottom: RS.x8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// FOR SALE / FEATURED badges + price + title + location block.
class PropertyTitleBlock extends StatelessWidget {
  const PropertyTitleBlock({super.key, required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: RS.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RBadge(
                property.listingType.label,
                color: property.listingType == ListingType.forSale
                    ? RC.teal
                    : RC.info,
                solid: true,
                uppercase: true,
              ),
              if (property.featured) ...[
                const SizedBox(width: RS.x6),
                RBadge('featured_badge'.tr(),
                    color: RC.warning, solid: true, uppercase: true),
              ],
              const Spacer(),
              Flexible(
                child: Text('ID: ${property.id}',
                    style: RT.captionSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: RS.x12),
          Text(property.priceLabel, style: RT.price),
          const SizedBox(height: RS.x6),
          Text(property.title, style: RT.h1),
          const SizedBox(height: RS.x6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 15, color: RC.teal),
              const SizedBox(width: RS.x4),
              Expanded(
                child: Text(property.location, style: RT.caption),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The four-up statistics card (bedrooms / bathrooms / area / type).
class PropertyStatsCard extends StatelessWidget {
  const PropertyStatsCard({super.key, required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final stats = <(IconData, String, String)>[
      if (property.bedrooms != null)
        (Icons.bed_outlined, '${property.bedrooms}', 'Bedrooms'),
      if (property.bathrooms != null)
        (Icons.bathtub_outlined, '${property.bathrooms}', 'Bathrooms'),
      (Icons.straighten_outlined, property.areaSqft.split(' ').first, 'Sqft'),
      (Icons.home_work_outlined, property.category, 'Type'),
    ];

    return RCard(
      padding: const EdgeInsets.symmetric(vertical: RS.x16, horizontal: RS.x8),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Icon(stats[i].$1, size: 19, color: RC.teal),
                  const SizedBox(height: RS.x8),
                  Text(
                    stats[i].$2,
                    style: RT.title.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stats[i].$3,
                    style: RT.captionSm.copyWith(fontSize: 9.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (i != stats.length - 1)
              Container(width: 1, height: 34, color: RC.border),
          ],
        ],
      ),
    );
  }
}

/// Property consultant card with call / WhatsApp / book actions.
class ConsultantCard extends StatelessWidget {
  const ConsultantCard({super.key, this.showBookViewing = true});

  final bool showBookViewing;

  @override
  Widget build(BuildContext context) {
    return RCard(
      child: Column(
        children: [
          Row(
            children: [
              const ResivynAvatar(
                url: Img.avatarMichael,
                name: 'Michael Anderson',
                size: 52,
                ring: true,
              ),
              const SizedBox(width: RS.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Flexible(
                          child: Text('Michael Anderson',
                              style: RT.title, maxLines: 1),
                        ),
                        SizedBox(width: RS.x4),
                        Icon(Icons.verified_rounded,
                            size: 14, color: RC.teal),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text('Senior Property Consultant',
                        style: RT.captionSm, maxLines: 1),
                    const SizedBox(height: RS.x6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: RC.warning),
                        const SizedBox(width: RS.x4),
                        Text('4.9',
                            style: RT.captionSm.copyWith(
                              color: RC.navy,
                              fontWeight: FontWeight.w700,
                            )),
                        const SizedBox(width: RS.x4),
                        const Text('(128 reviews)', style: RT.captionSm),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: RS.x16),
          Row(
            children: [
              Expanded(
                child: RButton(
                  'Call',
                  kind: RButtonKind.outline,
                  icon: Icons.phone_outlined,
                  compact: true,
                  expanded: true,
                  onPressed: () async {
                    final uri = Uri.parse('tel:+971501234567');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      toast(context, 'Could not initiate call',
                          icon: Icons.error_outline_rounded);
                    }
                  },
                ),
              ),
              const SizedBox(width: RS.x8),
              Expanded(
                child: RButton(
                  'WhatsApp',
                  kind: RButtonKind.soft,
                  icon: Icons.chat_bubble_outline_rounded,
                  compact: true,
                  expanded: true,
                  onPressed: () async {
                    final uri = Uri.parse('https://wa.me/971501234567');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      toast(context, 'Could not open WhatsApp',
                          icon: Icons.error_outline_rounded);
                    }
                  },
                ),
              ),
              if (showBookViewing) ...[
                const SizedBox(width: RS.x8),
                Expanded(
                  child: RButton(
                    'Book',
                    icon: Icons.event_outlined,
                    compact: true,
                    expanded: true,
                    onPressed: () => showBookViewingSheet(context),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Monthly payment estimator with a live slider.
class PaymentEstimator extends StatefulWidget {
  const PaymentEstimator({
    super.key,
    required this.propertyPrice,
    this.showResult = true,
  });

  final double propertyPrice;
  final bool showResult;

  @override
  State<PaymentEstimator> createState() => _PaymentEstimatorState();
}

class _PaymentEstimatorState extends State<PaymentEstimator> {
  double _downPaymentPct = 20;
  double _years = 25;
  bool _calculated = false;

  /// Standard amortising payment at an indicative 4.5% annual rate.
  double get _monthly {
    final principal = widget.propertyPrice * (1 - _downPaymentPct / 100);
    const monthlyRate = 0.045 / 12;
    final n = _years * 12;
    final factor = 1 - 1 / _pow(1 + monthlyRate, n);
    if (factor <= 0) return 0;
    return principal * monthlyRate / factor;
  }

  double _pow(double base, double exp) {
    var result = 1.0;
    for (var i = 0; i < exp.round(); i++) {
      result *= base;
    }
    return result;
  }

  String get _formatted {
    final v = _monthly.round();
    final s = v.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return 'AED ${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final showValue = widget.showResult || _calculated;

    return RCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(Icons.calculate_outlined, tint: RC.info),
              const SizedBox(width: RS.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimate your monthly payment', style: RT.title),
                    SizedBox(height: 2),
                    Text('Get a quick affordability estimate',
                        style: RT.captionSm),
                  ],
                ),
              ),
            ],
          ),
          if (showValue) ...[
            const SizedBox(height: RS.x16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(RS.x16),
              decoration: const BoxDecoration(
                color: RC.tealSoft,
                borderRadius: RR.inner,
              ),
              child: Column(
                children: [
                  Text('$_formatted / month',
                      style: RT.h1.copyWith(color: RC.tealDark)),
                  const SizedBox(height: RS.x4),
                  Text(
                    '${_downPaymentPct.round()}% down • ${_years.round()} years • 4.5% p.a.',
                    style: RT.captionSm,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: RS.x12),
          Row(
            children: [
              Expanded(
                child: Text('Down payment: ${_downPaymentPct.round()}%',
                    style: RT.captionSm),
              ),
            ],
          ),
          Slider(
            value: _downPaymentPct,
            min: 10,
            max: 60,
            divisions: 10,
            activeColor: RC.teal,
            inactiveColor: RC.border,
            onChanged: (v) => setState(() => _downPaymentPct = v),
          ),
          Text('Term: ${_years.round()} years', style: RT.captionSm),
          Slider(
            value: _years,
            min: 5,
            max: 30,
            divisions: 5,
            activeColor: RC.teal,
            inactiveColor: RC.border,
            onChanged: (v) => setState(() => _years = v),
          ),
          const SizedBox(height: RS.x8),
          RButton(
            'Calculate',
            kind: RButtonKind.navy,
            expanded: true,
            icon: Icons.calculate_outlined,
            onPressed: () {
              setState(() => _calculated = true);
              toast(context, 'Estimated at $_formatted per month',
                  icon: Icons.calculate_outlined);
            },
          ),
        ],
      ),
    );
  }
}

/// Community highlights checklist.
class HighlightsCard extends StatelessWidget {
  const HighlightsCard({super.key, this.items = MockData.communityHighlights});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return RCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: RC.tealSoft,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Center(
                    child: Icon(Icons.check_rounded, size: 14, color: RC.teal),
                  ),
                ),
                const SizedBox(width: RS.x12),
                Expanded(child: Text(items[i], style: RT.bodyStrong)),
              ],
            ),
            if (i != items.length - 1) const SizedBox(height: RS.x14),
          ],
        ],
      ),
    );
  }
}

/// Amenities grid used on the Amenities tab.
class AmenitiesGrid extends StatelessWidget {
  const AmenitiesGrid({super.key});

  static const _amenities = <(String, IconData)>[
    ('Private Pool', Icons.pool_outlined),
    ('Beach Access', Icons.beach_access_outlined),
    ('Smart Home', Icons.sensors_outlined),
    ('Gym & Spa', Icons.fitness_center_outlined),
    ('Covered Parking', Icons.local_parking_outlined),
    ('24/7 Security', Icons.security_outlined),
    ('Landscaped Garden', Icons.park_outlined),
    ('Wine Cellar', Icons.wine_bar_outlined),
    ('Maid\'s Room', Icons.cleaning_services_outlined),
    ('Concierge', Icons.room_service_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return RCard(
      child: Wrap(
        spacing: RS.x8,
        runSpacing: RS.x12,
        children: [
          for (final (label, icon) in _amenities)
            SizedBox(
              width: (MediaQuery.of(context).size.width - RS.x40 - RS.x32 - RS.x8) / 2,
              child: Row(
                children: [
                  IconBubble(icon, tint: RC.teal, size: 32),
                  const SizedBox(width: RS.x8),
                  Expanded(
                    child: Text(
                      label,
                      style: RT.captionSm.copyWith(
                        color: RC.navy,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Nearby places list used on the Nearby tab.
class NearbyList extends StatelessWidget {
  const NearbyList({super.key});

  static const _places = <(String, String, String, IconData)>[
    ('Nakheel Mall', 'Shopping', '4 min drive', Icons.shopping_bag_outlined),
    ('GEMS Wellington Academy', 'School', '9 min drive', Icons.school_outlined),
    ('Emirates Hospital Jumeirah', 'Healthcare', '12 min drive',
        Icons.local_hospital_outlined),
    ('Palm West Beach', 'Leisure', '6 min walk', Icons.beach_access_outlined),
    ('Dubai Marina Metro', 'Transport', '14 min drive', Icons.train_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return RCard(
      padding: const EdgeInsets.symmetric(horizontal: RS.x16),
      child: Column(
        children: [
          for (var i = 0; i < _places.length; i++) ...[
            RowItem(
              title: _places[i].$1,
              subtitle: _places[i].$2,
              leading: IconBubble(_places[i].$4, tint: RC.info, size: 38),
              trailing: Text(
                _places[i].$3,
                style: RT.captionSm.copyWith(
                  color: RC.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => toast(context, 'Opening ${_places[i].$1} on the map',
                  icon: Icons.place_outlined),
            ),
            if (i != _places.length - 1) const ThinDivider(inset: 50),
          ],
        ],
      ),
    );
  }
}

/// Sticky bottom action bar used on detail screens.
class StickyActionBar extends StatelessWidget {
  const StickyActionBar({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(RS.x20, RS.x12, RS.x20, RS.x12),
  });

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: RC.surface,
        border: Border(top: BorderSide(color: RC.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x140B2348),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: padding, child: Row(children: children)),
      ),
    );
  }
}
