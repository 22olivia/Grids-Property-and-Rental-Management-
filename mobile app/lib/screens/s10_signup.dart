import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/routes.dart';
import '../core/theme/tokens.dart';
import '../data/models/models.dart';
import '../widgets/common.dart';

/// SCREEN — SIGN UP / REGISTRATION
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;
  UserRole _role = UserRole.visitor;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  String _destinationFor(UserRole role) => switch (role) {
        UserRole.visitor => Routes.shell,
        UserRole.tenant => Routes.tenantDashboard,
        UserRole.owner => Routes.ownerDashboard,
        UserRole.maintainer => Routes.maintenanceDashboard,
        UserRole.superAdmin => Routes.adminDashboard,
      };

  void _signUp() {
    if (_name.text.trim().isEmpty) {
      toast(context, 'please_enter_name'.tr(), icon: Icons.error_outline_rounded);
      return;
    }
    if (_email.text.trim().isEmpty) {
      toast(context, 'please_enter_email'.tr(), icon: Icons.error_outline_rounded);
      return;
    }
    if (_password.text.length < 6) {
      toast(context, 'password_min_6'.tr(),
          icon: Icons.error_outline_rounded);
      return;
    }
    if (_password.text != _confirmPassword.text) {
      toast(context, 'passwords_no_match'.tr(), icon: Icons.error_outline_rounded);
      return;
    }
    if (!_agreeTerms) {
      toast(context, 'agree_terms'.tr(),
          icon: Icons.error_outline_rounded);
      return;
    }
    AppScope.read(context).role = _role;
    Navigator.pushNamedAndRemoveUntil(
      context,
      _destinationFor(_role),
      (route) => false,
    );
    toast(context, 'account_created_success'.tr(),
        icon: Icons.check_circle_outline_rounded);
  }

  void _signUpWithProvider(String provider) {
    AppScope.read(context).role = _role;
    Navigator.pushNamedAndRemoveUntil(
      context,
      _destinationFor(_role),
      (route) => false,
    );
    toast(context, 'signed_up_with'.tr(namedArgs: {'provider': provider}),
        icon: Icons.check_circle_outline_rounded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ---- Header ----
            Padding(
              padding: const EdgeInsets.fromLTRB(RS.x20, RS.x16, RS.x20, RS.x8),
              child: Row(
                children: [
                  const ResivynWordmark(),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: RS.x12, vertical: RS.x8),
                      decoration: BoxDecoration(
                        color: RC.surface,
                        borderRadius: RR.chip,
                        border: Border.all(color: RC.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 14, color: RC.navy),
                          const SizedBox(width: RS.x4),
                          Text('sign_in'.tr(),
                              style: RT.caption.copyWith(
                                color: RC.navy,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: RS.x24),
            Padding(
              padding: RS.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('create_account_title'.tr(), style: RT.display),
                  SizedBox(height: RS.x6),
                  Text(
                    'join_resivyn_desc'.tr(),
                    style: RT.body,
                  ),
                ],
              ),
            ),

            // ---- Role selection ----
            Padding(
              padding: const EdgeInsets.fromLTRB(RS.x20, RS.x24, RS.x20, RS.x12),
              child: Text('select_your_role'.tr(), style: RT.label),
            ),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: RS.page,
                itemCount: UserRole.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: RS.x10),
                itemBuilder: (context, i) {
                  final role = UserRole.values[i];
                  final active = role == _role;
                  return GestureDetector(
                    onTap: () => setState(() => _role = role),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 104,
                      padding: const EdgeInsets.all(RS.x12),
                      decoration: BoxDecoration(
                        color: RC.surface,
                        borderRadius: RR.inner,
                        border: Border.all(
                          color: active ? RC.teal : RC.border,
                          width: active ? 1.6 : 1,
                        ),
                        boxShadow: active ? RShadow.teal : RShadow.soft,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconBubble(
                                role.icon,
                                tint: active ? RC.teal : RC.navy,
                                size: 30,
                                solid: active,
                              ),
                              const Spacer(),
                              if (active)
                                const Icon(Icons.check_circle_rounded,
                                    size: 16, color: RC.teal),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            role.label,
                            style: RT.caption.copyWith(
                              color: RC.navy,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            role.blurb,
                            style: RT.captionSm.copyWith(fontSize: 9.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ---- Registration card ----
            Padding(
              padding: const EdgeInsets.fromLTRB(RS.x20, RS.x20, RS.x20, 0),
              child: RCard(
                padding: const EdgeInsets.all(RS.x20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('fill_details'.tr(), style: RT.h2),
                    const SizedBox(height: RS.x4),
                    Text(
                      'create_account_desc'.tr(),
                      style: RT.caption,
                    ),
                    const SizedBox(height: RS.x20),
                    RTextField(
                      hint: 'full_name'.tr(),
                      controller: _name,
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: RS.x12),
                    RTextField(
                      hint: 'email_address'.tr(),
                      controller: _email,
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: RS.x12),
                    RTextField(
                      hint: 'password'.tr(),
                      controller: _password,
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 19,
                          color: RC.textTertiary,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: RS.x12),
                    RTextField(
                      hint: 'confirm_password'.tr(),
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
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    const SizedBox(height: RS.x16),

                    // Terms checkbox
                    GestureDetector(
                      onTap: () =>
                          setState(() => _agreeTerms = !_agreeTerms),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 19,
                            height: 19,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color:
                                  _agreeTerms ? RC.teal : Colors.transparent,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color:
                                    _agreeTerms ? RC.teal : RC.borderStrong,
                                width: 1.5,
                              ),
                            ),
                            child: _agreeTerms
                                ? const Icon(Icons.check,
                                    size: 13, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: RS.x8),
                          Expanded(
                            child: Text(
                              'agree_terms_long'.tr(),
                              style: RT.caption.copyWith(height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: RS.x20),
                    RButton(
                      'create_account'.tr(),
                      expanded: true,
                      icon: Icons.person_add_alt_rounded,
                      onPressed: _signUp,
                    ),
                    const SizedBox(height: RS.x20),
                    Row(
                      children: [
                        const Expanded(child: ThinDivider()),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: RS.x12),
                          child: Text('or_continue_with'.tr(),
                              style: RT.captionSm.copyWith(fontSize: 10.5)),
                        ),
                        const Expanded(child: ThinDivider()),
                      ],
                    ),
                    const SizedBox(height: RS.x16),
                    for (final provider in const [
                      ('Google', Icons.g_mobiledata_rounded),
                      ('Apple', Icons.apple_rounded),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: RS.x10),
                        child: RButton(
                          'Continue with ${provider.$1}',
                          kind: RButtonKind.outline,
                          icon: provider.$2,
                          expanded: true,
                          onPressed: () => _signUpWithProvider(provider.$1),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ---- Footer ----
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(RS.x20, RS.x24, RS.x20, RS.x20),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text('already_have_account'.tr(), style: RT.caption),
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Text(
                        'sign_in'.tr(),
                        style: RT.caption.copyWith(
                          color: RC.teal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: RS.x20),
          ],
        ),
      ),
    );
  }
}
