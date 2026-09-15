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

/// SCREEN 03 — NOTIFICATIONS
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _navIndex = 0;
  int _filter = 0;

  /// Notifications the user has opened or cleared this session.
  final Set<String> _read = <String>{};

  late Future<List<AppNotification>> _notifications;

  static const _filters = ['All', 'Property', 'Management', 'Payments', 'Support'];

  @override
  void initState() {
    super.initState();
    _notifications = Services.notifications.all();
  }

  bool _matchesFilter(AppNotification n) {
    if (_filter == 0) return true;
    return n.category.label == _filters[_filter];
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
                RIconButton(
                  icon: Icons.notifications_active_outlined,
                  tooltip: 'Notification settings',
                  onTap: () =>
                      Navigator.pushNamed(context, Routes.notificationSettings),
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
              'notifications'.tr(),
              subtitle: 'stay_updated'.tr(),
              trailing: GestureDetector(
                onTap: () {
                  setState(() {
                    for (final n in MockData.notifications) {
                      _read.add(n.title);
                    }
                  });
                  toast(context, 'all_read_done'.tr(),
                      icon: Icons.done_all_rounded);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: RS.x12, vertical: RS.x8),
                  decoration: const BoxDecoration(
                    color: RC.tealSoft,
                    borderRadius: RR.chip,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.done_all_rounded,
                          size: 14, color: RC.tealDark),
                      const SizedBox(width: RS.x4),
                      Text('mark_all_read'.tr(),
                          style: RT.captionSm.copyWith(
                            color: RC.tealDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                          )),
                    ],
                  ),
                ),
              ),
            ),

            RPillBar(
              items: _filters,
              selectedIndex: _filter,
              onChanged: (i) => setState(() => _filter = i),
            ),

            const SizedBox(height: RS.x8),

            FutureBuilder<List<AppNotification>>(
              future: _notifications,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 260,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: RC.teal, strokeWidth: 2.5),
                    ),
                  );
                }

                final visible = snapshot.data!.where(_matchesFilter).toList();

                if (visible.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(RS.x20),
                    child: RCard(
                      padding: const EdgeInsets.all(RS.x32),
                      child: Column(
                        children: [
                          const IconBubble(Icons.notifications_off_outlined,
                              tint: RC.textTertiary, size: 52),
                          const SizedBox(height: RS.x16),
                          Text('nothing_here'.tr(), style: RT.h2),
                          const SizedBox(height: RS.x6),
                          Text(
                            'no_notifications_category'.tr(),
                            textAlign: TextAlign.center,
                            style: RT.caption,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Group by day, preserving the order they arrive in.
                final days = <String>[];
                for (final n in visible) {
                  if (!days.contains(n.day)) days.add(n.day);
                }

                return Column(
                  children: [
                    for (final day in days) ...[
                      SectionTitle(
                        day,
                        padding: const EdgeInsets.fromLTRB(
                            RS.x20, RS.x20, RS.x20, RS.x12),
                      ),
                      Padding(
                        padding: RS.page,
                        child: Column(
                          children: [
                            for (final n
                                in visible.where((n) => n.day == day))
                              Padding(
                                padding: const EdgeInsets.only(bottom: RS.x12),
                                child: _NotificationCard(
                                  notification: n,
                                  read: _read.contains(n.title),
                                  onTap: () {
                                    setState(() => _read.add(n.title));
                                    toast(context, n.title,
                                        icon: n.icon ??
                                            Icons.notifications_outlined);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
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
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.read,
    required this.onTap,
  });

  final AppNotification notification;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = notification.unread && !read;

    return RCard(
      onTap: onTap,
      color: unread ? RC.tealSoft.withOpacity(0.45) : RC.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail for property notifications, icon bubble otherwise.
          if (notification.thumbnailUrl != null)
            ResivynImage(
              url: notification.thumbnailUrl!,
              width: 46,
              height: 46,
              borderRadius: BorderRadius.circular(13),
            )
          else
            IconBubble(
              notification.icon ?? Icons.notifications_outlined,
              tint: notification.badgeColor ?? RC.teal,
              size: 46,
            ),
          const SizedBox(width: RS.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: RT.title.copyWith(
                          fontWeight:
                              unread ? FontWeight.w700 : FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unread) ...[
                      const SizedBox(width: RS.x8),
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: const BoxDecoration(
                          color: RC.teal,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: RS.x4),
                Text(
                  notification.subtitle,
                  style: RT.captionSm,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: RS.x8),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 11, color: RC.textTertiary),
                    const SizedBox(width: RS.x4),
                    Text(notification.time,
                        style: RT.captionSm.copyWith(fontSize: 10)),
                    if (notification.badge != null) ...[
                      const Spacer(),
                      RBadge(
                        notification.badge!,
                        color: notification.badgeColor ?? RC.teal,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
