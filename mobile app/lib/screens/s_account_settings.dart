import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../core/routes.dart';
import '../core/theme/tokens.dart';
import '../widgets/common.dart';

/// Account settings — display name, email, phone, linked accounts, export, delete.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  String _displayName = 'Alex Johnson';
  String _email = 'alex.johnson@email.com';
  String _phone = '+971 50 123 4567';
  bool _editing = false;
  final _nameController = TextEditingController(text: 'Alex Johnson');
  final _emailController = TextEditingController(text: 'alex.johnson@email.com');
  final _phoneController = TextEditingController(text: '+971 50 123 4567');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    setState(() {
      _displayName = _nameController.text;
      _email = _emailController.text;
      _phone = _phoneController.text;
      _editing = false;
    });
    toast(context, 'Profile updated', icon: Icons.check_circle_outline_rounded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: RC.navy),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Account Settings', style: RT.h2),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              if (_editing) {
                _saveProfile();
              } else {
                setState(() => _editing = true);
              }
            },
            child: Text(
              _editing ? 'Save' : 'Edit',
              style: RT.bodyStrong.copyWith(color: RC.teal),
            ),
          ),
          const SizedBox(width: RS.x4),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: RS.x8),

          // ---- Profile info ----
          Padding(
            padding: RS.page,
            child: RCard(
              padding: const EdgeInsets.all(RS.x20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profile Information', style: RT.h2),
                  const SizedBox(height: RS.x20),
                  RTextField(
                    label: 'display_name'.tr(),
                    hint: 'your_name_hint'.tr(),
                    controller: _nameController,
                    icon: Icons.person_outline_rounded,
                    readOnly: !_editing,
                  ),
                  const SizedBox(height: RS.x14),
                  RTextField(
                    label: 'email_address'.tr(),
                    hint: 'your_email_hint'.tr(),
                    controller: _emailController,
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: !_editing,
                  ),
                  const SizedBox(height: RS.x14),
                  RTextField(
                    label: 'phone_number'.tr(),
                    hint: 'phone_hint'.tr(),
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    readOnly: !_editing,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: RS.x12),

          // ---- Linked accounts ----
          SectionTitle('linked_accounts'.tr()),
          Padding(
            padding: RS.page,
            child: RCard(
              padding: const EdgeInsets.symmetric(horizontal: RS.x16),
              child: Column(
                children: [
                  RowItem(
                    title: 'Google',
                    subtitle: 'alex.johnson@gmail.com',
                    leading: const IconBubble(Icons.g_mobiledata_rounded,
                        tint: RC.info, size: 36),
                    trailing: RBadge('connected_status'.tr(), color: RC.success),
                    onTap: () => toast(context, 'Google account connected',
                        icon: Icons.check_circle_outline_rounded),
                    dense: true,
                  ),
                  const ThinDivider(inset: 48),
                  RowItem(
                    title: 'Apple',
                    subtitle: 'not_connected'.tr(),
                    leading: const IconBubble(Icons.apple_rounded,
                        tint: RC.navy, size: 36),
                    trailing: RBadge('connect_action'.tr(), color: RC.textSecondary),
                    onTap: () => toast(context, 'Apple sign-in is not available in the local build',
                        icon: Icons.info_outline_rounded),
                    dense: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: RS.x12),

          // ---- Data & privacy ----
          SectionTitle('data_privacy'.tr()),
          Padding(
            padding: RS.page,
            child: RCard(
              padding: const EdgeInsets.symmetric(horizontal: RS.x16),
              child: Column(
                children: [
                  RowItem(
                    title: 'export_my_data'.tr(),
                    subtitle: 'export_data_desc'.tr(),
                    leading: const IconBubble(Icons.download_outlined,
                        tint: RC.teal, size: 36),
                    onTap: () => toast(context, 'Data export started — check your email',
                        icon: Icons.download_outlined),
                    dense: true,
                  ),
                  const ThinDivider(inset: 48),
                  RowItem(
                    title: 'privacy_policy_title'.tr(),
                    subtitle: 'privacy_policy_desc'.tr(),
                    leading: const IconBubble(Icons.shield_outlined,
                        tint: RC.purple, size: 36),
                    onTap: () => Navigator.pushNamed(context, Routes.privacy),
                    dense: true,
                  ),
                  const ThinDivider(inset: 48),
                  RowItem(
                    title: 'delete_account'.tr(),
                    subtitle: 'permanently_remove_data'.tr(),
                    leading: const IconBubble(Icons.delete_forever_outlined,
                        tint: RC.danger, size: 36),
                    onTap: () => toast(context, 'Account deletion is not available in the local build',
                        icon: Icons.warning_amber_rounded),
                    dense: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: RS.x32),
        ],
      ),
    );
  }
}
