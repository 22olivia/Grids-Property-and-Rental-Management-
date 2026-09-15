import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme/tokens.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/common.dart';

/// SCREEN 14 — SELL YOUR PROPERTY
class SellPropertyScreen extends StatefulWidget {
  const SellPropertyScreen({super.key});

  @override
  State<SellPropertyScreen> createState() => _SellPropertyScreenState();
}

class _SellPropertyScreenState extends State<SellPropertyScreen> {
  int _navIndex = 0;
  int _step = 0;

  int _listingType = 0;
  String _propertyType = 'Villa';
  String _transactionType = 'Resale';
  String _community = 'Palm Jumeirah';

  final _title = TextEditingController(
      text: 'Luxury 5-Bedroom Villa with Burj Khalifa View');
  final _price = TextEditingController(text: '8,200,000');
  final _area = TextEditingController(text: '7,280');
  final _description = TextEditingController(
    text: 'Experience elevated living in this exceptional 5-bedroom villa '
        'located on the iconic Palm Jumeirah. Designed with elegance and '
        'crafted for comfort, this residence offers panoramic views, premium '
        'finishes, and world-class amenities.',
  );

  int _bedrooms = 5;
  int _bathrooms = 6;

  static const _steps = ['Basic Info', 'Details', 'Location', 'Photos', 'Review'];
  static const _listingTypes = ['For Sale', 'For Rent', 'Featured'];
  static const _propertyTypes = [
    'Villa',
    'Apartment',
    'House',
    'Office',
    'Store',
    'Land',
  ];
  static const _transactionTypes = ['Resale', 'Off-plan', 'New'];
  static const _communities = [
    'Palm Jumeirah',
    'Dubai Marina',
    'Downtown Dubai',
    'Business Bay',
    'Emirates Hills',
    'Dubai Creek Harbour',
  ];

