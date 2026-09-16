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

/// SCREEN 07 — PROPERTY OWNER DASHBOARD
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _navIndex = 0;
  String _period = 'May 1 – May 31, 2025';

  late Future<List<double>> _income;
  late Future<List<Inquiry>> _inquiries;
  late Future<List<PaymentRecord>> _payments;
  late Future<List<PropertyPerformance>> _performance;

  static const _periods = [
    'May 1 – May 31, 2025',
    'Apr 1 – Apr 30, 2025',
    'Q2 2025',
    'Year to date',
  ];

  @override
  void initState() {
    super.initState();
    _income = Services.owner.incomeSeries();
    _inquiries = Services.owner.inquiries();
    _payments = Services.owner.recentPayments();
    _performance = Services.owner.performance();
  }

  void _pickPeriod() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(RS.x20),
              child: Text('reporting_period'.tr(), style: RT.h2),
            ),
            for (final p in _periods)
              ListTile(
                leading: Icon(
                  _period == p
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: _period == p ? RC.teal : RC.textTertiary,
                  size: 20,
                ),
                title: Text(p, style: RT.title),
                onTap: () {
                  setState(() => _period = p);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: RS.x20),
          ],
        ),
      ),
    );
  }

  void _replyToInquiry(Inquiry inquiry) {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          RS.x20,
          RS.x16,
          RS.x20,
          MediaQuery.of(sheetContext).viewInsets.bottom + RS.x16,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: RC.border,
                    borderRadius: RR.chip,
                  ),
                ),
              ),
              const SizedBox(height: RS.x16),
              Row(
                children: [
                  ResivynAvatar(
                    url: inquiry.avatarUrl,
                    name: inquiry.name,
                    size: 36,
                  ),
                  const SizedBox(width: RS.x10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inquiry.name, style: RT.bodyStrong),
                        Text(inquiry.message,
                            style: RT.captionSm,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Text(inquiry.time,
                      style: RT.captionSm.copyWith(fontSize: 10)),
                ],
              ),
              const SizedBox(height: RS.x16),
              const ThinDivider(),
              const SizedBox(height: RS.x12),
              TextField(
                controller: ctrl,
                autofocus: true,
                maxLines: 3,
                minLines: 2,
                style: RT.body,
                decoration: InputDecoration(
                  hintText: 'type_reply'.tr(),
                  hintStyle: RT.body.copyWith(color: RC.textTertiary),
                  filled: true,
                  fillColor: RC.surface,
                  border: OutlineInputBorder(
                    borderRadius: RR.inner,
                    borderSide: const BorderSide(color: RC.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: RR.inner,
                    borderSide: const BorderSide(color: RC.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: RR.inner,
                    borderSide: const BorderSide(color: RC.teal, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: RS.x12),
              SizedBox(
                width: double.infinity,
                child: RButton(
                  'send_reply'.tr(),
                  icon: Icons.send_rounded,
                  onPressed: () {
                    final text = ctrl.text.trim();
                    Navigator.pop(sheetContext);
                    if (text.isNotEmpty) {
                      toast(context,
                          'reply_sent'.tr(namedArgs: {'name': inquiry.name}),
                          icon: Icons.check_circle_outline_rounded);
                    }
                  },
                ),
              ),
              const SizedBox(height: RS.x8),
            ],
          ),
        ),
      ),
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

            GreetingBlock(
              greeting: 'good_morning'.tr(namedArgs: {'name': 'Alex'}),
              subtitle: 'property_owner_label'.tr(),
              subtitleIcon: Icons.business_center_outlined,
              weather: false,
            ),

            PageTitle(
              'owner_dashboard'.tr(),
              subtitle: 'owner_overview'.tr(),
              padding: const EdgeInsets.fromLTRB(RS.x20, RS.x20, RS.x20, RS.x12),
            ),

            // ---- Period selector ----
            Padding(
              padding: RS.page,
              child: GestureDetector(
                onTap: _pickPeriod,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: RS.x16, vertical: RS.x12),
                  decoration: BoxDecoration(
                    color: RC.surface,
                    borderRadius: RR.inner,
                    border: Border.all(color: RC.border),
                    boxShadow: RShadow.soft,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined,
                          size: 17, color: RC.teal),
                      const SizedBox(width: RS.x10),
                      Expanded(
                        child: Text(_period,
                            style: RT.bodyStrong, maxLines: 1),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 20, color: RC.textTertiary),
                    ],
                  ),
                ),
              ),
            ),

            // ---- Portfolio summary ----
            SectionTitle('portfolio_summary'.tr()),
            Padding(
              padding: RS.page,
              child: RGrid(
                childAspectRatio: 1.28,
                children: [
                  StatTile(
                    value: '28',
                    label: 'total_properties_label'.tr(),
                    icon: Icons.apartment_outlined,
                    tint: RC.teal,
                    delta: '+2 this month',
                    onTap: () => toast(context, 'Opening property list',
                        icon: Icons.apartment_outlined),
                  ),
                  StatTile(
                    value: '92%',
                    label: 'occupancy_rate'.tr(),
                    icon: Icons.donut_large_outlined,
                    tint: RC.info,
                    delta: '+4% vs Apr',
                    onTap: () => toast(context, 'Occupancy breakdown',
                        icon: Icons.donut_large_outlined),
                  ),
                  StatTile(
                    value: 'AED 512,400',
                    label: 'monthly_rent_collected'.tr(),
                    icon: Icons.payments_outlined,
                    tint: RC.success,
                    delta: '+12% vs Apr',
                    onTap: () => toast(context, 'Showing rent collection breakdown for all properties',
                        icon: Icons.payments_outlined),
                  ),
                  StatTile(
                    value: 'AED 48,750',
                    label: 'pending_payments'.tr(namedArgs: {'count': '3'}),
                    icon: Icons.schedule_outlined,
                    tint: RC.warning,
                    delta: '3 payments',
                    deltaUp: false,
                    onTap: () => toast(context, 'Showing 3 pending payments — reminders sent',
                        icon: Icons.schedule_outlined),
                  ),
                ],
              ),
            ),

            // ---- Income overview ----
            SectionTitle('income_overview'.tr()),
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
                              const Text('AED 512,400', style: RT.price),
                              const SizedBox(height: RS.x4),
                              Text('total_rent_collected'.tr(),
                                  style: RT.captionSm),
                            ],
                          ),
                        ),
                        const RBadge('+12% vs Apr',
                            color: RC.success,
                            icon: Icons.trending_up_rounded),
                      ],
                    ),
                    const SizedBox(height: RS.x20),
                    FutureBuilder<List<double>>(
                      future: _income,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox(
                            height: 150,
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: RC.teal, strokeWidth: 2.5),
                            ),
                          );
                        }
                        return RBarChart(
                          values: snapshot.data!,
                          labels: MockData.incomeLabels,
                          valueFormatter: (v) =>
                              '${(v / 1000).toStringAsFixed(0)}k',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ---- Maintenance requests ----
            SectionTitle('maintenance_requests'.tr()),
            Padding(
              padding: RS.page,
              child: RCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const IconBubble(Icons.build_outlined, tint: RC.warning),
                        const SizedBox(width: RS.x12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('18 Total', style: RT.h2),
                              const SizedBox(height: 2),
                              Text('across_portfolio'.tr(),
                                  style: RT.captionSm),
                            ],
                          ),
                        ),
                        RButton(
                          'manage'.tr(),
                          kind: RButtonKind.outline,
                          compact: true,
                          onPressed: () => Navigator.pushNamed(
                              context, Routes.maintenanceDashboard),
                        ),
                      ],
                    ),
                    const SizedBox(height: RS.x16),
                    const ThinDivider(),
                    const SizedBox(height: RS.x16),
                    Row(
                      children: [
                        Expanded(
                          child: _SplitStat(
                              value: '8',
                              label: 'open_label'.tr(),
                              tint: RC.danger),
                        ),
                        Expanded(
                          child: _SplitStat(
                              value: '6',
                              label: 'in_progress_label'.tr(),
                              tint: RC.warning),
                        ),
                        Expanded(
                          child: _SplitStat(
                              value: '4',
                              label: 'completed_label'.tr(),
                              tint: RC.success),
                        ),
                      ],
                    ),
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
                  columns: 5,
                  childAspectRatio: 0.62,
                  gap: 0,
                  children: [
                    QuickAction(
                      label: 'add_property'.tr(),
                      icon: Icons.add_home_outlined,
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.sellProperty),
                    ),
                    QuickAction(
                      label: 'tenants_label'.tr(),
                      icon: Icons.people_outline_rounded,
                      tint: RC.info,
                      onTap: () => toast(context, 'Tenant directory',
                          icon: Icons.people_outline_rounded),
                    ),
                    QuickAction(
                      label: 'contracts'.tr(),
                      icon: Icons.description_outlined,
                      tint: RC.purple,
                      onTap: () => toast(context, 'Showing contracts for all 24 units',
                          icon: Icons.description_outlined),
                    ),
                    QuickAction(
                      label: 'payments_label'.tr(),
                      icon: Icons.payments_outlined,
                      tint: RC.success,
                      onTap: () => toast(context, 'Payments ledger loaded — AED 512,400 this month',
                          icon: Icons.payments_outlined),
                    ),
                    QuickAction(
                      label: 'reports_label'.tr(),
                      icon: Icons.insert_chart_outlined_rounded,
                      tint: RC.warning,
                      onTap: () => toast(context, 'Financial report generated — ready to download',
                          icon: Icons.check_circle_outline_rounded),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Recent inquiries ----
            SectionTitle('recent_inquiries'.tr(),
                actionLabel: 'see_all'.tr(),
                onAction: () => toast(context, 'All inquiries',
                    icon: Icons.mark_email_unread_outlined)),
            FutureBuilder<List<Inquiry>>(
              future: _inquiries,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const _Loader();
                final items = snapshot.data!;
                return Padding(
                  padding: RS.page,
                  child: RCard(
                    padding: const EdgeInsets.symmetric(horizontal: RS.x16),
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          RowItem(
                            title: items[i].name,
                            subtitle: items[i].message,
                            leading: ResivynAvatar(
                              url: items[i].avatarUrl,
                              name: items[i].name,
                              size: 40,
                            ),
                            trailing: Text(items[i].time,
                                style: RT.captionSm.copyWith(fontSize: 10)),
                            onTap: () => _replyToInquiry(items[i]),
                          ),
                          if (i != items.length - 1)
                            const ThinDivider(inset: 52),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            // ---- Recent payments ----
            SectionTitle('recent_payments'.tr()),
            FutureBuilder<List<PaymentRecord>>(
              future: _payments,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const _Loader();
                final items = snapshot.data!;
                return Padding(
                  padding: RS.page,
                  child: RCard(
                    padding: const EdgeInsets.symmetric(horizontal: RS.x16),
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          RowItem(
                            title: items[i].unit,
                            subtitle: items[i].date,
                            leading: const IconBubble(
                                Icons.check_circle_outline_rounded,
                                tint: RC.success,
                                size: 38),
                            trailing: Text(items[i].amount, style: RT.bodyStrong),
                            onTap: () => toast(context, 'Receipt downloaded',
                                icon: Icons.check_circle_outline_rounded),
                          ),
                          if (i != items.length - 1)
                            const ThinDivider(inset: 50),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            // ---- Property performance ----
            SectionTitle('property_performance'.tr()),
            FutureBuilder<List<PropertyPerformance>>(
              future: _performance,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const _Loader();
                final items = snapshot.data!;
                return Padding(
                  padding: RS.page,
                  child: RCard(
                    child: Column(
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
                                    Text(items[i].rent, style: RT.captionSm),
                                  ],
                                ),
                                const SizedBox(height: RS.x8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: RProgressBar(
                                        value: items[i].occupancy / 100,
                                        color: items[i].occupancy >= 95
                                            ? RC.success
                                            : RC.teal,
                                      ),
                                    ),
                                    const SizedBox(width: RS.x10),
                                    SizedBox(
                                      width: 42,
                                      child: Text(
                                        '${items[i].occupancy}%',
                                        textAlign: TextAlign.right,
                                        style: RT.captionSm.copyWith(
                                          color: RC.navy,
                                          fontWeight: FontWeight.w700,
                                        ),
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
              },
            ),

            const BottomGutter(),
          ],
        ),
      ),

      bottomNavigationBar: ResivynBottomNav(
        items: ownerNav,
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          switch (i) {
            case 1:
              Navigator.pushNamed(context, Routes.search);
            case 2:
              Navigator.pushNamed(context, Routes.sellProperty);
            case 3:
              Navigator.pushNamed(context, Routes.community);
            case 4:
              Navigator.pushNamed(context, Routes.profile);
          }
        },
      ),
    );
  }
}

class _SplitStat extends StatelessWidget {
  const _SplitStat({
    required this.value,
    required this.label,
    required this.tint,
  });

  final String value;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: RT.metric.copyWith(color: tint)),
        const SizedBox(height: RS.x4),
        Text(label,
            style: RT.captionSm.copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 130,
        child: Center(
          child: CircularProgressIndicator(color: RC.teal, strokeWidth: 2.5),
        ),
      );
}
