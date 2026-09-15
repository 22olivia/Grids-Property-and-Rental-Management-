import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../widgets/common.dart';

/// Security settings — change password, 2FA, biometrics, active sessions.
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _twoFactorEnabled = false;
  bool _biometricsEnabled = false;
  int _expandedSection = -1; // -1 = none

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _changePassword() {
    if (_currentPassword.text.isEmpty) {
      toast(context, 'Enter your current password',
          icon: Icons.error_outline_rounded);
      return;
    }
    if (_newPassword.text.length < 6) {
      toast(context, 'New password must be at least 6 characters',
          icon: Icons.error_outline_rounded);
      return;
    }
    if (_newPassword.text != _confirmPassword.text) {
      toast(context, 'Passwords do not match',
          icon: Icons.error_outline_rounded);
      return;
    }
    _currentPassword.clear();
    _newPassword.clear();
    _confirmPassword.clear();
    setState(() => _expandedSection = -1);
    toast(context, 'Password changed successfully',
        icon: Icons.check_circle_outline_rounded);
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
        title: const Text('Security', style: RT.h2),
        centerTitle: false,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: RS.x16),

          // ---- Change Password ----
          Padding(
            padding: RS.page,
            child: RCard(
              padding: const EdgeInsets.all(RS.x20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IconBubble(Icons.lock_reset_rounded, size: 36),
                      const SizedBox(width: RS.x12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Change Password', style: RT.title),
                            SizedBox(height: 2),
                            Text('Update your account password',
                                style: RT.captionSm),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() =>
                            _expandedSection = _expandedSection == 0 ? -1 : 0),
                        child: Icon(
                          _expandedSection == 0
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 24,
                          color: RC.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _expandedSection == 0
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Padding(
                      padding: const EdgeInsets.only(top: RS.x16),
                      child: Column(
                        children: [
                          RTextField(
                            label: 'Current Password',
                            hint: 'Enter current password',
                            controller: _currentPassword,
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscureCurrent,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureCurrent
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 19,
                                color: RC.textTertiary,
                              ),
                              onPressed: () => setState(
                                  () => _obscureCurrent = !_obscureCurrent),
                            ),
                          ),
                          const SizedBox(height: RS.x12),
                          RTextField(
                            label: 'New Password',
                            hint: 'Enter new password',
                            controller: _newPassword,
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscureNew,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureNew
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 19,
                                color: RC.textTertiary,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                            ),
                          ),
                          const SizedBox(height: RS.x12),
                          RTextField(
                            label: 'Confirm New Password',
                            hint: 'Confirm new password',
                            controller: _confirmPassword,
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscureConfirm,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 19,
                                color: RC.textTertiary,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          const SizedBox(height: RS.x20),
                          RButton(
                            'Update Password',
                            expanded: true,
                            icon: Icons.check_rounded,
                            onPressed: _changePassword,
                          ),
                        ],
                      ),
                    ),
                    secondChild: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: RS.x12),

          // ---- Two-Factor Authentication ----
          Padding(
            padding: RS.page,
            child: RCard(
              child: Column(
                children: [
                  ToggleRow(
                    title: 'Two-Factor Authentication',
                    subtitle: 'Extra layer of security via SMS or authenticator',
                    icon: Icons.security_rounded,
                    tint: RC.info,
                    value: _twoFactorEnabled,
                    onChanged: (v) {
                      setState(() => _twoFactorEnabled = v);
                      toast(
                        context,
                        v ? '2FA enabled' : '2FA disabled',
                        icon: Icons.security_rounded,
                      );
                    },
                  ),
                  const ThinDivider(),
                  ToggleRow(
                    title: 'Biometric Sign-in',
                    subtitle: 'Face ID / fingerprint to sign in',
                    icon: Icons.fingerprint_rounded,
                    tint: RC.purple,
                    value: _biometricsEnabled,
                    onChanged: (v) {
                      setState(() => _biometricsEnabled = v);
                      toast(
                        context,
                        v ? 'Biometrics enabled' : 'Biometrics disabled',
                        icon: Icons.fingerprint_rounded,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: RS.x12),

          // ---- Active sessions ----
          const SectionTitle('Active Sessions'),
          Padding(
            padding: RS.page,
            child: RCard(
              padding: const EdgeInsets.symmetric(horizontal: RS.x16),
              child: Column(
                children: [
                  _sessionTile(
                    icon: Icons.phone_iphone_rounded,
                    title: 'iPhone 15 Pro',
                    subtitle: 'Dubai, UAE • Last active now',
                    isCurrent: true,
                  ),
                  const ThinDivider(inset: 48),
                  _sessionTile(
                    icon: Icons.laptop_mac_rounded,
                    title: 'MacBook Pro',
                    subtitle: 'Dubai, UAE • Last active 2 hours ago',
                    isCurrent: false,
                  ),
                  const ThinDivider(inset: 48),
                  _sessionTile(
                    icon: Icons.desktop_windows_rounded,
                    title: 'Windows PC',
                    subtitle: 'Abu Dhabi, UAE • Last active yesterday',
                    isCurrent: false,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: RS.x12),

          // ---- Danger zone ----
          Padding(
            padding: RS.page,
            child: RCard(
              child: Column(
                children: [
                  RowItem(
                    title: 'Deactivate Account',
                    subtitle: 'Temporarily disable your account',
                    leading: const IconBubble(Icons.pause_circle_outline_rounded,
                        tint: RC.warning, size: 36),
                    onTap: () => toast(context, 'Account deactivation is not available in the local build',
                        icon: Icons.warning_amber_rounded),
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

  Widget _sessionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCurrent,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RS.x12),
      child: Row(
        children: [
          IconBubble(icon, tint: isCurrent ? RC.teal : RC.textSecondary, size: 36),
          const SizedBox(width: RS.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: RT.title),
                    if (isCurrent) ...[
                      const SizedBox(width: RS.x6),
                      const RBadge('Current', color: RC.success),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: RT.captionSm),
              ],
            ),
          ),
          if (!isCurrent)
            TextButton(
              onPressed: () => toast(context, '$title session revoked',
                  icon: Icons.remove_circle_outline_rounded),
              child: Text('Revoke',
                  style: RT.caption.copyWith(
                      color: RC.danger, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
