import 'package:flutter/material.dart';

/// RESIVYN design tokens.
///
/// Every colour, radius, shadow and gap in the app comes from here so the
/// 21 screens stay visually identical without copy-pasted magic numbers.
class RC {
  RC._();

  // ---- Brand ----
  static const navy = Color(0xFF0B2348);
  static const navySoft = Color(0xFF1B3A63);
  static const teal = Color(0xFF00A99D);
  static const tealDark = Color(0xFF00887E);
  static const tealSoft = Color(0xFFE6F6F5);

  // ---- Neutrals ----
  static const bg = Color(0xFFF6F8FA);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFFBFCFD);
  static const textPrimary = navy;
  static const textSecondary = Color(0xFF6B7A90);
  static const textTertiary = Color(0xFF9AA7B8);
  static const border = Color(0xFFE7ECF2);
  static const borderStrong = Color(0xFFD8E0EA);

  // ---- Semantic ----
  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFE7F7ED);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFEF4E4);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFDECEC);
  static const info = Color(0xFF2563EB);
  static const infoSoft = Color(0xFFEAF0FE);
  static const purple = Color(0xFF7C3AED);
  static const purpleSoft = Color(0xFFF1EAFE);
}

/// 8px spacing system.
class RS {
  RS._();
  static const double x2 = 2;
  static const double x4 = 4;
  static const double x6 = 6;
  static const double x8 = 8;
  static const double x10 = 10;
  static const double x12 = 12;
  static const double x14 = 14;
  static const double x16 = 16;
  static const double x18 = 18;
  static const double x20 = 20;
  static const double x24 = 24;
  static const double x32 = 32;
  static const double x40 = 40;

  /// Standard horizontal page padding.
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: x20);
}

class RR {
  RR._();
  static const card = BorderRadius.all(Radius.circular(22));
  static const cardLg = BorderRadius.all(Radius.circular(26));
  static const inner = BorderRadius.all(Radius.circular(16));
  static const chip = BorderRadius.all(Radius.circular(100));
  static const button = BorderRadius.all(Radius.circular(16));
  static const image = BorderRadius.all(Radius.circular(18));
}

class RShadow {
  RShadow._();

  /// Soft diffuse card shadow.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0F0B2348),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x0A0B2348),
      blurRadius: 14,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> lifted = [
    BoxShadow(
      color: Color(0x1A0B2348),
      blurRadius: 32,
      offset: Offset(0, 14),
      spreadRadius: -6,
    ),
  ];

  static List<BoxShadow> teal = const [
    BoxShadow(
      color: Color(0x3300A99D),
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
  ];
}

/// Text styles. Named by role, not by size, so screens read declaratively.
class RT {
  RT._();

  static const _base = 'Roboto';

  static const display = TextStyle(
    fontFamily: _base,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: RC.textPrimary,
    letterSpacing: -0.6,
    height: 1.2,
  );

  static const h1 = TextStyle(
    fontFamily: _base,
    fontSize: 21,
    fontWeight: FontWeight.w700,
    color: RC.textPrimary,
    letterSpacing: -0.4,
    height: 1.25,
  );

  static const h2 = TextStyle(
    fontFamily: _base,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: RC.textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const title = TextStyle(
    fontFamily: _base,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: RC.textPrimary,
    letterSpacing: -0.1,
    height: 1.35,
  );

  static const body = TextStyle(
    fontFamily: _base,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: RC.textSecondary,
    height: 1.5,
  );

  static const bodyStrong = TextStyle(
    fontFamily: _base,
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: RC.textPrimary,
    height: 1.45,
  );

  static const caption = TextStyle(
    fontFamily: _base,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: RC.textSecondary,
    height: 1.4,
  );

  static const captionSm = TextStyle(
    fontFamily: _base,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: RC.textTertiary,
    height: 1.35,
  );

  /// Uppercase section/eyebrow label.
  static const label = TextStyle(
    fontFamily: _base,
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: RC.textTertiary,
    letterSpacing: 1.1,
  );

  static const price = TextStyle(
    fontFamily: _base,
    fontSize: 23,
    fontWeight: FontWeight.w700,
    color: RC.textPrimary,
    letterSpacing: -0.6,
  );

  static const metric = TextStyle(
    fontFamily: _base,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: RC.textPrimary,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static const button = TextStyle(
    fontFamily: _base,
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0.1,
  );
}
