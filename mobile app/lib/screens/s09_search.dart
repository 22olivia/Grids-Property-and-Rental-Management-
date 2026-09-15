import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/service_locator.dart';
import '../core/theme/tokens.dart';
import '../data/mock/mock_data.dart';
import '../data/models/models.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/common.dart';
import '../widgets/property_card.dart';
import '../widgets/resivyn_image.dart';

/// SCREEN 09 — SEARCH PROPERTIES
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.embedded = false});

  /// When embedded in the tab shell there is no back button.
  final bool embedded;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  int _tab = 0; // Buy / Rent / Sell
  int _category = 0;
  bool _mapView = false;
  String _sort = 'Newest';
  int _totalCount = 1248;
  List<Property>? _results;

  static const _tabs = ['Buy', 'Rent', 'Sell'];
  static const _sorts = [
    'Newest',
    'Price: Low to High',
    'Price: High to Low',
    'Largest Area',
  ];

  @override
  void initState() {
    super.initState();
    _load();
    Services.properties.totalCount().then((value) {
      if (mounted) setState(() => _totalCount = value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Services.properties.search(
      query: _controller.text,
      category: MockData.propertyCategories[_category],
      tabIndex: _tab,
      sort: _sort,
    );
    if (mounted) setState(() => _results = results);
  }

  void _openSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(RS.x20),
              child: Text('sort_results'.tr(), style: RT.h2),
            ),
            for (final option in _sorts)
              ListTile(
                leading: Icon(
                  _sort == option
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: _sort == option ? RC.teal : RC.textTertiary,
                  size: 20,
                ),
                title: Text(option, style: RT.title),
                onTap: () {
                  setState(() => _sort = option);
                  Navigator.pop(sheetContext);
                  _load();
                  toast(context, 'Sorted by $option', icon: Icons.swap_vert_rounded);
                },
              ),
            const SizedBox(height: RS.x20),
          ],
        ),
      ),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _FilterSheet(
        onApply: () {
          Navigator.pop(sheetContext);
          _load();
          toast(context, 'Filters applied', icon: Icons.filter_alt_outlined);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      padding: EdgeInsets.zero,
      children: [
        ResivynHeader(
          showBack: !widget.embedded,
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
              ),
            ),
          ],
        ),

        PageTitle(
          'search_properties'.tr(),
          subtitle: 'find_perfect_space'.tr(),
        ),

        // ---- Search + filters ----
        Padding(
          padding: RS.page,
          child: Row(
            children: [
              Expanded(
                child: RTextField(
                  hint: 'search_hint'.tr(),
                  controller: _controller,
                  icon: Icons.search_rounded,
                  onChanged: (_) => _load(),
                ),
              ),
              const SizedBox(width: RS.x10),
              GestureDetector(
                onTap: _openFilterSheet,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: RC.navy,
                    borderRadius: RR.button,
                    boxShadow: RShadow.soft,
                  ),
                  child: const Center(
                    child: Icon(Icons.filter_alt_outlined,
                        size: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: RS.x16),
        Padding(
          padding: RS.page,
          child: RSegmented(
            items: _tabs,
            selectedIndex: _tab,
            onChanged: (i) {
              setState(() => _tab = i);
              _load();
            },
          ),
        ),

        // ---- Sort + view toggle ----
        Padding(
          padding: const EdgeInsets.fromLTRB(RS.x20, RS.x16, RS.x20, 0),
          child: Row(
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: _openSortSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: RS.x12, vertical: RS.x10),
                    decoration: BoxDecoration(
                      color: RC.surface,
                      borderRadius: RR.chip,
                      border: Border.all(color: RC.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swap_vert_rounded,
                            size: 15, color: RC.navy),
                        const SizedBox(width: RS.x6),
                        Flexible(
                          child: Text(
                            'Sort: $_sort',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: RT.captionSm.copyWith(
                              color: RC.navy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: RS.x8),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: RC.surface,
                  borderRadius: RR.chip,
                  border: Border.all(color: RC.border),
                ),
                child: Row(
                  children: [
                    _ViewToggle(
                      label: 'map'.tr(),
                      icon: Icons.map_outlined,
                      active: _mapView,
                      onTap: () => setState(() => _mapView = true),
                    ),
                    _ViewToggle(
                      label: 'list'.tr(),
                      icon: Icons.view_agenda_outlined,
                      active: !_mapView,
                      onTap: () => setState(() => _mapView = false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: RS.x16),
        RPillBar(
          items: MockData.propertyCategories,
          selectedIndex: _category,
          onChanged: (i) {
            setState(() => _category = i);
            _load();
          },
        ),

        // ---- Result count ----
        Padding(
          padding: const EdgeInsets.fromLTRB(RS.x20, RS.x20, RS.x20, RS.x12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'properties_found'.tr(namedArgs: {
                    'count': _formatCount(_totalCount).toString(),
                  }),
                  style: RT.title,
                ),
              ),
              GestureDetector(
                onTap: () => toast(context, 'Search saved — we will alert you',
                    icon: Icons.bookmark_added_outlined),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_add_outlined,
                        size: 15, color: RC.teal),
                    const SizedBox(width: RS.x4),
                    Text('save_search'.tr(),
                        style: RT.captionSm.copyWith(
                          color: RC.teal,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (_mapView)
          Padding(
            padding: RS.page,
            child: _MapPlaceholder(count: _results?.length ?? 0),
          ),

        // ---- Results ----
        if (_results == null)
          const Padding(
            padding: EdgeInsets.all(RS.x40),
            child: Center(
              child: CircularProgressIndicator(color: RC.teal, strokeWidth: 2.5),
            ),
          )
        else if (_results!.isEmpty)
          Padding(
            padding: const EdgeInsets.all(RS.x20),
            child: RCard(
              padding: const EdgeInsets.all(RS.x32),
              child: Column(
                children: [
                  const IconBubble(Icons.search_off_rounded,
                      tint: RC.textTertiary, size: 52),
                  const SizedBox(height: RS.x16),
                  Text('no_matching_properties'.tr(), style: RT.h2),
                  const SizedBox(height: RS.x6),
                  Text(
                    'try_widening'.tr(),
                    textAlign: TextAlign.center,
                    style: RT.caption,
                  ),
                  const SizedBox(height: RS.x20),
                  RButton(
                    'clear_filters'.tr(),
                    kind: RButtonKind.outline,
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _category = 0;
                        _tab = 0;
                      });
                      _load();
                    },
                  ),
                ],
              ),
            ),
          )
        else
          for (final property in _results!)
            Padding(
              padding: const EdgeInsets.fromLTRB(RS.x20, 0, RS.x20, RS.x16),
              child: PropertyCard(
                property: property,
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.propertyDetails,
                  arguments: property,
                ),
              ),
            ),

        // ---- Smart search banner ----
        Padding(
          padding: const EdgeInsets.fromLTRB(RS.x20, RS.x8, RS.x20, 0),
          child: InfoBanner(
            title: 'save_time_smart'.tr(),
            body: 'get_notified'.tr(),
            icon: Icons.auto_awesome_rounded,
            dark: true,
            ctaLabel: 'create_alert'.tr(),
            onCta: () => toast(context, 'smart_search_created'.tr(),
                icon: Icons.notifications_active_outlined),
          ),
        ),

        const BottomGutter(),
      ],
    );

    // Embedded in the tab shell the Scaffold and bottom nav belong to the
    // shell; pushed as its own route it owns them.
    if (widget.embedded) return body;

    return Scaffold(
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: ResivynBottomNav(
        currentIndex: 1,
        onTap: (i) => Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.shell,
          (route) => route.settings.name == Routes.login,
          arguments: i,
        ),
      ),
    );
  }

  String _formatCount(int value) {
    final s = value.toString();
    if (s.length <= 3) return s;
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: RS.x12, vertical: RS.x8),
        decoration: BoxDecoration(
          color: active ? RC.navy : Colors.transparent,
          borderRadius: RR.chip,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14, color: active ? Colors.white : RC.textSecondary),
            const SizedBox(width: RS.x4),
            Text(
              label,
              style: RT.captionSm.copyWith(
                color: active ? Colors.white : RC.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Static map surface. A real map SDK slots in behind the same box.
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: RS.x16),
      decoration: BoxDecoration(
        borderRadius: RR.card,
        border: Border.all(color: RC.border),
        boxShadow: RShadow.card,
      ),
      child: ClipRRect(
        borderRadius: RR.card,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ResivynImage(url: Img.dubaiWaterfront, icon: Icons.map_outlined),
            DecoratedBox(
              decoration: BoxDecoration(color: RC.navy.withOpacity(0.55)),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.place_rounded, color: Colors.white, size: 34),
                  const SizedBox(height: RS.x8),
                  Text(
                    '$count properties in view',
                    style: RT.bodyStrong.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: RS.x4),
                  Text(
                    'map_view_dubai'.tr(),
                    style: RT.captionSm.copyWith(color: Colors.white70),
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

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.onApply});
  final VoidCallback onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  RangeValues _price = const RangeValues(1, 12);
  int _beds = 4;
  int _baths = 5;
  final Set<String> _amenities = {'Private Pool'};

  static const _allAmenities = [
    'Private Pool',
    'Beach Access',
    'Gym',
    'Maid\'s Room',
    'Furnished',
    'Balcony',
    'Parking',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(RS.x20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: RC.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: RS.x20),
              Text('filters'.tr(), style: RT.h1),
              const SizedBox(height: RS.x24),
              Text('price_range'.tr(),
                  style: RT.caption.copyWith(fontWeight: FontWeight.w700)),
              RangeSlider(
                values: _price,
                min: 0,
                max: 20,
                divisions: 40,
                activeColor: RC.teal,
                inactiveColor: RC.border,
                labels: RangeLabels(
                  '${_price.start.toStringAsFixed(1)}M',
                  '${_price.end.toStringAsFixed(1)}M',
                ),
                onChanged: (v) => setState(() => _price = v),
              ),
              const SizedBox(height: RS.x8),
              _StepperRow(
                label: 'bedrooms'.tr(),
                value: _beds,
                onChanged: (v) => setState(() => _beds = v),
              ),
              const ThinDivider(),
              _StepperRow(
                label: 'bathrooms'.tr(),
                value: _baths,
                onChanged: (v) => setState(() => _baths = v),
              ),
              const SizedBox(height: RS.x20),
              Text('amenities'.tr(),
                  style: RT.caption.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: RS.x12),
              Wrap(
                spacing: RS.x8,
                runSpacing: RS.x8,
                children: [
                  for (final a in _allAmenities)
                    GestureDetector(
                      onTap: () => setState(() {
                        if (_amenities.contains(a)) {
                          _amenities.remove(a);
                        } else {
                          _amenities.add(a);
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: RS.x14, vertical: RS.x10),
                        decoration: BoxDecoration(
                          color: _amenities.contains(a) ? RC.tealSoft : RC.surface,
                          borderRadius: RR.chip,
                          border: Border.all(
                            color:
                                _amenities.contains(a) ? RC.teal : RC.border,
                          ),
                        ),
                        child: Text(
                          a,
                          style: RT.captionSm.copyWith(
                            color: _amenities.contains(a)
                                ? RC.tealDark
                                : RC.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: RS.x24),
              Row(
                children: [
                  Expanded(
                    child: RButton(
                      'reset'.tr(),
                      kind: RButtonKind.outline,
                      expanded: true,
                      onPressed: () => setState(() {
                        _price = const RangeValues(0, 20);
                        _beds = 0;
                        _baths = 0;
                        _amenities.clear();
                      }),
                    ),
                  ),
                  const SizedBox(width: RS.x12),
                  Expanded(
                    flex: 2,
                    child: RButton(
                      'show_results'.tr(),
                      expanded: true,
                      onPressed: widget.onApply,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: RS.x12),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RS.x8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: RT.title)),
          IconButton(
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
            color: RC.navy,
          ),
          SizedBox(
            width: 34,
            child: Text(
              value == 0 ? 'Any' : '$value+',
              textAlign: TextAlign.center,
              style: RT.bodyStrong,
            ),
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
