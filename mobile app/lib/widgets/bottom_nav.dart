import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

class NavItem {
  const NavItem(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// The five standard visitor tabs.
const visitorNav = [
  NavItem('nav_home', Icons.home_outlined, Icons.home_rounded),
  NavItem('nav_search', Icons.search_outlined, Icons.search_rounded),
  NavItem('nav_saved', Icons.bookmark_outline_rounded, Icons.bookmark_rounded),
  NavItem('nav_community', Icons.people_outline_rounded, Icons.people_rounded),
  NavItem('nav_profile', Icons.person_outline_rounded, Icons.person_rounded),
];

const tenantNav = [
  NavItem('nav_home', Icons.home_outlined, Icons.home_rounded),
  NavItem('nav_community', Icons.people_outline_rounded, Icons.people_rounded),
  NavItem('nav_access', Icons.vpn_key_outlined, Icons.vpn_key_rounded),
  NavItem('nav_payments', Icons.payments_outlined, Icons.payments_rounded),
  NavItem('nav_menu', Icons.grid_view_outlined, Icons.grid_view_rounded),
];

const ownerNav = [
  NavItem('nav_home', Icons.home_outlined, Icons.home_rounded),
  NavItem('nav_properties', Icons.apartment_outlined, Icons.apartment_rounded),
  NavItem('nav_add', Icons.add_circle_outline_rounded, Icons.add_circle_rounded),
  NavItem('nav_community', Icons.people_outline_rounded, Icons.people_rounded),
  NavItem('nav_profile', Icons.person_outline_rounded, Icons.person_rounded),
];

const maintainerNav = [
  NavItem('nav_dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
  NavItem('nav_work_orders', Icons.assignment_outlined, Icons.assignment_rounded),
  NavItem('nav_schedule', Icons.calendar_today_outlined, Icons.calendar_today_rounded),
  NavItem('nav_assets', Icons.inventory_2_outlined, Icons.inventory_2_rounded),
  NavItem('nav_more', Icons.more_horiz_rounded, Icons.more_horiz_rounded),
];

const adminNav = [
  NavItem('nav_dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
  NavItem('nav_communities', Icons.holiday_village_outlined, Icons.holiday_village_rounded),
  NavItem('nav_properties', Icons.apartment_outlined, Icons.apartment_rounded),
  NavItem('nav_support', Icons.support_agent_outlined, Icons.support_agent_rounded),
  NavItem('nav_settings', Icons.settings_outlined, Icons.settings_rounded),
];

class ResivynBottomNav extends StatelessWidget {
  const ResivynBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = visitorNav,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: RC.surface,
        border: Border(top: BorderSide(color: RC.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0B2348),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: _NavCell(item: items[i], active: i == currentIndex),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  const _NavCell({required this.item, required this.active});

  final NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? RC.teal : RC.textTertiary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 3,
          width: active ? 20 : 0,
          margin: const EdgeInsets.only(bottom: RS.x6),
          decoration: BoxDecoration(
            color: RC.teal,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Icon(active ? item.activeIcon : item.icon, size: 21, color: color),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            item.label.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              height: 1.1,
              color: color,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
