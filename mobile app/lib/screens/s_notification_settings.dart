import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../widgets/common.dart';

/// Notification settings screen — toggle categories, quiet hours, etc.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;
  bool _propertyAlerts = true;
  bool _paymentAlerts = true;
  bool _maintenanceAlerts = true;
  bool _supportUpdates = true;
  bool _communityPosts = false;
  bool _marketingEmails = false;
  bool _quietHours = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, matchTextDirection: true,
              size: 18, color: RC.navy),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('notification_settings_title'.tr(), style: RT.h2),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: RS.x16),

          // ---- Channels ----
          const SectionTitle('Notification Channels'),
          Padding(
            padding: RS.page,
            child: RCard(
              child: Column(
                children: [
                  ToggleRow(
                    title: 'Push Notifications',
                    subtitle: 'Real-time alerts on this device',
                    icon: Icons.notifications_active_outlined,
                    value: _pushEnabled,
                    onChanged: (v) => setState(() => _pushEnabled = v),
                  ),
                  const ThinDivider(),
                  ToggleRow(
                    title: 'Email Notifications',
                    subtitle: 'Sent to alex.johnson@email.com',
                    icon: Icons.mail_outline_rounded,
                    tint: RC.info,
                    value: _emailEnabled,
                    onChanged: (v) => setState(() => _emailEnabled = v),
                  ),
                  const ThinDivider(),
                  ToggleRow(
                    title: 'SMS Alerts',
                    subtitle: 'Sent to +971 50 123 4567',
                    icon: Icons.sms_outlined,
                    tint: RC.success,
                    value: _smsEnabled,
                    onChanged: (v) => setState(() => _smsEnabled = v),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: RS.x12),

          // ---- Categories ----
          const SectionTitle('Notification Types'),
          Padding(
            padding: RS.page,
            child: RCard(
              child: Column(
                children: [
                  ToggleRow(
                    title: 'Property Alerts',
                    subtitle: 'New listings, price drops, saved matches',
                    icon: Icons.home_outlined,
                    value: _propertyAlerts,
                    onChanged: (v) => setState(() => _propertyAlerts = v),
                  ),
                  const ThinDivider(),
                  ToggleRow(
                    title: 'Payment Reminders',
                    subtitle: 'Rent due, invoices, receipts',
                    icon: Icons.receipt_long_outlined,
                    tint: RC.warning,
                    value: _paymentAlerts,
                    onChanged: (v) => setState(() => _paymentAlerts = v),
                  ),
                  const ThinDivider(),
                  ToggleRow(
                    title: 'Maintenance Updates',
                    subtitle: 'Request status, scheduled visits',
                    icon: Icons.build_outlined,
                    tint: RC.info,
                    value: _maintenanceAlerts,
                    onChanged: (v) => setState(() => _maintenanceAlerts = v),
                  ),
                  const ThinDivider(),
                  ToggleRow(
                    title: 'Support Ticket Updates',
                    subtitle: 'Replies, resolutions, escalations',
                    icon: Icons.support_agent_outlined,
                    tint: RC.success,
                    value: _supportUpdates,
                    onChanged: (v) => setState(() => _supportUpdates = v),
                  ),
                  const ThinDivider(),
                  ToggleRow(
                    title: 'Community Posts',
                    subtitle: 'Updates from your community feed',
                    icon: Icons.forum_outlined,
                    tint: RC.purple,
                    value: _communityPosts,
                    onChanged: (v) => setState(() => _communityPosts = v),
                  ),
                  const ThinDivider(),
                  ToggleRow(
                    title: 'Marketing & Promotions',
                    subtitle: 'New features, offers, newsletters',
                    icon: Icons.campaign_outlined,
                    tint: RC.textSecondary,
                    value: _marketingEmails,
                    onChanged: (v) => setState(() => _marketingEmails = v),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: RS.x12),

          // ---- Quiet Hours ----
          const SectionTitle('Quiet Hours'),
          Padding(
            padding: RS.page,
            child: RCard(
              child: Column(
                children: [
                  ToggleRow(
                    title: 'Enable Quiet Hours',
                    subtitle: 'Silence all notifications during set hours',
                    icon: Icons.do_not_disturb_on_outlined,
                    tint: RC.navy,
                    value: _quietHours,
                    onChanged: (v) => setState(() => _quietHours = v),
                  ),
                  if (_quietHours) ...[
                    const ThinDivider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: RS.x16, vertical: RS.x12),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 18, color: RC.textTertiary),
                          const SizedBox(width: RS.x10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('from_label'.tr(), style: RT.captionSm),
                                const SizedBox(height: RS.x2),
                                Text('10:00 PM',
                                    style: RT.bodyStrong.copyWith(fontSize: 14)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: RS.x14, vertical: RS.x6),
                            decoration: BoxDecoration(
                              color: RC.tealSoft,
                              borderRadius: RR.chip,
                            ),
                            child: Text('to_label'.tr(),
                                style: TextStyle(
                                    color: RC.teal,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ),
                          const SizedBox(width: RS.x16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('until_label'.tr(), style: RT.captionSm),
                                const SizedBox(height: RS.x2),
                                Text('7:00 AM',
                                    style: RT.bodyStrong.copyWith(fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: RS.x24),

          // ---- Reset ----
          Padding(
            padding: RS.page,
            child: RButton(
              'Reset to Defaults',
              kind: RButtonKind.outline,
              expanded: true,
              icon: Icons.restart_alt_rounded,
              onPressed: () {
                setState(() {
                  _pushEnabled = true;
                  _emailEnabled = true;
                  _smsEnabled = false;
                  _propertyAlerts = true;
                  _paymentAlerts = true;
                  _maintenanceAlerts = true;
                  _supportUpdates = true;
                  _communityPosts = false;
                  _marketingEmails = false;
                  _quietHours = false;
                });
                toast(context, 'Settings reset to defaults',
                    icon: Icons.restart_alt_rounded);
              },
            ),
          ),

          const SizedBox(height: RS.x32),
        ],
      ),
    );
  }
}
