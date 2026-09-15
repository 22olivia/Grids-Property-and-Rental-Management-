import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/auth_state.dart';
import '../core/routes.dart';
import '../core/service_locator.dart';
import '../core/theme/tokens.dart';
import '../data/api/api_client.dart';
import '../data/models/models.dart';
import '../widgets/common.dart';

/// SCREEN 10 — LOGIN / ROLE SELECTION
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'alex.johnson@email.com');
  final _password = TextEditingController(text: 'resivyn2025');
  bool _obscure = true;
  bool _remember = true;
  UserRole _role = UserRole.visitor;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Each role lands on its own home surface.
  String _destinationFor(UserRole role) => switch (role) {
        UserRole.visitor => Routes.shell,
        UserRole.tenant => Routes.tenantDashboard,
        UserRole.owner => Routes.ownerDashboard,
        UserRole.maintainer => Routes.maintenanceDashboard,
        UserRole.superAdmin => Routes.adminDashboard,
      };

  void _signIn() async {
    final email = _email.text.trim();
    final password = _password.text.trim();

    if (email.isEmpty || password.isEmpty) {
      toast(context, 'please_enter_email_password'.tr(),
          icon: Icons.warning_amber_rounded);
      return;
    }

    // Try live API login.
    final auth = Services.auth;
    if (auth != null) {
      try {
        final result = await auth.login(email, password);
        await AuthState.instance.login(Services.apiClient, result);

        // Map backend role to UserRole.
        final role = _mapRole(result.user.role);
        AppScope.read(context).role = role;

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          _destinationFor(role),
          (route) => false,
        );
        toast(context, 'welcome_user'.tr(namedArgs: {'name': result.user.name}),
            icon: Icons.check_circle_outline_rounded);
        return;
      } on ApiException catch (e) {
        if (!mounted) return;
        toast(context, e.message, icon: Icons.error_outline_rounded);
        return;
      } catch (_) {
        // Fall through to mock mode on network error.
      }
    }

    // Fallback: mock login (no backend).
    AppScope.read(context).role = _role;
    Navigator.pushNamedAndRemoveUntil(
      context,
      _destinationFor(_role),
      (route) => false,
    );
  }

  UserRole _mapRole(String backendRole) => switch (backendRole) {
        'super_admin' || 'admin' => UserRole.superAdmin,
        'owner' => UserRole.owner,
        'tenant' => UserRole.tenant,
        'maintainer' => UserRole.maintainer,
        _ => UserRole.visitor,
      };

  void _pickLanguage() {
    final currentCode = context.locale.languageCode;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: RS.x12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: RC.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(RS.x20),
              child: Text('select_language'.tr(), style: RT.h2),
            ),
            for (final entry in const [
              ('en', 'English'),
              ('ar', 'العربية'),
              ('hi', 'हिन्दी'),
              ('ru', 'Русский'),
            ])
              ListTile(
                leading: Icon(
                  currentCode == entry.$1
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: currentCode == entry.$1 ? RC.teal : RC.textTertiary,
                  size: 20,
                ),
                title: Text(entry.$2, style: RT.title),
                trailing: Text(entry.$1.toUpperCase(), style: RT.captionSm),
                onTap: () async {
                  await context.setLocale(Locale(entry.$1));
                  if (mounted) Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: RS.x20),
          ],
        ),
      ),
    );
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
                    onTap: _pickLanguage,
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
                          const Icon(Icons.language_rounded,
                              size: 16, color: RC.navy),
                          const SizedBox(width: RS.x6),
                          Text(context.locale.languageCode.toUpperCase(),
                              style: RT.caption.copyWith(
                                color: RC.navy,
                                fontWeight: FontWeight.w700,
                              )),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16, color: RC.textTertiary),
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
                  Text('welcome_back'.tr(), style: RT.display),
                  SizedBox(height: RS.x6),
                  Text(
                    'welcome_desc'.tr(),
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

            // ---- Sign-in card ----
            Padding(
              padding: const EdgeInsets.fromLTRB(RS.x20, RS.x20, RS.x20, 0),
              child: RCard(
                padding: const EdgeInsets.all(RS.x20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('sign_in_to_account'.tr(), style: RT.h2),
                    const SizedBox(height: RS.x4),
                    Text(
                      'secure_access_desc'.tr(),
                      style: RT.caption,
                    ),
                    const SizedBox(height: RS.x20),
                    RTextField(
                      hint: 'email_or_phone'.tr(),
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
                    Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () => setState(() => _remember = !_remember),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 19,
                                  height: 19,
                                  decoration: BoxDecoration(
                                    color: _remember
                                        ? RC.teal
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color:
                                          _remember ? RC.teal : RC.borderStrong,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: _remember
                                      ? const Icon(Icons.check,
                                          size: 13, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: RS.x8),
                                Flexible(
                                  child: Text('remember_me'.tr(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: RT.caption),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: RS.x8),
                        Flexible(
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamed(
                                context, Routes.forgotPassword),
                            child: Text(
                              'forgot_password'.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: RT.caption.copyWith(
                                color: RC.teal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: RS.x20),
                    RButton(
                      'sign_in'.tr(),
                      expanded: true,
                      icon: Icons.login_rounded,
                      onPressed: _signIn,
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
                    for (final provider in [
                      ('continue_with_google'.tr(), Icons.g_mobiledata_rounded),
                      ('continue_with_apple'.tr(), Icons.apple_rounded),
                      ('continue_with_sso'.tr(), Icons.corporate_fare_rounded),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: RS.x10),
                        child: RButton(
                          provider.$1,
                          kind: RButtonKind.outline,
                          icon: provider.$2,
                          expanded: true,
                          onPressed: () {
                            AppScope.read(context).role = _role;
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              _destinationFor(_role),
                              (route) => false,
                            );
                            toast(
                              context,
                              'Signed in with ${provider.$1.replaceFirst('Continue with ', '')}',
                              icon: Icons.check_circle_outline_rounded,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ---- Security note ----
            Padding(
              padding: const EdgeInsets.fromLTRB(RS.x20, RS.x20, RS.x20, 0),
              child: InfoBanner(
                title: 'your_data_safe'.tr(),
                body: 'your_data_desc'.tr(),
                icon: Icons.shield_outlined,
                dark: true,
              ),
            ),

            // ---- Footer ----
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(RS.x20, RS.x24, RS.x20, RS.x12),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text('new_to_resivyn'.tr(), style: RT.caption),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.signup),
                      child: Text(
                        'create_account'.tr(),
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

            // Convenience entry point for reviewing the build.
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, Routes.devIndex),
                icon: const Icon(Icons.grid_view_rounded,
                    size: 16, color: RC.textTertiary),
                label: Text('browse_all_screens'.tr(),
                    style: RT.captionSm.copyWith(fontSize: 11)),
              ),
            ),
            const SizedBox(height: RS.x20),
          ],
        ),
      ),
    );
  }
}
