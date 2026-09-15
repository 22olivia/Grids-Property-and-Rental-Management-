import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resivyn/app.dart';
import 'package:resivyn/core/app_state.dart';
import 'package:resivyn/screens/s09_search.dart';
import 'package:resivyn/screens/s14_sell_property.dart';
import 'package:resivyn/screens/s20_ticket_details.dart';
import 'package:resivyn/screens/s04_admin_dashboard.dart';
import 'package:resivyn/screens/s06_tenant_dashboard.dart';
import 'package:resivyn/screens/s07_owner_dashboard.dart';
import 'package:resivyn/screens/s05_maintenance_dashboard.dart';
import 'package:resivyn/screens/shell.dart';

import 'test_http.dart';

/// Drives the real app through the flows a reviewer would click through,
/// so "it renders" is backed up by "it actually works".
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = TestHttpOverrides();
  });

  tearDownAll(() => HttpOverrides.global = null);

  /// A tall surface so lazily-built list children are actually constructed
  /// and every control is on-screen and tappable.
  void useTallPhone(WidgetTester tester, {double width = 1080}) {
    tester.view.physicalSize = Size(width, 7200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      AppScope(state: AppState(), child: MaterialApp(home: screen)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  Future<void> boot(WidgetTester tester, {double width = 1080}) async {
    useTallPhone(tester, width: width);

    await tester.pumpWidget(const ResivynApp());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  testWidgets('app boots on the login screen', (tester) async {
    await boot(tester);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('SELECT YOUR ROLE'), findsOneWidget);
  });

  testWidgets('signing in as Visitor opens the tab shell', (tester) async {
    await boot(tester);

    await tester.tap(find.text('Sign In'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Good morning, Alex'), findsWidgets);
  });

  // One test per role: each needs a fresh widget tree, otherwise the previous
  // role's navigation stack carries over.
  final roleDestinations = <String, Type>{
    'Tenant': TenantDashboardScreen,
    'Owner': OwnerDashboardScreen,
    'Maintainer': MaintenanceDashboardScreen,
    'Super Admin': AdminDashboardScreen,
  };

  roleDestinations.forEach((role, screen) {
    testWidgets('signing in as $role opens its dashboard', (tester) async {
      // Extra width so the horizontal role chips are all on-screen.
      await boot(tester, width: 2000);

      await tester.tap(find.text(role));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      await tester.tap(find.text('Sign In'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.byType(screen), findsOneWidget,
          reason: '$role did not reach its dashboard');
    });
  });

  testWidgets('bottom navigation switches tabs in the shell', (tester) async {
    await boot(tester);
    await tester.tap(find.text('Sign In'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('Nothing saved yet'), findsOneWidget);

    await tester.tap(find.text('Search').last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('Search Properties'), findsOneWidget);
  });

  testWidgets('saving a property makes it appear in the Saved tab',
      (tester) async {
    await boot(tester);
    await tester.tap(find.text('Sign In'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    // Go to Search, where full property cards with a save button are listed.
    await tester.tap(find.text('Search').last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    final heart = find.byIcon(Icons.favorite_border_rounded);
    expect(heart, findsWidgets);
    await tester.tap(heart.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.text('Nothing saved yet'), findsNothing);
    expect(find.textContaining('propert'), findsWidgets);
  });

  testWidgets('search filters results as the query changes', (tester) async {
    useTallPhone(tester);
    await pumpScreen(tester, const SearchScreen());

    // "Buy" is the default tab, so the villa and the office are listed.
    expect(find.text('Luxury Villa'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Business Bay');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Luxury Villa'), findsNothing);
    expect(find.text('Prime Office Space'), findsOneWidget);

    // A query that matches nothing shows the empty state.
    await tester.enterText(find.byType(TextField).first, 'zzzzz');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('No matching properties'), findsOneWidget);
  });

  testWidgets('search Buy/Rent tabs change the result set', (tester) async {
    useTallPhone(tester);
    await pumpScreen(tester, const SearchScreen());

    expect(find.text('Marina Apartment'), findsNothing);

    await tester.tap(find.text('Rent'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Marina Apartment'), findsOneWidget);
    expect(find.text('Luxury Villa'), findsNothing);
  });

  testWidgets('the sell-property form advances through its steps',
      (tester) async {
    useTallPhone(tester);
    await pumpScreen(tester, const SellPropertyScreen());

    expect(find.text('Listing Type'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('Property Details'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('Location'), findsWidgets);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('Photos & Media'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('Review & Submit'), findsOneWidget);
    expect(find.text('Submit Listing'), findsOneWidget);

    // Going back returns to the previous step.
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    expect(find.text('Photos & Media'), findsOneWidget);
  });

  testWidgets('sending a ticket reply appends it to the conversation',
      (tester) async {
    useTallPhone(tester);
    await pumpScreen(tester, const TicketDetailsScreen());

    expect(find.text('Just now'), findsNothing);

    await tester.enterText(find.byType(TextField).last, 'Any update on this?');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.text('Any update on this?'), findsOneWidget);
    expect(find.text('Just now'), findsOneWidget);
  });

  testWidgets('marking a ticket resolved updates its status', (tester) async {
    useTallPhone(tester);
    await pumpScreen(tester, const TicketDetailsScreen());

    await tester.tap(find.text('Mark as Resolved'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.text('Ticket Resolved'), findsOneWidget);
  });

  testWidgets('the tenant can pay rent end to end', (tester) async {
    useTallPhone(tester);
    await pumpScreen(tester, const TenantDashboardScreen());

    expect(find.text('Rent Due'), findsOneWidget);

    await tester.tap(find.text('Pay Rent Now'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(find.text('Confirm payment'), findsOneWidget);

    await tester.tap(find.text('Pay AED 12,850'));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.text('Rent Paid'), findsOneWidget);
    expect(find.text('View Receipt'), findsOneWidget);
  });
}
