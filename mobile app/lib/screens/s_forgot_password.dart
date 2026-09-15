import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme/tokens.dart';
import '../widgets/common.dart';

/// Forgot password screen — multi-step: enter email → check inbox → set new password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  int _step = 0; // 0 = enter email, 1 = verify code, 2 = new password, 3 = done

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _sendReset() {
    if (_email.text.trim().isEmpty) {
      toast(context, 'Please enter your email', icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _step = 1);
    toast(context, 'Reset code sent to ${_email.text}',
        icon: Icons.mark_email_read_outlined);
  }

  void _verifyCode() {
    if (_code.text.trim().isEmpty) {
      toast(context, 'Please enter the code', icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _step = 2);
  }

  void _resetPassword() {
    if (_newPassword.text.length < 6) {
      toast(context, 'Password must be at least 6 characters',
          icon: Icons.error_outline_rounded);
      return;
    }
    if (_newPassword.text != _confirmPassword.text) {
      toast(context, 'Passwords do not match', icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _step = 3);
  }

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.login,
      (route) => false,
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
                  if (_step < 3)
                    GestureDetector(
                      onTap: () {
                        if (_step == 0) {
                          Navigator.maybePop(context);
                        } else {
                          setState(() => _step--);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(RS.x10),
                        decoration: BoxDecoration(
                          color: RC.surface,
                          borderRadius: RR.chip,
                          border: Border.all(color: RC.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: RC.navy),
                      ),
                    ),
                  const SizedBox(width: RS.x12),
                  const ResivynWordmark(),
                ],
              ),
            ),

            const SizedBox(height: RS.x32),

            // ---- Step indicator ----
            Padding(
              padding: RS.page,
              child: Row(
                children: List.generate(3, (i) {
                  final active = i <= _step;
                  final current = i == _step;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 2 ? RS.x8 : 0),
                      decoration: BoxDecoration(
                        color: active ? RC.teal : RC.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: RS.x32),

            // ---- Content based on step ----
            if (_step == 0) _buildEmailStep(),
            if (_step == 1) _buildCodeStep(),
            if (_step == 2) _buildNewPasswordStep(),
            if (_step == 3) _buildDoneStep(),

            const SizedBox(height: RS.x32),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Padding(
      padding: RS.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_reset_rounded, size: 48, color: RC.teal),
          const SizedBox(height: RS.x20),
          const Text('Forgot Password?', style: RT.display),
          const SizedBox(height: RS.x6),
          const Text(
            "No worries! Enter your email and we'll send you a reset code.",
            style: RT.body,
          ),
          const SizedBox(height: RS.x32),
          RTextField(
            hint: 'Email address',
            controller: _email,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: RS.x24),
          RButton(
            'Send Reset Code',
            expanded: true,
            icon: Icons.send_rounded,
            onPressed: _sendReset,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep() {
    return Padding(
      padding: RS.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 48, color: RC.teal),
          const SizedBox(height: RS.x20),
          const Text('Check Your Email', style: RT.display),
          const SizedBox(height: RS.x6),
          Text(
            "We sent a 6-digit code to ${_email.text}. Enter it below.",
            style: RT.body,
          ),
          const SizedBox(height: RS.x32),
          RTextField(
            hint: 'Enter 6-digit code',
            controller: _code,
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: RS.x24),
          RButton(
            'Verify Code',
            expanded: true,
            icon: Icons.verified_outlined,
            onPressed: _verifyCode,
          ),
          const SizedBox(height: RS.x16),
          Center(
            child: GestureDetector(
              onTap: () {
                toast(context, 'Code resent to ${_email.text}',
                    icon: Icons.mark_email_read_outlined);
              },
              child: Text(
                "Didn't receive it? Resend code",
                style: RT.caption.copyWith(
                  color: RC.teal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordStep() {
    return Padding(
      padding: RS.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 48, color: RC.teal),
          const SizedBox(height: RS.x20),
          const Text('New Password', style: RT.display),
          const SizedBox(height: RS.x6),
          const Text(
            'Create a strong password for your account.',
            style: RT.body,
          ),
          const SizedBox(height: RS.x32),
          RTextField(
            hint: 'New password',
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
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
          const SizedBox(height: RS.x12),
          RTextField(
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
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          const SizedBox(height: RS.x24),
          RButton(
            'Reset Password',
            expanded: true,
            icon: Icons.check_circle_outline_rounded,
            onPressed: _resetPassword,
          ),
        ],
      ),
    );
  }

  Widget _buildDoneStep() {
    return Padding(
      padding: RS.page,
      child: Column(
        children: [
          const SizedBox(height: RS.x24),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: RC.tealSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 48, color: RC.teal),
          ),
          const SizedBox(height: RS.x24),
          const Text('All Done!', style: RT.display),
          const SizedBox(height: RS.x6),
          const Text(
            'Your password has been reset successfully. You can now sign in with your new password.',
            style: RT.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: RS.x32),
          RButton(
            'Back to Sign In',
            expanded: true,
            icon: Icons.login_rounded,
            onPressed: _goToLogin,
          ),
        ],
      ),
    );
  }
}
