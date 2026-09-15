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

/// SCREEN 06 — TENANT DASHBOARD
class TenantDashboardScreen extends StatefulWidget {
  const TenantDashboardScreen({super.key});

  @override
  State<TenantDashboardScreen> createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen> {
  int _navIndex = 0;
  bool _rentPaid = false;

  late Future<LeaseInfo> _lease;
  late Future<List<Announcement>> _announcements;

  @override
  void initState() {
    super.initState();
    _lease = Services.tenant.lease();
    _announcements = Services.tenant.announcements();
  }

  void _payRent() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(RS.x20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('confirm_payment'.tr(), style: RT.h1),
              const SizedBox(height: RS.x6),
              const Text('Monthly rent for Marina Apartment A-1204',
                  style: RT.caption),
              const SizedBox(height: RS.x20),
              const RCard(
                child: Column(
                  children: [
                    KeyValueRow('Rent', 'AED 12,000'),
                    KeyValueRow('Service charge', 'AED 850'),
                    ThinDivider(),
                    KeyValueRow('Total due', 'AED 12,850'),
                  ],
                ),
              ),
              const SizedBox(height: RS.x20),
              RButton(
                'Pay AED 12,850',
                expanded: true,
                icon: Icons.lock_outline_rounded,
                onPressed: () {
                  Navigator.pop(sheetContext);
                  setState(() => _rentPaid = true);
                  toast(context, 'payment_success'.tr(),
                      icon: Icons.check_circle_outline_rounded);
                },
              ),
              const SizedBox(height: RS.x12),
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

            const GreetingBlock(
              greeting: 'Good morning, Alex 👋',
              subtitle: 'Marina Apartment, Dubai Marina',
            ),

            PageTitle(
              'tenant_dashboard'.tr(),
              subtitle: 'tenant_home_desc'.tr(),
              padding: const EdgeInsets.fromLTRB(RS.x20, RS.x20, RS.x20, RS.x16),
            ),

            // ---- Rent due hero card ----
            FutureBuilder<LeaseInfo>(
              future: _lease,
              builder: (context, snapshot) {
                final lease = snapshot.data ?? MockData.lease;
                return Padding(
                  padding: RS.page,
                  child: RCard(
                    color: _rentPaid ? RC.success : RC.navy,
                    showBorder: false,
                    padding: const EdgeInsets.all(RS.x20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _rentPaid ? 'rent_paid'.tr() : 'rent_due'.tr(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    RT.caption.copyWith(color: Colors.white70),
                              ),
                            ),
                            const Spacer(),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: RS.x10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.16),
                                  borderRadius: RR.chip,
                                ),
                                child: Text(
                                  _rentPaid
                                      ? 'settled'.tr()
                                      : 'days_remaining'.tr(
                                          namedArgs: {
                                            'count': '${lease.daysRemaining}'
                                          }),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: RT.captionSm.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: RS.x12),
                        Text(
                          lease.rentAmount,
                          style: RT.display.copyWith(
                            color: Colors.white,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: RS.x4),
                        Text(
                          'Due on ${lease.dueDate}',
                          style: RT.caption.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: RS.x20),
                        RButton(
                          _rentPaid ? 'view_receipt'.tr() : 'pay_rent_now'.tr(),
                          expanded: true,
                          icon: _rentPaid
                              ? Icons.receipt_long_outlined
                              : Icons.account_balance_wallet_outlined,
                          onPressed: _rentPaid
                              ? () => toast(context, 'Receipt downloaded to your device',
                                  icon: Icons.check_circle_outline_rounded)
                              : _payRent,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ---- Next payment ----
            SectionTitle('next_payment'.tr()),
            Padding(
              padding: RS.page,
              child: RCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const IconBubble(Icons.event_outlined, tint: RC.teal),
                        const SizedBox(width: RS.x12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('05 May 2025', style: RT.title),
                              const SizedBox(height: 2),
                              Text('monthly_rent'.tr(), style: RT.captionSm),
                            ],
                          ),
                        ),
                        const Text('AED 12,000', style: RT.h2),
                      ],
                    ),
                    const SizedBox(height: RS.x12),
                    const ThinDivider(),
                    const SizedBox(height: RS.x8),
                    RButton(
                      'view_payment_history'.tr(),
                      kind: RButtonKind.ghost,
                      expanded: true,
                      icon: Icons.history_rounded,
                      compact: true,
                      onPressed: () => toast(context, 'Payment history loaded — showing last 12 months',
                          icon: Icons.history_rounded),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Lease summary ----
            SectionTitle('lease_summary'.tr()),
            FutureBuilder<LeaseInfo>(
              future: _lease,
              builder: (context, snapshot) {
                final lease = snapshot.data ?? MockData.lease;
                return Padding(
                  padding: RS.page,
                  child: RCard(
                    child: Column(
                      children: [
                        KeyValueRow('property_label'.tr(), lease.property),
                        const ThinDivider(),
                        KeyValueRow('unit'.tr(), lease.unit),
                        const ThinDivider(),
                        KeyValueRow('lease_period'.tr(), lease.period),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ---- Service charges + maintenance ----
            SectionTitle('this_month'.tr()),
            Padding(
              padding: RS.page,
              child: Column(
                children: [
                  RCard(
                    onTap: () => toast(context, 'Service charge statement downloaded',
                        icon: Icons.check_circle_outline_rounded),
                    child: Row(
                      children: [
                        const IconBubble(Icons.receipt_long_outlined,
                            tint: RC.warning),
                        const SizedBox(width: RS.x12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('service_charges'.tr(), style: RT.title),
                              const SizedBox(height: 2),
                              const Text('Due on 05 May 2025', style: RT.captionSm),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('AED 850', style: RT.h2),
                            const SizedBox(height: 2),
                            Text('view_statement'.tr(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: RC.teal,
                                  fontWeight: FontWeight.w700,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: RS.x12),
                  RCard(
                    onTap: () => Navigator.pushNamed(context, Routes.support),
                    child: Row(
                      children: [
                        const IconBubble(Icons.build_outlined, tint: RC.info),
                        const SizedBox(width: RS.x12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('maintenance'.tr(), style: RT.title),
                              const SizedBox(height: 2),
                              const Text('2 open • 1 in progress',
                                  style: RT.captionSm),
                            ],
                          ),
                        ),
                        Text('view_all'.tr(),
                            style: RT.captionSm.copyWith(
                              color: RC.teal,
                              fontWeight: FontWeight.w700,
                            )),
                        const Icon(Icons.chevron_right_rounded,
                            size: 18, color: RC.teal),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---- Announcements ----
            SectionTitle('community_announcements'.tr()),
            FutureBuilder<List<Announcement>>(
              future: _announcements,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: RC.teal, strokeWidth: 2.5),
                    ),
                  );
                }
                return Padding(
                  padding: RS.page,
                  child: Column(
                    children: [
                      for (final a in snapshot.data!)
                        Padding(
                          padding: const EdgeInsets.only(bottom: RS.x12),
                          child: RCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const IconBubble(Icons.campaign_outlined,
                                    tint: RC.purple),
                                const SizedBox(width: RS.x12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(a.title, style: RT.title),
                                      const SizedBox(height: RS.x4),
                                      Text(a.body, style: RT.caption),
                                      const SizedBox(height: RS.x8),
                                      Text(a.date, style: RT.captionSm),
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

            // ---- Visitor passes + documents ----
            SectionTitle('access_documents'.tr()),
            Padding(
              padding: RS.page,
              child: RGrid(
                childAspectRatio: 1.3,
                children: [
                  StatTile(
                    value: '2',
                    label: 'active_visitor_passes'.tr(),
                    icon: Icons.badge_outlined,
                    tint: RC.teal,
                    onTap: () => toast(context, 'Managing visitor passes',
                        icon: Icons.badge_outlined),
                  ),
                  StatTile(
                    value: '1',
                    label: 'upcoming_passes'.tr(),
                    icon: Icons.upcoming_outlined,
                    tint: RC.info,
                    onTap: () => toast(context, 'Upcoming visitors',
                        icon: Icons.upcoming_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RS.x12),
            Padding(
              padding: RS.page,
              child: RCard(
                padding: const EdgeInsets.symmetric(horizontal: RS.x16),
                child: Column(
                  children: [
                    RowItem(
                      title: 'lease_agreement'.tr(),
                      subtitle: 'PDF • 2.4 MB',
                      leading: const IconBubble(Icons.picture_as_pdf_outlined,
                          tint: RC.danger, size: 38),
                      onTap: () => toast(context, 'Lease agreement downloaded',
                          icon: Icons.check_circle_outline_rounded),
                    ),
                    const ThinDivider(inset: 50),
                    RowItem(
                      title: 'house_rules'.tr(),
                      subtitle: 'PDF • 640 KB',
                      leading: const IconBubble(Icons.picture_as_pdf_outlined,
                          tint: RC.danger, size: 38),
                      onTap: () => toast(context, 'House rules downloaded',
                          icon: Icons.check_circle_outline_rounded),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Support ----
            Padding(
              padding: const EdgeInsets.fromLTRB(RS.x20, RS.x24, RS.x20, 0),
              child: InfoBanner(
                title: 'need_help'.tr(),
                body: 'need_help_desc'.tr(),
                icon: Icons.support_agent_rounded,
                dark: true,
                ctaLabel: 'contact_support'.tr(),
                onCta: () => Navigator.pushNamed(context, Routes.support),
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
                      label: 'pay_rent'.tr(),
                      icon: Icons.account_balance_wallet_outlined,
                      onTap: _payRent,
                    ),
                    QuickAction(
                      label: 'raise_ticket'.tr(),
                      icon: Icons.confirmation_number_outlined,
                      tint: RC.warning,
                      onTap: () => Navigator.pushNamed(context, Routes.support),
                    ),
                    QuickAction(
                      label: 'book_facility'.tr(),
                      icon: Icons.pool_outlined,
                      tint: RC.info,
                      onTap: () => toast(context, 'Facility booking opened',
                          icon: Icons.pool_outlined),
                    ),
                    QuickAction(
                      label: 'contact'.tr(),
                      icon: Icons.apartment_outlined,
                      tint: RC.purple,
                      onTap: () => Navigator.pushNamed(context, Routes.contact),
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
        items: tenantNav,
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          if (i == 1) {
            Navigator.pushNamed(context, Routes.community);
          } else if (i == 4) {
            Navigator.pushNamed(context, Routes.profile);
          } else if (i != 0) {
            toast(context, '${tenantNav[i].label} module',
                icon: tenantNav[i].activeIcon);
          }
        },
      ),
    );
  }
}
