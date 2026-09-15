import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/service_locator.dart';
import '../core/theme/tokens.dart';
import '../data/mock/mock_data.dart';
import '../data/models/models.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/common.dart';
import '../widgets/resivyn_image.dart';

/// SCREEN 05 — MAINTENANCE TEAM DASHBOARD
class MaintenanceDashboardScreen extends StatefulWidget {
  const MaintenanceDashboardScreen({super.key});

  @override
  State<MaintenanceDashboardScreen> createState() =>
      _MaintenanceDashboardScreenState();
}

class _MaintenanceDashboardScreenState
    extends State<MaintenanceDashboardScreen> {
  int _navIndex = 0;

  late Future<List<WorkOrder>> _schedule;
  late Future<List<WorkOrder>> _assigned;
  late Future<List<ApprovalRequest>> _approvals;
  late Future<List<ActivityEntry>> _activity;

  /// Work orders the user has started this session.
  final Set<String> _started = <String>{};

  @override
  void initState() {
    super.initState();
    _schedule = Services.maintenance.todaySchedule();
    _assigned = Services.maintenance.assigned();
    _approvals = Services.maintenance.pendingApprovals();
    _activity = Services.maintenance.recentActivity();
  }

  Color _priorityColor(WorkPriority p) => switch (p) {
        WorkPriority.high => RC.danger,
        WorkPriority.medium => RC.warning,
        WorkPriority.low => RC.info,
      };

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
                    url: Img.avatarSam,
                    name: 'Sam Peterson',
                    size: 40,
                    ring: true,
                  ),
                ),
              ],
            ),

            const GreetingBlock(
              greeting: 'Good morning, Sam',
              subtitle: 'Maintenance Team',
              subtitleIcon: Icons.handyman_outlined,
              avatarUrl: Img.avatarSam,
              avatarName: 'Sam Peterson',
            ),

            // ---- Stats ----
            const SizedBox(height: RS.x20),
            Padding(
              padding: RS.page,
              child: RGrid(
                columns: 4,
                childAspectRatio: 0.82,
                gap: RS.x8,
                children: [
                  _CompactStat(
                      value: '8', label: 'assigned'.tr(), tint: RC.info),
                  _CompactStat(
                      value: '3',
                      label: 'in_progress'.tr(),
                      tint: RC.warning),
                  _CompactStat(
                      value: '2',
                      label: 'on_hold'.tr(),
                      tint: RC.textSecondary),
                  _CompactStat(
                      value: '12', label: 'completed'.tr(), tint: RC.success),
                ],
              ),
            ),

            // ---- Urgent alert ----
            Padding(
              padding: const EdgeInsets.fromLTRB(RS.x20, RS.x20, RS.x20, 0),
              child: Container(
                padding: const EdgeInsets.all(RS.x16),
                decoration: BoxDecoration(
                  color: RC.dangerSoft,
                  borderRadius: RR.card,
                  border: Border.all(color: RC.danger.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const IconBubble(Icons.priority_high_rounded,
                        tint: RC.danger, size: 38),
                    const SizedBox(width: RS.x12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('urgent_issues'.tr(),
                              style: RT.title.copyWith(color: RC.danger)),
                          const SizedBox(height: RS.x4),
                          Text(
                            'urgent_maintenance'.tr(),
                            style: RT.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: RS.x8),
                    RButton(
                      'view_all'.tr(),
                      kind: RButtonKind.danger,
                      compact: true,
                      onPressed: () => toast(context, 'Showing urgent work orders',
                          icon: Icons.priority_high_rounded),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Today's schedule ----
            SectionTitle('todays_schedule'.tr(),
                actionLabel: 'full_calendar'.tr(),
                onAction: () => toast(context, 'Opening schedule',
                    icon: Icons.calendar_month_outlined)),
            FutureBuilder<List<WorkOrder>>(
              future: _schedule,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const _Loader(height: 160);
                }
                final orders = snapshot.data!;
                return Padding(
                  padding: RS.page,
                  child: Column(
                    children: [
                      for (final order in orders)
                        Padding(
                          padding: const EdgeInsets.only(bottom: RS.x12),
                          child: RCard(
                            onTap: () => toast(context, 'Opening #${order.id}',
                                icon: Icons.assignment_outlined),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Timeline column.
                                Column(
                                  children: [
                                    Text(
                                      order.time.split(' ').first,
                                      style: RT.title.copyWith(fontSize: 13),
                                    ),
                                    Text(
                                      order.time.split(' ').last,
                                      style: RT.captionSm
                                          .copyWith(fontSize: 9.5),
                                    ),
                                    const SizedBox(height: RS.x8),
                                    Container(
                                      width: 2,
                                      height: 26,
                                      color: RC.border,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: RS.x14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text('#${order.id}',
                                              style: RT.captionSm.copyWith(
                                                color: RC.teal,
                                                fontWeight: FontWeight.w700,
                                              )),
                                          const Spacer(),
                                          RBadge(
                                            order.priority.label,
                                            color:
                                                _priorityColor(order.priority),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: RS.x6),
                                      Text(order.title, style: RT.title),
                                      const SizedBox(height: RS.x4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined,
                                              size: 12, color: RC.textTertiary),
                                          const SizedBox(width: RS.x4),
                                          Expanded(
                                            child: Text(order.unit,
                                                style: RT.captionSm,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: RS.x12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: RButton(
                                              _started.contains(order.id)
                                                  ? 'in_progress'.tr()
                                                  : 'start_job'.tr(),
                                              kind: _started.contains(order.id)
                                                  ? RButtonKind.soft
                                                  : RButtonKind.primary,
                                              compact: true,
                                              expanded: true,
                                              icon: _started.contains(order.id)
                                                  ? Icons.timelapse_rounded
                                                  : Icons.play_arrow_rounded,
                                              onPressed: () {
                                                setState(() =>
                                                    _started.add(order.id));
                                                toast(context,
                                                    'Started #${order.id}',
                                                    icon: Icons
                                                        .play_arrow_rounded);
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: RS.x8),
                                          RIconButton(
                                            icon: Icons.navigation_outlined,
                                            tooltip: 'navigate'.tr(),
                                            onTap: () => toast(
                                                context, 'Navigating to ${order.unit}',
                                                icon: Icons.navigation_outlined),
                                          ),
                                          const SizedBox(width: RS.x8),
                                          RIconButton(
                                            icon: Icons.phone_outlined,
                                            tooltip: 'contact'.tr(),
                                            onTap: () => toast(
                                                context, 'Calling tenant',
                                                icon: Icons.phone_outlined),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // ---- Areas ----
            SectionTitle('your_areas'.tr()),
            Padding(
              padding: RS.page,
              child: RCard(
                padding: const EdgeInsets.symmetric(horizontal: RS.x16),
                child: Column(
                  children: [
                    for (var i = 0;
                        i < MockData.areaWorkload.length;
                        i++) ...[
                      RowItem(
                        title: MockData.areaWorkload.keys.elementAt(i),
                        subtitle:
                            '${MockData.areaWorkload.values.elementAt(i)} '
                            '${MockData.areaWorkload.values.elementAt(i) == 1 ? 'job' : 'jobs'} today',
                        leading: const IconBubble(Icons.place_outlined,
                            tint: RC.teal, size: 38),
                        onTap: () => toast(
                          context,
                          'Filtering by ${MockData.areaWorkload.keys.elementAt(i)}',
                          icon: Icons.place_outlined,
                        ),
                      ),
                      if (i != MockData.areaWorkload.length - 1)
                        const ThinDivider(inset: 50),
                    ],
                  ],
                ),
              ),
            ),

            // ---- Quick actions ----
            SectionTitle('quick_actions'.tr()),
            Padding(
              padding: RS.page,
              child: RCard(
                padding: const EdgeInsets.symmetric(vertical: RS.x12),
                child: RGrid(
                  columns: 4,
                  childAspectRatio: 0.78,
                  gap: 0,
                  children: [
                    QuickAction(
                      label: 'start_job'.tr(),
                      icon: Icons.play_arrow_rounded,
                      onTap: () => toast(context, 'Select a work order to start',
                          icon: Icons.play_arrow_rounded),
                    ),
                    QuickAction(
                      label: 'upload_photos'.tr(),
                      icon: Icons.photo_camera_outlined,
                      tint: RC.info,
                      onTap: () => showMockPhotoPicker(context),
                    ),
                    QuickAction(
                      label: 'mark_complete'.tr(),
                      icon: Icons.task_alt_rounded,
                      tint: RC.success,
                      onTap: () => toast(context, 'Marked as complete',
                          icon: Icons.task_alt_rounded),
                    ),
                    QuickAction(
                      label: 'contact'.tr(),
                      icon: Icons.support_agent_outlined,
                      tint: RC.warning,
                      onTap: () => toast(context, 'Contacting tenant / owner',
                          icon: Icons.support_agent_outlined),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Assigned work orders ----
            SectionTitle('assigned_work_orders'.tr(),
                actionLabel: 'see_all'.tr(),
                onAction: () => toast(context, 'Opening all work orders',
                    icon: Icons.assignment_outlined)),
            FutureBuilder<List<WorkOrder>>(
              future: _assigned,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const _Loader(height: 120);
                final orders = snapshot.data!;
                return Padding(
                  padding: RS.page,
                  child: RCard(
                    padding: const EdgeInsets.symmetric(horizontal: RS.x16),
                    child: Column(
                      children: [
                        for (var i = 0; i < orders.length; i++) ...[
                          RowItem(
                            title: '#${orders[i].id} — ${orders[i].title}',
                            subtitle:
                                '${orders[i].unit} • ${orders[i].status}',
                            leading: IconBubble(
                              Icons.build_outlined,
                              tint: _priorityColor(orders[i].priority),
                              size: 38,
                            ),
                            trailing: RBadge(
                              orders[i].priority.label,
                              color: _priorityColor(orders[i].priority),
                            ),
                            onTap: () => toast(
                                context, 'Opening #${orders[i].id}',
                                icon: Icons.assignment_outlined),
                          ),
                          if (i != orders.length - 1)
                            const ThinDivider(inset: 50),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            // ---- Pending approvals ----
            SectionTitle('pending_approvals'.tr()),
            FutureBuilder<List<ApprovalRequest>>(
              future: _approvals,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const _Loader(height: 100);
                return Padding(
                  padding: RS.page,
                  child: Column(
                    children: [
                      for (final approval in snapshot.data!)
                        RCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: RS.x8,
                                runSpacing: RS.x6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text('#${approval.id}',
                                      style: RT.captionSm.copyWith(
                                        color: RC.teal,
                                        fontWeight: FontWeight.w700,
                                      )),
                                  RBadge('awaiting_approval'.tr(),
                                      color: RC.warning),
                                ],
                              ),
                              const SizedBox(height: RS.x8),
                              Text(approval.title, style: RT.title),
                              const SizedBox(height: RS.x4),
                              Text(approval.unit, style: RT.captionSm),
                              const SizedBox(height: RS.x12),
                              const ThinDivider(),
                              const SizedBox(height: RS.x12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('estimated_cost'.tr(),
                                              style: RT.captionSm),
                                        const SizedBox(height: 2),
                                        Text(approval.amount, style: RT.h2),
                                      ],
                                    ),
                                  ),
                                  RButton(
                                    'remind'.tr(),
                                    kind: RButtonKind.outline,
                                    compact: true,
                                    onPressed: () => toast(
                                        context, 'Reminder sent to the owner',
                                        icon: Icons.notifications_active_outlined),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // ---- Recent activity ----
            SectionTitle('recent_activity'.tr()),
            FutureBuilder<List<ActivityEntry>>(
              future: _activity,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const _Loader(height: 100);
                final entries = snapshot.data!;
                return Padding(
                  padding: RS.page,
                  child: RCard(
                    padding: const EdgeInsets.symmetric(horizontal: RS.x16),
                    child: Column(
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
                    ),
                  ),
                );
              },
            ),

            const BottomGutter(),
          ],
        ),
      ),

      bottomNavigationBar: ResivynBottomNav(
        items: maintainerNav,
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          if (i == 4) {
            Navigator.pushNamed(context, Routes.profile);
          } else if (i != 0) {
            toast(context, '${maintainerNav[i].label} module',
                icon: maintainerNav[i].activeIcon);
          }
        },
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({
    required this.value,
    required this.label,
    required this.tint,
  });

  final String value;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return RCard(
      padding: const EdgeInsets.symmetric(vertical: RS.x12, horizontal: RS.x6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: RT.metric.copyWith(color: tint)),
          const SizedBox(height: RS.x4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: RT.captionSm.copyWith(fontSize: 9.5, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader({this.height = 140});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: const Center(
          child: CircularProgressIndicator(color: RC.teal, strokeWidth: 2.5),
        ),
      );
}
