import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'core/routes.dart';
import 'core/theme/app_theme.dart';
import 'data/models/models.dart';
import 'screens/dev_index.dart';
import 'screens/s01_floor_plan.dart';
import 'screens/s02_support_center.dart';
import 'screens/s03_notifications.dart';
import 'screens/s04_admin_dashboard.dart';
import 'screens/s04a_admin_communities.dart';
import 'screens/s04b_admin_properties.dart';
import 'screens/s05_maintenance_dashboard.dart';
import 'screens/s06_tenant_dashboard.dart';
import 'screens/s07_owner_dashboard.dart';
import 'screens/s08_villa_details.dart';
import 'screens/s09_search.dart';
import 'screens/s10_login.dart';
import 'screens/s10_signup.dart';
import 'screens/s_forgot_password.dart';
import 'screens/s_live_chat.dart';
import 'screens/s_personal_info.dart';
import 'screens/s_security.dart';
import 'screens/s_notification_settings.dart';
import 'screens/s_account_settings.dart';
import 'screens/s_language.dart';
import 'screens/s_payment_methods.dart';
import 'screens/s_saved_searches.dart';
import 'screens/s_support_category.dart';
import 'screens/s12_property_details.dart';
import 'screens/s13_gallery.dart';
import 'screens/s14_sell_property.dart';
import 'screens/s15_about.dart';
import 'screens/s16_contact.dart';
import 'screens/s17_plans.dart';
import 'screens/s18_s19_legal.dart';
import 'screens/s20_ticket_details.dart';
import 'screens/s21_profile.dart';
import 'screens/shell.dart';
import 'screens/supporting.dart';

class ResivynApp extends StatefulWidget {
  const ResivynApp({super.key});

  @override
  State<ResivynApp> createState() => _ResivynAppState();
}

class _ResivynAppState extends State<ResivynApp> {
  final _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  /// Central route table. Arguments are read here so screens stay
  /// constructor-driven and remain trivially testable in isolation.
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    Widget builder() {
      switch (settings.name) {
        case Routes.login:
          return const LoginScreen();
        case Routes.signup:
          return const SignupScreen();
        case Routes.forgotPassword:
          return const ForgotPasswordScreen();
        case Routes.liveChat:
          return const LiveChatScreen();
        case Routes.personalInfo:
          return const PersonalInfoScreen();
        case Routes.security:
          return const SecurityScreen();
        case Routes.notificationSettings:
          return const NotificationSettingsScreen();
        case Routes.accountSettings:
          return const AccountSettingsScreen();
        case Routes.language:
          return const LanguageScreen();
        case Routes.paymentMethods:
          return const PaymentMethodsScreen();
        case Routes.savedSearches:
          return const SavedSearchesScreen();
        case Routes.supportCategory:
          return SupportCategoryDetailScreen(
              category: args is String ? args : 'Support');
        case Routes.devIndex:
          return const DevIndexScreen();
        case Routes.shell:
          return MainShell(initialIndex: args is int ? args : 0);

        case Routes.search:
          return const SearchScreen();
        case Routes.saved:
          return const Scaffold(body: SafeArea(child: SavedScreen()));
        case Routes.community:
          return const CommunityScreen();
        case Routes.profile:
          return const ProfileScreen();

        case Routes.propertyDetails:
          return PropertyDetailsScreen(
              property: args is Property ? args : null);
        case Routes.villaDetails:
          return const VillaDetailsScreen();
        case Routes.floorPlan:
          return FloorPlanScreen(property: args is Property ? args : null);
        case Routes.gallery:
          return GalleryScreen(property: args is Property ? args : null);
        case Routes.sellProperty:
          return const SellPropertyScreen();

        case Routes.support:
          return const SupportCenterScreen();
        case Routes.ticketDetails:
          return const TicketDetailsScreen();
        case Routes.notifications:
          return const NotificationsScreen();

        case Routes.adminDashboard:
          return const AdminDashboardScreen();
        case Routes.adminCommunities:
          return const AdminCommunitiesScreen();
        case Routes.adminProperties:
          return const AdminPropertiesScreen();
        case Routes.maintenanceDashboard:
          return const MaintenanceDashboardScreen();
        case Routes.tenantDashboard:
          return const TenantDashboardScreen();
        case Routes.ownerDashboard:
          return const OwnerDashboardScreen();

        case Routes.about:
          return const AboutScreen();
        case Routes.contact:
          return const ContactScreen();
        case Routes.plans:
          return const PlansScreen();
        case Routes.privacy:
          return const PrivacyPolicyScreen();
        case Routes.terms:
          return const TermsScreen();

        default:
          return const LoginScreen();
      }
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => builder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'RESIVYN',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: context.locale,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        initialRoute: Routes.login,
        onGenerateRoute: _onGenerateRoute,
        // Keep the layout stable regardless of the device font-scale setting.
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(
                media.textScaler.scale(1).clamp(0.85, 1.15),
              ),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
