import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../core/routes.dart';
import '../core/theme/tokens.dart';
import '../data/mock/mock_data.dart';
import '../data/models/models.dart';
import '../widgets/common.dart';
import '../widgets/resivyn_image.dart';

/// SUPER ADMIN — COMMUNITIES MANAGEMENT
class AdminCommunitiesScreen extends StatefulWidget {
  const AdminCommunitiesScreen({super.key});

  @override
  State<AdminCommunitiesScreen> createState() => _AdminCommunitiesScreenState();
}

class _AdminCommunitiesScreenState extends State<AdminCommunitiesScreen> {
  String _filter = 'All';
  String _search = '';

  static const _filters = ['All', 'Active', 'Review', 'Inactive'];

  List<AdminCommunity> get _filtered {
    var list = MockData.adminCommunities;
    if (_filter != 'All') {
      list = list.where((c) => c.status == _filter).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.location.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final communities = _filtered;

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
                  Row(
                    children: [
Expanded(
                        child: Text('communities'.tr(), style: RT.display),
                      ),
                      Text(
                        '${communities.length} total',
                        style: RT.captionSm.copyWith(color: RC.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: RS.x20),
              child: RTextField(
                hint: 'search_communities_hint'.tr(),
                icon: Icons.search_outlined,
                onChanged: (v) => setState(() => _search = v),
              ),
            ),

            // Filter pills
            RPillBar(
              items: _filters,
              selectedIndex: _filters.indexOf(_filter),
              onChanged: (i) => setState(() => _filter = _filters[i]),
            ),

            // Summary stats
            Padding(
              padding: RS.page,
              child: RGrid(
                childAspectRatio: 1.35,
                children: [
                  StatTile(
                    value: '${communities.length}',
                    label: 'communities'.tr(),
                    icon: Icons.holiday_village_outlined,
                    tint: RC.teal,
                  ),
                  StatTile(
                    value: '${communities.fold<int>(0, (s, c) => s + c.properties)}',
                    label: 'total_properties'.tr(),
                    icon: Icons.apartment_outlined,
                    tint: RC.info,
                  ),
                  StatTile(
                    value:
                        '${(communities.isEmpty ? 0 : communities.fold<int>(0, (s, c) => s + c.occupancy) / communities.length).round()}%',
                    label: 'avg_occupancy'.tr(),
                    icon: Icons.pie_chart_outline_rounded,
                    tint: RC.success,
                  ),
                ],
              ),
            ),

            // Community list
            SectionTitle('all_communities'.tr()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: RS.x20),
              child: communities.isEmpty
                  ? RCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(RS.x24),
                          child: Text(
                            'No communities match your search',
                            style: RT.caption.copyWith(color: RC.textTertiary),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < communities.length; i++)
                          _CommunityTile(community: communities[i]),
                      ],
                    ),
            ),

            const BottomGutter(),
          ],
        ),
      ),
    );
  }
}

class _CommunityTile extends StatelessWidget {
  const _CommunityTile({required this.community});
  final AdminCommunity community;

  Color get _statusColor => switch (community.status) {
        'Active' => RC.success,
        'Review' => RC.warning,
        _ => RC.textTertiary,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: RS.x12),
      child: RCard(
        padding: EdgeInsets.zero,
        onTap: () => toast(context, 'Opening ${community.name}',
            icon: Icons.holiday_village_outlined),
        child: Row(
          children: [
            ResivynImage(
              url: community.imageUrl,
              width: 90,
              height: 90,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(21),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(RS.x14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(community.name,
                        style: RT.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: RS.x4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: RC.textTertiary),
                        const SizedBox(width: RS.x4),
                        Expanded(
                          child: Text(community.location,
                              style: RT.captionSm,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: RS.x8),
                    Row(
                      children: [
                        RBadge('${community.properties} units',
                            color: RC.info),
                        const SizedBox(width: RS.x6),
                        RBadge('${community.occupancy}% occ.',
                            color: RC.success),
                        const SizedBox(width: RS.x6),
                        RBadge(community.status, color: _statusColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: RS.x12),
              child: Icon(Icons.chevron_right_rounded,
                  size: 20, color: RC.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
