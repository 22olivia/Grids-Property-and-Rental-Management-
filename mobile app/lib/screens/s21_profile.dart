import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/routes.dart';
import '../core/theme/tokens.dart';
import '../data/models/models.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/common.dart';
import '../widgets/resivyn_image.dart';

/// SCREEN 21 — PROFILE / ACCOUNT SETTINGS
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _linkedRoles = [
    UserRole.owner,
    UserRole.tenant,
    UserRole.visitor,
  ];

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: RC.surface,
        shape: const RoundedRectangleBorder(borderRadius: RR.card),
        title: Text('log_out_confirm'.tr(), style: RT.h2),
        content: Text(
          'log_out_desc'.tr(),
          style: RT.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr(),
                style: RT.bodyStrong.copyWith(color: RC.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.login,
                (route) => false,
              );
            },
            child: Text('log_out'.tr(),
                style: RT.bodyStrong.copyWith(color: RC.danger)),
          ),
        ],
      ),
    );
  }

  void _openMenuItem(String label) {
    switch (label) {
      case 'personal_information':
        Navigator.pushNamed(context, Routes.personalInfo);
      case 'account_settings':
        Navigator.pushNamed(context, Routes.accountSettings);
      case 'security':
        Navigator.pushNamed(context, Routes.security);
      case 'notifications':
        Navigator.pushNamed(context, Routes.notificationSettings);
      case 'language':
        Navigator.pushNamed(context, Routes.language);
      case 'payment_methods':
        Navigator.pushNamed(context, Routes.paymentMethods);
      case 'saved_searches':
        Navigator.pushNamed(context, Routes.savedSearches);
      case 'help_support':
        Navigator.pushNamed(context, Routes.support);
      case 'about_resivyn':
        Navigator.pushNamed(context, Routes.about);
      case 'privacy_policy':
        Navigator.pushNamed(context, Routes.privacy);
      case 'terms_conditions':
        Navigator.pushNamed(context, Routes.terms);
      default:
        toast(context, '$label opened', icon: Icons.settings_outlined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final languageLabel = context.locale.languageCode.toUpperCase();

    final menu = <(String, IconData, Color, String?)>[
      ('personal_information', Icons.person_outline_rounded, RC.teal, null),
      ('account_settings', Icons.manage_accounts_outlined, RC.info, null),
      ('security', Icons.lock_outline_rounded, RC.navy, null),
      ('notifications', Icons.notifications_none_rounded, RC.warning, null),
      ('language', Icons.language_rounded, RC.purple, languageLabel),
      ('payment_methods', Icons.credit_card_outlined, RC.success, null),
      ('saved_searches', Icons.bookmark_outline_rounded, RC.teal, null),
      ('help_support', Icons.support_agent_outlined, RC.info, null),
      ('about_resivyn', Icons.info_outline_rounded, RC.navy, null),
      ('privacy_policy', Icons.shield_outlined, RC.purple, null),
      ('terms_conditions', Icons.gavel_outlined, RC.textSecondary, null),
    ];

    final body = ListView(
      padding: EdgeInsets.zero,
      children: [
        ResivynHeader(
          showBack: !widget.embedded,
          trailing: [
            RIconButton(
              icon: Icons.edit_outlined,
              tooltip: 'edit_profile'.tr(),
              onTap: () => Navigator.pushNamed(context, Routes.personalInfo),
            ),
          ],
        ),

        // ---- Profile card ----
        Padding(
          padding: const EdgeInsets.fromLTRB(RS.x20, RS.x8, RS.x20, 0),
          child: RCard(
            padding: const EdgeInsets.all(RS.x20),
            child: Column(
              children: [
                ResivynAvatar(
                  url: state.avatarUrl,
                  name: 'Alex Johnson',
                  size: 84,
                  ring: true,
                  onTap: () => pickProfilePhoto(
                    context,
                    onPicked: state.setAvatarPath,
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: RC.teal,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 15, color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: RS.x14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Alex Johnson', style: RT.h1),
                    SizedBox(width: RS.x6),
                    Icon(Icons.verified_rounded,
                        size: 18, color: RC.teal),
                  ],
                ),
                SizedBox(height: RS.x4),
                Text('alex.johnson@email.com', style: RT.caption),
                SizedBox(height: RS.x12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: RS.x8,
                  runSpacing: RS.x8,
                  children: [
                    RBadge('verified'.tr(),
                        color: RC.success, icon: Icons.verified_user_outlined),
                    RBadge('member_since'.tr(), color: RC.navy),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ---- Account menu ----
        SectionTitle('account'.tr()),
        Padding(
          padding: RS.page,
          child: RCard(
            padding: const EdgeInsets.symmetric(horizontal: RS.x16),
            child: Column(
              children: [
                for (var i = 0; i < menu.length; i++) ...[
                  RowItem(
                    title: menu[i].$1.tr(),
                    leading: IconBubble(menu[i].$2, tint: menu[i].$3, size: 36),
                    trailing: menu[i].$4 == null
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(menu[i].$4!, style: RT.captionSm),
                              const SizedBox(width: RS.x4),
                              const Icon(Icons.chevron_right_rounded, matchTextDirection: true,
                                  size: 20, color: RC.textTertiary),
                            ],
                          ),
                    onTap: () => _openMenuItem(menu[i].$1),
                    dense: true,
                  ),
                  if (i != menu.length - 1) const ThinDivider(inset: 48),
                ],
              ],
            ),
          ),
        ),

        // ---- Preferences ----
        SectionTitle('preferences'.tr()),
        Padding(
          padding: RS.page,
          child: RCard(
            child: Column(
              children: [
                ToggleRow(
                  title: 'push_notifications'.tr(),
                  subtitle: 'alerts_on_device'.tr(),
                  icon: Icons.notifications_active_outlined,
                  value: state.pushNotifications,
                  onChanged: (v) {
                    state.setPreference('push', v);
                    toast(context, '${v ? 'push_on'.tr() : 'push_off'.tr()}',
                        icon: Icons.notifications_active_outlined);
                  },
                ),
                const ThinDivider(),
                ToggleRow(
                  title: 'email_updates'.tr(),
                  subtitle: 'weekly_digest'.tr(),
                  icon: Icons.mail_outline_rounded,
                  tint: RC.info,
                  value: state.emailUpdates,
                  onChanged: (v) => state.setPreference('email', v),
                ),
                const ThinDivider(),
                ToggleRow(
                  title: 'dark_mode'.tr(),
                  subtitle: 'coming_future'.tr(),
                  icon: Icons.dark_mode_outlined,
                  tint: RC.navy,
                  value: state.darkMode,
                  onChanged: (v) {
                    state.setPreference('dark', v);
                    toast(context, 'dark_not_available'.tr(),
                        icon: Icons.dark_mode_outlined);
                  },
                ),
                const ThinDivider(),
                ToggleRow(
                  title: 'biometrics'.tr(),
                  subtitle: 'face_fingerprint'.tr(),
                  icon: Icons.fingerprint_rounded,
                  tint: RC.purple,
                  value: state.biometrics,
                  onChanged: (v) => state.setPreference('biometrics', v),
                ),
              ],
            ),
          ),
        ),

        // ---- Linked roles ----
        SectionTitle('linked_roles_portals'.tr()),
        Padding(
          padding: RS.page,
          child: Column(
            children: [
              for (final role in _linkedRoles)
                Padding(
                  padding: const EdgeInsets.only(bottom: RS.x10),
                  child: RCard(
                    selected: state.role == role,
                    onTap: () {
                      state.role = role;
                      toast(context, 'switched_portal'.tr(namedArgs: {'role': role.label}),
                          icon: role.icon);
                    },
                    child: Row(
                      children: [
                        IconBubble(
                          role.icon,
                          tint: RC.teal,
                          size: 40,
                          solid: state.role == role,
                        ),
                        const SizedBox(width: RS.x12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(role.label, style: RT.title),
                              const SizedBox(height: 2),
                              Text(
                                state.role == role ? 'active'.tr() : 'access'.tr(),
                                style: RT.captionSm,
                              ),
                            ],
                          ),
                        ),
                        if (state.role == role)
                          const Icon(Icons.check_circle_rounded,
                              size: 20, color: RC.teal)
                        else
                          const Icon(Icons.chevron_right_rounded, matchTextDirection: true,
                              size: 20, color: RC.textTertiary),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ---- Logout ----
        Padding(
          padding: const EdgeInsets.fromLTRB(RS.x20, RS.x20, RS.x20, 0),
          child: RButton(
            'log_out'.tr(),
            kind: RButtonKind.danger,
            expanded: true,
            icon: Icons.logout_rounded,
            onPressed: _confirmLogout,
          ),
        ),

        const SizedBox(height: RS.x16),
        Center(
          child: Text('app_version_footer'.tr(),
              style: RT.captionSm.copyWith(fontSize: 10)),
        ),

        const BottomGutter(),
      ],
    );

    // Embedded inside the tab shell — the shell owns the bottom navigation.
    if (widget.embedded) return body;

    return Scaffold(
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: ResivynBottomNav(
        currentIndex: 4,
        onTap: (i) => Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.shell,
          (route) => route.settings.name == Routes.login,
          arguments: i,
        ),
      ),
    );
  }
}
