import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../core/routes.dart';
import '../core/service_locator.dart';
import '../core/theme/tokens.dart';
import '../data/mock/mock_data.dart';
import '../data/models/models.dart';
import '../widgets/common.dart';
import '../widgets/property_card.dart';
import '../widgets/resivyn_image.dart';

/// SUPER ADMIN — PROPERTIES MANAGEMENT
class AdminPropertiesScreen extends StatefulWidget {
  const AdminPropertiesScreen({super.key});

  @override
  State<AdminPropertiesScreen> createState() => _AdminPropertiesScreenState();
}

class _AdminPropertiesScreenState extends State<AdminPropertiesScreen> {
  int _tab = 0;
  String _search = '';
  late Future<List<Property>> _properties;

  static const _tabs = ['All', 'For Sale', 'For Rent'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _properties = _tab == 0
        ? Services.properties.search(query: _search)
        : Services.properties.search(
            query: _search,
            tabIndex: _tab == 1 ? 0 : 1,
          );
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
              trailing: [
                RIconButton(
                  icon: Icons.notifications_none_rounded,
                  badge: true,
                  tooltip: 'notifications'.tr(),
                  onTap: () =>
                      Navigator.pushNamed(context, Routes.notifications),
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

            Padding(
              padding: RS.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RBadge('super_admin'.tr(),
                      color: RC.navy, icon: Icons.shield_outlined),
                  const SizedBox(height: RS.x10),
                  const Text('Properties', style: RT.display),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: RS.x20),
              child: RTextField(
                hint: 'search_properties_admin_hint'.tr(),
                icon: Icons.search_outlined,
                onChanged: (v) {
                  _search = v;
                  _load();
                  setState(() {});
                },
              ),
            ),

            // Buy / Rent tabs
            RSegmented(
              items: _tabs,
              selectedIndex: _tab,
              onChanged: (i) {
                _tab = i;
                _load();
                setState(() {});
              },
            ),

            const SizedBox(height: RS.x8),

            // Property list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: RS.x20),
              child: FutureBuilder<List<Property>>(
                future: _properties,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(RS.x24),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: RC.teal, strokeWidth: 2.5),
                      ),
                    );
                  }
                  final list = snapshot.data!;
                  if (list.isEmpty) {
                    return RCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(RS.x24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 40, color: RC.textTertiary),
                              const SizedBox(height: RS.x12),
                              Text('No properties found',
                                  style: RT.caption
                                      .copyWith(color: RC.textTertiary)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final p in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: RS.x12),
                          child: PropertyCard(
                            property: p,
                            onTap: () => Navigator.pushNamed(
                              context,
                              Routes.propertyDetails,
                              arguments: p,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            const BottomGutter(),
          ],
        ),
      ),
    );
  }
}