  static const _maxDescription = 1200;

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _area.dispose();
    _description.dispose();
    super.dispose();
  }

  void _continue() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
      return;
    }
    toast(context, 'Listing submitted for review',
        icon: Icons.check_circle_outline_rounded);
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
                GestureDetector(
                  onTap: () => toast(context, 'Draft saved',
                      icon: Icons.save_outlined),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: RS.x14, vertical: RS.x10),
                    decoration: BoxDecoration(
                      color: RC.surface,
                      borderRadius: RR.chip,
                      border: Border.all(color: RC.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.save_outlined,
                            size: 14, color: RC.navy),
                        const SizedBox(width: RS.x6),
                        Text('save_draft'.tr(),
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

            const PageTitle(
              'Sell Your Property',
              subtitle: 'List your property in 5 easy steps',
            ),

            // ---- Progress ----
            Padding(
              padding: RS.page,
              child: StepProgress(
                steps: _steps,
                currentIndex: _step,
                onStepTap: (i) => setState(() => _step = i),
              ),
            ),

            const SizedBox(height: RS.x24),

            Padding(
              padding: RS.page,
              child: switch (_step) {
                0 => _basicInfo(),
                1 => _details(),
                2 => _location(),
                3 => _photos(),
                _ => _review(),
              },
            ),

            // ---- Nav buttons ----
            Padding(
              padding: const EdgeInsets.fromLTRB(RS.x20, RS.x24, RS.x20, 0),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      child: RButton(
                        'Back',
                        kind: RButtonKind.outline,
                        expanded: true,
                        onPressed: () => setState(() => _step--),
                      ),
                    ),
                    const SizedBox(width: RS.x12),
                  ],
                  Expanded(
                    flex: 2,
                    child: RButton(
                      _step == _steps.length - 1 ? 'Submit Listing' : 'Continue',
                      expanded: true,
                      icon: _step == _steps.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      onPressed: _continue,
                    ),
                  ),
                ],
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

  // ---- Step 1 ----
  Widget _basicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('listing_type'.tr(), style: RT.h2),
        const SizedBox(height: RS.x12),
        Row(
          children: [
            for (var i = 0; i < _listingTypes.length; i++) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _listingType = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: RS.x14),
                    decoration: BoxDecoration(
                      color: _listingType == i ? RC.tealSoft : RC.surface,
                      borderRadius: RR.inner,
                      border: Border.all(
                        color: _listingType == i ? RC.teal : RC.border,
                        width: _listingType == i ? 1.6 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _listingTypes[i],
                        style: RT.captionSm.copyWith(
                          color: _listingType == i ? RC.tealDark : RC.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (i != _listingTypes.length - 1) const SizedBox(width: RS.x8),
            ],
          ],
        ),

        const SizedBox(height: RS.x24),
        _DropdownField(
          label: 'Property Type',
          value: _propertyType,
          options: _propertyTypes,
          icon: Icons.home_work_outlined,
          onChanged: (v) => setState(() => _propertyType = v),
        ),

        const SizedBox(height: RS.x16),
        _DropdownField(
          label: 'Transaction Type',
          value: _transactionType,
          options: _transactionTypes,
          icon: Icons.swap_horiz_rounded,
          onChanged: (v) => setState(() => _transactionType = v),
        ),

        const SizedBox(height: RS.x16),
        RTextField(
          label: 'Listing Title',
          hint: 'e.g. Luxury 5-Bedroom Villa',
          controller: _title,
          icon: Icons.title_rounded,
        ),

        const SizedBox(height: RS.x16),
        RTextField(
          label: 'Price (AED)',
          hint: '8,200,000',
          controller: _price,
          icon: Icons.payments_outlined,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  // ---- Step 2 ----
  Widget _details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('property_details'.tr(), style: RT.h2),
        const SizedBox(height: RS.x12),
        RCard(
          child: Column(
            children: [
              _CounterRow(
                label: 'Bedrooms',
                icon: Icons.bed_outlined,
                value: _bedrooms,
                onChanged: (v) => setState(() => _bedrooms = v),
              ),
              const ThinDivider(),
              _CounterRow(
                label: 'Bathrooms',
                icon: Icons.bathtub_outlined,
                value: _bathrooms,
                onChanged: (v) => setState(() => _bathrooms = v),
              ),
            ],
          ),
        ),

        const SizedBox(height: RS.x16),
        RTextField(
          label: 'Built-up Area (sqft)',
          hint: '7,280',
          controller: _area,
          icon: Icons.straighten_outlined,
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: RS.x16),
        Text('description'.tr(),
            style: RT.caption.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: RS.x8),
        RTextField(
          hint: 'Describe the property…',
          controller: _description,
          maxLines: 6,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: RS.x6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_description.text.length} / $_maxDescription',
            style: RT.captionSm.copyWith(
              color: _description.text.length > _maxDescription
                  ? RC.danger
                  : RC.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  // ---- Step 3 ----
  Widget _location() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('location_step'.tr(), style: RT.h2),
        const SizedBox(height: RS.x12),
        _DropdownField(
          label: 'Community',
          value: _community,
          options: _communities,
          icon: Icons.location_city_outlined,
          onChanged: (v) => setState(() => _community = v),
        ),
        const SizedBox(height: RS.x16),
        const RTextField(
          label: 'Building / Street',
          hint: 'e.g. Frond K, Villa 27',
          icon: Icons.signpost_outlined,
        ),
        const SizedBox(height: RS.x16),
        RCard(
          onTap: () => toast(context, 'Drop a pin on the map',
              icon: Icons.my_location_rounded),
          child: const Row(
            children: [
              IconBubble(Icons.map_outlined, tint: RC.info),
              SizedBox(width: RS.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('pin_exact_location'.tr(), style: RT.title),
                    SizedBox(height: 2),
                    Text('buyers_approximate'.tr(),
                        style: RT.captionSm),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, matchTextDirection: true,
                  size: 20, color: RC.textTertiary),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Step 4 ----
  Widget _photos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('photos_media'.tr(), style: RT.h2),
        const SizedBox(height: RS.x6),
        Text('photos_8_more'.tr(),
            style: RT.caption),
        const SizedBox(height: RS.x16),
        GestureDetector(
          onTap: () => showMockPhotoPicker(context),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: RC.surface,
              borderRadius: RR.card,
              border: Border.all(
                color: RC.borderStrong,
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconBubble(Icons.add_photo_alternate_outlined,
                    tint: RC.teal, size: 52),
                SizedBox(height: RS.x12),
                Text('upload_photos_label'.tr(), style: RT.title),
                SizedBox(height: RS.x4),
                Text('jpg_png_10mb'.tr(), style: RT.captionSm),
              ],
            ),
          ),
        ),
        const SizedBox(height: RS.x16),
        RCard(
          padding: const EdgeInsets.symmetric(horizontal: RS.x16),
          child: Column(
            children: [
              RowItem(
                title: 'Add video tour',
                subtitle: 'MP4 • up to 200 MB',
                leading: const IconBubble(Icons.videocam_outlined,
                    tint: RC.purple, size: 38),
                onTap: () => showMockVideoPicker(context),
              ),
              const ThinDivider(inset: 50),
              RowItem(
                title: 'Add 360° tour link',
                subtitle: 'Matterport or similar',
                leading: const IconBubble(Icons.threesixty_rounded,
                    tint: RC.info, size: 38),
                onTap: () => showMockUrlDialog(context,
                    title: 'Add 360° tour link',
                    hint: 'https://my.matterport.com/...'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Step 5 ----
  Widget _review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('review_submit'.tr(), style: RT.h2),
        const SizedBox(height: RS.x12),
        RCard(
          child: Column(
            children: [
              KeyValueRow('Listing Type', _listingTypes[_listingType]),
              const ThinDivider(),
              KeyValueRow('Property Type', _propertyType),
              const ThinDivider(),
              KeyValueRow('Transaction', _transactionType),
              const ThinDivider(),
              KeyValueRow('Price', 'AED ${_price.text}'),
              const ThinDivider(),
              KeyValueRow('Bedrooms', '$_bedrooms'),
              const ThinDivider(),
              KeyValueRow('Bathrooms', '$_bathrooms'),
              const ThinDivider(),
              KeyValueRow('Built-up Area', '${_area.text} sqft'),
              const ThinDivider(),
              KeyValueRow('Community', _community),
            ],
          ),
        ),
        const SizedBox(height: RS.x16),
        RCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title.text, style: RT.title),
              const SizedBox(height: RS.x8),
              Text(_description.text, style: RT.body),
            ],
          ),
        ),
        const SizedBox(height: RS.x16),
        const InfoBanner(
          title: 'Listings are reviewed within 24 hours',
          body: 'Our team verifies ownership documents before publishing.',
          icon: Icons.verified_outlined,
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.icon,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: RT.caption.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: RS.x8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: RS.x16),
          decoration: BoxDecoration(
            color: RC.surface,
            borderRadius: RR.inner,
            border: Border.all(color: RC.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: RC.textTertiary),
              const SizedBox(width: RS.x12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: RC.textTertiary),
                    style: RT.bodyStrong,
                    borderRadius: RR.inner,
                    padding: const EdgeInsets.symmetric(vertical: RS.x8),
                    items: [
                      for (final o in options)
                        DropdownMenuItem(value: o, child: Text(o)),
                    ],
                    onChanged: (v) {
                      if (v != null) onChanged(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RS.x6),
      child: Row(
        children: [
          IconBubble(icon, tint: RC.teal, size: 36),
          const SizedBox(width: RS.x12),
          Expanded(child: Text(label, style: RT.title)),
          IconButton(
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
            color: RC.navy,
          ),
          SizedBox(
            width: 28,
            child: Text('$value',
                textAlign: TextAlign.center, style: RT.bodyStrong),
          ),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
            color: RC.teal,
          ),
        ],
      ),
    );
  }
}
