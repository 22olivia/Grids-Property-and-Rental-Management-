import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, matchTextDirection: true,
              size: 18, color: RC.navy),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('account_settings'.tr(), style: RT.h2),
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
                  Text('profile_information'.tr(), style: RT.h2),
                  const SizedBox(height: RS.x20),
                  RTextField(
                    label: 'Display Name',
                    hint: 'Your name',
                    controller: _nameController,
                    icon: Icons.person_outline_rounded,
                    readOnly: !_editing,
                  ),
                  const SizedBox(height: RS.x14),
                  RTextField(
                    label: 'Email Address',
                    hint: 'your@email.com',
                    controller: _emailController,
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: !_editing,
                  ),
                  const SizedBox(height: RS.x14),
                  RTextField(
                    label: 'Phone Number',
                    hint: '+971 ...',
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
          const SectionTitle('Linked Accounts'),
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
                    trailing: const RBadge('Connected', color: RC.success),
                    onTap: () => toast(context, 'Google account connected',
                        icon: Icons.check_circle_outline_rounded),
                    dense: true,
                  ),
                  const ThinDivider(inset: 48),
                  RowItem(
                    title: 'Apple',
                    subtitle: 'Not connected',
                    leading: const IconBubble(Icons.apple_rounded,
                        tint: RC.navy, size: 36),
                    trailing: const RBadge('Connect', color: RC.textSecondary),
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
          const SectionTitle('Data & Privacy'),
          Padding(
            padding: RS.page,
            child: RCard(
              padding: const EdgeInsets.symmetric(horizontal: RS.x16),
              child: Column(
                children: [
                  RowItem(
                    title: 'Export My Data',
                    subtitle: 'Download a copy of your account data',
                    leading: const IconBubble(Icons.download_outlined,
                        tint: RC.teal, size: 36),
                    onTap: () => toast(context, 'Data export started — check your email',
                        icon: Icons.download_outlined),
                    dense: true,
                  ),
                  const ThinDivider(inset: 48),
                  RowItem(
                    title: 'Privacy Policy',
                    subtitle: 'How we handle your data',
                    leading: const IconBubble(Icons.shield_outlined,
                        tint: RC.purple, size: 36),
                    onTap: () => Navigator.pushNamed(context, Routes.privacy),
                    dense: true,
                  ),
                  const ThinDivider(inset: 48),
                  RowItem(
                    title: 'Delete Account',
                    subtitle: 'Permanently remove all data',
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
