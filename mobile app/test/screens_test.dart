import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_http.dart';

import 'package:resivyn/core/app_state.dart';
import 'package:resivyn/core/theme/app_theme.dart';
import 'package:resivyn/screens/dev_index.dart';
import 'package:resivyn/screens/s01_floor_plan.dart';
import 'package:resivyn/screens/s02_support_center.dart';
import 'package:resivyn/screens/s03_notifications.dart';
import 'package:resivyn/screens/s04_admin_dashboard.dart';
import 'package:resivyn/screens/s05_maintenance_dashboard.dart';
import 'package:resivyn/screens/s06_tenant_dashboard.dart';
import 'package:resivyn/screens/s07_owner_dashboard.dart';
import 'package:resivyn/screens/s08_villa_details.dart';
import 'package:resivyn/screens/s09_search.dart';
import 'package:resivyn/screens/s10_login.dart';
import 'package:resivyn/screens/s12_property_details.dart';
import 'package:resivyn/screens/s13_gallery.dart';
import 'package:resivyn/screens/s14_sell_property.dart';
import 'package:resivyn/screens/s15_about.dart';
import 'package:resivyn/screens/s16_contact.dart';
import 'package:resivyn/screens/s17_plans.dart';
import 'package:resivyn/screens/s18_s19_legal.dart';
import 'package:resivyn/screens/s20_ticket_details.dart';
import 'package:resivyn/screens/s21_profile.dart';
import 'package:resivyn/screens/shell.dart';
import 'package:resivyn/screens/supporting.dart';

/// Wraps a screen in the minimum app scaffolding it needs (theme + AppScope)
/// so each one can be pumped in isolation.
Widget host(Widget child) {
  return AppScope(
    state: AppState(),
    child: MaterialApp(
      theme: AppTheme.light(),
      home: child,
    ),
  );
}

/// Every screen in the app, keyed by its spec number.
final screens = <String, Widget Function()>{
  '01 Floor Plan': () => const FloorPlanScreen(),
  '02 Support Center': () => const SupportCenterScreen(),
  '03 Notifications': () => const NotificationsScreen(),
  '04 Admin Dashboard': () => const AdminDashboardScreen(),
  '05 Maintenance Dashboard': () => const MaintenanceDashboardScreen(),
  '06 Tenant Dashboard': () => const TenantDashboardScreen(),
  '07 Owner Dashboard': () => const OwnerDashboardScreen(),
  '08 Villa Details': () => const VillaDetailsScreen(),
  '09 Search': () => const SearchScreen(),
  '10 Login': () => const LoginScreen(),
  '11/Shell Home': () => const MainShell(),
  '12 Property Details': () => const PropertyDetailsScreen(),
  '13 Gallery': () => const GalleryScreen(),
  '14 Sell Property': () => const SellPropertyScreen(),
  '15 About': () => const AboutScreen(),
  '16 Contact': () => const ContactScreen(),
  '17 Plans': () => const PlansScreen(),
  '18 Privacy Policy': () => const PrivacyPolicyScreen(),
  '19 Terms': () => const TermsScreen(),
  '20 Ticket Details': () => const TicketDetailsScreen(),
  '21 Profile': () => const ProfileScreen(),
  'Dev Index': () => const DevIndexScreen(),
  'Community': () => const CommunityScreen(),
};

void main() {
  // Serve a real (tiny) PNG for every network image so image failures don't
  // masquerade as layout failures.
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = TestHttpOverrides();
  });

  tearDownAll(() => HttpOverrides.global = null);

  group('every screen renders without exceptions', () {
    screens.forEach((name, build) {
      testWidgets(name, (tester) async {
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(host(build()));

        // Let the mock repositories' artificial latency resolve.
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull, reason: '$name threw');
      });
    });
  });

  group('every screen survives a scroll to the bottom', () {
    screens.forEach((name, build) {
      testWidgets('$name scrolls', (tester) async {
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(host(build()));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty) {
          // Drag the primary scroll view a long way up.
          await tester.drag(scrollables.first, const Offset(0, -4000));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pumpAndSettle(const Duration(milliseconds: 100));
        }

        expect(tester.takeException(), isNull,
            reason: '$name threw while scrolling');
      });
    });
  });

  group('screens render on a small viewport without overflow', () {
    screens.forEach((name, build) {
      testWidgets('$name at 360x640dp', (tester) async {
        // A deliberately cramped device — overflow shows up here first.
        tester.view.physicalSize = const Size(720, 1280);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(host(build()));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull,
            reason: '$name overflowed on a small screen');
      });
    });
  });
}
