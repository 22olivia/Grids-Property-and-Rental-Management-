import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/service_locator.dart';
import '../core/theme/tokens.dart';
import '../data/mock/mock_data.dart';
import '../data/models/models.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/resivyn_image.dart';

/// SCREEN 04 — SUPER ADMIN DASHBOARD
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _navIndex = 0;

  late Future<List<double>> _revenue;
  late Future<List<PlanSlice>> _plans;
  late Future<List<ActivityEntry>> _activity;
  late Future<List<CommunityRevenue>> _communities;

  static final _metrics = <(String, String, IconData, Color, String)>[
    ('128', 'active_communities'.tr(), Icons.holiday_village_outlined, RC.teal, '+6%'),
    ('3,562', 'total_properties'.tr(), Icons.apartment_outlined, RC.info, '+12%'),
    ('8,942', 'owners'.tr(), Icons.business_center_outlined, RC.purple, '+4%'),
    ('12,685', 'tenants'.tr(), Icons.people_outline_rounded, RC.warning, '+9%'),
    ('245', 'maintainers'.tr(), Icons.handyman_outlined, RC.navy, '+3%'),
    ('AED 1.24M', 'monthly_saas_revenue'.tr(), Icons.payments_outlined, RC.success, '+16%'),
  ];

  static final _quickControls = <(String, IconData, Color)>[
    ('users'.tr(), Icons.manage_accounts_outlined, RC.teal),
    ('plans'.tr(), Icons.workspace_premium_outlined, RC.warning),
    ('content'.tr(), Icons.article_outlined, RC.info),
    ('communities'.tr(), Icons.holiday_village_outlined, RC.purple),
    ('reports'.tr(), Icons.insert_chart_outlined_rounded, RC.navy),
    ('settings'.tr(), Icons.settings_outlined, RC.textSecondary),
  ];

  @override
  void initState() {
    super.initState();
    _revenue = Services.admin.revenueSeries();
    _plans = Services.admin.planBreakdown();
    _activity = Services.admin.platformActivity();
    _communities = Services.admin.topCommunities();
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

            // ---- Role + date ----
            Padding(
              padding: RS.page,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: RS.x6,
                          runSpacing: RS.x6,
                          children: [
                            RBadge('super_admin'.tr(),
                                color: RC.navy, icon: Icons.shield_outlined),
                            RBadge('live'.tr(), color: RC.success),
                          ],
                        ),
                        const SizedBox(height: RS.x10),
                        Text('platform_dashboard'.tr(), style: RT.display),
                      ],
                    ),
                  ),
                  const SizedBox(width: RS.x12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: RS.x12, vertical: RS.x10),
                    decoration: BoxDecoration(
                      color: RC.surface,
                      borderRadius: RR.inner,
                      border: Border.all(color: RC.border),
                    ),
                    child: const Column(
                      children: [
                        Text('May 21, 2025',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: RC.navy,
                            )),
                        SizedBox(height: 2),
                        Text('Wednesday', style: RT.captionSm),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---- Metric grid ----
            SectionTitle('platform_at_a_glance'.tr()),
            Padding(
              padding: RS.page,
              child: RGrid(
                childAspectRatio: 1.25,
                children: [
                  for (final (value, label, icon, tint, delta) in _metrics)
                    StatTile(
                      value: value,
                      label: label,
                      icon: icon,
                      tint: tint,
                      delta: delta,
                      onTap: () => toast(context, '$label breakdown',
                          icon: Icons.insights_outlined),
                    ),
                ],
              ),
            ),

            // ---- Revenue ----
            SectionTitle('revenue_overview'.tr()),
            Padding(
              padding: RS.page,
              child: RCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AED 1,240,000', style: RT.price),
                              const SizedBox(height: RS.x4),
                              Text('total_saas_revenue'.tr(), style: RT.captionSm),
                            ],
                          ),
                        ),
                        const RBadge('+16% vs Apr 2025',
                            color: RC.success,
                            icon: Icons.trending_up_rounded),
                      ],
                    ),
                    const SizedBox(height: RS.x20),
                    FutureBuilder<List<double>>(
                      future: _revenue,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const _ChartLoader();
                        return RLineChart(
                          values: snapshot.data!,
                          labels: MockData.revenueLabels,
                          valueFormatter: (v) =>
                              'AED ${(v / 1000000).toStringAsFixed(2)}M',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ---- Subscription plans ----
            SectionTitle('subscription_plans'.tr()),
            Padding(
              padding: RS.page,
              child: RCard(
                child: FutureBuilder<List<PlanSlice>>(
                  future: _plans,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const _ChartLoader();
                    final slices = snapshot.data!;
                    return Column(
                      children: [
                        Center(
                          child: RDonutChart(
                            segments: [
                              for (final s in slices)
                                (s.count.toDouble(), s.color),
                            ],
                            centerValue: '128',
                            centerLabel: 'total'.tr(),
                          ),
                        ),
                        const SizedBox(height: RS.x20),
                        for (final s in slices)
                          Padding(
                            padding: const EdgeInsets.only(bottom: RS.x10),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: s.color,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: RS.x10),
                                Expanded(
                                    child: Text(s.name, style: RT.bodyStrong)),
                                Text('${s.count}',
                                    style: RT.bodyStrong
                                        .copyWith(color: RC.navy)),
                                const SizedBox(width: RS.x8),
                                SizedBox(
                                  width: 42,
                                  child: Text(
                                    '(${s.percent}%)',
                                    textAlign: TextAlign.right,
                                    style: RT.captionSm,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ---- Secondary cards ----
            SectionTitle('operations'.tr()),
            Padding(
              padding: RS.page,
              child: RGrid(
                childAspectRatio: 1.3,
                children: [
                  StatTile(
                    value: '42',
                    label: 'pending_approvals'.tr(),
                    icon: Icons.pending_actions_outlined,
                    tint: RC.warning,
                    onTap: () => toast(context, 'Opening approvals queue',
                        icon: Icons.pending_actions_outlined),
                  ),
                  StatTile(
                    value: '18',
                    label: 'support_tickets'.tr(),
                    icon: Icons.confirmation_number_outlined,
                    tint: RC.info,
                    onTap: () => Navigator.pushNamed(context, Routes.support),
                  ),
                  StatTile(
                    value: '3',
                    label: 'announcements'.tr(),
                    icon: Icons.campaign_outlined,
                    tint: RC.purple,
                    onTap: () => toast(context, 'Managing announcements',
                        icon: Icons.campaign_outlined),
                  ),
                  StatTile(
                    value: 'all_systems_ok'.tr(),
                    label: 'all_systems_operational'.tr(),
                    icon: Icons.check_circle_outline_rounded,
                    tint: RC.success,
                    onTap: () => toast(context, 'System status: operational',
                        icon: Icons.check_circle_outline_rounded),
                  ),
                ],
              ),
            ),

            // ---- Platform activity ----
            SectionTitle('platform_activity'.tr(),
                actionLabel: 'view_all'.tr(),
                onAction: () => toast(context, 'Opening full activity log',
                    icon: Icons.history_rounded)),
            Padding(
              padding: RS.page,
              child: RCard(
                padding: const EdgeInsets.symmetric(horizontal: RS.x16),
                child: FutureBuilder<List<ActivityEntry>>(
                  future: _activity,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const _ChartLoader(height: 120);
                    final entries = snapshot.data!;
                    return Column(
                      children: [
                        for (var i = 0; i < entries.length; i++) ...[
                          RowItem(
                            title: entries[i].title,
                            subtitle: entries[i].time,
                            leading: IconBubble(entries[i].icon,
                                tint: entries[i].tint, size: 38),
                            showChevron: false,
                          ),
                          if (i != entries.length - 1)
                            const ThinDivider(inset: 50),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),

            // ---- Top communities ----
            SectionTitle('top_communities_revenue'.tr()),
            Padding(
              padding: RS.page,
              child: RCard(
                child: FutureBuilder<List<CommunityRevenue>>(
                  future: _communities,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const _ChartLoader(height: 140);
                    final items = snapshot.data!;
                    return Column(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                                bottom: i == items.length - 1 ? 0 : RS.x16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(items[i].name,
                                          style: RT.bodyStrong,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: RS.x8),
                                    Text(items[i].revenue,
                                        style: RT.caption.copyWith(
                                          color: RC.navy,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ],
                                ),
                                const SizedBox(height: RS.x8),
                                RProgressBar(value: items[i].value),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ---- Quick controls ----
            SectionTitle('quick_controls'.tr()),
            Padding(
              padding: RS.page,
              child: RCard(
                padding: const EdgeInsets.symmetric(vertical: RS.x12),
                child: RGrid(
                  columns: 3,
                  childAspectRatio: 0.95,
                  gap: 0,
                  children: [
                    for (final (label, icon, tint) in _quickControls)
                      QuickAction(
                        label: label,
                        icon: icon,
                        tint: tint,
                        onTap: () => toast(context, '$label console opened',
                            icon: icon),
                      ),
                  ],
                ),
              ),
            ),

            const BottomGutter(),
          ],
        ),
      ),

      bottomNavigationBar: ResivynBottomNav(
        items: adminNav,
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          if (i == 1) {
            Navigator.pushNamed(context, Routes.adminCommunities);
          } else if (i == 2) {
            Navigator.pushNamed(context, Routes.adminProperties);
          } else if (i == 3) {
            Navigator.pushNamed(context, Routes.support);
          } else if (i == 4) {
            Navigator.pushNamed(context, Routes.profile);
          }
        },
      ),
    );
  }
}

class _ChartLoader extends StatelessWidget {
  const _ChartLoader({this.height = 160});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: const Center(
          child: CircularProgressIndicator(color: RC.teal, strokeWidth: 2.5),
        ),
      );
}
